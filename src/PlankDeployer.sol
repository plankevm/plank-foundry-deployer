// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PushableStrings, vmFFI} from "./mini-vm.sol";

struct Dependency {
    string name;
    string path;
}

struct BuildOptions {
    bool optimizationsEnabled;
    string optimizations;
    string moduleRoot;
    bool moduleRootSet;
    string moduleName;
    bool moduleNameSet;
    Backend backend;
    Dependency[] dependencies;
}

enum Backend {
    Debug,
    Release,
    Sonatina
}

using BuildOptionsLib for BuildOptions global;

library BuildOptionsLib {
    function disableOptimizations(BuildOptions memory self) internal pure returns (BuildOptions memory) {
        self.optimizationsEnabled = false;
        self.optimizations = "";
        return self;
    }

    function withOptimizations(BuildOptions memory self, string memory optimizations)
        internal
        pure
        returns (BuildOptions memory)
    {
        self.optimizationsEnabled = true;
        self.optimizations = optimizations;
        return self;
    }

    function withBackend(BuildOptions memory self, Backend backend) internal pure returns (BuildOptions memory) {
        self.backend = backend;
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
        opt.optimizationsEnabled = true;
        opt.optimizations = "csud";
        opt.moduleRootSet = false;
        opt.moduleNameSet = false;
        opt.backend = Backend.Debug;
        opt.dependencies = new Dependency[](0);
    }

    function plankBuildFFI(string memory root, BuildOptions memory opt) internal returns (bytes memory) {
        string[] memory bin = new string[](1);
        bin[0] = "plank";
        return plankBuildFFI(bin, root, opt);
    }

    function plankBuildFFI(string[] memory plankBin, string memory root, BuildOptions memory opt)
        internal
        returns (bytes memory)
    {
        PushableStrings memory args = PushableStrings(plankBin.length, plankBin);

        args.push("build");
        args.push(root);

        if (opt.optimizationsEnabled) {
            args.push("-O");
            args.push(opt.optimizations);
        }

        if (opt.moduleRootSet) {
            args.push("--module-root");
            args.push(opt.moduleRoot);
        }
        if (opt.moduleNameSet) {
            args.push("--module-name");
            args.push(opt.moduleName);
        }
        for (uint256 i = 0; i < opt.dependencies.length; i++) {
            args.push("--dep");
            args.push(string.concat(opt.dependencies[i].name, "=", opt.dependencies[i].path));
        }

        return vmFFI(args.intoArray());
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

