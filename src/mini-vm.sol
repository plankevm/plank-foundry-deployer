// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

address constant VM_ADDR = address(uint160(uint256(keccak256("hevm cheat code"))));

function vmEtch(address to, bytes memory code) {
    (bool success,) = VM_ADDR.call(abi.encodeWithSignature("etch(address,bytes)", to, code));
    if (success) return;
    assembly ("memory-safe") {
        let freeMemoryPointer := mload(0x40)
        returndatacopy(freeMemoryPointer, 0, returndatasize())
        revert(freeMemoryPointer, returndatasize())
    }
}

// forge-lint: disable-next-item(mixed-case-function)
function vmFFI(string[] memory args) returns (bytes memory res) {
    (bool success,) = VM_ADDR.call(abi.encodeWithSignature("ffi(string[])", args));
    if (!success) {
        assembly ("memory-safe") {
            let freeMemoryPointer := mload(0x40)
            returndatacopy(freeMemoryPointer, 0, returndatasize())
            revert(freeMemoryPointer, returndatasize())
        }
    }

    assembly ("memory-safe") {
        res := mload(0x40)
        returndatacopy(res, 0x20, sub(returndatasize(), 0x20))
        mstore(0x40, add(res, sub(returndatasize(), 0x20)))
    }
}

struct PushableStrings {
    uint256 length;
    string[] inner;
}

using PushableStringsLib for PushableStrings global;

library PushableStringsLib {
    function push(PushableStrings memory self, string memory value) internal pure returns (PushableStrings memory) {
        if (self.length >= self.inner.length) {
            uint256 newCapacity = self.length < 4 ? 8 : self.length * 2;
            string[] memory newBacking = new string[](newCapacity);
            for (uint256 i = 0; i < self.inner.length; i++) {
                newBacking[i] = self.inner[i];
            }
            self.inner = newBacking;
        }
        self.inner[self.length++] = value;
        return self;
    }

    function intoArray(PushableStrings memory self) internal pure returns (string[] memory inner) {
        inner = self.inner;
        uint256 len = self.length;
        assembly ("memory-safe") {
            mstore(inner, len)
        }
        require(inner.length == self.length);
    }
}

