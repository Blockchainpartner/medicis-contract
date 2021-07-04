// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../Donatore.sol";
import "../Beneficiario.sol";

contract WithGovernance {
    uint256 	public constant MAX_BPS = 10000; // 100%
	uint256 	public performanceFee = 500; // 5%
    uint256 	public managementFee = 500; // 5%
    address 	public governance = address(0);
    address 	public management = address(0);
    address 	public guardian = address(0);
    address 	public pendingGovernance = address(0);
    address 	public rewards = address(0);
    Donatori    public donatori;
    Beneficiari public beneficiari;

    event UpdateGovernance(address indexed governance);
    event UpdateManagement(address indexed management);
    event UpdateGuardian(address indexed pendingGovernance);
    event UpdateRewards(address indexed rewards);
    event UpdateDonatori(address indexed donatori);
    event UpdateBeneficiari(address indexed beneficiari);
    event UpdatePerformanceFee(uint256 governance);
    event UpdateManagementFee(uint256 management);

	modifier onlyGovernance() {
		require(msg.sender == governance, "!authorized");
		_;
	}
	modifier onlyPendingGovernance() {
		require(msg.sender == pendingGovernance, "!authorized");
		_;
	}
	modifier onlyGuardianOrGovernance() {
		require(msg.sender == guardian || msg.sender == governance, "!authorized");
		_;
	}
	modifier onlyManagement() {
		require(msg.sender == management, "!authorized");
		_;
	}
	modifier onlyManagementOrGovernance() {
		require(msg.sender == management || msg.sender == governance, "!authorized");
		_;
	}

	/*******************************************************************************
	**	@notice
	**		Nominate a new address to use as governance.
	**		The change does not go into effect immediately. This function sets a
	**		pending change, and the governance address is not updated until
	**		the proposed governance address has accepted the responsibility.
	**		This may only be called by the current governance address.
	**	@param _governance The address requested to take over Vault governance.
	*******************************************************************************/
    function setGovernance(address _governance) public onlyGovernance() {
		pendingGovernance = _governance;
	}

	/*******************************************************************************
	**	@notice
	**		Once a new governance address has been proposed using setGovernance(),
	**		this function may be called by the proposed address to accept the
	**		responsibility of taking over governance for this contract.
	**		This may only be called by the proposed governance address.
	**	@dev
	**		setGovernance() should be called by the existing governance address,
	**		prior to calling this function.
	*******************************************************************************/
    function acceptGovernance() public onlyPendingGovernance() {
		governance = msg.sender;
		emit UpdateGovernance(msg.sender);
	}

	/*******************************************************************************
	**	@notice
	**		Used to change the address of `guardian`.
	**		This may only be called by governance or the existing guardian.
	**	@param _guardian The new guardian address to use.
	*******************************************************************************/
    function setGuardian(address _guardian) public onlyGuardianOrGovernance() {
		guardian = _guardian;
		emit UpdateGuardian(guardian);
	}
	
	/*******************************************************************************
	**	@notice
	**		Used to change the address of `management`.
	**		This may only be called by governance
	**	@param _management The new management address to use.
	*******************************************************************************/
    function setManagement(address _management) public onlyGovernance() {
		management = _management;
		emit UpdateManagement(management);
	}

	/*******************************************************************************
	**	@notice
	**		Used to change the address of `rewards`.
	**		This may only be called by governance
	**	@param _rewards The new rewards address to use.
	*******************************************************************************/
    function setRewards(address _rewards) public onlyGovernance() {
		rewards = _rewards;
		emit UpdateRewards(rewards);
	}

	/*******************************************************************************
	**	@notice
	**		Used to change the address of `donatori`.
	**		This may only be called by governance
	**	@param _donatori The new donatori address to use.
	*******************************************************************************/
    function setDonatori(address _donatori) public onlyGovernance() {
		donatori = Donatori(_donatori);
		emit UpdateDonatori(address(donatori));
	}

	/*******************************************************************************
	**	@notice
	**		Used to change the address of `beneficiari`.
	**		This may only be called by governance
	**	@param _beneficiari The new beneficiari address to use.
	*******************************************************************************/
    function setBeneficiari(address _beneficiari) public onlyGovernance() {
		beneficiari = Beneficiari(_beneficiari);
		emit UpdateBeneficiari(address(beneficiari));
	}
	
	/*******************************************************************************
	**	@notice
	**		Used to change the value of `performanceFee`.
	**		Should set this value below the maximum strategist performance fee.
	**		This may only be called by governance.
	**	@param _performanceFee The new performance fee to use.
	*******************************************************************************/
    function setPerformanceFee(uint256 _performanceFee) public onlyGovernance() {
		require(_performanceFee <= MAX_BPS, "above capacity");

		performanceFee = _performanceFee;
		emit UpdatePerformanceFee(_performanceFee);
	}

	/*******************************************************************************
	**	@notice
	**		Used to change the value of `managementFee`.
	**		This may only be called by governance.
	**	@param _managementFee The new management fee to use.
	*******************************************************************************/
    function setManagementFee(uint256 _managementFee) public onlyGovernance() {
		require(_managementFee <= MAX_BPS, "above capacity");

		managementFee = _managementFee;
		emit UpdateManagementFee(_managementFee);
	}
	
	function unPauseDonatori() external onlyGovernance() {
		donatori.unpause();
	}
	function unPauseBeneficiari() external onlyGovernance() {
		beneficiari.unpause();
	}
}

