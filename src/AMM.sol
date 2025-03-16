//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AMM is ReentrancyGuard {
    error AMM__ShouldBeMoreThanZero();
    error AMM__InvalidToken(address token);
    error AMM__InsufficientLiquidity();

    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;

    address public addressOfTokenA = address(tokenA);
    address public addressOfTokenB = address(tokenB);

    uint256 public reserveOfTokenA;
    uint256 public reserveOfTokenB;
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

        _updateReserve(tokenA.balanceOf(address(this)), tokenB.balanceOf(address(this)));
    }

    function _selectSides(address tokenIn)
        internal
        view
        returns (address tokenOut, uint256 reserveIn, uint256 reserveOut)
    {
        if (tokenIn == addressOfTokenA) {
            tokenOut = addressOfTokenB;
            reserveIn = reserveOfTokenA;
            reserveOut = reserveOfTokenB;
        } else {
            tokenOut = addressOfTokenA;
            reserveIn = reserveOfTokenB;
            reserveOut = reserveOfTokenA;
        }
    }

    function _updateReserve(uint256 _reserveA, uint256 _reserveB) internal {
        reserveOfTokenA = _reserveA;
        reserveOfTokenB = _reserveB;
    }
}
