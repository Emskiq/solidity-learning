// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";


contract FundFundMe is Script {

    uint256 constant SEND_VALUE = 0.69 ether;

    function run() external {
        vm.startBroadcast();

        address contractAddress = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        fundFundMe(contractAddress);

        vm.stopBroadcast();
    }

    function fundFundMe(address mostRecent) public {
        vm.startBroadcast();
        FundMe(payable(mostRecent)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();
    }
}

contract WithdrawFundMe is Script {

    function run() external {
        vm.startBroadcast();

        address contractAddress = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        withdrawFundMe(contractAddress);

        vm.stopBroadcast();
    }

    function withdrawFundMe(address mostRecent) public {
        vm.startBroadcast();
        FundMe(payable(mostRecent)).withdraw();
        vm.stopBroadcast();
    }
}
