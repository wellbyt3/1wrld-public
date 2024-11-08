// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
interface IMembershipERC1155 {
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _owner,
        address _currency
    ) external;

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;
}
