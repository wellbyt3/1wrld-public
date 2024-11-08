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

    function testConsoleLog() public {
        console.log("Hello Delvir!");
    }
}

