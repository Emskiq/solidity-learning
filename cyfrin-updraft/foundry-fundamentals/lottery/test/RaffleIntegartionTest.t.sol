// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

import {Raffle} from "src/Raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig, Constants} from "script/HelperConfig.s.sol";

import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleIntegrationTest is Test, Constants {
    Raffle public raffle;
    HelperConfig public config;

    uint256 entranceFee;
    uint256 interval;
    uint256 subscriptionId;
    address vrfCordinatorAddress;
    bytes32 gasLane;

    address public PLAYER = makeAddr("PLAYER");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    event PlayerEnterredRaffle(address indexed playerAddress);
    event PickingWinner(uint256 indexed requestId);
    event WinnerPicked(uint256 indexed requestId, address indexed winnerAddress);
    event WinnerAwarded(address indexed winnerAddress, uint256 indexed awardAmount);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, config) = deployer.deployContract();

        HelperConfig.NetworkConfig memory networkConfig = config.getConfig();

        entranceFee = networkConfig.entranceFee;
        interval = networkConfig.interval;
        subscriptionId = networkConfig.subscriptionId;
        vrfCordinatorAddress = networkConfig.vrfCordinatorAddress;
        gasLane = networkConfig.gasLane;

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // pass time
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testGoodWeatherRaffleLocalChain() public raffleEntered {
        if (block.chainid != LOCAL_CHAIN_ID) {
            return;
        }

        // arrange
        uint256 initialBalance = address(PLAYER).balance;

        uint8 additionalPlayers = 3;
        uint8 startingIdx = 1;

        for (uint8 i = startingIdx; i < startingIdx + additionalPlayers; i++) {
            address newPlayer = address(uint160(i));
            hoax(newPlayer, STARTING_PLAYER_BALANCE);
            raffle.enterRaffle{value: entranceFee}();
        }

        // Act
        vm.recordLogs();
        raffle.performUpkeep("");

        // Get the requestID from the emitted event
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        VRFCoordinatorV2_5Mock(vrfCordinatorAddress).fulfillRandomWords(uint256(requestId), address(raffle));

        address winner = raffle.getRecentWinnter();
        uint256 winnerBalance = address(winner).balance;
        uint256 prize =  entranceFee * (additionalPlayers + 1);

        assertEq(initialBalance + prize, winnerBalance, "KUR");
    }

    function testGoodWeatherRaffleTestnet() public {
        if (block.chainid != ETH_SEPOLIA_CHAIN_ID) {
            return;
        }

        // arrange
        uint256 initialBalance = address(PLAYER).balance;

        uint8 additionalPlayers = 3;
        uint8 startingIdx = 1;

        for (uint8 i = startingIdx; i < startingIdx + additionalPlayers; i++) {
            address newPlayer = address(uint160(i));
            hoax(newPlayer, STARTING_PLAYER_BALANCE);
            raffle.enterRaffle{value: entranceFee}();
        }

        // Act
        vm.recordLogs();
        raffle.performUpkeep("");

        // Get the requestID from the emitted event
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // should be called by chainlink
        // wait?

        address winner = raffle.getRecentWinnter();
        uint256 winnerBalance = address(winner).balance;
        uint256 prize =  entranceFee * (additionalPlayers + 1);

        assertEq(initialBalance + prize, winnerBalance, "KUR");
    }

}
