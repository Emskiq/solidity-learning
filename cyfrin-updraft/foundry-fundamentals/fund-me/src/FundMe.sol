// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Note: The AggregatorV3Interface might be at a different location than what was in the video!
import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;

    // ----------------------------------------------------------------------------------------------------------------
    // Gas optimization *advance* stuff:

    // We store the global variables of a contract in Storage.
    // Storage is an array like structure with [0] i_owner , [1] s_PriceFeed, [2], ...

    // In the Storage everythinf is separated on 32 bytes long slot
    // For dynamic like structure we do some hashing to point for the actual value

    // Constants are not taking part in the storage because they are directly written in the byte/assembly code
    // Memory is another location (not like storage) which is alocated during function execution

    // SLOAD/SSTORE - OP codes to read/write in storage are much more expensive (100 gas) than from memory for example
    // You can check the OP Codes' gas prices in evm.codes website

    // ----------------------------------------------------------------------------------------------------------------


    address private immutable i_owner; // immutable because we won't change it after first assignemtn (in constructor)
    AggregatorV3Interface s_priceFeed;
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        // 0x694AA1769357215DE4FAC081bf1f309aDC325306
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // 0x694AA1769357215DE4FAC081bf1f309aDC325306
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    function cheaperWithdraw() public onlyOwner {
        address[] memory funders = s_funders;
        // mappings can't be in memory, sorry!
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // payable(msg.sender).transfer(address(this).balance);
        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

    ///// ---------------------------
    ///// Pure/view methods (GETTERS)
    ///// ---------------------------

    function getAmountTOFundingAddres(address _adr) external view returns (uint256) {
        return s_addressToAmountFunded[_adr];
    }

    function getFunder(uint256 idx) external view returns (address) {
        return s_funders[idx];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly

