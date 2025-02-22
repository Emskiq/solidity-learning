// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";

import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {EmskiToken} from "src/EmskiToken.sol";

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 constant ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;

    uint256 claimAmount = (25 * 1e18); // 25.000000
    uint256 AMOUNT_TO_TRANSFER = claimAmount * 4;

    function run() public {
        deployMerkleAirdrop();
    }

    function deployMerkleAirdrop() public returns(EmskiToken, MerkleAirdrop) {

        vm.startBroadcast();

        EmskiToken token = new EmskiToken();
        MerkleAirdrop airdrop = new MerkleAirdrop(ROOT, token);
        token.mint(token.owner(), AMOUNT_TO_TRANSFER);
        IERC20(token).transfer(address(airdrop), AMOUNT_TO_TRANSFER);

        vm.stopBroadcast();

        return (token, airdrop);
    }
}
