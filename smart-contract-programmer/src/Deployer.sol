// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Video: https://www.youtube.com/watch?v=YbRGTF1OGdM&list=PLO5VPQH6OWdVQwpQfw9rZ67O6Pjfo6q-p&index=27

// TODO: After Ethers Wallet
// Contract that deploys any contract

contract Proxy {
    event Deploy(address);

    function deploy(bytes memory _code) external payable returns(address addr) {
        assembly {
            // create(v, p, n);
            // v - amount of ETH to send
            // p - pointer in memory where new _code to start
            // n - size of the code
            addr := create(callvalue(), add(_code, 0x20), mload(_code))
        }

        return addr;
    }
}
