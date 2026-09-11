# builtin.csv — builtin.csv

Module grouping comes from the qualified inventory; it is not a package artifact, compiled .ni or capability grant.

```text
Identity: module:builtin.csv (MODULE_IDENTITY)
Edition: 1
Target: x86_64-systemv-elf-linux
Availability: INTRINSIC_NAMESPACE_NOT_AN_IMPORTABLE_MODULE
```

## Syntax or signature

```text
Intrinsic namespace: builtin.csv. Use the exact receiver-qualified or operator syntax on each member page; no selective import is declared for this namespace.
```

## Stability and availability

Module grouping comes from the qualified inventory; it is not a package artifact, compiled .ni or capability grant.

## Canonical import policy

Intrinsic namespace: builtin.csv. Use the exact receiver-qualified or operator syntax on each member page; no selective import is declared for this namespace. Importing never grants capabilities. std.core and std.console exports retain their canonical core/prelude reference owners.

## Packages and compiled interfaces

The stdlib registry supplies visibility metadata. G180 package manifests and lockfiles describe content-addressed offline packages; an intrinsic namespace is not a fictitious shipped package. See docs/reference/packages/PACKAGE-MANIFEST-SPEC.md and LOCKFILE-SPEC.md. Serialized .ni declarations retain their original SymbolIds; intrinsic entries do not acquire fabricated IDs.

## Executed examples

### codec:csv-nullable-True; expected 23

```nebo
import "std.fs" { Path; File; }.fs;
start(){Schema.new([Tuple.of("a",Int,false),Tuple.of("b",Int,true)]).s;Path.parse("input.csv").p;Csv.read(p,s).t;Path.parse("output.csv").q;Csv.write(t,q,s).console();23.return;}
```

Oracle: {"capabilities": {"console": "RETAINED_DOCUMENT", "filesystem": "EXPLICIT_SCRATCH_EFFECT_ORACLE", "network": "DENIED_BY_SECCOMP"}, "console_text_utf8": "2", "expected_files": {"output.csv": {"bytes_hex": "31372c0a32392c37310a"}}, "filesystem_effects": {"output.csv": "a5aa5c99d9f6021a4408411f2780fc625ad75a11c89ba5cf9f42333d6b46321a"}, "independent_builds": 2, "inputs": {"input.csv": {"bytes_hex": "31372c0a32392c37310a"}}, "kinds": \[4\], "process_exit": 23, "runtime_determinism": "BYTE_IDENTICAL", "runtime_sha256": "ada65271c31b0bc29d43a86977c740d413f0cae3cb9363a295e8b2642318c565", "text": {"bytes_hex": "32"}}

## Rejected examples

### codec:json-negative-wrong-type; expected NEBO_TYPE_MISMATCH

```nebo
start(){Json.parse(17).j;23.return;}
```

Oracle: {"artifact_publication": "REJECTED", "compiler_exit": 1, "diagnostic": "NEBO_TYPE_MISMATCH"}

## Related entries

[Index](index.md)

- [symbol-6581898a3bb42d6ec25612f2](symbol-6581898a3bb42d6ec25612f2.md)

- [symbol-350c627ed952ca48a01be3a5](symbol-350c627ed952ca48a01be3a5.md)

- [symbol-7b9b622ffd53f875382766f3](symbol-7b9b622ffd53f875382766f3.md)

## Provenance

- sdk/interfaces/prelude/stdlib-registry.json — SHA-256 a70407bf8b12d694da501b3a9b515c6a7760c03eeb72ab6b6580e79db731c922

- compiler/sdk/prelude.py — SHA-256 edcc9b51c6e6683d3d208a033c3c9f3bda4d70b0ca63d38b9bd362a31cdd1ad3

- tests/rf204/G170/harness.py — SHA-256 6a31e65687ed1199e30e8fc2220bc41e5e5d94429d5bc9800018e338d4fa85b0
