// SPDX-Licnse-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


/*
 * @title StableCoin
 * @author Emil Tsanev
 * Collateral: Exogenous
 * Minting (Stability Mechanism): Decentralized (Algorithmic)
 * Value (Relative Stability): Anchored (Pegged to USD)
 * Collateral Type: Crypto (wETH/wBTC)
 *
 * This is the contract meant to be owned by DSCEngine.
 * It is a ERC20 token that can be minted and burned by the DSCEngine smart contract.
 *
 */
contract StableCoin is ERC20Burnable, Ownable {
    error StableCoin__MustBeMoreThanZero();
    error StableCoin__BurnAmountExceedsBalance();
    error StableCoin__CannotMintToZeroAddress();


    constructor(address ownerAddress)
        ERC20("Stable Coin", "EM-USDC")
        Ownable(ownerAddress)
    { }

    function burn(uint256 _amount) public override onlyOwner {
        if (_amount <= 0) {
            revert StableCoin__MustBeMoreThanZero();
        }

        uint256 balance = balanceOf(msg.sender);
        if (_amount > balance) {
            revert StableCoin__BurnAmountExceedsBalance();
        }

        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns(bool) {
        if (_to == address(0)) {
            revert StableCoin__CannotMintToZeroAddress();
        }
        if (_amount <= 0) {
            revert StableCoin__MustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
}
