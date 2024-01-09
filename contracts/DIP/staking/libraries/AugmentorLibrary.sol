pragma solidity ^0.8.17;

library AugmentorLibrary {
    struct State {
        /// address of LUM
        address LUM;
        /// address of WETH
        address WETH;
        /// address of market engine
        address engine;
        /// address of augmented token impl
        address impl;
        mapping(address => mapping(address => uint256)) balances;
    }
}
