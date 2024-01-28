// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";

//0x694AA1769357215DE4FAC081bf1f309aDC325306


/// 863,997 - First state (transaction cost on deploying contract
/// 844,051 - Adding constant to minUsd
/// 819,843 - Adding immutable to owner address 
// constant, immutable -> will save gase

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MIN_USD = 5e18;

    address[] public funders;
    mapping(address funder => uint256 amountFunded) public addressToAmountFunded;

    address public immutable i_owner;

    // AggregatorV3Interface internal dataFeed;
    // int public price;
    constructor() {
        i_owner = msg.sender;
    }

    function fund() public payable  {
        require(msg.value.getConversionRate() > MIN_USD, "Inssufificeint amount!");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        require(msg.sender == i_owner, "Must be called by the i_owner!");

        for (uint256 funderIdx = 0; funderIdx < funders.length; funderIdx++)  {
            address funder = funders[funderIdx];
            addressToAmountFunded[funder] = 0; 
        }
        // Reset array
        funders = new address[](0); // New dynamic array with lenght of 0

        // // Transfer method
        // /// Trhows error if transaction exceeded 2'300 gas limit
        // /// Payable address type - this is needed to send eth to address
        // payable(msg.sender).transfer(address(this).balance);

        // // Send method
        // /// Returns true if transaction didn't exceeded 2'300 gas limit, false otherwise
        // bool isSuccess = payable(msg.sender).send(address(this).balance);
        // // This way we are doing the same thing as transfer -> returning state on send failure
        // require(isSuccess, "Withdrawing failed!");

        // Call method - low level
        /// Treated like normal transaction {args} - here we are typing the transaction arguments
        /// Returns isSuccessful and what data in bytes array has been returned by the function
        (bool callSuccess, ) = payable (msg.sender).call {value:address(this).balance} ("");
        require(callSuccess, "Withdrawing failed!");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not i_owner");
        // _;
        if (msg.sender != i_owner) {
            revert NotOwner(); /// gas optimization (calling the error code instead of string)
        }
        _;
    }

    //// Sending eth without calling fund() function above
    receive() external payable { 
        fund();
    }

    fallback() external payable {
        fund();
    }

}
