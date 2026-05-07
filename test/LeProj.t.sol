// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PlankDeployer, BuildOptions} from "src/PlankDeployer.sol";

/// @author philogy <https://github.com/philogy>
contract LeProjTest is PlankDeployer {
    function test_moduleRootAndName() public {
        BuildOptions memory options = initBuildOptions().withModuleRoot("test/le-proj").withModuleName("le_proj");
        address proj = plankDeployFFI("test/le-proj/main.plk", options);

        (bool succ, bytes memory data) = proj.call("");
        require(succ, "call failed");
        require(data.length == 0x20, "unexpected data length");
        uint256 value = abi.decode(data, (uint256));
        require(value == 420, "incorrect return value");
    }

    function test_moduleNameOnly() public {
        BuildOptions memory options = initBuildOptions().withModuleName("le_proj");
        address proj = plankDeployFFI("test/le-proj/main.plk", options);

        (bool succ, bytes memory data) = proj.call("");
        require(succ, "call failed");
        require(data.length == 0x20, "unexpected data length");
        uint256 value = abi.decode(data, (uint256));
        require(value == 420, "incorrect return value");
    }
}
