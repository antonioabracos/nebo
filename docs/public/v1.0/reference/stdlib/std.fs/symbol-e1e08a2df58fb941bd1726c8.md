# std.fs — Path.isAbsolute

Reports lexical absoluteness; absolute I/O still requires authority and is rejected by the private-directory profile.

```text
Identity: qualified:Path.isAbsolute (QUALIFIED_INTRINSIC_OR_REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: STABLE_1_0
```

## Syntax or signature

```text
Path.isAbsolute() -> Bool
```

## Bounded behavior

Reports lexical absoluteness; absolute I/O still requires authority and is rejected by the private-directory profile. Actual nominal immutable Path, canonical native normalize/join/isAbsolute/fileName owners; 4096-byte paths, 64 components, 255-byte components. File.readText/writeText consume typed Path and Text, explicit utf8 and truncate/append/atomic policies, at most 4096 bytes. Native File capability is restricted to the execution directory through openat2 beneath/no-symlink resolution. Every file and root descriptor closes; private filesystem byte effects and 512 repeated reads are independent observations. This is the material convenience profile, not a claim for arbitrary live handle or directory APIs. Caller-owned beneath directory; no symlinks; UTF-8; 4096-byte paths, 64 components, 255-byte component; atomic write

## Lifecycle, safety and determinism

Actual nominal immutable Path, canonical native normalize/join/isAbsolute/fileName owners; 4096-byte paths, 64 components, 255-byte components. File.readText/writeText consume typed Path and Text, explicit utf8 and truncate/append/atomic policies, at most 4096 bytes. Native File capability is restricted to the execution directory through openat2 beneath/no-symlink resolution. Every file and root descriptor closes; private filesystem byte effects and 512 repeated reads are independent observations. This is the material convenience profile, not a claim for arbitrary live handle or directory APIs. Caller-owned beneath directory; no symlinks; UTF-8; 4096-byte paths, 64 components, 255-byte component; atomic write. Failures retain previous private files and do not grant network or device access. Cooperative execution is not proof of OS-thread race freedom.

## Availability

STABLE_1_0. This individual member retains its owning profile maturity. Only x86_64-systemv-elf-linux is observed.

## Executed examples

### filesystem:path-absolute-4; expected 23

```nebo
import "std.fs" { Path; File; }.fs;
start(){Path.parse("/").isAbsolute().console();23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "true", "filesystem_effects": {}, "independent_builds": 2, "kinds": \[5\], "process_exit": 23, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "26e99610443e30ab87a629aa5de2392ce6d0117574455307c7c97e44b2fcac90", "text": {"bytes_hex": "74727565"}}

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

- sdk/contracts/stdlib/STDLIB-PROFILE-BOUNDARIES.tsv — SHA-256 f75432d694f4cdd8f47bc28f34f8d031ba92fdf5147cd157161356c9832036e3

- compiler/semantic/system/filesystem_source_vertical.inc — SHA-256 9bcaac38c0e6f9ee6e24263b8d53dc84492ddeddb9d1bf8e537b4ebab402f3d3

- compiler/driver/cli/linux-x86_64/scalar_program.inc — SHA-256 54bad41b6d43ffc48c264adae8a0a776071c6a3917abaf05520344e11ae6afbe

- tests/rf204/G170/filesystem_test.py — SHA-256 ee5a99cb6e5636d20f7b91f30fb473d7990c088af494a2a95d03951e8ef81062

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0

- tests/rf204/G170/text_test.py — SHA-256 2a6be89787726ec8c3e4acbcb2c728b82e1c9fc7acc8a2680f2d830648448f52
