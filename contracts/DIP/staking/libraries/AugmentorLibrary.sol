pragma solidity ^0.8.17;

import {CloneFactory} from "./CloneFactory.sol";
import {Augment} from "../Augment.sol";
import {TransferHelper} from "../../libraries/TransferHelper.sol";
import {IWETH} from "../../../mock/interfaces/IWETH.sol";
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
        //// Delegator
        /// points stacked after staking
        mapping(address => uint256) points;
        /// delegator ids
        mapping(address => uint32) dIds;
        /// delegators
        mapping(uint32 => address) delegators;
        /// delegator points
        mapping(uint32 => uint256) delegated;
        /// delegated total points
        uint256 total;
        /// delegator array
        uint32[20] dArr;
        uint32 dCount;
        /// confisticated until
        mapping(uint32 => uint64) confiscated;
    }

    // errors
    error PairDoesNotExist(address asset, address LUM);
    error InvalidAccess(address sender, address owner);
    error AugmentAlreadyExists(address original, address augment);
    error AmountExceedsBalance(uint256 amount, uint256 balance);
    /// delegators
    error InvalidDelegator(address delegateTo);
    error AlreadyOccupied(address delegator, uint32 dId);
    error AmountExceedsPoint(uint256 amount, uint256 point);

    // functions

    function _augmentExists(
        State storage self,
        address original
    ) internal view returns (bool) {
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

    function _predictAddress(
        State storage self,
        address original
    ) internal view returns (address) {
        bytes32 salt = _getSalt(original);
        return
            CloneFactory.predictAddressWithSalt(address(this), self.impl, salt);
    }

    function _getSalt(address original) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(original));
    }

    function stake(
        State storage self,
        address asset,
        uint256 amount,
        address recipient
    ) internal {
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
            self.points[recipient] += (price * amount) / 1e8;
            IAugment(augment).mint(recipient, amount);
        } else {
            address augment = _predictAddress(self, asset);
            // mint asset to recipient
            self.balances[recipient][asset] += amount;
            self.points[recipient] += (price * amount) / 1e8;
            IAugment(augment).mint(recipient, amount);
        }
    }

    function unstake(
        State storage self,
        address asset,
        uint256 amount
    ) internal {
        // check if the asset pair between ETH exists in exchange
        uint256 price = IEngine(self.engine).mktPrice(asset, self.LUM);

        // check if the amount exceeds balance
        if (amount > self.balances[msg.sender][asset]) {
            // if not, revert with error
            revert AmountExceedsBalance(
                amount,
                self.balances[msg.sender][asset]
            );
        }
        // unstake
        self.balances[msg.sender][asset] -= amount;
        if (self.points[msg.sender] < (price * amount) / 1e8) {
            self.points[msg.sender] = 0;
        } else {
            self.points[msg.sender] -= (price * amount) / 1e8;
        }
        if (asset == self.WETH) {
            IWETH(self.WETH).withdraw(amount);
            payable(msg.sender).transfer(amount);
        } else {
            TransferHelper.safeTransfer(asset, msg.sender, amount);
        }
    }

    // delegator functions

    function register(State storage self) internal {
        // check occupation
        if(self.dIds[msg.sender] != 0) {
            revert AlreadyOccupied(msg.sender, self.dIds[msg.sender]);
        }

        // Transfer required LUMs to register as validator
        // TODO: set point decimals
        TransferHelper.safeTransferFrom(self.LUM, msg.sender, address(this), 32e18);

        // Add delegator in the list
        self.dCount += 1;
        self.dIds[msg.sender] = self.dCount;
        self.delegated[self.dCount] += 32e18;
        _reorder(self, self.dCount);
    }

    function _reorder(State storage self, uint32 newId) internal {
        for (uint256 i = 19; i > 0; i--) {
            if(self.delegated[self.dArr[i]] >= self.delegated[newId]) {
                if(i==19) {
                    return;
                } else {
                    self.dArr[i+1] = newId;
                    return;
                }
            }
            if(self.delegated[self.dArr[i]] < self.delegated[newId]) {
                if(i==19) {
                    self.dArr[i] = newId;
                } else {
                    self.dArr[i+1] = self.dArr[i];
                    self.dArr[i] = newId;
                }
            }
        }
    }

    function delegate(
        State storage self,
        address delegateTo,
        uint256 amount
    ) internal returns (uint32 id) {
        // check if delegator exists
        id = self.dIds[delegateTo];
        if (id == 0) {
            revert InvalidDelegator(delegateTo);
        }
        // check if amount exceeds point balance
        if (amount > self.points[msg.sender]) {
            revert AmountExceedsPoint(amount, self.points[msg.sender]);
        }
        self.points[msg.sender] -= amount;
        self.delegated[id] += amount;
        self.total += amount;
        _reorder(self, id);
        return id;
    }

    function undelegate(
        State storage self,
        address delegateTo,
        uint256 amount
    ) external returns (uint32 id) {
        // check if delegator exists
        id = self.dIds[delegateTo];
        if (id == 0) {
            revert InvalidDelegator(delegateTo);
        }
        self.points[msg.sender] += amount;
        self.delegated[id] -= amount;
        self.total -= amount;
        _reorder(self, id);
        return id;
    }

    function authorize(
        State storage self
    ) internal view returns (address author, address validator1, address validator2) {
        // Get the current block hash
        bytes32 hash = blockhash(block.number - 1);

        // Ensure that the block hash is not zero
        require(hash != 0, "Block hash is zero");

        // Extract 4-byte chunks from bytes32 and convert to uint32
        uint32[3] memory chunks;
        address[] memory validators;
        assembly {
            mstore(chunks, hash)
            mstore(add(chunks, 32), shr(32, hash))
            mstore(add(chunks, 64), shr(64, hash))
            //mstore(add(chunks, 96), shr(96, hash))
            //mstore(add(chunks, 128), shr(128, hash))
        }
       
        validators = new address[](3);

        // get validators in the array
        for (uint32 i = 0; i < 3; i++) {
            validators[i] = self.delegators[chunks[i] % 20];
        }

        return (validators[0], validators[1], validators[2]);
    }

    function slash(State storage self, address delegator) internal {
        // slash points on delegator
        self.delegated[self.dIds[delegator]] = 0;

        // distribute slashed LUM to reporter for 1/8


        // confiscate delegator for 3 months

    }
}
