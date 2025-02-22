// SPDX-Licnse-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @title EmskiToken
 * @author Emil Tsanev
 *
 * This is the contract meant to be owned by MerkleAirdrop.
 * It is a ERC20 token that can be minted and burned..
 *
 */
contract EmskiToken is ERC20, Ownable {

    constructor()
        ERC20("Emski's coin", "EMSKI")
        Ownable(msg.sender)
    { }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

}
