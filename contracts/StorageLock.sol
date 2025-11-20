// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract StorageLock {
    bool private locked;

    modifier nonReentrant() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    function doSomething() external nonReentrant {
        
    }
}