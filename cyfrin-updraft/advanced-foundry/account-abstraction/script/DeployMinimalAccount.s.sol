// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployMinimalAccount is Script {
    function setUp() public {}

    function run() public { }

    function deploytMinimalContract() public returns(HelperConfig, MinimalAccount) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);

        vm.startBroadcast(config.account);
        MinimalAccount minAccount = new  MinimalAccount(config.entryPoint);
        console.log("transfer owenrcalling address: ", msg.sender);
        minAccount.transferOwnership(config.account);
        vm.stopBroadcast();

        return (helperConfig, minAccount);
    }
}
