// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract BoxV2 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 internal num;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function setNumber(uint256 number) external {
        num = number;
    }

    function getNumber() public view returns(uint256) {
        return num;
    }

    function version() external view returns(uint16) {
        return 2;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }
}