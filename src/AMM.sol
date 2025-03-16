//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AMM is ReentrancyGuard{
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public balanceOfTokenA;
    uint256 public balanceOfTokenB;
    uint256 public totalShares;

    mapping (address user => uint256 shares) numberOfShares;

    constructor(address _tokenA , address _tokenB){
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }
    
    function _mintShares(address to, uint256 amount) internal {
        numberOfShares[to] += amount;
        totalShares += amount;
    }

    function _burnShares(address from, uint256 amount) internal {
        numberOfShares[from] -= amount;
        totalShares -= amount;
    }

}