// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract TransientLock {

    // nonReentrant modifier realizaton using transient storage
    modifier nonReentrant() {
        assembly {
            if tload(1) {
                revert(0, 0)
            }
            tstore(1, 1)
        }
        _;

        assembly {
            tstore(1, 0)
        }
    }

    function doSomething() external nonReentrant {

    }
}