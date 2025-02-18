// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";

import {StableCoin} from "src/StableCoin.sol";
import {DeployStableCoin} from "script/DeployStableCoin.s.sol";

contract StableCoinTest is Test {
	StableCoin stableCoin;

	address public EMSKI = makeAddr("EMSKI");
	address public DUDI = makeAddr("DUDI");

	function setUp() external {
		DeployStableCoin deployer = new DeployStableCoin();
		stableCoin = deployer.run();
	}

	function testMetadata() public view {
		assertEq(stableCoin.name(), "Stable Coin", "Token name is incorrect");
		assertEq(stableCoin.symbol(), "EM-USDC", "Token symbol is incorrect");
		assertEq(stableCoin.decimals(), 18, "Token decimals should be 18");
	}

}
