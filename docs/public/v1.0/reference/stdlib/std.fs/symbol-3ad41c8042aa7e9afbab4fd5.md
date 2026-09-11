# std.fs — Path

Actual nominal immutable Path, canonical native normalize/join/isAbsolute/fileName owners; 4096-byte paths, 64 components, 255-byte components. File.readText/writeText consume typed Path and Text, explicit utf8 and truncate/append/atomic policies, at most 4096 bytes. Native File capability is restricted to the execution directory through openat2 beneath/no-symlink resolution. Every file and root descriptor closes; private filesystem byte effects and 512 repeated reads are independent observations. This is the material convenience profile, not a claim for arbitrary live handle or directory APIs. Caller-owned beneath directory; no symlinks; UTF-8; 4096-byte paths, 64 components, 255-byte component; atomic write

```text
Identity: claim:906cf79438abd7c0f42d0f42 (QUALIFIED_INTRINSIC_OR_REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
Path
Actual nominal immutable Path, canonical native normalize/join/isAbsolute/fileName owners; 4096-byte paths, 64 components, 255-byte components. File.readText/writeText consume typed Path and Text, explicit utf8 and truncate/append/atomic policies, at most 4096 bytes. Native File capability is restricted to the execution directory through openat2 beneath/no-symlink resolution. Every file and root descriptor closes; private filesystem byte effects and 512 repeated reads are independent observations. This is the material convenience profile, not a claim for arbitrary live handle or directory APIs. Caller-owned beneath directory; no symlinks; UTF-8; 4096-byte paths, 64 components, 255-byte component; atomic write
```

## Ownership and complexity

Exact typed owner contract; no copy/borrow/clone capability inferred from spelling Actual nominal immutable Path, canonical native normalize/join/isAbsolute/fileName owners; 4096-byte paths, 64 components, 255-byte components. File.readText/writeText consume typed Path and Text, explicit utf8 and truncate/append/atomic policies, at most 4096 bytes. Native File capability is restricted to the execution directory through openat2 beneath/no-symlink resolution. Every file and root descriptor closes; private filesystem byte effects and 512 repeated reads are independent observations. This is the material convenience profile, not a claim for arbitrary live handle or directory APIs. Caller-owned beneath directory; no symlinks; UTF-8; 4096-byte paths, 64 components, 255-byte component; atomic write

## Effects, capabilities and sandbox

filesystem; PRIVATE_DIRECTORY. Import grants capability: NO.

## Availability and errors

Edition 1; x86_64-systemv-elf-linux; BOUNDED_PUBLIC_EXECUTED_WITHIN_LIMITS. Actual nominal immutable Path, canonical native normalize/join/isAbsolute/fileName owners; 4096-byte paths, 64 components, 255-byte components. File.readText/writeText consume typed Path and Text, explicit utf8 and truncate/append/atomic policies, at most 4096 bytes. Native File capability is restricted to the execution directory through openat2 beneath/no-symlink resolution. Every file and root descriptor closes; private filesystem byte effects and 512 repeated reads are independent observations. This is the material convenience profile, not a claim for arbitrary live handle or directory APIs. Caller-owned beneath directory; no symlinks; UTF-8; 4096-byte paths, 64 components, 255-byte component; atomic write Use the declared operand and receiver domain; source rejection publishes no executable.

## Identity and aliases

STDLIB_DECLARATION_TO_TYPED_NATIVE_FILESYSTEM. Identity kind: QUALIFIED_INTRINSIC_OR_REGISTRY_ID. SymbolId: NOT_SERIALIZED. Alias entries describe the same qualified operation; they do not create another runtime API.

## Executed examples

### filesystem:path-name-2; expected 23

```nebo
import "std.fs" { Path; File; }.fs;
start(){Path.parse("ação/Ω.dat").fileName().console();23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "Ω.dat", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[2\], "process_exit": 23, "publications": 1, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "2c71bccf66993e52532635f622e112f19ffbbd6f2638b01ec7fed1b030231b77", "text": {"bytes_hex": "cea92e646174"}}

## Rejected examples

### filesystem:path-status; expected NEBO_ENTRYPOINT_INVALID_SIGNATURE

```nebo
import "std.fs" { Path; File; }.fs;
start(){Path.parse("a").return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_ENTRYPOINT_INVALID_SIGNATURE"}

## Related entries

[Index](index.md)

- [symbol-36fc09bc3f5b25f52e204668](symbol-36fc09bc3f5b25f52e204668.md)

## Provenance

- sdk/contracts/stdlib/STDLIB-STABLE-CATALOG.tsv — SHA-256 a66eec0cbb7f0a99f20ae489208f1ba1106cd2c327e475daf406d615e3e55bab

- compiler/semantic/system/filesystem_source_vertical.inc — SHA-256 9bcaac38c0e6f9ee6e24263b8d53dc84492ddeddb9d1bf8e537b4ebab402f3d3

- compiler/driver/cli/linux-x86_64/scalar_program.inc — SHA-256 54bad41b6d43ffc48c264adae8a0a776071c6a3917abaf05520344e11ae6afbe

- compiler/codegen/functions/x86_64/function_codegen.asm — SHA-256 944358cec673b2132c51b5c4b5842edaf4cf9ce157b23d83892449fbb12487f7

- runtime/core/runtime_core.asm — SHA-256 9786591602649f222e73dc91ea2449fba1c98d2e504ae779208caf7373e06797

- tests/rf204/G170/filesystem_test.py — SHA-256 ee5a99cb6e5636d20f7b91f30fb473d7990c088af494a2a95d03951e8ef81062

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0

- tests/rf204/G170/text_test.py — SHA-256 2a6be89787726ec8c3e4acbcb2c728b82e1c9fc7acc8a2680f2d830648448f52
