//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {AMM} from "../src/AMM.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract DeployAMM is Script {
    function run() external returns (AMM amm, ERC20Mock tokenA, ERC20Mock tokenB) {
        vm.startBroadcast();
        tokenA = new ERC20Mock();
        tokenB = new ERC20Mock();

        amm = new AMM(address(tokenA), address(tokenB));
        vm.stopBroadcast();
    }
}
