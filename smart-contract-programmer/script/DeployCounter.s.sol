// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "forge-std/console.sol";
import {Counter} from "../src/Counter.sol";

contract DeployCounter is Script {
    function run() external {
        // Start broadcasting the transaction
        vm.startBroadcast();
        // deploy contract
        Counter counter = new Counter();
        counter.inc();
        counter.inc();
        counter.dec();
        vm.stopBroadcast();

        console.logInt(counter.count());
    }
}
