// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./WithRules.sol";

interface Strategy {
	function want() external returns (address);
	function vault() external returns (address);
	function estimatedTotalAssets() external returns (uint256);
	function withdraw(uint256 _amount) external returns (uint256);
	function migrate(address _newStrategy) external;
}

contract WithStrategies is WithRules {
    uint256 public constant MAXIMUM_STRATEGIES = 20;

	struct StrategyParams {
		uint256 performanceFee;
		uint256 activation;
		uint256 debtRatio;
		uint256 rateLimit;
		uint256 lastReport;
		uint256 totalDebt;
		uint256 totalGain;
		uint256 totalLoss;
	}

	event StrategyAdded(address strategy, uint256 debtRatio, uint256 rateLimit, uint256 performanceFee);
	event StrategyReported(address strategy, uint256 gain, uint256 loss, uint256 totalGain, uint256 totalLoss, uint256 totalDebt, uint256 debtAdded, uint256 debtRatio);
	event StrategyUpdateDebtRatio(address strategy, uint256 debtRatio);
	event StrategyUpdateRateLimit(address strategy, uint256 rateLimit);
	event StrategyUpdatePerformanceFee(address strategy, uint256 performanceFee);
	event StrategyMigrated(address oldVersion, address newVersion);
	event StrategyRevoked(address strategy);
	event StrategyRemovedFromQueue(address strategy);
	event StrategyAddedToQueue(address strategy);
	event UpdateWithdrawalQueue(address[MAXIMUM_STRATEGIES] queue);

	mapping (address => StrategyParams) public strategies;

	uint256 debtRatio = 0;  // Debt ratio for the Vault across all strategies (in BPS, <= 10k)
	uint256 totalDebt = 0;  // Amount of tokens that all strategies have borrowed
	uint256 lastReport = 0;  // block.timestamp of last report
	// Ordering that `withdraw` uses to determine which strategies to pull funds from
	// NOTE: Does *NOT* have to match the ordering of all the current strategies that
	//       exist, but it is recommended that it does or else withdrawal depth is
	//       limited to only those inside the queue.
	// NOTE: Ordering is determined by governance, and should be balanced according
	//       to risk, slippage, and/or volatility. Can also be ordered to increase the
	//       withdrawal speed of a particular Strategy.
	// NOTE: The first time a address(0) is encountered, it stops withdrawing
	address[MAXIMUM_STRATEGIES] public withdrawalQueue;

	modifier onlyActivated(address strategy) {
		require(strategies[strategy].activation > 0, "!activated");
		_;
	}

	/*******************************************************************************
    **	@notice
    **		The totalAssets represent the total amount of underlying managed by this 
    **      contract, aka the underlying in the contract wallet, but also the
    **      underlying lended to the strategies.
    **  @return: The total amount of assets under management.
    *******************************************************************************/
	function totalAssets() internal view returns (uint256) {
	    return token.balanceOf(address(this)) + totalDebt;
	}

	function debt() public view returns (uint256) { //TODO: switch to internal
	    return totalDebt;
	}

	/*******************************************************************************
	**	@notice
	**		Updates the withdrawalQueue to match the addresses and order specified
	**		by `queue`.
	**		There can be fewer strategies than the maximum, as well as fewer than
	**		the total number of strategies active in the vault. `withdrawalQueue`
	**		will be updated in a gas-efficient manner, assuming the input is well-
	**		ordered with 0x0 only at the end.
	**		This may only be called by governance or management.
	**	@dev
	**		This is order sensitive, specify the addresses in the order in which
	**		funds should be withdrawn (so `queue`[0] is the first Strategy withdrawn
	**		from, `queue`[1] is the second, etc.)
	**		This means that the least impactful Strategy (the Strategy that will have
	**		its core positions impacted the least by having funds removed) should be
	**		at `queue`[0], then the next least impactful at `queue`[1], and so on.
	**	@param queue
	**		The array of addresses to use as the new withdrawal queue. This is
	**		order sensitive.
	*******************************************************************************/
	function setWithdrawalQueue(address[MAXIMUM_STRATEGIES] memory queue) external onlyManagementOrGovernance() {
		// HACK: Temporary until Vyper adds support for Dynamic arrays
		for(uint256 i = 0; i < queue.length; i++) {
			require(strategies[queue[i]].activation > 0, "!activated");
			withdrawalQueue[i] = queue[i];
		}
		emit UpdateWithdrawalQueue(queue);
	}

	function _organizeWithdrawalQueue() internal {
		// Reorganize `withdrawalQueue` based on premise that if there is an
		// empty value between two actual values, then the empty value should be
		// replaced by the later value.
		// NOTE: Relative ordering of non-zero values is maintained.
		uint256 offset = 0;
		for (uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
			address strategy = withdrawalQueue[i];
			if (strategy == address(0)) {
				offset += 1;  // how many values we need to shift, always `<= i`
			} else if (offset > 0) {
				withdrawalQueue[i - offset] = strategy;
				withdrawalQueue[i] = address(0);
			}
		}
	}

	/*******************************************************************************
	**	@notice
	**		Add a Strategy to the Vault.
	**		This may only be called by governance.
	**	@dev
	**		The Strategy will be appended to `withdrawalQueue`, call
	**		`setWithdrawalQueue` to change the order.
	**	@param strategy The address of the Strategy to add.
	**	@param debtRatio The ratio of the total assets in the `vault that the `strategy` can manage.
	**	@param rateLimit
	**		Limit on the increase of debt per unit time since last harvest
	**	@param performanceFee
	**		The fee the strategist will receive based on this Vault's performance.
	*******************************************************************************/
	function addStrategy(address strategy, uint256 _debtRatio, uint256 _rateLimit, uint256 _performanceFee) external onlyGovernance() {
		require(strategy != address(0), "invalid address");
		require(!emergencyShutdown, "emergencyShutdown");
		require(debtRatio + _debtRatio <= MAX_BPS, "invalid debtRatio");
		require(_performanceFee <= MAX_BPS - performanceFee, "invalid performanceFee");
		require(strategies[strategy].activation == 0, "already activated");
		require(address(this) == Strategy(strategy).vault(), "invalid medicis contract");
		require(address(token) == Strategy(strategy).want(), "invalid token");

		strategies[strategy] = StrategyParams({
			performanceFee: _performanceFee,
			activation: block.timestamp,
			debtRatio: _debtRatio,
			rateLimit: _rateLimit,
			lastReport: block.timestamp,
			totalDebt: 0,
			totalGain: 0,
			totalLoss: 0
		});
		debtRatio += _debtRatio;
		emit StrategyAdded(strategy, _debtRatio, _rateLimit, _performanceFee);

		require(withdrawalQueue[MAXIMUM_STRATEGIES - 1] == address(0), "queue is full");
		withdrawalQueue[MAXIMUM_STRATEGIES - 1] = strategy;
		_organizeWithdrawalQueue();
	}

	/*******************************************************************************
	**	@notice
	**		Change the quantity of assets `strategy` may manage.
	**		This may be called by governance or management.
	**	@param strategy The Strategy to update.
	**	@param debtRatio The quantity of assets `strategy` may now manage.
	*******************************************************************************/
	function updateStrategyDebtRatio(address strategy, uint256 _debtRatio) external onlyManagementOrGovernance() onlyActivated(strategy) {
		debtRatio -= strategies[strategy].debtRatio;
		strategies[strategy].debtRatio = _debtRatio;
		debtRatio += _debtRatio;
		require(debtRatio <= MAX_BPS, "invalid debtRatio");
		emit StrategyUpdateDebtRatio(strategy, _debtRatio);
	}

	/*******************************************************************************
	**	@notice
	**		Change the quantity assets per block this Vault may deposit to or
	**		withdraw from `strategy`.
	**		This may only be called by governance or management.
	**	@param strategy The Strategy to update.
	**	@param rateLimit Limit on the increase of debt per unit time since last harvest
	*******************************************************************************/
	function updateStrategyRateLimit(address strategy, uint256 _rateLimit) external onlyManagementOrGovernance() onlyActivated(strategy) {
		strategies[strategy].rateLimit = _rateLimit;
		emit StrategyUpdateRateLimit(strategy, _rateLimit);
	}

	/*******************************************************************************
	**	@notice
	**		Change the fee the strategist will receive based on this Vault's
	**		performance.
	**		This may only be called by governance.
	**	@param strategy The Strategy to update.
	**	@param performanceFee The new fee the strategist will receive.
	*******************************************************************************/
	function updateStrategyPerformanceFee(address strategy, uint256 _performanceFee) external onlyGovernance() onlyActivated(strategy) {
		require(_performanceFee <= MAX_BPS - performanceFee, "invalid performanceFee");
		strategies[strategy].performanceFee = _performanceFee;
		emit StrategyUpdatePerformanceFee(strategy, _performanceFee);
	}


	function _revokeStrategy(address strategy) internal {
		debtRatio -= strategies[strategy].debtRatio;
		strategies[strategy].debtRatio = 0;
		emit StrategyRevoked(strategy);
	}

	/*******************************************************************************
	**	@notice
	**		Migrates a Strategy, including all assets from `oldVersion` to
	**		`newVersion`.
	**		This may only be called by governance.
	**	@dev
	**		Strategy must successfully migrate all capital and positions to new
	**		Strategy, or else this will upset the balance of the Vault.
	**		The new Strategy should be "empty" e.g. have no prior commitments to
	**		this Vault, otherwise it could have issues.
	**	@param oldVersion The existing Strategy to migrate from.
	**	@param newVersion The new Strategy to migrate to.
	*******************************************************************************/
	function migrateStrategy(address oldVersion, address newVersion) external onlyGovernance() onlyActivated(oldVersion) {
		require(newVersion != address(0), "invalid version");
		require(strategies[newVersion].activation == 0, "strategy already activated");

		StrategyParams memory strategy = strategies[oldVersion];
		_revokeStrategy(oldVersion);
		debtRatio += strategy.debtRatio; // _revokeStrategy will lower the debtRatio
		strategies[oldVersion].totalDebt = 0; // Debt is migrated to new strategy

		strategies[newVersion] = StrategyParams({
			performanceFee: strategy.performanceFee,
			activation: block.timestamp,
			debtRatio: strategy.debtRatio,
			rateLimit: strategy.rateLimit,
			lastReport: block.timestamp,
			totalDebt: strategy.totalDebt,
			totalGain: 0,
			totalLoss: 0
		});

		Strategy(oldVersion).migrate(newVersion);
		emit StrategyMigrated(oldVersion, newVersion);
		// TODO: Ensure a smooth transition in terms of  Strategy return

		for(uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
			if (withdrawalQueue[i] == oldVersion) {
				withdrawalQueue[i] = newVersion;
				return; // Don't need to reorder anything because we swapped
			}
		}
	}

	/*******************************************************************************
	**	@notice
	**		Revoke a Strategy, setting its debt limit to 0 and preventing any
	**		future deposits.
	**		This function should only be used in the scenario where the Strategy is
	**		being retired but no migration of the positions are possible, or in the
	**		extreme scenario that the Strategy needs to be put into "Emergency Exit"
	**		mode in order for it to exit as quickly as possible. The latter scenario
	**		could be for any reason that is considered "critical" that the Strategy
	**		exits its position as fast as possible, such as a sudden change in market
	**		conditions leading to losses, or an imminent failure in an external
	**		dependency.
	**		This may only be called by governance, the guardian, or the Strategy
	**		itself. Note that a Strategy will only revoke itself during emergency
	**		shutdown.
	**	@param strategy The Strategy to revoke.
	*******************************************************************************/
	function revokeStrategy(address strategy) external {
		require(msg.sender == strategy || msg.sender == governance || msg.sender == guardian , "!authorized");
		_revokeStrategy(strategy);
	}

	/*******************************************************************************
	**	@notice
	**		Adds `strategy` to `withdrawalQueue`.
	**		This may only be called by governance or management.
	**	@dev
	**		The Strategy will be appended to `withdrawalQueue`, call
	**		`setWithdrawalQueue` to change the order.
	**	@param strategy The Strategy to add.
	*******************************************************************************/
	function addStrategyToQueue(address strategy) external onlyManagementOrGovernance() onlyActivated(strategy) {
		require(withdrawalQueue[MAXIMUM_STRATEGIES - 1] == address(0), "queue is full");

		for(uint256 i = 0; i < withdrawalQueue.length; i++) {
			if (strategy == address(0)) {
				break;
			}
			require (withdrawalQueue[i] != strategy, "already strategy");
		}
		withdrawalQueue[MAXIMUM_STRATEGIES - 1] = strategy;
		_organizeWithdrawalQueue();
		emit StrategyAddedToQueue(strategy);
	}

	/*******************************************************************************
	**	@notice
	**		Remove `strategy` from `withdrawalQueue`.
	**		This may only be called by governance or management.
	**	@dev
	**		We don't do this with revokeStrategy because it should still
	**		be possible to withdraw from the Strategy if it's unwinding.
	**	@param strategy The Strategy to remove.
	*******************************************************************************/
	function removeStrategyFromQueue(address strategy) external onlyManagementOrGovernance() {
		for(uint256 i = 0; i < MAXIMUM_STRATEGIES; i++) {
			if (withdrawalQueue[i] == strategy) {
				withdrawalQueue[i] = address(0);
				_organizeWithdrawalQueue();
				emit StrategyRemovedFromQueue(strategy);
				return;  // We found the right location and cleared it
			}
		}
		revert();  // We didn't find the Strategy in the queue
	}

	/*******************************************************************************
	**	@notice
	**		Determines if `strategy` is past its debt limit and if any tokens
	**		should be withdrawn to the Vault.
	**	@param strategy The Strategy to check. Defaults to the caller.
	**	@return The quantity of tokens to withdraw.
	*******************************************************************************/
	function debtOutstanding(address strategy) external view returns(uint256) {
		return _debtOutstanding(strategy);
	}
	function debtOutstanding() external view returns(uint256) {
		return _debtOutstanding(msg.sender);
	}

	function _debtOutstanding(address strategy) internal view returns(uint256) {
		uint256 strategy_debtLimit = strategies[strategy].debtRatio * totalAssets() / MAX_BPS;
		uint256 strategy_totalDebt = strategies[strategy].totalDebt;

		if (emergencyShutdown) {
			return strategy_totalDebt;
		} else if (strategy_totalDebt <= strategy_debtLimit) {
			return 0;
		}
		return strategy_totalDebt - strategy_debtLimit;
	}

	/*******************************************************************************
	**	@notice
	**		Amount of tokens in Vault a Strategy has access to as a credit line.
	**		This will check the Strategy's debt limit, as well as the tokens
	**		available in the Vault, and determine the maximum amount of tokens
	**		(if any) the Strategy may draw on.
	**		In the rare case the Vault is in emergency shutdown this will return 0.
	**	@param strategy The Strategy to check. Defaults to caller.
	**	@return The quantity of tokens available for the Strategy to draw on.
	*******************************************************************************/
	function creditAvailable(address strategy) external view returns(uint256) {
		return _creditAvailable(strategy);
	}

	function _creditAvailable(address strategy) internal view returns(uint256) {
		if (emergencyShutdown) {
			return 0;
		}

		uint256 vault_totalAssets = totalAssets();
		uint256 vault_debtLimit = debtRatio * vault_totalAssets / MAX_BPS;
		uint256 vault_totalDebt = totalDebt;
		uint256 strategy_debtLimit = strategies[strategy].debtRatio * vault_totalAssets / MAX_BPS;
		uint256 strategy_totalDebt = strategies[strategy].totalDebt;
		uint256 strategy_rateLimit = strategies[strategy].rateLimit;
		uint256 strategy_lastReport = strategies[strategy].lastReport;

		// Exhausted credit line
		if (strategy_debtLimit <= strategy_totalDebt || vault_debtLimit <= vault_totalDebt) {
			return 0;
		}

		// Start with debt limit left for the Strategy
		uint256 available = strategy_debtLimit - strategy_totalDebt;

		// Adjust by the global debt limit left
		available = Math.min(available, vault_debtLimit - vault_totalDebt);

		// Adjust by the rate limit algorithm (limits the step size per reporting period)
		uint256 delta = block.timestamp - strategy_lastReport;
		// NOTE: Protect against unnecessary overflow faults here
		// NOTE: Set `strategy_rateLimit` to 0 to disable the rate limit
		if (strategy_rateLimit > 0 && available / strategy_rateLimit >= delta) {
			available = strategy_rateLimit * delta;
		}

		// Can only borrow up to what the contract has in reserve
		// NOTE: Running near 100% is discouraged
		return Math.min(available, token.balanceOf(address(this)));
	}


	/*******************************************************************************
	**	@notice
	**		Provide an accurate expected value for the return this `strategy`
	**		would provide to the Vault the next time `report()` is called
	**		(since the last time it was called).
	**	@param strategy The Strategy to determine the expected return for. Defaults to caller.
	**	@return
	**		The anticipated amount `strategy` should make on its investment
	**		since its last report.
	*******************************************************************************/
	function expectedReturn(address strategy) external view returns(uint256) {
		return _expectedReturn(strategy);
	}

	function _expectedReturn(address strategy) internal view returns(uint256) {
		uint256 delta = block.timestamp - strategies[strategy].lastReport;
		if (delta > 0) {
			// NOTE: Unlikely to throw unless strategy accumalates >1e68 returns
			// NOTE: Will not throw for DIV/0 because activation <= lastReport
			return (strategies[strategy].totalGain * delta) / (block.timestamp - strategies[strategy].activation);
		}
		return 0;  // Covers the scenario when block.timestamp == activation
	}

	function _reportLoss(address strategy, uint256 loss) internal {
		// Loss can only be up the amount of debt issued to strategy
		uint256 _totalDebt = strategies[strategy].totalDebt;
		require(_totalDebt >= loss, "invalid loss");
		strategies[strategy].totalLoss += loss;
		strategies[strategy].totalDebt = _totalDebt - loss;
		totalDebt -= loss;

		// Also, make sure we reduce our trust with the strategy by the same amount
		uint256 _debtRatio = strategies[strategy].debtRatio;
		strategies[strategy].debtRatio -= Math.min(loss * MAX_BPS / totalAssets(), _debtRatio);
	}
}