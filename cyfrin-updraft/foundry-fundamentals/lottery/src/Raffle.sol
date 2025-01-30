// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/v0.8/automation/AutomationCompatible.sol";

/**
 * @title A simple Raffle account
 * @author Emskiq
 * @notice This contract represent a simple entering of a Raffle
 */
contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    // Events
    event PlayerEnterredRaffle(address indexed playerAddress);
    event PickingWinner(uint256 indexed requestId);
    event WinnerPicked(uint256 indexed requestId, address indexed winnerAddress);
    event WinnerAwarded(address indexed winnerAddress, uint256 indexed awardAmount);
    // Errors
    error Raffle__NotEnoughEntranceFunds();
    error Raffle__WaitTimeHasntPassed();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLen, uint256 raffleState);
    // Enums
    enum LotteryState { Open, CalculatingWinner }

    // State variables
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint256 private immutable i_subscriptionId;

    uint256 private s_lastTimestamp;
    address payable [] private s_players;
    address payable private s_mostRecentWinner;
    LotteryState s_currentState;

    // Chainlink VRF Randomizer constants/variables
    // address private constant VRF_CORDINATOR = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B; // for the sepolia test net
    uint16 public constant REQUEST_CONFIRMATIONS = 3; // hardcode for the Sepolia Testnet
    uint32 public constant CALLBACK_GAS_LIMIT = 400_000; // could be changable?
    uint32 public constant NUM_WORDS = 1;

    bytes32 public immutable i_keyHash;

    constructor(uint256 entranceFee, uint256 interval, uint256 subscriptionId, address vrfCordinatorAddress, bytes32 gasLane) VRFConsumerBaseV2Plus(vrfCordinatorAddress) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        s_lastTimestamp = block.timestamp;
        i_keyHash = gasLane;
        s_currentState = LotteryState.Open;
    }

    // TODO:
    fallback() external payable { }
    receive() external payable { }


    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEntranceFunds();
        }
        if (s_currentState != LotteryState.Open) {
            revert Raffle__RaffleNotOpen();
        }
        
        s_players.push(payable(msg.sender));
        emit PlayerEnterredRaffle(msg.sender);
    }

    // ---------- CEI Pattern ----------
    // Check, effects, interraction patterns - basically the sequence of the function executing
    // Reentraccy attacks prevention + Gas optimization

    function pickWinner() internal {
        // check
        if (block.timestamp - s_lastTimestamp < i_interval) {
            revert Raffle__WaitTimeHasntPassed();
        }

        // effects
        s_currentState = LotteryState.CalculatingWinner;

        // interactions
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: CALLBACK_GAS_LIMIT,
                numWords: NUM_WORDS,
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );

        emit PickingWinner(requestId);
    }

    // VRF Randomizer callback implementation
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        // Checks - no checks here... :(

        // Effects
        uint256 playerIdx = (randomWords[0] % s_players.length);
        address payable winnerAddress = s_players[playerIdx];
        s_mostRecentWinner = winnerAddress;
        emit WinnerPicked(requestId, winnerAddress);

        s_currentState = LotteryState.Open;
        s_players = new address payable[](0); // reseting array
        s_lastTimestamp = block.timestamp;

        // Interactions (+ external contraction interactions)
        uint256 awardAmount = address(this).balance;
        (bool success,) = winnerAddress.call{value: awardAmount}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }

        emit WinnerAwarded(winnerAddress, awardAmount);
    }

    // Timer callbacks
    function checkUpkeep( bytes calldata /* checkData */) external view override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = (s_currentState == LotteryState.Open); // just a sanity check for the opening of the Lottery
        bool timePassed = (block.timestamp - s_lastTimestamp) > i_interval; // the actual interval check
        bool hasFunds = address(this).balance > 0; // the actual interval check
        bool hasPlayers = s_players.length > 0; // the actual interval check
        upkeepNeeded = isOpen && timePassed && hasFunds && hasPlayers;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if ((block.timestamp - s_lastTimestamp) > i_interval && s_currentState == LotteryState.Open && s_players.length > 0) {
            pickWinner();
        }
        else {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_currentState));
        }
    }

    // ---------------------------------------------
    //                    GETTERS
    // ---------------------------------------------
    function getEntranceFee() external view returns(uint256) { return i_entranceFee; }
    function getRecentWinnter() external view returns(address) { return s_mostRecentWinner; }
    function getRaffleState() external view returns(LotteryState) { return s_currentState; }
    function getPlayer(uint256 idx) external view returns(address) { return s_players[idx]; }
}
