// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";

import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";

import {DeployMinimalAccount} from "script/DeployMinimalAccount.s.sol";
import {SendPackedUserOps} from "script/SendPackedUserOps.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "@account-abstraction/contracts/core/Helpers.sol";

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract TestMinimalAccount is Test {
    using MessageHashUtils for bytes32;

    DeployMinimalAccount deployer;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig config;
    MinimalAccount minimalAccount;

    SendPackedUserOps userOpsPacketSender;

    ERC20Mock usdc;

    // Also works (and it is cleaner)
    // bytes4 constant MINT_FUNC_SELECTOR = ERC20Mock.mint.selector;
    bytes4 constant MINT_FUNC_SELECTOR = bytes4(keccak256("mint(address,uint256)"));
    uint256 constant MINT_AMOUNT = 25 ether;

    uint256 constant FUNDS_AMOUNT = 25 ether;

    address randomUser;

    function setUp() public {
       deployer = new DeployMinimalAccount();
       (helperConfig, minimalAccount) = deployer.deploytMinimalContract();
       usdc = new ERC20Mock();
       userOpsPacketSender = new SendPackedUserOps();

       config = helperConfig.getConfig();

       randomUser = makeAddr("random");
    }


    function testOwnerCanExecute() public {
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);

        address dest = address(usdc);
        bytes memory functionData = abi.encodeWithSelector(MINT_FUNC_SELECTOR, address(minimalAccount), MINT_AMOUNT);

        vm.prank(address(this));

        minimalAccount.execute(dest, 0, functionData);

        assertEq(usdc.balanceOf(address(minimalAccount)), MINT_AMOUNT);
    }

    function testRandomUserCannotExecute() public {
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);

        address dest = address(usdc);
        bytes memory functionData = abi.encodeWithSelector(MINT_FUNC_SELECTOR, address(minimalAccount), MINT_AMOUNT);

        vm.prank(randomUser);
        vm.expectRevert(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector);
        minimalAccount.execute(dest, 0, functionData);
    }

    function testRecoverSignOp() public {
        address dest = address(usdc);
        uint256 val = 0;

        bytes memory functionData = abi.encodeWithSelector(MINT_FUNC_SELECTOR, address(minimalAccount), MINT_AMOUNT);

        bytes memory executeCalldata = abi.encodeWithSelector(MinimalAccount.execute.selector, dest, val, functionData);

        PackedUserOperation memory userOps = userOpsPacketSender.generateSignedUserOperations(executeCalldata, address(minimalAccount), config);
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOps);

        // verify signature
        address actualSigner = ECDSA.recover(userOpHash.toEthSignedMessageHash(), userOps.signature);
        assertEq(actualSigner, minimalAccount.owner());
    }

    function testValidationOfUserOps() public {
        address dest = address(usdc);
        uint256 val = 0;

        bytes memory functionData = abi.encodeWithSelector(MINT_FUNC_SELECTOR, address(minimalAccount), MINT_AMOUNT);

        bytes memory executeCalldata = abi.encodeWithSelector(MinimalAccount.execute.selector, dest, val, functionData);

        PackedUserOperation memory userOps = userOpsPacketSender.generateSignedUserOperations(executeCalldata, address(minimalAccount), config);
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOps);

        
        vm.prank(config.entryPoint);
        uint256 signatureValidation = minimalAccount.validateUserOp(userOps, userOpHash, 1e18);
        assertEq(SIG_VALIDATION_SUCCESS, signatureValidation);
    }

    function testEntryPointCanExecuteCommands() public {
        address dest = address(usdc);
        uint256 val = 0;

        bytes memory functionData = abi.encodeWithSelector(MINT_FUNC_SELECTOR, address(minimalAccount), MINT_AMOUNT);

        bytes memory executeCalldata = abi.encodeWithSelector(MinimalAccount.execute.selector, dest, val, functionData);

        PackedUserOperation memory userOps = userOpsPacketSender.generateSignedUserOperations(executeCalldata, address(minimalAccount), config);
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOps);

        vm.deal(address(minimalAccount), FUNDS_AMOUNT);

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOps;

        vm.prank(randomUser);
        IEntryPoint(config.entryPoint).handleOps(ops, payable(randomUser));
        assertEq(usdc.balanceOf(address(minimalAccount)), MINT_AMOUNT);
    }
}
