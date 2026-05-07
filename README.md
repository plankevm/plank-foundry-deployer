# Plank Foundry Deployer

Requires `plank` to be installed. [See here](https://docs.plankevm.org/getting-started#installation) for installation instructions.


## Example Use

```solidity
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
```

## More Intricate Project Configurations

```solidity
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
```

The `BuildOptions` has the following methods you can chain in a builder-style
pattern:
- `self.disableOptimizations()`: removes the default applied optimization flags
- `self.withModuleRoot(path: string)`: sets the path of the root module (equivalent to
  the `--module-root` flag)
- `self.withModuleName(name: string)`: sets the name of the root module (equivalent to
  the `--module-name` flag)
- `self.dependency(name: string, path: string)`: configures a dependency
  (equivalent to `--dep <name>=<path>`)
