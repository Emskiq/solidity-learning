// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

import {HelperConfig, Constants} from "./HelperConfig.s.sol";
import {LinkToken} from "test/LinkTokenMock.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {

    function createSubscriptionFromConfig() public returns(uint256, address) {
        HelperConfig config = new HelperConfig();

        address vrfCordinator = config.getConfig().vrfCordinatorAddress;
        address account = config.getConfig().account;
        uint256 subId = createSubscription(vrfCordinator, account);
        return (subId, vrfCordinator);
    }

    function createSubscription(address vrfCordinator, address account) public returns(uint256) {
        console.log("creating subscription on chain id: ", block.chainid);

        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Created sub Id: ", subId);
        return subId;
    }

    function run() public {
        createSubscriptionFromConfig();
    }
}

contract FundSubscription is Script, Constants {

    uint256 public constant FUND_AMOUNT = 69 ether; // Link

    function fundSubscriptionFromConfig() public returns(uint256, address) {
        HelperConfig config = new HelperConfig();

        address vrfCordinator = config.getConfig().vrfCordinatorAddress;
        uint256 subId = config.getConfig().subscriptionId;
        address linkToken = config.getConfig().link;
        address account = config.getConfig().account;

        fundSubscription(vrfCordinator, subId, linkToken, account);

        return (subId, vrfCordinator);
    }

    function fundSubscription(address vrfCordinator, uint256 subId, address linkToken, address account) public {
        console.log("funding subscription on chain id: ", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vrfCordinator).fundSubscription(subId, FUND_AMOUNT * 5000);
            vm.stopBroadcast();
        }
        else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(vrfCordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }

        console.log("funded subscript Id: ", subId);
    }

    function run() public {
        fundSubscriptionFromConfig();
    }
}

contract AddConsumer is Script {

    function addConsumerUsingConfig(address contractAddress) public {
        HelperConfig config = new HelperConfig();

        address vrfCordinator = config.getConfig().vrfCordinatorAddress;
        uint256 subId = config.getConfig().subscriptionId;
        address account = config.getConfig().account;

        addConsumer(vrfCordinator, subId, contractAddress, account);
    }

    function addConsumer(address vrfCordinator, uint256 subId, address contractAddress, address account) public {
        console.log("consumer contract address (Raffle): ", contractAddress);

        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCordinator).addConsumer(subId, contractAddress);
        vm.stopBroadcast();
    }


    function run() public {
        address raffleContractAddress = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(raffleContractAddress);
    }
}
