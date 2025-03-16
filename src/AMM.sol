//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AMM is ReentrancyGuard {
    error AMM__ShouldBeMoreThanZero();
    error AMM__InvalidToken(address token);
    error AMM__InsufficientLiquidity();

    IERC20 public tokenA;
    IERC20 public tokenB;

    address public addressOfTokenA = address(tokenA);
    address public addressOfTokenB = address(tokenB);

    // uint256 public balanceOfTokenA;
    // uint256 public balanceOfTokenB;
    uint256 public totalShares;

    mapping(address user => uint256 shares) numberOfShares;

    modifier moreThanZero(uint256 amount) {
        require(amount > 0, AMM__ShouldBeMoreThanZero());
        _;
    }

    modifier validToken(address token) {
        if (token == address(0) || (token != addressOfTokenA && token != addressOfTokenB)) {
            revert AMM__InvalidToken(token);
        }
        _;
    }

    constructor(address _tokenA, address _tokenB) {
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

    function swap(address tokenIn, uint256 amountIn)
        public
        moreThanZero(amountIn)
        validToken(tokenIn)
        returns (uint256 amountOut)
    {
        (address tokenOut, uint256 reserveIn, uint256 reserveOut) = _selectSides(tokenIn);
        amountOut = (reserveOut * amountIn) / (reserveIn + amountIn);
        if (amountOut >= reserveOut) {
            revert AMM__InsufficientLiquidity();
        }
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transferFrom(address(this), msg.sender, amountOut);
    }

    function _selectSides(address tokenIn)
        internal
        view
        returns (address tokenOut, uint256 reserveIn, uint256 reserveOut)
    {
        if (tokenIn == addressOfTokenA) {
            tokenOut = addressOfTokenB;
            reserveIn = tokenA.balanceOf(address(this));
            reserveOut = tokenB.balanceOf(address(this));
        } else {
            tokenOut = addressOfTokenA;
            reserveIn = tokenB.balanceOf(address(this));
            reserveOut = tokenA.balanceOf(address(this));
        }
    }
}
