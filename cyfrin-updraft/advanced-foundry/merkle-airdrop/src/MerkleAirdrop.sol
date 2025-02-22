// SPDX-Licnse-Identifier: MIT
pragma solidity ^0.8.24;

import {console} from "forge-std/console.sol";

import {EmskiToken} from "./EmskiToken.sol";

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/*
 * @title MerkleAirdrop
 * @author Emil Tsanev
 *
 * Airdroping tokens for users
 *
 */
contract MerkleAirdrop is EIP712 {
    struct AirdropClaim {
        address user;
        uint256 amount;
    }

    using SafeERC20 for IERC20;

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    event Claim(address indexed account, uint256 indexed amount);

    bytes32 private constant AIRDROP_CLAIM_TYPEHASH = keccak256("AirdropClaim(address user,uint256 amount)");

    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;

    address[] private s_claimers;
    mapping(address claimer => bool claimed) private s_hasClaimed;

    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("MerkleAirdrop", "1") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    function claim(address user, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s) external {
        // calculate using the account + amount
        if (s_hasClaimed[user] == true) {
            console.log("has claimed");
            revert MerkleAirdrop__AlreadyClaimed();
        }
            console.log("KURRR");

        // check signature
        if (!_isValidSignature(user, getMessageHash(user, amount), v, r, s)) {
            console.log("invalid signature");
            revert MerkleAirdrop__InvalidSignature();
        }

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(user, amount))));

        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            console.log("invalid proof");
            revert MerkleAirdrop__InvalidProof();
        }

        s_hasClaimed[user] = true;

        emit Claim(user, amount);
        i_airdropToken.safeTransfer(user, amount);

    }

    function getAirdropToken() external view returns(IERC20) {
        return i_airdropToken;
    }

    function getMerkleRoot() external view returns(bytes32) {
        return i_merkleRoot;
    }

    function getMessageHash(address user, uint256 amount) public view returns(bytes32) {
        return _hashTypedDataV4(
            keccak256(abi.encode(AIRDROP_CLAIM_TYPEHASH, AirdropClaim({user: user, amount: amount})))
        );
    }

    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s) internal pure returns(bool) {
        (address actualSigner, ,) = ECDSA.tryRecover(digest, v, r, s);
        return actualSigner == account;
    }

}

