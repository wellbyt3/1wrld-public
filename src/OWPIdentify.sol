// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.22;

import "../lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {NativeMetaTransaction} from "./meta-transaction/NativeMetaTransaction.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract OWPIdentity is ERC1155, AccessControl, ERC1155Burnable, ERC1155Supply, NativeMetaTransaction {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    using Strings for uint256;
    string public name = "One World Project";
    string public symbol = "OWP";

    constructor(address defaultAdmin, address minter, string memory newUri) ERC1155(newUri) {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
    }

    function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newuri);
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string.concat(super.uri(tokenId), tokenId.toString());
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        _mintBatch(to, ids, amounts, data);
    }

    function burn(address account, uint256 id, uint256 amount)
        public override
        onlyRole(MINTER_ROLE)
    {
        _burn(account, id, amount);
    }

    function burnBatch(address to, uint256[] memory ids, uint256[] memory amounts)
        public override
        onlyRole(MINTER_ROLE)
    {
        _burnBatch(to, ids, amounts);
    }

    function burnBatchMultiple(address[] memory tos, uint256[] memory ids, uint256[] memory amounts)
        public
        onlyRole(MINTER_ROLE)
    {
        require(tos.length == ids.length, "Invalid input");
        require(amounts.length == ids.length, "Invalid input");

        for(uint256 i = 0; i < tos.length; i++){
            _burn(tos[i], ids[i], amounts[i]);            
        }
    }

    // The following functions are overrides required by Solidity.
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override(ERC1155, ERC1155Supply){
        require(from == address(0) || to == address(0), "OWPIdentity: NFT Not transferrable.");
        super._update(from, to, ids, amounts);
    }

    function _msgSender()
        internal
        view
        override
        returns (address sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}