// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// Contract used to play around while studying
/// from Smart Contract Programmer's tutorials
/// Videos - Structs - Events (including)
contract Tutorials4 {
    // Struct
    struct Car {
        string model;
        uint year;
        address owner;
    }

    Car public contractCar;
    Car[] public cars;

    function initializeCarsArray() external {
        contractCar = Car("Contract-a", 2024, address(this));
        Car memory porch = Car ({model: "Porche Cayene", year: 2021, owner: msg.sender});
        Car memory lambo  = Car ({model: "Lamborghini", year: 2024, owner: msg.sender});
        Car memory bmw  = Car ({model: "BMW", year: 2004, owner: msg.sender});
        
        cars.push(contractCar);
        cars.push(porch);
        cars.push(lambo);
        cars.push(bmw);

        // Should be memory -> tell the EVM that we are editing the state
        Car memory _car = cars[1];
        delete _car.owner;
    }

    function carsLength() external view returns (uint) {
        return cars.length;
    }

    // Enums
    enum Status {
        None,
        Pending,
        Completed,
        Canceled
    }

    Status public contractOrderStatus;

    function getStatus() view external returns(Status) {
        return contractOrderStatus;
    }

    function setStatus(Status _status) external {
        contractOrderStatus = _status;
    }

    function cancelContractStatus() external {
        contractOrderStatus = Status.Canceled;
    }

    // Data locations:
    // storage - state variable (modifiable in the blockchain/"global")
    // memory - loaded in the memory (modifiable only in the block of code, not "global")
    // calldata - like memory, but just for function inputs (not modifiable)

    struct Foo {
        uint num;
        string text;
    }

    mapping(address => Foo) public foos;
    
    function examplesWithStorages(uint[] calldata y, string calldata s) external returns(uint[] memory) {
        foos[msg.sender] = Foo({num: 1, text: "EMSKIQ"});

        Foo storage editable = foos[msg.sender];
        editable.text = "EMSKIQ22";

        Foo memory readOnly = foos[msg.sender];
        editable.text = "EMSKIQ23"; // Cannot do that - no error, but no point of doing it

        uint[] memory memArr = new uint[](3);
        memArr[0] = 69;
        memArr[1] = 420;

        _internal(y);

        return memArr;
    }

    // no memory -> no unnecessary copy
    // calldata -> means that the input is not modifiable
    function _internal(uint[] calldata y) private {
        uint x = y[0];
    }

    // Events: https://www.youtube.com/watch?v=nopo9KwwRg4&list=PLO5VPQH6OWdVQwpQfw9rZ67O6Pjfo6q-p&index=30
    event Log(string message, uint val);
    // up to 3 indexed
    event IndexedLog(address indexed sender, uint val);

    // transactional function because of the events - they store data on blockchain
    function exampleEvents() external {
        emit Log("foo", 420);
        emit IndexedLog(msg.sender, 69);
    }

    event Message(address indexed _from, address indexed _to, string _msg);

    function sendMessage(address _to, string memory _msg) external {
        emit Message(msg.sender, _to, _msg);
    }
}
