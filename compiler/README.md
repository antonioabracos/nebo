# Compiler implementation state

```txt
Foundation:
FOUNDATION_EXECUTABLE_GREEN

Current front:
MF032

HostServices:
v0

FakeHost capabilities:
MEMORY FILE TEMP PROCESS TIME DIAGNOSTIC EXIT

Linux adapter capabilities:
MEMORY FILE TEMP TIME DIAGNOSTIC EXIT

Linux native process capability:
DEFERRED — explicit UNSUPPORTED_TARGET

Memory foundation:
MemoryRegion v0; Arena v0; checked bump allocation

Collection support:
Slice v0; Buffer v0; TypedArray v0

String interning support:
StringPool v0; FNV-1a 32-bit; typed IDs v0

Functional lexer/parser:
GREEN

Architecture Backend / Assembly writer:
v0 GREEN

C/C++/Rust source:
0
```

The Compiler Core dispatches host operations only through the versioned table
in `compiler/host/contracts/`. Syscalls remain isolated in the Linux adapter.


## MF010 CompilationSession support

```txt
CompilationSession: v0
Limits: DG-009 defaults
Statistics: deterministic counters
Phase model: 15 normative phases
Central cleanup: green
TR02: HOST_SUPPORT_FOUNDATION_GREEN
```


## MF011 SourceFile support

```txt
SourceFile: v0
UTF-8 validator: strict
BOM: forbidden
Logical path: stable relative only
Content hash: FNV-1a 32-bit
Source limit: DG-009 16 MiB
Lexer: not started
```


## MF012 source-location foundation

```txt
LineMap:
v0 GREEN

SourceSpan:
v0 GREEN

Snippet extraction:
v0 GREEN

Columns:
Unicode codepoint, 1-based

Lexer:
NOT_CREATED

DiagnosticEngine:
NOT_CREATED
```


## MF013 diagnostic foundation

```txt
Diagnostic object/store: v0 GREEN
Catalog: 11 entries
Human/no-color renderer: GREEN
JSON: ABSENT
Lexer: NOT_CREATED
```


## MF014 structural lexer

```txt
Token model: v0 GREEN
TokenArray: caller-backed
ASCII identifiers: GREEN
Active/deferred keywords: GREEN
Line comments: GREEN
Longest-match operators: GREEN
Strings/integers: NOT_CREATED
Parser: NOT_CREATED
```


## MF015 complete lexer

```txt
Structural tokens: GREEN
Signed Int literals: GREEN
Text UTF-8 literals: GREEN
Escapes: GREEN
Lexical negative diagnostics: GREEN
Fuzz/determinism: GREEN
Parser: NOT_CREATED
```


## MF016 parser skeleton

```txt
Program/top-level: GREEN
start(): GREEN
Receiver-first functions: GREEN
Parameters: GREEN
Balanced blocks: GREEN
Opaque body token intervals: GREEN
Complex expressions: NOT_CREATED
Semantic resolution: NOT_CREATED
```


## MF017 Pratt expressions

```txt
Primary expressions: GREEN
Unary expressions: GREEN
Binary precedence: GREEN
Receiver-first call suffix: GREEN
Arguments: GREEN
Multiline chains: GREEN
Binding/.return terminal shape: GREEN
Statement semantics: NOT_CREATED
```


## MF018 flow statements

```txt
Expression statements: GREEN
Terminal bindings: GREEN
.return statements: GREEN
if/else: GREEN
else-if: GREEN
Block scopes: GREEN
Deferred controls: DIAGNOSTIC
Recovery/ErrorNode: NOT_CREATED
```


## MF019 parser recovery

```txt
Missing semicolon diagnostic: GREEN
Unexpected token diagnostic: GREEN
ErrorNode: GREEN
Synchronization progress: GREEN
Token/AST/nesting/diagnostic limits: GREEN
Unlimited diagnostics: ABSENT
Semantic ErrorNode validation: NOT_CREATED
```


## MF020 immutable AstStore

