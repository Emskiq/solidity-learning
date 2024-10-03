// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// Contract used to play around while studying
/// from Smart Contract Programmer's tutorials
/// Videos - First till Counter
contract Tutorials {
	string public helloWrld = "hello world from emskiq";

	// Public means it will be stored on the block chain (like static)
	uint public maxUint = type(uint).max; // Should be 2^256 - 1
	uint public minUint = type(uint).min; // Should be 0

	int public maxInt = type(int).max; // Should be 2^128 - 1
	int public minInt = type(int).min; // Should be -2^128 + 1

	function sub (uint a, uint b) public pure returns(uint) {
		return a - b;
	}

	function foo() external pure {
		// Local variable (stored only on the stack)
		// Stack will be *cleared* when `foo` is done
		uint notStateVariable = 69;
	}

	function globalVar() external view returns(address, uint, uint) {
		address caller = msg.sender;
		uint time = block.timestamp;
		uint blockNum = block.number;
		return (caller, time, blockNum);
	}
}
