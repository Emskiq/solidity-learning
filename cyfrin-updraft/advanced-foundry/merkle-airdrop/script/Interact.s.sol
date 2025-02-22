// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {EmskiToken} from "src/EmskiToken.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";

import {DeployMerkleAirdrop} from "script/DeployMerkleAirdrop.s.sol";

import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

/**
 * @title Interaction
 * @author Emil Tsanev
 */
contract ClaimAirdrop is Script {
    error ClaimAirdrop__InvalidSignatureLength();

    address public constant CLAIM_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 private constant CLAIM_AMOUNT = (25 * 1e18); // 25.000000

    bytes32 private constant PROOF_ONE = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 private constant PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] private PROOF = [PROOF_ONE, PROOF_TWO];

    // bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    // bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    // bytes32[] PROOF = [proofOne, proofTwo];



    // This signature is created via `cast` command
    // NOTE: The signature will change every time you redeploy the airdrop contract!
    bytes private SIGNATURE = hex"30f40db34312d8dac5992bb8117d1707584ec3b4afbbd2db75536289402fe0af7886dbcf69866aff1b6e330488b9d2a70f9b825baca4246d7752d691e1c0758f1c";

    // bytes SIGNATURE = 0x112712fa008390e0510406e48207371d7af0b9a32788e7a1ffdeb800ede83ec0142986a9ef0f17cfa4253a8c65224209c188bf8f17a081f3c0ecc5c244b356251c;


    function claimMostRecentDeploy(address airdropAddress) public {
        vm.startBroadcast();
        // (bytes32 r, bytes32 s, uint8 v) = splitSignature(SIGNATURE);
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        MerkleAirdrop(airdropAddress).claim(CLAIM_ADDRESS, CLAIM_AMOUNT, PROOF, v, r, s);
        vm.stopBroadcast();
    }

    /// @dev Run interactions with the deployed MerkleAirdrop contract
    function run() external {
        // Again there is a problem with the most recent get most deployment function from DevOpsTools...
        // address mostRecentDeploy = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        // That's why I am using the hardcoded address of the MerkleAirdrop contract
        address mostRecentDeploy = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;

        claimMostRecentDeploy(mostRecentDeploy);
    }

    function splitSignature(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (sig.length != 65) {
            revert ClaimAirdrop__InvalidSignatureLength();
        }
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    // function splitSignature(bytes memory sig)
    //     public
    //     pure
    //     returns (bytes32 r, bytes32 s, uint8 v)
    // {
    //     if (sig.length != 65) {
    //         revert ClaimAirdrop__InvalidSignatureLength();
    //     }
    //
    //     // XXX: You can see the following resources regarding splitting a signature
    //     // - https://ethereum.stackexchange.com/questions/134450/get-signature-bytes-from-v-r-s-ecdsa-using-solidity
    //     // - https://www.cyfrin.io/glossary/verifying-signature-solidity-code-example
    //
    //     assembly {
    //         /*
    //             First 32 bytes stores the length of the signature
    //
    //             add(sig, 32) = pointer of sig + 32
    //             effectively, skips first 32 bytes of signature
    //
    //             mload(p) loads next 32 bytes starting at the memory address p into memory
    //         */
    //
    //         // first 32 bytes, after the length prefix
    //         r := mload(add(sig, 32))
    //         // second 32 bytes
    //         s := mload(add(sig, 64))
    //         // final byte (first byte of the next 32 bytes)
    //         v := byte(0, mload(add(sig, 96)))
    //     }
    // }
}
