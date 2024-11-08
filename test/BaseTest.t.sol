// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {MembershipERC1155} from "../src/dao/tokens/MembershipERC1155.sol";
import {CurrencyManager} from "../src/dao/CurrencyManager.sol";
import {MembershipFactory} from "../src/dao/MembershipFactory.sol";
import {OWPIdentity} from "../src/OWPIdentify.sol";
import "../src/dao/libraries/MembershipDAOStructs.sol";
import "forge-std/Test.sol";

import "../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract BaseTest is Test {
    address defaultAdmin = makeAddr("defaultAdmin");
    address minter = makeAddr("minter");
    address owp_wallet = makeAddr("owp_wallet");
    address daoCreator = makeAddr("daoCreator");
    string baseURI = "NftMetaData";
    string newURI = "NewUri";

    MembershipERC1155 membershipImplementation;
    CurrencyManager currencyManager;
    MembershipFactory membershipFactory;
    OWPIdentity owpIdentity;
    ERC20Mock currency;
    

    function setUp() public {
        vm.startPrank(defaultAdmin);
        membershipImplementation = new MembershipERC1155();
        currencyManager = new CurrencyManager();
        membershipFactory = new MembershipFactory(
            address(currencyManager),
            owp_wallet,
            baseURI,
            address(membershipImplementation)
        );
        owpIdentity = new OWPIdentity(
            defaultAdmin, 
            minter, 
            newURI
        );

        currency = new ERC20Mock();
        vm.stopPrank();
    }

    function testCreateNewDAOMembership() public {

        vm.startPrank(defaultAdmin);
        currencyManager.addCurrency(address(currency));
        vm.stopPrank();
        
        // Configure DAO
        DAOInputConfig memory daoInputConfig = DAOInputConfig({
            ensname: "test",
            daoType: DAOType.PUBLIC,
            currency: address(currency),
            maxMembers: 100,
            noOfTiers: 3
        });

        // Create the DAO tiers
        TierConfig[] memory tiers = new TierConfig[](3);

        tiers[0] = TierConfig({
            amount: 10,
            price: 300e18,
            power: 12,
            minted: 0
        });
        tiers[1] = TierConfig({
            amount: 10,
            price: 200e18,
            power: 6,
            minted: 0
        });
        tiers[2] = TierConfig({
            amount: 10,
            price: 100e18,
            power: 3,
            minted: 0
        });

        // Create the DAO
        
        vm.startPrank(daoCreator);
        address daoAddress = membershipFactory.createNewDAOMembership(daoInputConfig, tiers);
        vm.stopPrank();
        console.log("defaultAdmin address: ",defaultAdmin);
        console.log("membershipFactory address: ",address(membershipFactory));
        // // console.log(uint160(bytes20(bytes32(MembershipERC1155(daoAddress).getRoleAdmin(DEFAULT_ADMIN_ROLE)))));
        // bytes32 returnval = MembershipERC1155(daoAddress).OWP_FACTORY_ROLE();
        // bytes32 roleadminreturn = MembershipERC1155(daoAddress).getRoleAdmin(returnval);
        // console.logBytes32(roleadminreturn);

        // (string memory ensname,,address currency,,) = membershipFactory.daos(daoAddress);
        // console.log(ensname);
        // console.log(currency);

        // console.log("daoAddress: ",daoAddress);
    }

    // @audit-check there's a bunch of stuff to test here
    function testUpdateDAOMEmbership() public {}

}

