// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Handler} from "./Handler.t.sol";
import {AMM} from "../src/AMM.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {DeployAMM} from "../script/DeployAMM.s.sol";

contract InvariantsTest is Test {
    AMM public amm;
    ERC20Mock public tokenA;
    ERC20Mock public tokenB;
    Handler public handler;

    function setUp() public {
        (amm, tokenA, tokenB) = new DeployAMM().run();
        handler = new Handler(amm, tokenA, tokenB);
        targetContract(address(handler));
    }

    function invariant_constant_product() public view {
    uint256 k = amm.reserveOfTokenA() * amm.reserveOfTokenB();
    uint256 totalShares = amm.getTotalShares();
    uint256 expectedK = totalShares * totalShares;
    uint256 tolerance = 1e18; // Adjust tolerance as needed
    assertApproxEqAbs(k, expectedK, tolerance, "K != shares squared");
    }

    function invariant_shares_balance() public view {
        uint256 totalShares;
        for (uint256 i = 0; i < handler.getUsersCount(); i++) {
            totalShares += amm.getNumberOfShares(handler.users(i));
        }
        assertEq(totalShares, amm.getTotalShares(), "Shares mismatch");
    }

    function invariant_reserve_balance() public view {
        assertEq(
            tokenA.balanceOf(address(amm)), 
            amm.reserveOfTokenA(),
            "TokenA reserve mismatch"
        );
        assertEq(
            tokenB.balanceOf(address(amm)), 
            amm.reserveOfTokenB(),
            "TokenB reserve mismatch"
        );
    }
}