// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";

import {OurToken} from "src/OurToken.sol";
import {DeployOurToken} from "script/DeployScript.s.sol";

contract OurTokenTest is Test {
	OurToken token;
	uint256 initialTotalSupply;

	address public EMSKI = makeAddr("EMSKI");
	address public DUDI = makeAddr("DUDI");

	function setUp() external {
		DeployOurToken deployer = new DeployOurToken();
		(token, initialTotalSupply) = deployer.run();

		// For clarity, label addresses so they show nicely in traces/logs
		vm.label(EMSKI, "EMSKI");
		vm.label(DUDI, "DUDI");
		vm.label(address(this), "TestContract");
		vm.label(msg.sender, "MessageSender");
	}

	function testInitialTotalSupply() public view {
		uint256 balance = token.totalSupply();
		assertEq(initialTotalSupply, balance, "Total supply mismatch");
	}

	function testInitialBalanceOfCreator() public view {
		uint256 balanceOfCreator = token.balanceOf(address(msg.sender));
		assertEq(initialTotalSupply, balanceOfCreator, "Deployer balance mismatch");
	}

	function testMetadata() public view {
		assertEq(token.name(), "Our token", "Token name is incorrect");
		assertEq(token.symbol(), "EM", "Token symbol is incorrect");
		assertEq(token.decimals(), 18, "Token decimals should be 18");
	}


	function testTransfer() public {
		uint256 transferAmount = 69 ether;

		vm.prank(msg.sender);
		token.transfer(EMSKI, transferAmount);

		uint256 creatorBalance = token.balanceOf(msg.sender);
		uint256 emskiBalance = token.balanceOf(EMSKI);

		assertEq(emskiBalance, transferAmount, "Incorrect EMSKI balance after transfer");
		assertEq(
			creatorBalance, 
			initialTotalSupply - transferAmount, 
			"Test contract balance should decrement by transfer amount"
		);
	}

	function testTransferInsufficientBalance() public {
		uint256 transferAmount = initialTotalSupply + 1;

		vm.prank(msg.sender);
		vm.expectRevert();
		token.transfer(EMSKI, transferAmount);
	}


	function testApprove() public {
		uint256 allowanceAmount = 5000 ether;
		bool success = token.approve(EMSKI, allowanceAmount);
		assertTrue(success, "approve should return true");

		uint256 allowance = token.allowance(address(this), EMSKI);
		assertEq(allowance, allowanceAmount, "Allowance should match after approve");
	}


	function testTransferFrom() public {
		uint256 allowanceAmount = 3000 ether;
		vm.prank(msg.sender); // msg.sender is the caller of the deploy script is the token creator => all of initial tokens belongs to him
		token.approve(EMSKI, allowanceAmount);

		vm.prank(EMSKI);
		token.transferFrom(msg.sender, DUDI, 1000 ether);

		// Validate final balances and leftover allowance
		uint256 bobBalance = token.balanceOf(DUDI);
		uint256 testContractBalance = token.balanceOf(msg.sender);
		uint256 remainingAllowance = token.allowance(msg.sender, EMSKI);

		assertEq(bobBalance, 1000 ether, "DUDI should receive 1000 tokens");
		assertEq(
			testContractBalance,
			initialTotalSupply - 1000 ether,
			"Test contract balance should go down by 1000"
		);
		assertEq(
			remainingAllowance,
			allowanceAmount - 1000 ether,
			"Allowance should decrease by spent amount"
		);
	}
}

