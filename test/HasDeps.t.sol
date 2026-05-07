// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PlankDeployer, BuildOptions} from "src/PlankDeployer.sol";

/// @author philogy <https://github.com/philogy>
contract HasDepsTest is PlankDeployer {
    function test_withDep() public {
        BuildOptions memory options = initBuildOptions().dependency("le_proj", "test/le-proj");
        address proj = plankDeployFFI("test/has-deps/its_a_me.plk", options);

        (bool succ, bytes memory data) = proj.call("");
        require(succ, "call failed");
        require(data.length == 0x20, "unexpected data length");
        uint256 value = abi.decode(data, (uint256));
        require(value == 420 ** 2, "incorrect return value");
    }
}
