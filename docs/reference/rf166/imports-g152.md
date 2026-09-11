# Selective imports, reexports, visibility and explicit import edits (G152)

G152 extends the single canonical `ImportAstNode` and module graph introduced
by G151. A selective import names every visible identity explicitly:

```nebo
import "project.users" { User; findUser; }.users;
export import "project.users" { User; }.users;
```

The first declaration creates only the listed bindings under `users`. The
second is the sole syntax that can add imported identities to a module's
public API. `import` alone never reexports, `*` remains rejected, and neither
form grants a capability, permission, effect, runtime object or initializer.

## Namespaces and visibility

One case-sensitive `SymbolId` spelling is resolved against an explicit
namespace kind: type, value, callable or module. Equal spellings in different
namespaces do not conflict. Equal spellings in the same namespace are
ambiguous and rejected with deterministic related evidence.

Visibility is metadata, not a naming convention:

- `public` is reachable across package boundaries and may be reexported only
  by an explicit `export import` edge;
- `internal` is reachable only from the owning package and cannot be
  reexported;
- `private` is reachable only from the owning module and cannot be selected by
  another module or proposed by auto-import.

Reexport edges retain origin, source module, SymbolId, namespace and digest.
Duplicate public identities and cycles fail before graph publication. Public
API impact reports list direct public and reexport identities in bytewise
order and bind the list to a SHA-256 digest.

## Explicit tooling

Import edits occur only through an explicit command:

```text
neboc organize-imports <paths> --check|--apply
neboc add-import <symbol> --to <module.no>
neboc imports api-impact <module.no> [--baseline <sha256>]
```

`organize-imports --check` never writes and exits nonzero when a change is
needed. `--apply` moves complete selected-name records, keeping their comments
attached, writes a same-directory temporary file, flushes it, atomically
replaces the source and flushes the directory. A repeated apply is
byte-idempotent.

`add-import` scans only sibling canonical Nebo modules and requires exactly one
explicitly public candidate. It binds the plan to the destination SHA-256 and
device/inode pair immediately before the atomic replacement. Missing,
ambiguous, internal, private or stale candidates leave the destination bytes
unchanged. Ordinary `check` and `build` never call this operation.

`imports api-impact` is read-only. An optional baseline digest makes a changed
public identity set visible as a breaking result rather than silently
accepting it.

## Bounded profile

The stable import AST admits one to eight selected identities of at most 32
ASCII bytes each. The current executable module profile remains one root plus
two auxiliary units. Sources are caller-owned, ASTs and plans are pointerless
except for caller-owned replacement transport, and rejected operations clear
their output records. Core parsing, resolution, lowering and code generation
remain Assembly-first and produce static no-libc ELF64 targets.