```txt
AstNode size: 80 bytes — unchanged
AstStore: GREEN
1-based NodeIds: GREEN
Parent side table: GREEN
Structural validation: GREEN
Immutable hash: GREEN
Canonical AST dump: GREEN
ErrorNode clean gate: GREEN
Parser fuzz: GREEN
HIR/MIR/LIR: ABSENT
Semantic metadata in AstNode: ABSENT
```


## MF021 name resolution

```txt
ScopeTable: GREEN
SymbolTable: GREEN
1-based ScopeIds: GREEN
1-based SymbolIds: GREEN
Function pre-collection: GREEN
Declare-before-use: GREEN
Duplicate/shadow/reserved diagnostics: GREEN
Node symbol/scope side tables: GREEN
Type checking: ABSENT
Complete overload selection: ABSENT
Modules: ABSENT
```


## MF022 fundamental types and operators

```txt
TypeTable: GREEN
Built-ins: Void Bool Int Text Console Pending<Text>
NodeType side table: GREEN
SymbolType side table: GREEN
Checked constants: GREEN
Truthiness: FORBIDDEN
Implicit coercions: ZERO
Text equality: GREEN
Text concatenation with +: FORBIDDEN
Signatures/call graph: NOT_CREATED
```

## MF023 signatures and calls

```txt
FunctionTable: GREEN
1-based FunctionIds: GREEN
Return inference: GREEN
Receiver/name/positional overload resolution: GREEN
Arity diagnostics: GREEN
Positional type diagnostics: GREEN
Void binding diagnostic: GREEN
Call graph: GREEN
Recursion: REJECTED_V0_1
Nested functions: ABSENT
Behavior/effect selection: NOT_CREATED
```

## MF024 semantic domains

- `semantic/behavior`: pure descriptor classification and conflict checks;
- `semantic/effect`: deterministic effect propagation and thread capability;
- `semantic/control`: Bool conditions, short-circuit annotations and branch scopes.


## MF025 semantic database

Validated AST side-table completeness: GREEN

ControlFlowTable: GREEN

ConstantValueTable: GREEN

Deterministic semantic dump: GREEN

ErrorNode advancement gate: GREEN

TR05 exit gate: `SEMANTIC_CORE_GREEN`

## MF026 intrinsic contracts

```txt
IntrinsicTable: GREEN
IntrinsicIds: 1-based deterministic
Text/Int/Bool.console: MATERIALIZED
Text.scan: MATERIALIZED
Console.scan: MATERIALIZED
Color.color descriptor: MATERIALIZED
Runtime contract IDs: VERSIONED_V0_1
Normal-call signature matching: GREEN
Console routing: NOT_CREATED
Runtime objects: NOT_CREATED
```


## MF027 Console routing

```txt
ConsoleRoutingTable: GREEN
ConsoleRouteIds: 1-based source-order deterministic
DEFAULT: GREEN
NAMED independent: GREEN
ANONYMOUS independent: GREEN
SCAN_DEFAULT: GREEN
SCAN_NAMED: GREEN
Canonical route dump: GREEN
Runtime routing heuristic: FORBIDDEN
Negative routing diagnostics: DEFERRED_MF028
Pending/dependency graph: NOT_CREATED
```

## MF028 Console routing diagnostics

```txt
Duplicate Console binding: REJECTED_PRE_ROUTE
Scan without terminal binding: REJECTED_PRE_ROUTE
Named scan receiver: MUST_BE_CONSOLE
Ambiguous chain: REJECTED_PRE_ROUTE
Console terminal: Console only
Scan terminal: Pending<Text> only
Void terminal: FORBIDDEN
Diagnostic mapping: STABLE_CANONICAL_NAMES
Runtime routing heuristic: FORBIDDEN
Pending/dependency graph: NOT_CREATED
```

## MF029 Pending dependency graph

```txt
PendingTable: GREEN_EXPECTED
DependencyGraph: GREEN_EXPECTED
PendingId: 1-based source order
EdgeId: canonical producer/source/consumer order
ContinuationSeedId: deterministic metadata only
Cycle detection: compile-time
Capture sets: explicit and minimal
Orphans: classified, runtime policy deferred
Continuations/cancellation/lowering: ABSENT
```


## MF030 continuations and lowering plan

