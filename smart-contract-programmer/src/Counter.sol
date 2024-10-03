// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
	int public count = 0;

	function inc() public {
		count += 1;
	}

	function dec() public {
		count -= 1;
	}
}
