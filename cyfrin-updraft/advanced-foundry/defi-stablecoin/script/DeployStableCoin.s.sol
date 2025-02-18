// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {StableCoin} from "src/StableCoin.sol";

contract DeployStableCoin is Script {
	function run() public returns(StableCoin) {
		vm.startBroadcast();
		StableCoin token = new StableCoin(msg.sender);
		vm.stopBroadcast();
		return token;
	}
}
