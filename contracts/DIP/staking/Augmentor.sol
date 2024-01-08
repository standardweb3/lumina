pragma solidity ^0.8.0;

import {TransferHelper} from "../libraries/TransferHelper.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IEngine} from "../../safex/interfaces/IEngine.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Augmentor is ReentrancyGuard {
    // state
    address public LUM;
    address public WETH;
    address public engine;


    // events
    event StakeCrypto(address indexed asset, address indexed account, uint256 amount);
    event UnstakeCrypto(address indexed asset, address indexed account, uint256 amount);


    // functions

    function stake(address asset, uint256 amount) nonReentrant external returns (bool) {
        // check if the asset pair between ETH exists in exchange
        // if not, revert with error
    
        // stake 
        TransferHelper.safeTransferFrom(asset, msg.sender, address(this), amount);
        
        

        emit StakeCrypto(WETH, msg.sender, amount);
        return true;
    }

    function stakeETH() nonReentrant external payable returns (bool)  {
        // stake asset
        
        // return point
        emit StakeCrypto(WETH, msg.sender, msg.value);
        return true;
    }

    function unstake(address asset, uint256 amount) nonReentrant external returns (bool)  {
        // check if the asset pair between ETH exists in exchange
        // if not, revert with error
    
        // unstake 
        TransferHelper.safeTransfer(asset, msg.sender, amount);
        
        
        emit UnstakeCrypto(asset, msg.sender, amount);
        // return point
    }

    function getPoint(address asset, address account) external view returns (uint256 point) {
        // get Account balance of an asset
        uint256 balance = IERC20(asset).balanceOf(account);
        // get market rate of an asset in exchange
        uint256 price = IEngine(engine).mktPrice(asset, LUM);
        return balance * price / 1e8;
    }


}