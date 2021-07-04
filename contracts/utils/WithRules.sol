// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./WithGovernance.sol";

contract WithRules is WithGovernance {
	bool public emergencyShutdown = false;
    uint256 public depositLimit;
    uint256 public maxGrants = 10;
    ERC20 public token;
    
    event EmergencyShutdown(bool active);
    event UpdateDepositLimit(uint256 limit);
    event UpdateMaxGrants(uint256 maxGrants);

    /*******************************************************************************
    **	@notice
    **		Activates or deactivates Vault mode where all Strategies go into full
    **		withdrawal.
    **		During Emergency Shutdown:
    **		1. No Users may deposit into the Vault (but may withdraw as usual.)
    **		2. Governance may not add new Strategies.
    **		3. Each Strategy must pay back their debt as quickly as reasonable to
    **			minimally affect their position.
    **		4. Only Governance may undo Emergency Shutdown.
    **		See contract level note for further details.
    **		This may only be called by governance or the guardian.
    **	@param active
    **		If true, the Vault goes into Emergency Shutdown. If false, the Vault
    **		goes back into Normal Operation.
    *******************************************************************************/
    function setEmergencyShutdown(bool active) public {
        if (active) {
            assert(msg.sender == guardian || msg.sender == governance);
        } else {
            assert(msg.sender == governance);
        }
        emergencyShutdown = active;
        emit EmergencyShutdown(active);
    }

    /*******************************************************************************
    **	@notice
    **		Changes the maximum amount of tokens that can be deposited in this Vault.
    **		Note, this is not how much may be deposited by a single depositor,
    **		but the maximum amount that may be deposited across all depositors.
    **		This may only be called by governance.
    **	@param limit The new deposit limit to use.
    *******************************************************************************/
    function setDepositLimit(uint256 limit) public onlyGovernance() {
        depositLimit = limit;
        emit UpdateDepositLimit(limit);
    }
    
    /*******************************************************************************
    **	@notice
    **		Changes the maximum number of grant you can have at the same time.
    **      The grant for one address is considered as one grant.
    **	@param _maxGrants The new maxGrants
    *******************************************************************************/
    function setMaxGrants(uint256 _maxGrants) public onlyGovernance() {
        maxGrants = _maxGrants;
        emit UpdateMaxGrants(maxGrants);
    }
}
