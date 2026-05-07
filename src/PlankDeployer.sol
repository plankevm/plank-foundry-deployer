// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {vmFFI} from "./mini-vm.sol";

struct Dependency {
    string name;
    string path;
}

struct BuildOptions {
    bool optimize;
    string moduleRoot;
    bool moduleRootSet;
    string moduleName;
    bool moduleNameSet;
    Dependency[] dependencies;
}

using BuildOptionsLib for BuildOptions global;

library BuildOptionsLib {
    function disableOptimizations(BuildOptions memory self) internal pure returns (BuildOptions memory) {
        self.optimize = false;
        return self;
    }

    function withModuleRoot(BuildOptions memory self, string memory moduleRoot)
        internal
        pure
        returns (BuildOptions memory)
    {
        self.moduleRoot = moduleRoot;
        self.moduleRootSet = true;
        return self;
    }

    function withModuleName(BuildOptions memory self, string memory moduleName)
        internal
        pure
        returns (BuildOptions memory)
    {
        self.moduleName = moduleName;
        self.moduleNameSet = true;
        return self;
    }

    function dependency(BuildOptions memory self, string memory name, string memory path)
        internal
        pure
        returns (BuildOptions memory)
    {
        Dependency[] memory dependencies = new Dependency[](self.dependencies.length + 1);
        // O(n) but oh well, it's a lib.
        for (uint256 i = 0; i < self.dependencies.length; i++) {
            dependencies[i] = self.dependencies[i];
        }
        dependencies[self.dependencies.length] = Dependency({name: name, path: path});
        self.dependencies = dependencies;
        return self;
    }
}

// forge-lint: disable-start(mixed-case-function)
abstract contract PlankDeployer {
    function plankBuildFFI(string memory root) internal returns (bytes memory) {
        string[] memory args = new string[](5);
        args[0] = "plank";
        args[1] = "build";
        args[2] = root;
        args[3] = "-O";
        args[4] = "csud";

        return vmFFI(args);
    }

    function initBuildOptions() internal pure returns (BuildOptions memory opt) {
        opt.optimize = true;
        opt.moduleRootSet = false;
        opt.moduleNameSet = false;
        opt.dependencies = new Dependency[](0);
    }

    function plankBuildFFI(string memory root, BuildOptions memory opt) internal returns (bytes memory) {
        uint256 totalArgs = 3;
        if (opt.optimize) totalArgs += 2;
        if (opt.moduleRootSet) totalArgs += 2;
        if (opt.moduleNameSet) totalArgs += 2;
        totalArgs += opt.dependencies.length * 2;
        string[] memory args = new string[](totalArgs);

        uint256 argIndex = 0;
        args[argIndex++] = "plank";
        args[argIndex++] = "build";
        args[argIndex++] = root;
        if (opt.optimize) {
            args[argIndex++] = "-O";
            args[argIndex++] = "csud";
        }

        if (opt.moduleRootSet) {
            args[argIndex++] = "--module-root";
            args[argIndex++] = opt.moduleRoot;
        }
        if (opt.moduleNameSet) {
            args[argIndex++] = "--module-name";
            args[argIndex++] = opt.moduleName;
        }
        for (uint256 i = 0; i < opt.dependencies.length; i++) {
            args[argIndex++] = "--dep";
            args[argIndex++] = string.concat(opt.dependencies[i].name, "=", opt.dependencies[i].path);
        }

        return vmFFI(args);
    }

    function plankDeployFFI(string memory root, BuildOptions memory opt) internal returns (address) {
        return _deploy(plankBuildFFI(root, opt), 0);
    }

    function plankDeployFFI(string memory root, BuildOptions memory opt, uint256 value) internal returns (address) {
        return _deploy(plankBuildFFI(root, opt), value);
    }

    function plankDeployFFI(string memory root) internal returns (address) {
        return _deploy(plankBuildFFI(root), 0);
    }

    function plankDeployFFI(string memory root, uint256 value) internal returns (address) {
        return _deploy(plankBuildFFI(root), value);
    }

    function _deploy(bytes memory initcode, uint256 value) internal returns (address addr) {
        assembly ("memory-safe") {
            addr := create(value, add(initcode, 0x20), mload(initcode))
        }
        if (addr != address(0)) return addr;

        assembly ("memory-safe") {
            let fmp := mload(0x40)
            returndatacopy(fmp, 0, returndatasize())
            revert(fmp, returndatasize())
        }
    }
}

// forge-lint: disable-end(mixed-case-function)

