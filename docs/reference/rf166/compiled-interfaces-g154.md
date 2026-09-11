# Compiled interfaces (`.ni`)

Nebo compiled interfaces are bounded, deterministic data artifacts. They carry
public source semantics and target ABI identity without loading code or running
module initialization.

## Commands

Emit an interface from one compiler-admitted module graph:

```text
neboc emit-interface module.no --unit consumer.no --unit support.no -o module.ni
```

An interface for a public constant can replace its provider source:

```text
neboc module-check consumer.no --unit module.ni --unit support.no
neboc build consumer.no --unit module.ni --unit support.no -o consumer.elf
```

The current module profile contains exactly three units, at most two imports
and two entry references, and public Int constants in `0..255`. A compiled
provider contains one pure public constant and no imports or entry body. Two
providers can both be interfaces; their original `.no` files are unnecessary.
The consumer uses the same SymbolId resolution, visibility, lowering and code
generation as a source provider. Explicit selective reexports resolve to the
original declaration, including through named import capsules.

Inspect the native-validated artifact in stable text or JSON form:

```text
neboc interface inspect module.ni
neboc interface inspect module.ni --json
```

Classify compatibility:

```text
neboc api-diff old.ni new.ni
```

`api-diff` returns zero for identical, source-compatible and recompile-only
changes. It returns one for a breaking change or a rejected interface.

## V1 layout

The 64-byte header records magic, schema version, header size, Edition, target
digest, `ModuleId`, API fingerprint, ABI fingerprint, section count, total size
and one global digest. Each 32-byte directory entry records kind, flags,
bounded offset/length and payload digest. V1 emits canonical export records and
semantic metadata records, each 64 bytes and ordered by `SymbolId`.

A material public constant adds optional section kind 4, keeping format and
Edition 1. Its 80-byte payload contains `NEBOMDC1`, the original SymbolId,
the Int value, logical-name length, 32 padded name bytes and two reserved zero
qwords. The native decoder authenticates the ordinary interface, then checks
the target, module identity, type, layout, visibility, effects and value digest
before publishing the existing pointerless ModuleRecord. It accepts at most
4 KiB for this bounded module transport and uses an aligned private copy.
Metadata-only older interfaces remain inspectable; compilation cannot recover
a value from their digest and rejects them with `NEBO-RF166-G154-007`.

The reader accepts at most 16 MiB, 64 sections and 1,024 records of each known
kind. It rejects partial headers, integer overflow, ranges inside the directory,
overlap, duplicate kinds, invalid flags or records, digest mismatches and
unknown required sections before writing caller-visible state. Unknown optional
sections remain part of the global digest and are reported as skipped.

## Identity and cache

The API fingerprint covers public names, kinds, types, generics, constants,
effects, capabilities, ownership and dependency API identities. Documentation
payload and target layout do not change that source-semantic projection. The
ABI fingerprint is target-specific and covers target, kind/type, layout and
dependency ABI identity. The reader recomputes both projections.

Private and internal declarations are filtered before serialization. A module
with no public declaration therefore emits a valid authenticated empty public
surface, and changing a private dependency value cannot alter its consumer's
API or ABI fingerprint.

The optional local cache key includes `ModuleId`, compiler identity, Edition,
target, source revision set, dependency set and prelude identity. Cache entries
have their own checksum and reference the authenticated interface digest. A key
change is a stale miss; corruption is a hard rejection. No network, package
download, user code execution or filename-specific fallback participates.
