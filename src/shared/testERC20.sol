// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract OWPERC20 is ERC20 {


    address public immutable owner;


    constructor(string memory name, string memory symbol) ERC20(name, symbol){
        owner = msg.sender;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}