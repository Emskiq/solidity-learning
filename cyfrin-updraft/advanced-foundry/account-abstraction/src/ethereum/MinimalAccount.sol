// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IAccount} from "@account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "@account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";


// This is the contract the actually is going to send the transactions to any dApps and so on..
// MyAccount.sol in the diagram of Patrick Collins' video on Account Abstraction
contract MinimalAccount is IAccount, Ownable {
    IEntryPoint immutable private i_entryPoint;

    error MinimalAccount__NotFromEntryPoint();
    error MinimalAccount__NotFromEntryPointOrOwner();
    error MinimalAccount__ExecutionFailed(bytes);

    modifier requireFromEntryPoint() {
        if (msg.sender != address(i_entryPoint)) {
            revert MinimalAccount__NotFromEntryPoint();
        }
        _;
    }

    modifier requireFromEntryPointOrOwner() {
        if (msg.sender != address(i_entryPoint) && msg.sender != owner()) {
            revert MinimalAccount__NotFromEntryPointOrOwner();
        }
        _;
    }

    constructor(address entryPoint) Ownable(msg.sender) {
        i_entryPoint = IEntryPoint(entryPoint);
    }

    function execute(address dest, uint256 val, bytes calldata functionData) external requireFromEntryPointOrOwner {
        (bool success, bytes memory result) = dest.call{value: val}(functionData);
        if (!success) {
            revert MinimalAccount__ExecutionFailed(result);
        }
    }


    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external
        requireFromEntryPoint
        returns (uint256 validationData)
    {
        validationData = _validateSignature(userOp, userOpHash);
        _validateNonce();
        _payPrefund(missingAccountFunds);
    }


    // Receive funds so we can then use them to pay for the calls
    receive() external payable {}

    // Only if contract owner is the caller
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash) internal view returns(uint256) {
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(digest, userOp.signature);

        if (signer != owner()) {
                // revert MinimalAccount__SignatureInvalid();
                return SIG_VALIDATION_FAILED;
        }

        // Here add the logic for Google authenittaction to sign the transaction

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


    // ------------------------------------------------------------------------
    //           Public view functions (getters)
    // ------------------------------------------------------------------------
    function getEntryPoint() public view returns(IEntryPoint) {
        return i_entryPoint;
    }
}
