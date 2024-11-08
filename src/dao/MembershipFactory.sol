// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import { IMembershipERC1155 } from "./interfaces/IERC1155Mintable.sol";
import { ICurrencyManager } from "./interfaces/ICurrencyManager.sol";
import { DAOConfig, DAOInputConfig, TierConfig, DAOType, TIER_MAX } from "./libraries/MembershipDAOStructs.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "../../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../../lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import { NativeMetaTransaction } from "../meta-transaction/NativeMetaTransaction.sol";

/// @title Membership Factory Contract
/// @notice This contract is used for creating and managing DAO memberships using ERC1155 tokens.
contract MembershipFactory is AccessControl, NativeMetaTransaction {
    string public baseURI;
    ICurrencyManager public currencyManager;
    address public membershipImplementation;
    ProxyAdmin public proxyAdmin;
    address public owpWallet;

    mapping(address => DAOConfig) public daos;
    mapping(string => address) public getENSAddress;
    mapping(address => mapping(string => address)) public userCreatedDAOs;

    bytes32 public constant EXTERNAL_CALLER = keccak256("EXTERNAL_CALLER");

    event MembershipDAONFTCreated(string indexed ensName, address nftAddress, DAOConfig daoData);
    event UserJoinedDAO(address user, address membershipNftAddress, uint256 tierIndex);

    /// @param _currencyManager The address of the CurrencyManager contract
    /// @param _baseURI Base URI for the NFT metadata
    /// @param _membershipImplementation The address of the MembershipERC1155 implementation contract
    constructor(address _currencyManager, address _owpWallet, string memory _baseURI, address _membershipImplementation) {
        currencyManager = ICurrencyManager(_currencyManager);
        baseURI = _baseURI;
        owpWallet = _owpWallet;
        membershipImplementation = _membershipImplementation;
        proxyAdmin = new ProxyAdmin(msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(EXTERNAL_CALLER, msg.sender);
    }

    /// @notice Returns the tier configurations for a given membership NFT address
    /// @param membershipNftAddress The address of the Membership ERC1155 token
    /// @return An array of TierConfig
    function tiers(address membershipNftAddress) external view returns (TierConfig[] memory) {
        return daos[membershipNftAddress].tiers;
    }

    /// @notice Creates a new DAO membership
    /// @param daoConfig The configuration for the DAO
    /// @param tierConfigs The configurations for the tiers
    /// @return The address of the newly created Membership ERC1155 proxy contract
    function createNewDAOMembership(DAOInputConfig calldata daoConfig, TierConfig[] calldata tierConfigs)
        external returns (address) {
        
        require(currencyManager.isCurrencyWhitelisted(daoConfig.currency), "Currency not accepted.");

        require(daoConfig.noOfTiers == tierConfigs.length, "Invalid tier input.");

        require(daoConfig.noOfTiers > 0 && daoConfig.noOfTiers <= TIER_MAX, "Invalid tier count.");

        require(getENSAddress[daoConfig.ensname] == address(0), "DAO already exist.");
        
        if (daoConfig.daoType == DAOType.SPONSORED) {
            require(daoConfig.noOfTiers == TIER_MAX, "Invalid tier count for sponsored.");
        }

        // enforce maxMembers
        uint256 totalMembers = 0;
        for (uint256 i = 0; i < tierConfigs.length; i++) {
            totalMembers += tierConfigs[i].amount;
        }

        require(totalMembers <= daoConfig.maxMembers, "Sum of tier amounts exceeds maxMembers.");


        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            membershipImplementation, //logic contract
            address(proxyAdmin), // proxy admin role (that can upgrade the implementation)
            

            abi.encodeWithSignature("initialize(string,string,string,address,address)", 
                daoConfig.ensname, 
                "OWP", 
                baseURI, 
                _msgSender(),
                daoConfig.currency
            )
        );
        
        DAOConfig storage dao = daos[address(proxy)];
        dao.ensname = daoConfig.ensname;
        dao.daoType = daoConfig.daoType;
        dao.currency = daoConfig.currency;
        dao.maxMembers = daoConfig.maxMembers;
        dao.noOfTiers = daoConfig.noOfTiers;

        for (uint256 i = 0; i < tierConfigs.length; i++) {
            
            require(tierConfigs[i].minted == 0, "Invalid tier config");
            dao.tiers.push(tierConfigs[i]);
        }

        getENSAddress[daoConfig.ensname] = address(proxy);
        userCreatedDAOs[_msgSender()][daoConfig.ensname] = address(proxy);
        emit MembershipDAONFTCreated(daoConfig.ensname, address(proxy), dao);
        return address(proxy);
    }

    /// @notice Updates the tier configurations for a specific DAO
    /// @param ensName The ENS name of the DAO
    /// @param tierConfigs The new tier configurations
    /// @return The address of the updated DAO
    
    function updateDAOMembership(string calldata ensName, TierConfig[] memory tierConfigs)
        external onlyRole(EXTERNAL_CALLER) returns (address) {
        address daoAddress = getENSAddress[ensName];
        require(tierConfigs.length <= TIER_MAX, "Invalid tier count.");
        require(tierConfigs.length > 0, "Invalid tier count.");
        require(daoAddress != address(0), "DAO does not exist.");
        DAOConfig storage dao = daos[daoAddress];
        if(dao.daoType == DAOType.SPONSORED){
            require(tierConfigs.length == TIER_MAX, "Invalid tier count.");
        }

        uint256 maxMembers = 0;

        // Preserve minted values and adjust the length of dao.tiers

        for (uint256 i = 0; i < tierConfigs.length; i++) {
            if (i < dao.tiers.length) {
                tierConfigs[i].minted = dao.tiers[i].minted;
            }
        }

        // Reset and update the tiers array
        delete dao.tiers;
        for (uint256 i = 0; i < tierConfigs.length; i++) {
            dao.tiers.push(tierConfigs[i]);
            maxMembers += tierConfigs[i].amount;
        }

        // updating the ceiling limit acc to new data

        if(maxMembers > dao.maxMembers){
            dao.maxMembers = maxMembers;
        }

        dao.noOfTiers = tierConfigs.length;
        return daoAddress;
    }


    /// @notice Allows a user to join a DAO by purchasing a membership NFT at a specific tier
    /// @param daoMembershipAddress The address of the DAO membership NFT
    /// @param tierIndex The index of the tier to join
    function joinDAO(address daoMembershipAddress, uint256 tierIndex) external {
        require(daos[daoMembershipAddress].noOfTiers > tierIndex, "Invalid tier.");
        require(daos[daoMembershipAddress].tiers[tierIndex].amount > daos[daoMembershipAddress].tiers[tierIndex].minted, "Tier full.");
        uint256 tierPrice = daos[daoMembershipAddress].tiers[tierIndex].price;
        
        uint256 platformFees = (20 * tierPrice) / 100;
        daos[daoMembershipAddress].tiers[tierIndex].minted += 1;

        IERC20(daos[daoMembershipAddress].currency).transferFrom(_msgSender(), owpWallet, platformFees);
        
        IERC20(daos[daoMembershipAddress].currency).transferFrom(_msgSender(), daoMembershipAddress, tierPrice - platformFees);
    
        IMembershipERC1155(daoMembershipAddress).mint(_msgSender(), tierIndex, 1);
        emit UserJoinedDAO(_msgSender(), daoMembershipAddress, tierIndex);
    }

    /// @notice Allows users to upgrade their tier within a sponsored DAO
    /// @param daoMembershipAddress The address of the DAO membership NFT
    /// @param fromTierIndex The current tier index of the user
    function upgradeTier(address daoMembershipAddress, uint256 fromTierIndex) external {
        
        require(daos[daoMembershipAddress].daoType == DAOType.SPONSORED, "Upgrade not allowed.");
        
        require(daos[daoMembershipAddress].noOfTiers >= fromTierIndex + 1, "No higher tier available.");
        
        IMembershipERC1155(daoMembershipAddress).burn(_msgSender(), fromTierIndex, 2);
        IMembershipERC1155(daoMembershipAddress).mint(_msgSender(), fromTierIndex - 1, 1);
        emit UserJoinedDAO(_msgSender(), daoMembershipAddress, fromTierIndex - 1);
    }

    function setCurrencyManager(address newCurrencyManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newCurrencyManager != address(0), "Invalid address");
        currencyManager = ICurrencyManager(newCurrencyManager);
    }

    
    function setBaseURI(string calldata _baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _baseURI;
    }

    /// @notice Performs an external call to another contract
    /// @param contractAddress The address of the external contract
    /// @param data The calldata to be sent
    /// @return result The bytes result of the external call
    
    function callExternalContract(address contractAddress, bytes memory data) external payable onlyRole(EXTERNAL_CALLER) returns (bytes memory ) {
    
        (bool success, bytes memory returndata) = contractAddress.call{value: msg.value}(data);
        require(success, "External call failed");
        return returndata;
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

    /// @notice Updates the implementation contract for future proxies
    /// @param newImplementation The address of the new implementation contract
    function updateMembershipImplementation(address newImplementation) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newImplementation != address(0), "Invalid address");
        membershipImplementation = newImplementation;
    }
}
