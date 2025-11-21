// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract TransientContext {
    function executeWithContext(address target, uint256 val) external {
        assembly {
            tstore(0, val)  // Storing val in transient storage to take access to it later in callbac
        }
        (bool success,) = target.call("");  // Calling intermediary
        require(success);
    }

    function callback() external view {
        uint val;
        assembly {
            val := tload(0)  // Getting in callback value from transient storage
        }  // tstorage allowed to get to callback with initial excecution context, without sending it to intermediary
    }
}
