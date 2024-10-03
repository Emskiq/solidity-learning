// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Unnecessary contract which stores a TODO list for someone
contract TodoList {
    struct Todo {
        string text;
        bool completed;
    }

    Todo[] public todos;

    function create(string calldata _text) external {
        todos.push(Todo(_text, false));
    }

    function update(uint idx, string memory _text) external {
        require(idx < todos.length, "Index out of range");
        todos[idx].text = _text;
    }

    function get(uint idx) external view returns(Todo memory) {
        require(idx < todos.length, "Index out of range");
        return todos[idx];
    }

    function complete(uint idx) external {
        require(idx < todos.length, "Index out of range");
        todos[idx].completed = true;
    }
}
