// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";

import {HelperConfig, Constants} from "./HelperConfig.s.sol";

contract SendPackedUserOps is Script {
    using MessageHashUtils for bytes32;

    function generateSignedUserOperations(bytes memory callData, address sender, HelperConfig.NetworkConfig memory config)
        public
        returns(PackedUserOperation memory)
    {
        uint256 nonce = vm.getNonce(sender) - 1;
        PackedUserOperation memory userOperation = _generateUnsignedUserOperations(callData, sender, nonce);

        // Signing
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOperation);
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);

        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ANVIL_DEFAULT_KEY, digest);

        userOperation.signature = abi.encodePacked(r, s, v);

       return userOperation;
    }

    function _generateUnsignedUserOperations(bytes memory userOpetionsCalldata, address sender, uint256 nonce) internal pure returns(PackedUserOperation memory) {
        uint128 verificationGasLimit = 69420420;
        uint128 callGasLimit = 69420420;

        uint128 maxPriorityGasFees = 256;
        uint128 maxFeePerGas = maxPriorityGasFees;

        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: userOpetionsCalldata,
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32(uint256(maxPriorityGasFees) << 128 | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });

    }

    // function _signUserOperation(
    //     PackedUserOperation memory userOperation,
    //     address sender,
    //     address entryPointAddress)
    //     internal
    // {
    // }
}
