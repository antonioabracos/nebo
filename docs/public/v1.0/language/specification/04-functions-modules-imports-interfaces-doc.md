# Functions, modules, imports, interfaces and doc blocks

Edition 1.0 · current G182 normative bounded profile.

Receiver-first functions, nested calls, declarations and supported scalar
generics retain semantic scope, argument types and source order. Exact overload
ranking is independent of declaration order. Named/default arguments have the
current pure scalar profile; arbitrary effectful named arguments are not promised.

Logical module/export identity is distinct from an absolute filename. Simple
and selective imports require aliases. Capsules and reexports preserve reachability
and visibility; neither import nor prelude grants capabilities. Advanced exports
such as File/Path require their explicit std.fs import. The Edition 1 prelude
injects exactly 11 exports from std.core and std.console; disabling it requires
explicit imports for those exports and does not load the entire Standard Library.

The material binary .ni source profile supplies public Int constants, preserving
identity and value when provider source is absent. Metadata-only files and the
separate JSON SDK prelude manifest do not supply arbitrary executable exports.
Interface encoding/ABI mechanics remain in the implementation-defined reference.

Native `doc {}` AST and DocRecord data attach to a declaration and its actual
SymbolId. Embedded examples/laws compile and execute. The current test-docs
profile requires labels `[public-|private-|secret-][law-]exit-N`, N=0..255;
a name alone is not an expected-value oracle. API registry identities are not
silently converted to serialized SymbolIds.


## N1-call-order

Evaluate receiver then positional arguments once; native hidden-result storage preserves effects and caller ownership.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S01-F002`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-overload-ranking

Exact supported receiver/argument types select deterministically regardless of declaration order. Named/default calls retain their bounded pure profile.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S02-F006`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-import-no-grant

Import and prelude resolution grant no capabilities and execute no user initializer.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S04-F004`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-module-init-order

The native module graph orders dependencies before consumers and lists each module once, independently of unit argument order. The admitted pure source/interface profile has zero runtime user initializers. Native initializer/rollback tests supplement this boundary without granting effectful imported startup.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S06-F001`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-module-init-failure

Cycles and effectful imported startup reject before publication. Native rollback reverses successfully initialized resources in the internal initialization contract; interface loading executes no user code.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S06-F002`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-pure-constants

Pure source/interface constants preserve values and typed symbol identity. Interface loading is not execution.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S06-F003`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-imports-and-capsules

Simple and selective imports have explicit aliases; named/anonymous capsules and reexports preserve logical module/export identity. Resolution must not depend on a fixture filename. Imported pure interfaces execute no initializer.

Authority: `docs/reference/language/GRAMMAR-AND-PROFILE-NOTES.md`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-material-interface

The admitted source-facing binary .ni profile supplies public Int constants with original symbol/type identity; a metadata-only interface cannot manufacture an executable value. Provider-source and material-interface consumers must agree.

Authority: `docs/reference/interfaces/NI-SCHEMA-AND-FINGERPRINT-FREEZE.md`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-doc-attachment

A doc block attaches to a material declaration through native AST/DocRecord identity. Its examples and laws are actual Nebo programs. Textual registry identities and serialized SymbolIds must not be conflated.

Authority: `docs/reference/interfaces/NI-SCHEMA-AND-FINGERPRINT-FREEZE.md`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

The [rule registry](NORMATIVE-RULE-REGISTRY.tsv) also lists this chapter’s 15 lexical, grammar or declaration obligations. Their linked authority rows retain exact source forms, bounds and negative associations.
