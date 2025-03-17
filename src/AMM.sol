//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AMM is ReentrancyGuard {
    error AMM__ShouldBeMoreThanZero();
    error AMM__InvalidToken(address token);
    error AMM__InsufficientLiquidity();
    error AMM__IncorrectRatioOfTokenProvidedForLiquidity();
    error AMM__LiquidityAlreadySetUp();
    error AMM__InsufficientSharesToBurn();

    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;

    address public addressOfTokenA;
    address public addressOfTokenB;

    uint256 public reserveOfTokenA;
    uint256 public reserveOfTokenB;
    uint256 private totalShares;

    mapping(address user => uint256 shares) private numberOfShares;

    modifier moreThanZero(uint256 amount) {
        require(amount > 0, AMM__ShouldBeMoreThanZero());
        _;
    }

    modifier validToken(address token) {
        if (token == addressOfTokenA || token == addressOfTokenB) {
            _;
        } else {
            revert AMM__InvalidToken(token);
        }
    }

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        addressOfTokenA = address(tokenA);
        addressOfTokenB = address(tokenB);
    }

    function _mintShares(address to, uint256 amount) internal {
        numberOfShares[to] += amount;
        totalShares += amount;
    }

    function _burnShares(address from, uint256 amount) internal {
        numberOfShares[from] -= amount;
        totalShares -= amount;
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

    function initialLiquidity(uint256 amountA, uint256 amountB)
        public
        moreThanZero(amountA)
        moreThanZero(amountB)
        nonReentrant
        returns (uint256 initialShares)
    {
        require(reserveOfTokenA == 0 && reserveOfTokenB == 0, AMM__LiquidityAlreadySetUp());
        initialShares = _sqrt(amountA * amountB);
        _mintShares(msg.sender, initialShares);
        _updateReserve(amountA, amountB);
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
    }

    function swap(address tokenIn, uint256 amountIn)
        public
        moreThanZero(amountIn)
        validToken(tokenIn)
        nonReentrant
        returns (uint256 amountOut)
    {
        (address tokenOut, uint256 reserveIn, uint256 reserveOut) = _selectSides(tokenIn);
        amountOut = (reserveOut * amountIn) / (reserveIn + amountIn);
        if (amountOut >= reserveOut) {
            revert AMM__InsufficientLiquidity();
        }
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        _updateReserve(tokenA.balanceOf(address(this)), tokenB.balanceOf(address(this)));
    }

    function addLiquidity(uint256 amountA, uint256 amountB)
        public
        moreThanZero(amountA)
        moreThanZero(amountB)
        nonReentrant
        returns (uint256 shares)
    {
        require(
            amountA * reserveOfTokenB == amountB * reserveOfTokenA, AMM__IncorrectRatioOfTokenProvidedForLiquidity()
        );
        shares = (amountA / reserveOfTokenA) * totalShares;
        _updateReserve(amountA + reserveOfTokenA, amountB + reserveOfTokenB);
        _mintShares(msg.sender, shares);
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
    }

    function removeLiquidity(address user, uint256 sharesToBurn) public moreThanZero(sharesToBurn) nonReentrant {
        require(numberOfShares[user] >= sharesToBurn, AMM__InsufficientSharesToBurn());
        uint256 tokenAOut = (reserveOfTokenA * sharesToBurn) / totalShares;
        uint256 tokenBOut = (reserveOfTokenA * sharesToBurn) / totalShares;
        tokenA.transfer(user, tokenAOut);
        tokenB.transfer(user, tokenBOut);
        _burnShares(user, sharesToBurn);
        _updateReserve(reserveOfTokenA - tokenAOut, reserveOfTokenB - tokenBOut);
    }

    // Taken from uinswap V2 diocs
    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    ////////////////GETTERS//////////////////////\

    function sqrt(uint256 y) public pure returns (uint256 z) {
        z = _sqrt(y);
    }

    function getNumberOfShares(address user) public view returns (uint256 shares) {
        shares = numberOfShares[user];
    }

    function getTotalShares() public view returns (uint256) {
        return totalShares;
    }
}
