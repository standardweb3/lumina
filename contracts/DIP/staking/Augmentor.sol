pragma solidity ^0.8.0;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IWETH} from "../../mock/interfaces/IWETH.sol";
import {AugmentorLibrary} from "./libraries/AugmentorLibrary.sol";
import {DelegatorLibrary} from "./libraries/DelegatorLibrary.sol";

interface IAugment {
    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function mint(address to, uint256 amount) external returns (bool);
}

contract Augmentor is ReentrancyGuard {
    using AugmentorLibrary for AugmentorLibrary.State;
    using DelegatorLibrary for DelegatorLibrary.State;

    AugmentorLibrary.State private _augmentor;
    DelegatorLibrary.State private _delegator;
    

    /// delegator state
    struct Delegator {
        uint32 id;
        string name;
        mapping (address => uint256) staked;
    }
    mapping (address => Delegator) delegators;

    // events
    event StakeCrypto(
        address indexed asset,
        address indexed account,
        uint256 amount,
        address sendTo
    );
    event UnstakeCrypto(
        address indexed asset,
        address indexed account,
        uint256 amount
    );

    // errors
    error PairDoesNotExist(address asset, address LUM);
    error InvalidAccess(address sender, address owner);
    error AugmentAlreadyExists(address original, address augment);
    error AmountExceedsBalance(uint256 amount, uint256 balance);
    
    // delegator
    error InvalidDelegator(address delegateTo);

    // functions

    function stake(
        address asset,
        uint256 amount,
        address recipient
    ) external nonReentrant returns (bool) {
        // stake asset
        _augmentor.stake(asset, amount, recipient);
        emit StakeCrypto(_augmentor.WETH, msg.sender, amount, recipient);
        return true;
    }

    function stakeETH(
        address recipient
    ) external payable nonReentrant returns (bool) {
        // wrap ETH
        IWETH(_augmentor.WETH).deposit{value: msg.value}();
        // stake asset
        _augmentor.stake(_augmentor.WETH, msg.value, recipient);
        emit StakeCrypto(_augmentor.WETH, msg.sender, msg.value, recipient);
        return true;
    }

    function delegate(
        address asset,
        address delegateTo,
        uint256 amount
    ) external returns (bool) {
        if(amount > _augmentor.balances[msg.sender][asset] ) {
            revert AmountExceedsBalance(amount, _augmentor.balances[msg.sender][asset]);
        }
        _augmentor.balances[msg.sender][asset] -= amount;

        _delegator.delegate(asset, delegateTo, amount);
        // TODO: reorder delegator priority
        // IDelegator.reorder(delegateTo, delegator.staked[asset]);

        return true;
    }

    function undelegate(
        address asset,
        address delegateTo,
        uint256 amount
    ) external returns (bool) {
         // check if delegator exists
        Delegator storage delegator = delegators[delegateTo];
        if(delegator.id == 0) {
            revert InvalidDelegator(delegateTo);
        }

        delegator.staked[asset] -= amount;
        _augmentor.balances[msg.sender][asset] += amount;
        // TODO: reorder delegator priority
        // IDelegator.reorder(delegateTo, delegator.staked[asset]);

        return true;
    }

    function unstake(
        address asset,
        uint256 amount
    ) external nonReentrant returns (bool) {
        _augmentor.unstake(asset, amount);
        emit UnstakeCrypto(asset, msg.sender, amount);
        return true;
    }

    function getBalance(
        address asset,
        address account
    ) external view returns (uint256 point) {
        return _augmentor.balances[account][asset];
    }
}
