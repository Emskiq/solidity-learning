// SPDX-Licnse-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract MoodNft is ERC721 {
    error MoodNft__NotNftOwner();

    enum Mood { Happy, Sad }

    uint256 private s_tokenCounter;
    string private s_happySvgImageUri;
    string private s_sadSvgImageUri;
    mapping(uint256 => Mood) s_tokenToMood;


    constructor(string memory happySvg, string memory sadSvg) ERC721("Emski's Sad and Happy SVGs", "EM-HAPPY-SAD") {
        s_tokenCounter = 0;
        s_happySvgImageUri = happySvg;
        s_sadSvgImageUri = sadSvg;
    }

    function mintNFT() public {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenToMood[s_tokenCounter] = Mood.Happy;
        s_tokenCounter++;
    }

    modifier onlyOwner(uint256 tokenId) {
        if (_ownerOf(tokenId) != msg.sender) {
            revert MoodNft__NotNftOwner();
        }
        _;
    }

    function flipMood(uint256 tokenId) public onlyOwner(tokenId) {
        if (s_tokenToMood[tokenId] == Mood.Happy) {
            s_tokenToMood[tokenId] = Mood.Sad;
        }
        else {
            s_tokenToMood[tokenId] = Mood.Happy;
        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        string memory imageUri;
        if (s_tokenToMood[tokenId] == Mood.Happy) {
            imageUri = s_happySvgImageUri;
        }
        else {
            imageUri = s_sadSvgImageUri;
        }

        return string(
            abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    bytes( // bytes casting actually unnecessary as 'abi.encodePacked()' returns a bytes
                        abi.encodePacked(
                            '{"name":"',
                            name(), // You can add whatever name here
                            '", "description":"An NFT that reflects the mood of the owner, 100% on Chain!", ',
                            '"attributes": [{"trait_type": "moodiness", "value": 100}], "image":"',
                            imageUri,
                            '"}'
                        )
                    )
                )
            )
        );
    }
}
