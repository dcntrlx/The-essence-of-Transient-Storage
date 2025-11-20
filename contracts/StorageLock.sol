// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract StorageLock {
    modifier nonReentrant() {
        assembly {
            if sload(1) {  // Using slot 1 as reentrancy flag. Only appropriate for comparison to TransientStorage. Not recommended in real projects
                revert(0, 0)
            }
            sstore(1, 1)
        }
        
        _;

        assembly {
            sstore(1, 0)
        }
    }

    function doSomething() external nonReentrant {
        
    }
}