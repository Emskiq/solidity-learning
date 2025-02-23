// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {BoxV1} from "src/BoxV1.sol";
import {BoxV2} from "src/BoxV2.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";


contract UpgradeBox is Script {

    function run(address proxy) public returns(address) {
        address recentDeployProxy = DevOpsTools.get_most_recent_deployment("ERC1967Proxy" , block.chainid);

        vm.startBroadcast();

        BoxV2 newBox = new BoxV2();
        address proxy = upgradeProxy(address(proxy), address(newBox));

        vm.stopBroadcast();


        return address(proxy);
    }

    function upgradeProxy(address proxy, address newImpl) public returns(address) {
        vm.startBroadcast();

        // old = new BoxV1(proxy);
        BoxV1(proxy).upgradeToAndCall(newImpl, "");

        vm.stopBroadcast();

        // BoxV1(proxy).upgradeToAndCall(newImpl, "");
        // BoxV2(proxy).upgradeToAndCall(newImpl, "");

        return proxy;
    }
}