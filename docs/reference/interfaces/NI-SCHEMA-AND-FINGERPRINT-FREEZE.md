# Current interface, fingerprint and public compatibility freeze

`NEBO-INTERFACE-v1` is the native binary format with magic `NEBO.NI\0`,
version 1, Edition 1, a 64-byte header and 32-byte section entries. The current
reader bounds inputs to 16 MiB, 64 sections and 1,024 records. All offsets,
lengths, section digests, required kinds, text encodings and the root digest
are validated before publication. Optional unknown sections are authenticated
and skipped. The exact constants are in PUBLIC-ABI-FREEZE.tsv.

Kinds 1 and 2 carry 64-byte export and metadata records. Kind 3 carries optional
DocRecord data; kind 4 carries an optional 80-byte material module constant.
The source-facing module profile is a bounded public Int constant with its
original SymbolId, typed layout and pure metadata. A metadata-only V1 file can
be read by tooling but cannot supply an executable value. Reading a schema does
not grant executable support for arbitrary functions, generics or foreign ABI.
The JSON file sdk/interfaces/prelude/std.prelude.ni is explicitly the separate
SDK manifest format, not a binary NEBO.NI file.

Header/API/ABI use the existing native FNV identities, not SHA-256 signatures.
SHA-256 in this freeze authenticates files; it is not a private-key signature.
The export API projection includes symbol, name, kind/visibility, type, receiver,
constant, ownership, effects, capabilities and public dependency fingerprints.
The ABI projection additionally carries target and native layout. Documentation
has its own metadata digest and optional records. Documentation-only changes
preserve API and ABI; public constant/effect changes affect API; layout/target
changes affect ABI. Content authentication includes all accepted optional data.
The native compatibility owner rejects target mismatches and has explicit
identical/source-compatible/recompile-required/breaking classes. An additive
claim requires proof that all previous export records remain identical.

Independent two-root builds require identical .ni, ASM and ELF bytes. Real
consumers run with provider source removed. Current V1 optional-extension
compatibility and native reader/writer roundtrip are exercised, without using
historical compiler binaries or claiming arbitrary old compiler support.

Public identities have explicit scopes. Native/serialized SymbolIds remain
unchanged. Contextual intrinsics and Registry syntax atoms retain the canonical
qualified IDs already authenticated by G170/G173; these are NOT invented .ni
SymbolIds. Duplicate spelling atoms remain separately identified claims and
must not be summed as distinct APIs. API signatures from the Compiler SDK,
source API registries and completion tables retain exact fields. A completion
projection does not establish executable availability. Every public claim is
joined to its current bounded declaration/profile and negative association.
The complete current compiler/runtime/interface owner manifest pins contextual
receiver/argument/result/generic/effect/capability/error behavior that is not
represented as a standalone serialized method signature. The freeze adds no
new API to fill a metadata gap.

Only x86_64-systemv-elf-linux is the executable baseline. System V AMD64 uses
RDI, RSI, RDX, RCX, R8, R9 for the first six integer arguments, RAX for scalar
returns, EAX for internal status, 16-byte call stack alignment and no red zone.
Native codegen's generated function labels and runtime thunk convention are
checked by the existing ABI owner assertions; there is no universal mangling
promise for another target. ABI/runtime versions remain 0; object metadata is
schema 1. LP64, little endian, Int64, Bool 0/1 (one-byte memory layout), pointer+
length slices and native tags/aggregate layouts are pinned to their exact
owners. Host SDK ABI label strings are cache identity labels, not a change to
the native ABI version. No version is bumped by this mission.

Diagnostics freeze public code, severity, phase, schema field types and causal
span interpretation. UTF-8 byte half-open spans are converted to UTF-16 LSP
positions. JSON-lines schema 1 and SARIF 2.1.0 with properties.neboSchema=1 are
checked against the same native error; LSP preserves code/severity/data. Source
errors exit 1; usage/environment errors exit 2; internal diagnostics have the
native 101 contract. Message interpolation can change values, never the code's
meaning. The main catalog contains 182 codes, with six additional v1 schema
registry codes. Other subsystem projections remain pinned in the owner input
manifest; their numeric IDs are not conflated with main-catalog ordinals.

The Operator Registry's 185 rows retain classes, context, arity, precedence,
associativity, aliases, protocols and reserved/rejected states. ASCII '-' and
Unicode '−' are subtraction aliases; '×' must not be invented as scalar '*'.
Edition 1 prelude injects exactly 11 exports, from std.core and std.console.
Disabling prelude requires explicit imports for those exports and grants no
capability. It never implicitly links the whole Standard Library.

Run `python3 scripts/rf204/api-diff.py OLD NEW --json`, or abi-diff.py,
ni-diff.py, diagnostic-diff.py. The shared freeze_diff.py also accepts a kind
argument. TSV rows use stable identity columns; JSON duplicate keys, nonfinite
values, duplicate/empty IDs, ragged TSV, invalid .ni and oversized inputs fail.
Limits: 16 MiB/file, 20,000 TSV rows, JSON depth 64, 300,000 nodes; native codec
child timeout 15 seconds. Symlinks and nonregular input are rejected. Return 0
means byte-identical valid input; 1 means review (including encoding-only
changes); 2 means invalid input. Field additions are reviewable, never silently
approved. Lists remain ordered and JSON true differs from numeric 1. Ordinary
validation compares regenerated projections with the committed baseline and
never rewrites it. Future contract changes require explicit compatibility
review; no release, tag, publication or migration is performed here.
