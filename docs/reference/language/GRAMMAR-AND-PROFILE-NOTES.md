# Material grammar and native ownership

`NEBO-1.0-GRAMMAR.ebnf` documents the current structural grammar.
`SYNTAX-FORM-REGISTRY.tsv` maps each production to a present native owner,
its exact digest, executed source family, positive IDs and associated negatives.
Its completeness check detects undefined, duplicate or unreachable productions;
it never parses Nebo source. Public acceptance belongs to the native product.

The EBNF is the union of admitted structural profiles, not an assertion that
all alternatives compose freely. Type constraints, exact method/constructor
arity, statement consumption, symbol resolution, ownership, runtime budgets,
operator binding power and nonassociativity remain mandatory owner checks.
The `profile_program` alternative documents existing bounded scientific/formal
source grammars. It does not grant extra adjacent statements to whole-program
profiles or advertise unrestricted symbolic mathematics. Their exact limits
and reference inputs accompany the operator Registry joins.

Ordinary expression binding uses `.name` and optional `.mutable`. A separate
`Type.name;` declaration is followed by an initializer binding. Uppercase
constant names retain existing semantic rules. A type alias starts with
`type alias`. Reduction binds its actual following finite-domain operand.
These distinctions correct the older incomplete grammar snapshot.

Imports are native module declarations: mandatory aliases on simple/selective
imports, named or anonymous capsules and explicit reexports. Public module
values and compiled `.ni` identities are tested through source consumers.
`doc {}` attaches to a material declaration; documentation examples/laws are
compiled and executed under the native doc contract. The public formatter
uses the native DocBlockAst projection when independent module units are not
available to its standalone syntax check. Recompiled module consumers verify
the resulting source with their actual units.

Source runtime cases use two independent absolute build roots and independent
exit/Console value oracles. They include function/default/named/capture forms,
control flow, nominal/composite/generic constructors, Option/Result, Dict/Set,
math, formatting, templates, Console and mock Scan. Negative cases require
check/emit/build rejection and no output artifact. G169 replays all RF172
invalid levels, including 511/512 nesting boundaries, adversarial driver
budgets, signals, spans and oracle falsification checks.

Internal recovery can retain an ErrorNode while rolling back partial AST
construction. This never makes invalid source executable. Native default
recovery limits and the public driver options are separate interfaces, as
recorded in `LIMIT-BUDGET-MATRIX.tsv`.
