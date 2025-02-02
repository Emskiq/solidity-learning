// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {BasicNFT} from "src/BasicNFT.sol";
import {DeployBasicNft} from "script/DeployBasicNft.s.sol";

contract BasicNFTTest is Test {
    DeployBasicNft public deployer;
    BasicNFT public basicNft;

    address public EMSKI = makeAddr("EMSKI");

    function setUp() public {
        deployer = new DeployBasicNft();
        basicNft = deployer.run();
    }

    function testName() public {
        string memory expectedName = "EMSKI's NFT";
        string memory actualName = basicNft.name();
        assertEq(expectedName, actualName, "NFT name mismatch");
    }

    function testSymbol() public {
        string memory expectedSymbol = "EM-NFT";
        string memory actualSymbol = basicNft.symbol();
        assertEq(expectedSymbol, actualSymbol, "NFT symbol mismatch");
    }

    function testMintNFTandOwner() public {
        string memory tokenURIString = "ipfs://KUR";

        vm.prank(EMSKI);
        basicNft.mintNFT(tokenURIString);

        address owner = basicNft.ownerOf(0);
        assertEq(owner, EMSKI, "Token owner should be the minter");

        uint256 emskiNFTBalance = basicNft.balanceOf(EMSKI);
        assertEq(emskiNFTBalance, 1, "Emski NFT balance is not 1!!");

        string memory returnedURI = basicNft.tokenURI(0);
        assert(keccak256(abi.encodePacked(returnedURI)) == keccak256(abi.encodePacked(tokenURIString)));
    }

    function testTokenURINonExistent() public {
        string memory uri = basicNft.tokenURI(696969420420);
        assertEq(uri, "", "Non-existent token should have an empty URI");
    }
}
