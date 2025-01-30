// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

import {Raffle} from "src/Raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig, Constants} from "script/HelperConfig.s.sol";

import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test, Constants {
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

    function testInitializeToOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.LotteryState.Open);
    }

    function testNotPayingEnoughToEnter() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughEntranceFunds.selector);
        raffle.enterRaffle();
    }

    function testNormalEnterSavePlayerInList() public {
        vm.prank(PLAYER);

        raffle.enterRaffle{value: entranceFee}();

        address playerEntered = raffle.getPlayer(0);
        assertEq(PLAYER, playerEntered);
    }

    function testNormalEnterEmitEvent() public {
        vm.prank(PLAYER);

        vm.expectEmit(true, false, false, false, address(raffle));
        emit PlayerEnterredRaffle(PLAYER);

        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayerToEnterWhileSpinning() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        raffle.enterRaffle{value: entranceFee}();
    }
    
    function testCheckUpkeepFalseIfNoBalance() public {
        vm.prank(PLAYER);

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool canEnter, ) = raffle.checkUpkeep("");

        assert(!canEnter);
    }

    function testCheckUpkeepFalseIfNotOpen() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        (bool canEnter, ) = raffle.checkUpkeep("");

        assert(!canEnter);
    }
    
    function testPerformUpkeepCanOnlyRunIfUpkeepTrue() public {
        vm.prank(PLAYER);

        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpkeepNotNeeded() public {
        vm.prank(PLAYER);
        uint256 balance = 0;
        uint256 numPlayers = 0;
        Raffle.LotteryState rState = raffle.getRaffleState();

        vm.prank(PLAYER);
        vm.expectRevert(
            abi.encodeWithSelector( Raffle.Raffle__UpkeepNotNeeded.selector, balance, numPlayers, rState)
        );
        raffle.performUpkeep("");
    }

    modifier skipFork() {
        if (block.chainid != LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // pass time
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpkeepEmitingEvent() public raffleEntered {
        vm.recordLogs();
        raffle.performUpkeep("");

        Raffle.LotteryState rState = raffle.getRaffleState();
        assert(rState == Raffle.LotteryState.CalculatingWinner);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 2); // one from our contract and one from the VRF cordinator
        assertEq(entries[1].topics[0], keccak256("PickingWinner(uint256)"));

    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerfomUpkeep(uint256 randomRequestId) public raffleEntered skipFork {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCordinatorAddress).fulfillRandomWords(randomRequestId, address(raffle));
    }

    function testFulfillRandomWordsPickAWinResetsAndSendMoney(uint256 randomRequestId) public raffleEntered skipFork {
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
}
