// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
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

    function setUp() public {
        deployer = new DeployAMM();
        (amm, tokenA, tokenB) = deployer.run();

        tokenA.mint(address(this), INITIAL_BALANCE);
        tokenB.mint(address(this), INITIAL_BALANCE);
        tokenA.mint(USER, INITIAL_BALANCE);
        tokenB.mint(USER, INITIAL_BALANCE);

        tokenA.approve(address(amm), type(uint256).max);
        tokenB.approve(address(amm), type(uint256).max);

        vm.prank(USER);
        tokenA.approve(address(amm), type(uint256).max);
        vm.prank(USER);
        tokenB.approve(address(amm), type(uint256).max);
    }
}
