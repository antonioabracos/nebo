# Public 1.0.1 array indexing compatibility

Edition 1.0 accepts `values[index]` for a bound immutable `Array<Int,4>` and a
single nonnegative integer literal. All four elements are `Int`. An untyped
four-element literal retains its public 1.0.1 meaning; an explicit
`Array<Int,4>` literal uses the same owner. Indices 0 through 3 are valid.
Decimal, hexadecimal, binary, octal and underscore-separated spellings follow
the native integer lexer. Whitespace and line comments remain trivia.

This is derived Registry entry `NSR-RES-015-COMPAT-1.0.1`, explicitly related to
historical `NSR-RES-015`. The general entry retains its numeric identity and
RESERVED class. Other receiver types, mutable arrays, other sizes, dynamic
indices, effectful receiver/index expressions, slicing `a:b`, and user-defined
index operator protocols are not activated by this decision.

Use `values.at(index)` in new code. Existing valid source needs no flag or
separate compatibility mode. Deprecation is documentary: there is no default
warning, including under warnings-as-errors. A migration must authenticate the
typed receiver and literal before replacing the suffix with `.at(index)`;
no untyped global replacement or automatic quick fix is enabled.

Both spellings share Array semantic validation, ordered CALL children, typed
function lowering and native emission. Receiver then index are consumed once.
The admitted operands are a binding and a literal, so neither can have an
effect; allowing effectful expressions to demonstrate an order would extend
the published envelope. The returned Int is copied without allocation, borrow,
retain or lifetime extension. Bounds use the canonical compile-time rejection
policy (the existing public code is `NEBO_TUPLE_INDEX_OUT_OF_RANGE`).

The general statement owner preserves adjacent bindings, function bodies,
Console effects, two arrays, and explicit returns. It consumes the complete
program; the old whole-file array recognizer is not the compatibility engine.
The original public file remains byte-identical and exits 5. The migrated
version also exits 5. The regression runner checks variable names, values and
indices, exact ELF equivalence, first/last indices, unsupported forms, duplicate
bindings and failure atomicity in check, emit-asm and build.

Formatter preserve/ASCII/math profiles preserve source spelling. Reserved
Registry/LSP metadata still describes the *general* entry. Accepted typed
compatibility calls receive no reserved diagnostic. No unconditional indexing
completion, hover promotion or safe quick fix is inferred from `[` alone.

The compatibility window starts at public 1.0.1 and remains open in Edition
1.0. No removal release is scheduled. Removal requires an explicit product
and SemVer review under G146. Native governance schema/ABI numbers are not
product versions and remain unchanged. The machine-readable authority is
[the derived Registry entry](../../specifications/nebo-language/NSR-RES-015-PUBLIC-1.0.1-COMPATIBILITY.json).
