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
    }
}
