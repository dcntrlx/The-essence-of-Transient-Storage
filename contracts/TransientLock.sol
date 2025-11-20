// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract TransientLock {

    // nonReentrant modifier realizaton using transient storage
    modifier nonReentrant() {
        assembly {
            if tload(1) {  // 100 gas
                revert(0, 0)
            }
            tstore(1, 1)  // 100 gas
        }
        _;

        assembly {
            tstore(1, 0)  // 100 gas
        }
    }

    function doSomething() external nonReentrant {
        // To make proper measurements we have to add some out call. Otherwise solc will skip sstore(1,1) omitting nonReentrant mechanism
        (bool success, ) = msg.sender.call("");
        require(success);
    }
}