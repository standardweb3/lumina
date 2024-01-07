pragma solidity ^0.8.0;

import {TransferHeler} from "../libraries/TransferHelper.sol";

contract Augmentor {
    // state
    address public lum;


    // functions

    function stake(address asset, uint256 amount) external returns (uint256 point) {
        // check if the asset pair between ETH exists in exchange
        // if not, revert with error
    
        // stake 
        TransferHelper.safeTransferFrom(asset, msg.sender, address(this), amount);
        
        
        // mint point
    
        // return point
    }

    function stakeETH() external payable returns (uint256 point) {
        // stake asset
        
        // mint point
        // return point
    }

    function unstake(address asset, uint256 amount) external returns (uint256 point) {
        // check if the asset pair between ETH exists in exchange
        // if not, revert with error
    
        // unstake 
        TransferHelper.safeTransfer(asset, msg.sender, amount);
        
        
        // burn point
    
        // return point
    }

    function getPoint(address asset, address account) external view returns (uint256 point) {
        // get Account balance of an asset
        uint256 balance = IERC20(asset).balanceOf(account);
        // get market rate of an asset in exchange
        uint256 price = IEngine(engine).getPrice(asset, lum);
        return balance * price / 1e8;
    }

    // events

}