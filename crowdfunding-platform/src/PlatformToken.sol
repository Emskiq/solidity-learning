// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PlatformToken is ERC20, Ownable {
    error PlatformToken__MustBeMoreThanZero();
    error PlatformToken__BurnAmountExceedsBalance();
    error PlatformToken__CannotMintToZeroAddress();

    constructor() 
        ERC20("PlatfromToken", "PTKN")
        Ownable(msg.sender)
    { }

    function mint(address _to, uint256 _amount) external onlyOwner returns(bool) {
        if (_to == address(0)) {
            revert PlatformToken__CannotMintToZeroAddress();
        }
        if (_amount <= 0) {
            revert PlatformToken__MustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }

}
