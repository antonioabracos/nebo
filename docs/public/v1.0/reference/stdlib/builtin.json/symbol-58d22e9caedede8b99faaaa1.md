# builtin.json — canonicalKeys

Requests canonical key serialization; it is not a global mutable value.

```text
Identity: material:canonicalKeys (QUALIFIED_INTRINSIC_OR_REGISTRY_ID)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: MATERIAL_BOUNDED_NOT_PROMOTED
```

## Syntax or signature

```text
canonicalKeys contextual option
```

## Bounded behavior

Requests canonical key serialization; it is not a global mutable value. Canonical key order; duplicate/trailing/malformed/depth rejection; 4096-byte input; private atomic sink

## Lifecycle, safety and determinism

Canonical key order; duplicate/trailing/malformed/depth rejection; 4096-byte input; private atomic sink. Failures retain previous private files and do not grant network or device access. Cooperative execution is not proof of OS-thread race freedom.

## Availability

MATERIAL_BOUNDED_NOT_PROMOTED. This individual member retains its owning profile maturity. Only x86_64-systemv-elf-linux is observed.

## Executed examples

### codec:json-file-17; expected 23

```nebo
import "std.fs" { Path; File; }.fs;
start(){Path.parse("input.json").p;File.readText(p,utf8,4096).s;Json.parse(s).j;j.toJson(canonicalKeys).out;Path.parse("output.json").q;File.writeText(q,out,utf8,atomic);File.readText(q,utf8,4096).actual;if(actual.byteLength()>0){actual.console();}23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "{\"alpha\":17,\"beta\":\[true,null,\"ação\"\]}", "expected_files": {"output.json": {"bytes_hex": "7b22616c706861223a31372c2262657461223a5b747275652c6e756c6c2c2261c3a7c3a36f225d7d"}}, "filesystem_effects": {"output.json": "71b909ac703513027cfa363978243260355d0d32fbc2fed97761c375f8b494d2"}, "independent_builds": 2, "inputs": {"input.json": {"bytes_hex": "7b0a202022616c706861223a2031372c0a20202262657461223a205b0a20202020747275652c0a202020206e756c6c2c0a202020202261c3a7c3a36f220a20205d0a7d"}}, "kinds": \[2\], "process_exit": 23, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "4f99301da5455f9eed89f7d4ad2ca6acdd98caa597ba3602f664eb9741b4081d", "text": {"bytes_hex": "7b22616c706861223a31372c2262657461223a5b747275652c6e756c6c2c2261c3a7c3a36f225d7d"}}

## Rejected examples

### codec:json-negative-wrong-type; expected NEBO_TYPE_MISMATCH

```nebo
start(){Json.parse(17).j;23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Related entries

[Index](index.md)

- [symbol-2815f1d8bd38243c5f90756b](symbol-2815f1d8bd38243c5f90756b.md)

## Provenance

- sdk/contracts/stdlib/STDLIB-PROFILE-BOUNDARIES.tsv — SHA-256 f75432d694f4cdd8f47bc28f34f8d031ba92fdf5147cd157161356c9832036e3

- runtime/serialization/json.asm — SHA-256 551f7c010f675c477f5ef6ba06feb00130a1266c374151fd718f4f432e2ef2c8

- compiler/driver/cli/linux-x86_64/scalar_program.inc — SHA-256 54bad41b6d43ffc48c264adae8a0a776071c6a3917abaf05520344e11ae6afbe

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
