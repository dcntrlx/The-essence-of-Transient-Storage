// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract StorageLock {
    modifier nonReentrant() {
        // Using slot 1 as reentrancy flag. Only appropriate for comparison to TransientStorage. Not recommended in real projects
        assembly {
            if sload(1) {  // 2100 gas
                revert(0, 0)  
            }
            sstore(1, 1)  // 20000 gas
        }
        
        _;

        assembly {
            sstore(1, 0)  // 5000 - 4900 = 100 gas
        }
    }

    function doSomething() external nonReentrant {
        // To make proper measurements we have to add some out call. Otherwise solc will skip sstore(1,1) omitting nonReentrant mechanism
        (bool success, ) = msg.sender.call("");
        require(success);
    }
}