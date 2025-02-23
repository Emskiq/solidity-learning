// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract BoxV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 internal num;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function setNumber(uint200 _number) public { 
        num = _number;
    }

    function getNumber() public view returns(uint256) {
        return num;
    }

    function version() external pure returns(uint16) {
        return 1;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }
}