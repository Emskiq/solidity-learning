// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";

import {EmskiToken} from "src/EmskiToken.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";

import {DeployMerkleAirdrop} from "script/DeployMerkleAirdrop.s.sol";

import {ZkSyncChainChecker} from "foundry-devops/src/ZkSyncChainChecker.sol";

contract MerkleAirdropTest is ZkSyncChainChecker, Test {
    MerkleAirdrop public airdrop;
    EmskiToken public token;

    bytes32 constant ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;

    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] PROOF = [proofOne, proofTwo];

    // uint256 public claimAmount = 1 ether;

    uint256 claimAmount = (25 * 1e18); // 25.000000
    uint256 amountToMint = claimAmount * 4;

    address gasPayer;

    address user;
    uint256 privKey;

    function setUp() public {
        if (!isZkSyncChain()) {
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (token, airdrop) = deployer.deployMerkleAirdrop();
        } else {
            token = new EmskiToken();
            airdrop = new MerkleAirdrop(ROOT, token);
            token.mint(token.owner(), amountToMint);
            token.transfer(address(airdrop), amountToMint);
        }

        // token = new EmskiToken();
        // airdrop = new MerkleAirdrop(ROOT, token);

        (user, privKey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");
    }

    function testUsersCanClaim() public {
        // Act: user claims with an empty proof (valid in a one-leaf tree)
        uint256 startingBalance = token.balanceOf(user);

        vm.prank(user);

        // signing the message
        bytes32 digest = airdrop.getMessageHash(user, claimAmount);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, digest);

        airdrop.claim(user, claimAmount, PROOF, v, r, s);

        // Assert: user's token balance should equal claimAmount
        assertEq(token.balanceOf(user), claimAmount);
    }

    // Test that a user cannot claim twice
    function testCannotClaimTwice() public {
        // First claim succeeds.
        vm.prank(user);
        bytes32 digest = airdrop.getMessageHash(user, claimAmount);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, digest);

        airdrop.claim(user, claimAmount, PROOF, v, r, s);

        // Second claim should revert with AlreadyClaimed error.
        vm.prank(user);
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__AlreadyClaimed.selector);
        airdrop.claim(user, claimAmount, PROOF, v, r, s);
    }

    // Test that a claim with an invalid proof (or for a non-eligible user) fails.
    function testInvalidProof() public {
        (address nonEligibleUser, uint256 privKeyNonEligebleUser) = makeAddrAndKey("kur");
        vm.prank(nonEligibleUser);

        // signing the message
        bytes32 digest = airdrop.getMessageHash(nonEligibleUser, claimAmount);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKeyNonEligebleUser, digest);

        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidProof.selector);
        airdrop.claim(nonEligibleUser, claimAmount, PROOF, v, r ,s);
    }

    function testCanClaimForAnotherUser() public {
        // Act: user claims with an empty proof (valid in a one-leaf tree)
        uint256 startingBalance = token.balanceOf(user);

        vm.prank(user);
        // signing the message
        bytes32 digest = airdrop.getMessageHash(user, claimAmount);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, digest);

        vm.prank(gasPayer);
        airdrop.claim(user, claimAmount, PROOF, v, r, s);

        // Assert: user's token balance should equal claimAmount
        assertEq(token.balanceOf(user), claimAmount);
    }

    function testInvalidSignature() public {
        // Act: user claims with an empty proof (valid in a one-leaf tree)
        address nonEligibleUser = makeAddr("kur2");
        vm.prank(nonEligibleUser);

        // signing the message
        bytes32 digest = airdrop.getMessageHash(nonEligibleUser, claimAmount);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, digest);

        vm.prank(gasPayer);
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidSignature.selector);
        airdrop.claim(nonEligibleUser, claimAmount, PROOF, v, r, s);
    }
}
