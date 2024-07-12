// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// Other ways to specify the version:
// pragma solidity >=0.8.18 <0.9.0;

contract SimpleStorage {
    /// Basic/Primative types: bool, uint, int, address, bytes
    uint256 myFavNumber = 5; // by default - internal visibility

    struct Person {
        uint256 favNumber;
        string name;
    }
    
    Person[] public friends;

    mapping (string => uint256) public nameToFavNum;

    function store (uint256 newFavNum) public virtual {
        myFavNumber = newFavNum;  
    }

    function retrieve() public view returns(uint256) {
        return myFavNumber;
    }

    function addPerson(uint256 _favNum, string memory _name) public {
        friends.push(Person(_favNum, _name));
        nameToFavNum[_name] = _favNum;
    }
}

contract Temp {}
