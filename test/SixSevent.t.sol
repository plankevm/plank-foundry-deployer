// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PlankDeployer} from "src/PlankDeployer.sol";

/// @author philogy <https://github.com/philogy>
contract SixSevenTest is PlankDeployer {
    address sixSeven;

    function setUp() public {
        sixSeven = plankDeployFFI("test/six_seven.plk");
    }

    function test_67() public {
        (bool succ, bytes memory data) = sixSeven.call("");
        require(succ, "call failed");
        require(data.length == 0x20, "unexpected data length");
        uint256 value = abi.decode(data, (uint256));
        require(value == 67, "incorrect return value");
    }
}