```txt
ContinuationTable: GREEN
ContinuationId: 1-based and deterministic
Entry identity: nebo_cont_<FunctionId>_<ContinuationId>
Capture analysis: minimal explicit SymbolIds
Cancellation: transitive over explicit edges
Duplicate resolution: controlled internal error
Orphan Pending at exit: controlled diagnostic
Function Lowering Plan: deterministic and target-independent
Logical operation sequence: six operations
Physical registers/stack slots: ABSENT
Assembly emission: ABSENT
TR06: CONSOLE_SCAN_SEMANTICS_GREEN
```

## MF031 target context and data layout

```txt
Target tuple: x86_64-systemv-elf-linux
TargetContext: v0 FROZEN
DataLayout: v0 FROZEN
Pointer / Int / handles: 8 bytes
Bool: 0/1, 1 byte
Slice: pointer + length, 16 bytes
Stack alignment: 16 bytes
Endianness: little
Second target: ABSENT
Architecture Backend: NOT_STARTED
Assembly writer: NOT_STARTED
```



## MF032 architecture backend and Assembly writer

```txt
Target selection: TargetContext only
Target: x86_64-systemv-elf-linux
Assembly syntax: NASM Intel
Writer: fixed caller buffer; checked; deterministic; sealed hash
Labels: nebo_fn_<id>, nebo_int_<id>, nebo_text_<id>
Text source bytes: decimal db operands only
Function Lowering Plan: consumed as target-independent logical operations
Unresolved nodes: rejected before output
C/libc: forbidden
Physical ABI lowering: MATERIALIZED_MF033
Object packaging/link driver: DEFERRED_MF034_MF035
```


## MF033 ABI Adapter

```txt
Path: compiler/codegen/abi/x86_64/
Internal ABI version: 0
Target ABI: System V AMD64
Register parameters: RDI, RSI, RDX, RCX, R8, R9
Additional arguments: stack
Scalar return: RAX
Status return: EAX
Stack alignment before CALL: 16
Red zone: forbidden
Function signature hash: FNV-1a
Runtime ABI version mismatch: controlled toolchain error
State: ABI_ADAPTER_FUNCTION_LOWERING_GREEN
```


## MF034 format, runtime and toolchain

```txt
Format Adapter: ELF64 textual boundary for _start
Runtime Core: exit, trap, Text equality, ABI version and stable Console symbols
Toolchain: explicit NASM/GNU ld paths and structured argv
Shell command construction: FORBIDDEN
Partial output cleanup: REQUIRED
Binary determinism: REQUIRED
Console contracts: lowered to MF033 versioned thunks
Visual Console and scan runtime: DEFERRED_MF041_PLUS
Direct ELF writer: ABSENT
C/libc: FORBIDDEN
State: FORMAT_ADAPTER_RUNTIME_CORE_TOOLCHAIN_GREEN
```


## MF035 public CLI driver

```txt
Entrypoint: compiler/driver/bootstrap/entry.asm -> neboc_cli_main
Commands: --help, --version, check, emit-asm, build
Source policy: .no only
check: Lexer/Parser gate, no toolchain
emit-asm: deterministic NASM Intel output
build: fork/execve/wait4 -> NASM + GNU ld -> ELF64
Temp policy: cleanup by default; --keep-temp preserves assembly and object
Exit codes: 0..6 frozen
run/package/REPL: ABSENT
C/libc/shell: FORBIDDEN
State: IMPLEMENTED_PENDING_LOCAL_VALIDATION
```

## MF037 Core value codegen

Checked signed Int arithmetic, canonical Bool comparison/logic lowering and deterministic runtime traps are materialized for expression statements in `start()`. Functions, `.return` and control flow remain later fronts.

## MF038 native functions

Receiver-first declarations, deterministic `nebo_fn_<id>` names, direct calls and terminal `.return` are lowered by `compiler/codegen/functions/x86_64/`.


## MF039 control and Text

The function code generator now lowers direct immutable bindings, deterministic
`if/else`, real Bool short-circuit and content-based Text equality. Explicit
`Int(value)`, `Bool(value)` and `Text(value)` forms are exact type assertions;
the pure Nebo literal-binding form remains equivalent.
