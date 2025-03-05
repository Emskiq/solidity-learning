// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IAccount, ACCOUNT_VALIDATION_SUCCESS_MAGIC} from "@foundry-era-contracts/system-contracts/contracts/interfaces/IAccount.sol";
import {INonceHolder} from "@foundry-era-contracts/system-contracts/contracts/interfaces/INonceHolder.sol";
import {Transaction, MemoryTransactionHelper} from "@foundry-era-contracts/system-contracts/contracts/libraries/MemoryTransactionHelper.sol";
import {SystemContractsCaller} from "@foundry-era-contracts/system-contracts/contracts/libraries/SystemContractsCaller.sol";
import {Utils} from "@foundry-era-contracts/system-contracts/contracts/libraries/Utils.sol";
import {NONCE_HOLDER_SYSTEM_CONTRACT,
        BOOTLOADER_FORMAL_ADDRESS,
        DEPLOYER_SYSTEM_CONTRACT
} from "@foundry-era-contracts/system-contracts/contracts/Constants.sol";


import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// This is the contract the actually is going to send the transactions to any dApps and so on..
// MyAccount.sol in the diagram of Patrick Collins' video on Account Abstraction

/* Flow of type 113 Transaction (0x71) */
/* msg.sender is Bootloader system contract */
/* Light node <=> ZK Sync API Clien for Etherum (kinda) */
/*
 * I) Validation
 *    1) The user send the transaction to the ZK Api client (light  client)
 *    2) Light node is checking the nonce (whether it is unique) with the NonceHolder System contract
 *        *** System contracts - just like we have in Solana, these contracts are making easier for us to
 *            interact with ZkSync. For example: we have a `ContractDeployer` system contract ***
 *    3) Light node is calling `validateTransaction` which MUST update the nonce
 *    4) Light node is calling `validateTransaction` which MUST update the nonce
 *    5) Light node is calling `payForTransaction` which MUST update the nonce
 *    6) Light node is veriying that the Bootloader gets paid
 *
 *
 * II) Execution
 *    1) Light node passes the validated transaction to the main node/sequencer
 *    2) Light node will call `executeTransaction`
 *    3) If paymaster is used -> postTransaction actions?
 *
 */
contract ZkMinimalAccount is IAccount, Ownable {
    using MemoryTransactionHelper for Transaction;

    error ZkMinimalAccount__InsufficentBalance();
    error ZkMinimalAccount__NotFromBootloader();
    error ZkMinimalAccount__ExecutionFailed();
    error ZkMinimalAccount__NotFromBootloaderOrOwner();
    error ZkMinimalAccount__PayingForTheTransactionFailed();
    error ZkMinimalAccount__NotAValidTransaction();

    modifier requireFromBootloader() {
        if (msg.sender != BOOTLOADER_FORMAL_ADDRESS) {
            revert ZkMinimalAccount__NotFromBootloader();
        }
        _;
    }

    modifier requireFromBootloaderOrOwner() {
        if (msg.sender != BOOTLOADER_FORMAL_ADDRESS && msg.sender != owner()) {
            revert ZkMinimalAccount__NotFromBootloaderOrOwner();
        }
        _;
    }


    constructor() Ownable(msg.sender) { }

    /// ----------------------------
    /// ---- External Functions ----
    /// ----------------------------

    /**
     * @notice Must increase the nonce
     * @notice Check whether owner signed the transaction
     * @notice Also check whether we have enough money
     * @notice Make sure only the Bootloader calls that function
     */
    function validateTransaction(bytes32 /* _txHash */, bytes32 /* _suggestedSignedHash */, Transaction memory _transaction)
        external
        payable
        requireFromBootloader
        returns (bytes4 magic)
    {
        return _validateTransaction(_transaction);
    }

    /**
     * @notice Should be called after `validateTransaction`
     * @notice Should be called after we have `payForTransaction`
     * @notice Only Bootloader or Owner can call this function
     * @param  _transaction - the transaction that went through `validateTransaction`
     */
    function executeTransaction(bytes32 /* _txHash */, bytes32 /* _suggestedSignedHash */, Transaction memory _transaction)
        external
        payable
        requireFromBootloaderOrOwner
    {
        _executeTransaction(_transaction);
    }

    // There is no point in providing possible signed hash in the `executeTransactionFromOutside` method,
    // since it typically should not be trusted.
    // every user from outside can call it
    function executeTransactionFromOutside(Transaction memory _transaction) external payable
    {
        bytes4 magic = _validateTransaction(_transaction);
        if (magic == ACCOUNT_VALIDATION_SUCCESS_MAGIC) {
            _executeTransaction(_transaction);
        }
        else {
            revert ZkMinimalAccount__NotAValidTransaction();
        }

    }

    // Just like prepaying for the transaction (we have _prePayFunds in our Mainnet implementation)
    // Essentially someone needs to just pay for the Transaction
    function payForTransaction(bytes32 _txHash, bytes32 _suggestedSignedHash, Transaction memory _transaction)
        external
        payable
    {
            // function payToTheBootloader(Transaction memory _transaction) internal returns (bool success) {

        bool sucess = MemoryTransactionHelper.payToTheBootloader(_transaction);
        if (!sucess) {
            revert ZkMinimalAccount__PayingForTheTransactionFailed();
        }
    }

    // called when we have paymaster which is paying for our transactions
    function prepareForPaymaster(bytes32 _txHash, bytes32 _possibleSignedHash, Transaction memory _transaction)
        external
        payable
    { }



    /// ----------------------------
    /// ---- Internal Functions ----
    /// ----------------------------

    function _validateTransaction(Transaction memory _transaction)
        internal
        returns(bytes4 magic)
    {
        // This is how we can "more explicitly" call a system contract
        // Call nonceHolder increase the nonce
        SystemContractsCaller.systemCallWithPropagatedRevert(
            uint32(gasleft()),
            address(NONCE_HOLDER_SYSTEM_CONTRACT),
            0,
            abi.encodeCall(INonceHolder.incrementMinNonceIfEquals, (_transaction.nonce))
        );

        // Check fee - calculate how much this transaction is going to cost

        uint256 totalRequiredBalance = _transaction.totalRequiredBalance();
        if (totalRequiredBalance > address(this).balance) {
            revert ZkMinimalAccount__InsufficentBalance();
        }

        // Check signature
        bytes32 txHash = _transaction.encodeHash();
        address signer = ECDSA.recover(txHash, _transaction.signature);

        bool isValidSigner = signer == owner();

        // Return the magic
        if (isValidSigner) {
            magic = ACCOUNT_VALIDATION_SUCCESS_MAGIC;
        } else {
            magic = bytes4(0);
        }
    }

    function _executeTransaction(Transaction memory _transaction)
        internal
    {
        address to = address(uint160(_transaction.to));
        uint128 value = Utils.safeCastToU128(_transaction.value);

        bytes memory data = _transaction.data;

        if (to == address(DEPLOYER_SYSTEM_CONTRACT)) {
            uint32 gas = Utils.safeCastToU32(gasleft());
            SystemContractsCaller.systemCallWithPropagatedRevert(gas, to, value, data);
        } else {
            // XXX: This is how we call it on "high level"
            // (bool success, bytes memory result) = to.call{value: value}(data);
            // if (!success) {
            //     revert ZkMinimalAccount__ExecutionFailed();
            // }

            // XXX: This is how we call it using low level transaction
            bool sucess;
            assembly {
                sucess := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
            }

            if (!sucess) {
                revert ZkMinimalAccount__ExecutionFailed();
            }
        }
    }
}
