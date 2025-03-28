// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {AMM} from "../src/AMM.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {DeployAMM} from "../script/DeployAMM.s.sol";

contract AMMTest is Test {
    AMM public amm;
    ERC20Mock public tokenA;
    ERC20Mock public tokenB;
    DeployAMM public deployer;

    address public constant USER = address(1);
    uint256 public constant INITIAL_BALANCE = 1000 ether;
    uint256 public constant amountA = 100 ether;
    uint256 public constant amountB = 100 ether;

    function setUp() public {
        deployer = new DeployAMM();
        (amm, tokenA, tokenB) = deployer.run();

        tokenA.mint(address(this), INITIAL_BALANCE);
        tokenB.mint(address(this), INITIAL_BALANCE);
        tokenA.mint(USER, INITIAL_BALANCE);
        tokenB.mint(USER, INITIAL_BALANCE);

        tokenA.approve(address(amm), type(uint256).max);
        tokenB.approve(address(amm), type(uint256).max);

        vm.startPrank(USER);
        tokenA.approve(address(amm), type(uint256).max);
        tokenB.approve(address(amm), type(uint256).max);
        vm.stopPrank();

        amm.initialLiquidity(amountA, amountB);
    }

    ///////////// InitialLiquidity Test //////////
    function test_InitialLiquidityAndReserveSetup() public view {
        assertEq(amm.reserveOfTokenA(), amountA);
        assertEq(amm.reserveOfTokenB(), amountB);
        assertEq(amm.getTotalShares(), amm.sqrt(amountA * amountB));
        assertEq(amm.getNumberOfShares(address(this)), amm.sqrt(amountA * amountB));
    }

    function test_RevertIf_InitialLiquidityAlreadySetup() public {
        vm.expectRevert(AMM.AMM__LiquidityAlreadySetUp.selector);
        amm.initialLiquidity(amountA, amountB);
    }

    //////////// Add Liquidity Test /////////////

    function test_UserAddLiquidityInCorrectRatio() public {
        vm.prank(USER);
        amm.addLiquidity(amountA, amountB);
        assertEq(amm.reserveOfTokenA(), 2 * amountA);
        assertEq(amm.reserveOfTokenB(), 2 * amountB);
        assertEq(amm.getNumberOfShares(USER), 100 ether);
    }

    function test_RevertIfUserAddLiquidityWithIncorrectRatio() public {
        vm.startPrank(USER);
        vm.expectRevert(AMM.AMM__IncorrectRatioOfTokenProvidedForLiquidity.selector);
        amm.addLiquidity(amountA + 1 ether, amountB);
    }

    //////////// Swap Tests /////////////

    function test_SwapTokenAForTokenB() public {
        uint256 swapAmount = 10 ether;
        uint256 expectedOutput = (amountB * swapAmount) / (amountA + swapAmount);
        console.log(expectedOutput);

        amm.swap(address(tokenA), swapAmount);

        assertEq(amm.reserveOfTokenA(), amountA + swapAmount);
        assertEq(amm.reserveOfTokenB(), amountB - expectedOutput);
        assertEq(tokenB.balanceOf(address(this)), INITIAL_BALANCE - amountB + expectedOutput);
    }

    function test_RevertIfSwapWithInvalidToken() public {
        uint256 swapAmount = 10 ether;
        address invalidToken = address(0x123);

        vm.expectRevert(abi.encodeWithSelector(AMM.AMM__InvalidToken.selector, invalidToken));
        amm.swap(invalidToken, swapAmount);
    }

    //////////// Remove Liquidity Tests /////////////
    function test_RemoveLiquidity() public {
        uint256 sharesToBurn = amm.getNumberOfShares(address(this)) / 2;
        uint256 expectedTokenA = (amountA * sharesToBurn) / amm.getTotalShares();
        uint256 expectedTokenB = (amountB * sharesToBurn) / amm.getTotalShares();
        console.log(expectedTokenA); // 50 ether
        console.log(expectedTokenB); // 50 ether

        amm.removeLiquidity(sharesToBurn);

        assertEq(tokenA.balanceOf(address(this)), INITIAL_BALANCE - amountA + expectedTokenA);
        assertEq(tokenB.balanceOf(address(this)), INITIAL_BALANCE - amountB + expectedTokenB);
        assertEq(amm.reserveOfTokenA(), amountA - expectedTokenA);
        assertEq(amm.reserveOfTokenB(), amountB - expectedTokenB);
        assertEq(amm.getTotalShares(), amm.sqrt(amountA * amountB) - sharesToBurn);
    }

    function test_RevertIf_RemoveLiquidityWithInsufficientShares() public {
        uint256 sharesToBurn = amm.getNumberOfShares(address(this)) + 1;

        vm.expectRevert(AMM.AMM__InsufficientSharesToBurn.selector);
        amm.removeLiquidity(sharesToBurn);
    }

    function test_RevertIf_RemoveLiquidityByNonOwner() public {
        uint256 sharesToBurn = amm.getNumberOfShares(address(this)) / 2;

        vm.prank(USER);
        vm.expectRevert(AMM.AMM__InsufficientSharesToBurn.selector);
        amm.removeLiquidity(sharesToBurn);
    }
}
