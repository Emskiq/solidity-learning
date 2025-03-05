// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";

import {ZkMinimalAccount} from "src/zksync/ZkMinimalAccount.sol";

import {ACCOUNT_VALIDATION_SUCCESS_MAGIC} from "@foundry-era-contracts/system-contracts/contracts/interfaces/IAccount.sol";
import {BOOTLOADER_FORMAL_ADDRESS} from "@foundry-era-contracts/system-contracts/contracts/Constants.sol";
import {Transaction, MemoryTransactionHelper} from "@foundry-era-contracts/system-contracts/contracts/libraries/MemoryTransactionHelper.sol";

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";


contract TestZkMinimalAccount is Test {
    using MessageHashUtils for bytes32;
    using MemoryTransactionHelper for Transaction;

    ERC20Mock usdc;
    ZkMinimalAccount minimalAccount;

    address constant ANVIL_DEFAULT_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 constant ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    bytes4 constant MINT_FUNC_SELECTOR = ERC20Mock.mint.selector;
    uint256 constant MINT_AMOUNT = 25 ether;
    uint256 constant FUNDS_AMOUNT = 25 ether;

    // ! Deploying cheat codes from Foundry does not work on ZkSync !
    function setUp() public {
        usdc = new ERC20Mock();
        minimalAccount = new ZkMinimalAccount();
        minimalAccount.transferOwnership(ANVIL_DEFAULT_ACCOUNT);
        vm.deal(address(minimalAccount), FUNDS_AMOUNT);
    }


    function testZkOwnerCanExecute() public {
        // arrange
        bytes32 txHash = bytes32(0);
        bytes32 suggestedSignedHash = bytes32(0);

        address dest = address(usdc);
        bytes memory functionData = abi.encodeWithSelector(MINT_FUNC_SELECTOR, address(minimalAccount), MINT_AMOUNT);

        Transaction memory transaction = createUnsignedTransaction(minimalAccount.owner(), 0x71, dest, 0, functionData);

        // act
        vm.prank(ANVIL_DEFAULT_ACCOUNT);
        minimalAccount.executeTransaction(txHash, suggestedSignedHash, transaction);

        // assert
        assertEq(usdc.balanceOf(address(minimalAccount)), MINT_AMOUNT);
    }

    function testZkValidateTransaction() public {
        // arrange
        bytes32 txHash = bytes32(0);
        bytes32 suggestedSignedHash = bytes32(0);

        address dest = address(usdc);
        bytes memory functionData = abi.encodeWithSelector(MINT_FUNC_SELECTOR, address(minimalAccount), MINT_AMOUNT);

        Transaction memory transaction = createUnsignedTransaction(minimalAccount.owner(), 0x71, dest, 0, functionData);

        // signing the transaction
        bytes32 transactionHash = transaction.encodeHash();
        // bytes32 digest = transactionHash.toEthSignedMessageHash(); // not needed!
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ANVIL_DEFAULT_KEY, transactionHash);

        transaction.signature = abi.encodePacked(r, s, v);

        // act
        vm.prank(BOOTLOADER_FORMAL_ADDRESS);
        bytes4 magic = minimalAccount.validateTransaction(txHash, suggestedSignedHash, transaction);

        // assert
        assertEq(ACCOUNT_VALIDATION_SUCCESS_MAGIC, magic);
    }

    function createUnsignedTransaction(address from, uint8 txType, address to, uint256 value, bytes memory data)
        internal
        returns(Transaction memory)
    {
        uint256 nonce = vm.getNonce(address(minimalAccount));
        bytes32[] memory factoryDeps = new bytes32[](0);

        Transaction memory transaction = Transaction({
            txType: txType,  // mostly type 113 (0x71)
            from: uint256(uint160(from)),
            to: uint256(uint160(to)),
            gasLimit: 69420420,
            gasPerPubdataByteLimit: 69420420,
            maxFeePerGas: 256,
            maxPriorityFeePerGas: 256,
            paymaster: 0,
            nonce: nonce,
            value: value,
            reserved: [uint256(0), uint256(0), uint256(0), uint256(0)],
            data: data,
            signature: hex"",
            factoryDeps: factoryDeps,
            paymasterInput: hex"",
            reservedDynamic: hex""
        });

        return transaction;
    }

}
