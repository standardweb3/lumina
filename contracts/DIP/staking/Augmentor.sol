pragma solidity ^0.8.0;

import {TransferHelper} from "../libraries/TransferHelper.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IEngine} from "../../safex/interfaces/IEngine.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "../../mock/interfaces/IWETH.sol";
import {CloneFactory} from "./libraries/CloneFactory.sol";
import {Augment} from "./Augment.sol";

interface IAugment {
    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function mint(address to, uint256 amount) external returns (bool);
}

contract Augmentor is ReentrancyGuard {
    // state

    /// address of LUM
    address public LUM;
    /// address of WETH
    address public WETH;
    /// address of market engine
    address public engine;
    /// address of augmented token impl
    address public impl;

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

    // functions

    function stake(
        address asset,
        uint256 amount,
        address recipient
    ) public nonReentrant returns (bool) {
        // check if the asset pair between ETH exists in exchange
        uint256 price = IEngine(engine).mktPrice(asset, LUM);

        // if not, revert with error
        if (price == 0) {
            revert PairDoesNotExist(asset, LUM);
        }

        // stake
        TransferHelper.safeTransferFrom(
            asset,
            msg.sender,
            address(this),
            amount
        );

        // if augment asset does not exist, create one
        if (!_augmentExists(asset)) {
            address augment = _createAugment(asset);
            // mint asset to recipient
            IAugment(augment).mint(recipient, amount);
        } else {
            address augment = _predictAddress(asset);
            // mint asset to recipient
            IAugment(augment).mint(recipient, amount);
        }

        emit StakeCrypto(WETH, msg.sender, amount, recipient);
        return true;
    }

    function stakeETH(
        address recipient
    ) external payable nonReentrant returns (bool) {
        // wrap ETH
        IWETH(WETH).deposit{value: msg.value}();
        // stake asset
        stake(WETH, msg.value, recipient);
        // return point
        emit StakeCrypto(WETH, msg.sender, msg.value, recipient);
        return true;
    }

    function unstake(
        address asset,
        uint256 amount
    ) external nonReentrant returns (bool) {
        // check if the asset pair between ETH exists in exchange
        // if not, revert with error

        // unstake
        TransferHelper.safeTransfer(asset, msg.sender, amount);

        emit UnstakeCrypto(asset, msg.sender, amount);
        // return point
    }

    function getPoint(
        address asset,
        address account
    ) external view returns (uint256 point) {
        // get Account balance of an asset
        uint256 balance = IERC20(asset).balanceOf(account);
        // get market rate of an asset in exchange
        uint256 price = IEngine(engine).mktPrice(asset, LUM);
        return (balance * price) / 1e8;
    }

    function _augmentExists(address original) internal returns (bool) {
        address augment = _predictAddress(original);

        // Check if the address has code
        uint32 size;
        assembly {
            size := extcodesize(augment)
        }

        // If the address has code and it's a clone of impl, revert.
        if (size > 0 || CloneFactory._isClone(impl, augment)) {
            return true;
        }
        return false;
    }

    function _createAugment(
        address original
    ) internal returns (address augment) {
        if (_augmentExists(original)) {
            revert AugmentAlreadyExists(original, augment);
        }

        // Build constructor args
        string memory symbol = IAugment(original).symbol();
        string memory name = IAugment(original).name();
        symbol = string(abi.encodePacked("lum", symbol));
        name = string(abi.encodePacked("lumina", name));

        bytes memory args = abi.encode(name, symbol, address(this));

        address proxy = CloneFactory._createCloneWithSaltOnConstructor(
            impl,
            _getSalt(original),
            args
        );

        return (proxy);
    }

    // Set immutable, consistant, one rule for orderbook implementation
    function _createImpl() internal {
        address addr;
        bytes memory bytecode = type(Augment).creationCode;
        bytes32 salt = keccak256(abi.encodePacked("augment", "0"));
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        impl = addr;
    }

    function _predictAddress(address original) internal view returns (address) {
        bytes32 salt = _getSalt(original);
        return CloneFactory.predictAddressWithSalt(address(this), impl, salt);
    }

    function _getSalt(address original) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(original));
    }
}
