// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "forge-std/console.sol";
import {Ownable} from "../src/Ownable.sol";

contract DeployOwnable is Script {
    function run() external {
        uint privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);
        console.log("Deployer: ", deployer);

        // Start broadcasting the transaction - using the deployer address
        vm.startBroadcast(deployer);

        Ownable ownableContract = new Ownable();
        ownableContract.setX(420); // ok
        ownableContract.setNewOwner(deployer);
        // ownableContract.setX(5); // fails - incorrect value
        ownableContract.setNewOwner(0xD81993511065fB80Fa160DebF57E2FceD1Cf4DbA);
        // ownableContract.setNewOwner(deployer); // Fails - not owner
        ownableContract.setX(420);

        vm.stopBroadcast();

        console.logInt(ownableContract.x());
        console.log(ownableContract.owner());
    }
}
