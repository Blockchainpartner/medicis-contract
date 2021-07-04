// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BasicToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("DAI", "DAI") {
        _mint(msg.sender, initialSupply);
    }

    function performMint(address to, uint256 amount) external {
        _mint(to, amount);
	}
}
