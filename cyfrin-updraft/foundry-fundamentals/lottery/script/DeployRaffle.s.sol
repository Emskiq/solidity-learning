// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig, Constants} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script, Constants {

    function deployContract() public returns(Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        console.log("Starting the creation of raffle contraxct...");

        if (config.subscriptionId == 0) {
            CreateSubscription subscription = new CreateSubscription();
            config.subscriptionId = subscription.createSubscription(config.vrfCordinatorAddress, config.account);

            FundSubscription fundSub = new FundSubscription();
            fundSub.fundSubscription(config.vrfCordinatorAddress, config.subscriptionId, config.link, config.account);
        }

        if (block.chainid == LOCAL_CHAIN_ID) {
            // one more time funding for the local chain scenario
            FundSubscription fundSub = new FundSubscription();
            fundSub.fundSubscription(config.vrfCordinatorAddress, config.subscriptionId, config.link, config.account);
        }


        vm.startBroadcast(config.account);
        // TODO: Get the corresponding value for the toolchain we are using
        // For example: Sepolia specific contract address + Local net and so on..
        Raffle raffleContract = new Raffle(config.entranceFee, config.interval, config.subscriptionId, config.vrfCordinatorAddress, config.gasLane);
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(config.vrfCordinatorAddress, config.subscriptionId, address(raffleContract), config.account);

        console.log("Finished the creation of raffle");

        return (raffleContract, helperConfig);
    }

    function run() public {
        deployContract();
    }
}
