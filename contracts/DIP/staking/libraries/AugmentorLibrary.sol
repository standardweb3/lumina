pragma solidity ^0.8.17;


import {CloneFactory} from "./CloneFactory.sol";
import {Augment} from "../Augment.sol";
import {TransferHelper} from "../../libraries/TransferHelper.sol";
import {IEngine} from "../../../safex/interfaces/IEngine.sol";

interface IAugment {
    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function mint(address to, uint256 amount) external returns (bool);
}

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
        /// balances of augmented token
        mapping(address => mapping(address => uint256)) balances;
        /// points stacked after staking
        mapping(address => uint256) points;
    }

    // errors
    error PairDoesNotExist(address asset, address LUM);
    error InvalidAccess(address sender, address owner);
    error AugmentAlreadyExists(address original, address augment);
    error AmountExceedsBalance(uint256 amount, uint256 balance);

    // functions 

    function _augmentExists(State storage self, address original) internal view returns (bool) {
        address augment = _predictAddress(self, original);

        // Check if the address has code
        uint32 size;
        assembly {
            size := extcodesize(augment)
        }

        // If the address has code and it's a clone of impl, revert.
        if (size > 0 || CloneFactory._isClone(self.impl, augment)) {
            return true;
        }
        return false;
    }

     function _createAugment(
        State storage self,
        address original
    ) internal returns (address augment) {
        if (_augmentExists(self, original)) {
            revert AugmentAlreadyExists(original, augment);
        }

        // Build constructor args
        string memory symbol = IAugment(original).symbol();
        string memory name = IAugment(original).name();
        symbol = string(abi.encodePacked("lum", symbol));
        name = string(abi.encodePacked("lumina", name));

        bytes memory args = abi.encode(name, symbol, address(this));

        address proxy = CloneFactory._createCloneWithSaltOnConstructor(
            self.impl,
            _getSalt(original),
            args
        );

        return (proxy);
    }

    // Set immutable, consistant, one rule for orderbook implementation
    function _createImpl(State storage self) internal {
        address addr;
        bytes memory bytecode = type(Augment).creationCode;
        bytes32 salt = keccak256(abi.encodePacked("augment", "0"));
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        self.impl = addr;
    }

    function _predictAddress(State storage self, address original) internal view returns (address) {
        bytes32 salt = _getSalt(original);
        return CloneFactory.predictAddressWithSalt(address(this), self.impl, salt);
    }

    function _getSalt(address original) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(original));
    }

    function stake(
        State storage self, 
        address asset,
        uint256 amount,
        address recipient) internal {
        // check if the asset pair between ETH exists in exchange
        uint256 price = IEngine(self.engine).mktPrice(asset, self.LUM);

        // if not, revert with error
        if (price == 0) {
            revert PairDoesNotExist(asset, self.LUM);
        }

        // stake
        TransferHelper.safeTransferFrom(
            asset,
            msg.sender,
            address(this),
            amount
        );

        // if augment asset does not exist, create one
        if (!_augmentExists(self, asset)) {
            address augment = _createAugment(self, asset);
            // mint asset to recipient
            self.balances[recipient][asset] += amount;
            self.points[recipient] += price * amount / 1e8;
            IAugment(augment).mint(recipient, amount);
        } else {
            address augment = _predictAddress(self, asset);
            // mint asset to recipient
            self.balances[recipient][asset] += amount;
            self.points[recipient] += price * amount / 1e8;
            IAugment(augment).mint(recipient, amount);
        }
    }

    function unstake(State storage self, address asset, uint256 amount) internal {
        // check if the asset pair between ETH exists in exchange
        uint256 price = IEngine(self.engine).mktPrice(asset, self.LUM);

        // check if the amount exceeds balance
        if (amount > self.balances[msg.sender][asset]) {
            // if not, revert with error
            revert AmountExceedsBalance(amount, self.balances[msg.sender][asset]);
        }
        // unstake
        self.balances[msg.sender][asset] -= amount;
        self.points[msg.sender] -= price * amount / 1e8;
        TransferHelper.safeTransfer(asset, msg.sender, amount);
    }

    
}
