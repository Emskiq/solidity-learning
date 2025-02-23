// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IAccount} from "@account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "@account-abstraction/contracts/core/Helpers.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MinimalAccount is IAccount, Ownable {
    error MinimalAccount__SignatureInvalid();

    constructor() Ownable(msg.sender) {}

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external returns (uint256 validationData)
    {
        validationData = _validateSignature(userOp, userOpHash);
        _validateNonce();
        _payPrefund(missingAccountFunds);
    }

    // Only if contract owner is the caller
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash) internal view returns(uint256) {
        // check whether userOp.signature is a valid signature of the userOpHash
        // -- if the contract owner is the caller

        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(digest, userOp.signature);

        if (signer != owner()) {
                // revert MinimalAccount__SignatureInvalid();
                return SIG_VALIDATION_FAILED;
        }

        // Here add the logic for Google authenittaction to sign the transaction
        // --------------------------------------------------------------------  

        return SIG_VALIDATION_SUCCESS;
    }

    function _validateNonce() internal pure {
        // TODO
    }

    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            (success);
        }
    }
}
