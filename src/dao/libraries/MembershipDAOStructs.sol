// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

uint64 constant TIER_MAX = 7;

enum DAOType { 
    PUBLIC,
    PRIVATE,
    SPONSORED
}


struct DAOConfig {
    string ensname;
    DAOType daoType;
    TierConfig[] tiers;
    address currency;
    uint256 maxMembers;
    uint256 noOfTiers;
    //joined members check
}

struct DAOInputConfig {
    string ensname;
    DAOType daoType;
    address currency;
    uint256 maxMembers;
    uint256 noOfTiers;
}

struct TierConfig {
    uint256 amount; // max amount of members allowed in this tier
    uint256 price;
    uint256 power;
    uint256 minted; // amount tht has been minted so far (starts at 0)
}
