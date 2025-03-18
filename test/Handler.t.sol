// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {AMM} from "../src/AMM.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Handler is Test {
    AMM public immutable amm;
    ERC20Mock public immutable tokenA;
    ERC20Mock public immutable tokenB;

    address[] public users;
    uint256 public constant MAX_TOKENS = 1e30 ether;

    constructor(AMM _amm, ERC20Mock _tokenA, ERC20Mock _tokenB) {
        amm = _amm;
        tokenA = _tokenA;
        tokenB = _tokenB;

        // Simulting protocol with 4 users
        for (uint256 i = 0; i < 4; i++) {
            address user = makeAddr(string(abi.encodePacked(i)));
            users.push(user);
            
            tokenA.mint(user, MAX_TOKENS);
            tokenB.mint(user, MAX_TOKENS);
            
            vm.prank(user);
            tokenA.approve(address(amm), type(uint256).max);
            
            vm.prank(user);
            tokenB.approve(address(amm), type(uint256).max);
        }

        // Setup initial liquidity 
        vm.prank(users[0]);
        amm.initialLiquidity(100 ether, 100 ether);
    }

    function addLiquidity(uint256 userSeed, uint256 amountA) external {
    address user = _getUser(userSeed);
    uint256 reserveA = amm.reserveOfTokenA();
    uint256 reserveB = amm.reserveOfTokenB();
    if (reserveA == 0 || reserveB == 0) return;
    amountA = bound(amountA, 1 ether, reserveA * 10);
    uint256 amountB = (amountA * reserveB) / reserveA;
    if (tokenA.balanceOf(user) < amountA || tokenB.balanceOf(user) < amountB) return;
    
    vm.prank(user);
    amm.addLiquidity(amountA, amountB);
}

    

    function removeLiquidity(uint256 userSeed, uint256 sharePct) external {
        address user = _getUser(userSeed);
        uint256 shares = amm.getNumberOfShares(user);
        shares = bound(shares, 1, shares);
        uint256 sharesToBurn = (shares * sharePct) / 100;
        
        vm.prank(user);
        amm.removeLiquidity(sharesToBurn);
    }

    function _getUser(uint256 seed) private view returns (address) {
        return users[bound(seed, 0, users.length - 1)];
    }

    function getUsersCount() public view returns (uint256) {
        return users.length;
    }
}