# Nebo Edition 1 semantic freeze

This is the current bounded Edition 1 semantic contract for G175. The corrected
G175 contract governs the eight fronts. It freezes the admitted product
profiles, without promoting internal plans, experimental APIs, or unsupported
grammar to stable public functionality. The current G173 maturity inventory is
preserved in `API-BEHAVIOR-MATRIX.tsv`: every public row is joined to this run's
atomic positive and associated negative observations; exclusions stay explicit.

Ordinary expression operands, receiver/positional arguments and collection or
product inputs evaluate in lexical order, once. Discard retains effects.
Short-circuit operators suppress the skipped side. Cleanup follows ownership
and the actual control-flow exit. The tests compare changed inputs, repeated
live values and explicit return statuses across independent build roots.

The current generic scalar and named/default argument profiles remain bounded.
Named/default argument witnesses use pure scalar inputs; arbitrary effectful
named arguments are not admitted by the current source profile. Alias layout
identity is supported by the nominal owner; ordinary local bindings cannot
freely substitute alias spelling for every built-in type. Newtypes require
explicit wrapping/unwrapping. No implicit Bool/Int/Float/Char/Text conversion
is introduced. The incompatible typed initializer repair preserves a causal
type error instead of falling through to value-name resolution.

`unwrapOr(value)` evaluates its value argument eagerly even for Some/Ok. The
current bounded `??` and combinator profiles preserve variant selection;
this does not promise arbitrary effectful callback forms. Active payloads,
error identity, match coverage and propagation follow the exact admitted
Option/Result/nominal/function owners identified below.

Effect atoms, grants, attenuation, Sensitive/Trusted metadata, policy and
provenance have explicit native contracts. They are not automatically public
source constructors. The source-level witnesses are actual transitive purity,
prelude/module nonexecution, private filesystem behavior and synthetic Scan
redaction. A historical seed program or a native assertion does not establish
an extra source API. Imports do not grant authority. No real secret is used.

Tasks use the supported noncapturing callback and single-consumer Future
profile. Channels are bounded FIFO. Scheduling/select is deterministic within
this profile; no preemptive async or general closure capture is inferred.
Module graphs run dependencies first, once; pure interface loading executes no
user initializer. Native rollback and actual public graph diagnostics are
separate complementary proofs.

Valid-source runtime failures are distinct from invalid-source diagnostics.
Only accepted source programs are executed; compile negatives must fail check,
emit-asm and build without an artifact. Domain/limit/IO failures have explicit
runtime statuses or typed error values and retain their sink atomicity oracle.
An exit status is never accepted without its source, code generation and
independent value/effect oracle. Linux process status uses the platform's
observable low byte; signals are represented separately by negative Python
return codes. SIGPIPE (-13) differs from a literal exit 141.

Numeric/source/transport budgets are finite. The rule tables and preserved API
limits are normative for these profiles: changing them is a contract change,
not permission to omit a boundary test. On OOM, overflow, cancellation or sink
failure, the corresponding runtime oracle checks cleanup and nonpublication.
The complete G170/G171/G172 replay extends beyond the eight principal examples.
The native effect lattice additionally checks 2,895 independently modeled
requests twice. G169/G168/G167 preserve invalid-program diagnostics and isolation.

## G175-S01 — Ordem de avaliação e exactly-once

**G175-S01-F001 — binary-order.** Evaluate ordinary operands left to right exactly once, including owned Bytes operands.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/codegen/functions/x86_64/function_codegen.asm`. Proofs: `source:eval-binary-17-2b`, `source:eval-binary-71-2b`, `G170:operator_test:bytes-xor-effects`.

**G175-S01-F002 — call-order.** Evaluate receiver then positional arguments once; native hidden-result storage preserves effects and caller ownership.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/codegen/functions/x86_64/function_codegen.asm`. Proofs: `source:eval-call-17`, `source:eval-call-71`, `G170:matrix_test:function-sret-effect-order`.

**G175-S01-F003 — aggregate-order.** List arguments and named product fields evaluate in lexical source order, independent of storage field order.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/codegen/functions/x86_64/function_codegen.asm`. Proofs: `source:eval-collection-17`, `G170:composite_test:typed-struct-lexical-effects`.

**G175-S01-F004 — short-circuit.** &&/and and ||/or aliases evaluate the RHS only when needed; no hidden arithmetic trap in skipped branch.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/codegen/functions/x86_64/function_codegen.asm`. Proofs: `source:short-2626-False-True`, `source:short-2626-True-False`, `source:short-7c7c-True-False`, `G170:operator_test:short-and`, `G170:operator_test:short-or`.

**G175-S01-F005 — temporary-lifetime.** Temporaries remain valid through use, and independent returned owned values do not alias.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/codegen/functions/x86_64/function_codegen.asm`. Proofs: `G171:pairwise:temporary-two-live-17`, `G171:pairwise:temporary-two-live-71`, `G170:ownership_test:temporary-block`.

**G175-S01-F006 — discard-and-return.** Discard keeps effects; return suppresses subsequent control paths and runs required cleanup.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/codegen/functions/x86_64/function_codegen.asm`. Proofs: `source:eval-discard-17`, `source:early-return-7`, `source:early-return-71`, `G170:ownership_test:early-return`.


## G175-S02 — Tipos, inference, conversões e overloads

**G175-S02-F001 — builtin-types.** Bool, Int64, binary64 Float, Unicode Char, UTF-8 Text and Bytes retain distinct typed identities.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/semantic/bindings/binding_vertical.asm`. Proofs: `G170:binding_test:Int-0-typed`, `G170:binding_test:Float-0-typed`, `G170:binding_test:Char-1-typed`, `G170:binding_test:Bytes-1-typed`.

**G175-S02-F002 — inference-and-binding.** Direct inference and explicit one-shot initialization agree; assignment preserves type and mutability.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/semantic/bindings/binding_vertical.asm`. Proofs: `G170:binding_test:Int-0-implicit`, `G170:binding_test:ordinary-mutable-shadow`, `G170:binding_test:constant-text-write`.

**G175-S02-F003 — no-coercions.** No implicit Bool/Int/Float/Char/Text conversion at binding boundaries; rejected initializer retains causal type error.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/semantic/bindings/binding_vertical.asm`. Proofs: `source:no-coercion-Int`, `source:no-coercion-Bool`, `source:no-coercion-Float`, `source:no-coercion-Char`, `source:no-coercion-Text`, `source:initializer-unknown-name`, `source:initializer-helper-mismatch`.

**G175-S02-F004 — nominal-identity.** Alias layout equals referent layout; newtype requires explicit construction/unwrap; enum discriminants and active payloads remain distinct.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/semantic/types/nominal_types.asm`. Proofs: `source:alias-identity-Int`, `source:alias-identity-Bool`, `source:alias-identity-Char`, `source:alias-identity-Text`, `G170:composite_test:newtype-two-values-17-29`, `G170:composite_test:newtype-wrong-value`.

**G175-S02-F005 — generic-constraints.** Supported scalar generic constraints are checked, not erased; const arguments specialize independently.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/semantic/generics/generic_semantic.asm`. Proofs: `G170:composite_test:generic-compose-whereTHashEq-23`, `G170:composite_test:const-generic-two-values-17-29`, `G170:composite_test:generic-ord-bool`.

**G175-S02-F006 — overload-ranking.** Exact supported receiver/argument types select deterministically regardless of declaration order. Named/default calls retain their bounded pure profile.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/codegen/functions/x86_64/function_codegen.asm`. Proofs: `G170:control_test:explicit-overload-17-False`, `G170:control_test:explicit-overload-17-True`, `G170:control_test:explicit-overload-true-False`, `G170:control_test:named-weighted-3-17`, `G170:control_test:call-argument`.

**G175-S02-F007 — explicit-conversions.** Narrowing, textual parsing and numeric rounding use explicit operations with checked domain/error behavior.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/semantic/types/numeric_safety_semantic.asm`. Proofs: `G170:binding_test:byte-value-255-typed`, `G170:precision_test:round-mode-effect-once`.


## G175-S03 — Ownership, borrow, move, copy, clone e drop

**G175-S03-F001 — move.** Move transfers ownership exactly once and invalidates the old binding.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/semantic/memory/ownership_semantic.asm`. Proofs: `G170:ownership_test:move-block`, `G170:ownership_test:move-arena-with-block`, `G170:ownership_test:use-after-move`.

**G175-S03-F002 — copy-clone.** Value copies and explicit owned clones remain independent; clone allocation is accounted and released.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/semantic/memory/ownership_semantic.asm`. Proofs: `G170:ownership_test:clone-block`, `G170:ownership_test:clone-arena`, `G170:composite_test:typed-struct-copy-isolation`.

**G175-S03-F003 — borrow-aliasing.** Shared/unique views constrain mutation, reset, drop and move until release.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/semantic/memory/ownership_semantic.asm`. Proofs: `G170:ownership_test:allocator-deallocate-active-borrow`, `G170:ownership_test:unique-reborrow-conflict`, `G170:ownership_test:arena-reset-active-borrow`, `G171:pairwise:struct-dict-borrow-move-17`.

**G175-S03-F004 — lifetime-escape.** Borrow cannot escape its owner; function result ownership is explicit and caller-owned.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/semantic/memory/ownership_semantic.asm`. Proofs: `G170:ownership_test:borrow-escape`, `G170:control_test:callable-borrow-escape`, `G171:pairwise:return-ends-local-view`.

**G175-S03-F005 — cleanup.** Success, early return and allocation failure release all live resources exactly once.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `runtime/core/runtime_core.asm`. Proofs: `G170:ownership_test:implicit-drop`, `G170:ownership_test:two-arenas`, `G171:pairwise:allocation-oom-cleanup`, `G170:ownership_test:double-drop`.

**G175-S03-F006 — layout-ownership.** Runtime descriptors carry root/generation identity; separate live arenas and composite results preserve payload and ownership.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `runtime/core/runtime_core.asm`. Proofs: `G170:ownership_test:two-arenas`, `G170:ownership_test:reset-and-reuse`, `G171:pairwise:temporary-two-live-71`.


## G175-S04 — Effects, capabilities, privacy e provenance

**G175-S04-F001 — effect-lattice.** Pure is bottom; 14 atoms form a Boolean lattice. Unknown bits and undeclared transitive effects fail closed.

Profile: `INTERNAL_COMPILER_CONTRACT`. Owner: `compiler/semantic/effects/effects_contract.asm`. Proofs: `native:effect-lattice`, `native:effect-inference`.

**G175-S04-F002 — source-effect-inference.** Interpolation permits only pure expressions, including transitive callees; discarded effects still execute outside pure contexts.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/codegen/functions/x86_64/function_codegen.asm`. Proofs: `source:pure-interpolation-17`, `source:pure-interpolation-71`, `G170:interpolation_test:effect-transitive`, `G170:interpolation_test:effect-mutable`.

**G175-S04-F003 — capability-grants.** Only authenticated host authority grants scoped capabilities. Attenuation cannot amplify effects, constraints, budget or lifetime.

Profile: `INTERNAL_RUNTIME_CONTRACT`. Owner: `runtime/capabilities/capabilities.asm`. Proofs: `native:capabilities`.

**G175-S04-F004 — import-no-grant.** Import and prelude resolution grant no capabilities and execute no user initializer.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/semantic/modules/module_init_effects.asm`. Proofs: `G170:metadata_test:prelude-declarations`, `G170:metadata_test:stdlib-profile`, `module:pure-dag-17`.

**G175-S04-F005 — policy-before-sink.** Deny precedes missing grants, trust, cancellation, deadline and budgets. Failure does not consume capability budget.

Profile: `INTERNAL_RUNTIME_CONTRACT`. Owner: `runtime/effects/policy.asm`. Proofs: `native:policy`.

**G175-S04-F006 — privacy-and-trust.** Sensitive labels, clearance, purpose and explicit reveal authority must pass flow policy; raw synthetic secrets never enter redacted output.

Profile: `INTERNAL_CONTRACT_WITH_PUBLIC_SCAN_WITNESS`. Owner: `runtime/privacy/privacy.asm`. Proofs: `native:privacy`, `G171:pairwise:scan-redacted-data-11-S`.

**G175-S04-F007 — provenance.** Immutable source/transform/artifact lineage hashes bind ordered parents and quality; tampering is rejected.

Profile: `INTERNAL_RUNTIME_CONTRACT`. Owner: `runtime/provenance/provenance.asm`. Proofs: `native:provenance`.


## G175-S05 — Option, Result, Error, match e propagation

**G175-S05-F001 — option-layout.** Some/None have a typed active payload; only the selected variant is observed. Invalid payloads and wrong observers reject.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/parser/option_result_parser.asm`. Proofs: `G170:option_result_test:two-options`, `G171:pairwise:tagged-negative-payload`, `G171:pairwise:observe-45`.

**G175-S05-F002 — result-layout.** Ok/Err preserve distinct success/error types and owned payloads across function returns.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/parser/option_result_result_parser.asm`. Proofs: `G170:option_result_test:two-results`, `G171:pairwise:result-collection-51`, `G171:pairwise:tagged-negative-error`.

**G175-S05-F003 — fallback-laziness.** unwrapOr accepts an eagerly evaluated value. Bounded combinators and ?? retain their documented variant selection; unsupported callback forms are not admitted.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/parser/option_result_parser.asm`. Proofs: `source:fallback-value-17-True`, `source:fallback-value-17-False`, `G170:option_result_test:option-lazy-or-else`, `G170:operator_test:coalesce-False-23`, `G170:operator_test:coalesce-True-23`.

**G175-S05-F004 — error-identity.** Error code/category/span/context and cause remain structured; messages are derived from active error identity and caller context.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `runtime/core/runtime_core.asm`. Proofs: `G170:option_result_test:error-two-messages`, `G170:option_result_test:error-diagnostic-span`, `G170:option_result_test:error-invalid-diagnostic-span`.

**G175-S05-F005 — match.** Current enum matching observes only the selected active variant and rejects invalid patterns according to the finite source profile.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/semantic/types/nominal_types.asm`. Proofs: `G170:composite_test:enum-payload-match`, `source:match-Some-17`, `source:match-Some-71`, `source:match-None-0`, `source:match-negative-non-exhaustive`, `source:match-negative-duplicate-arm`, `source:match-negative-guard-non-covering`.

**G175-S05-F006 — propagation.** ? retains the enclosing supported Result type and propagates the active error without reusing helper status as payload.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/codegen/functions/x86_64/function_codegen.asm`. Proofs: `G170:operator_test:propagate-False-23`, `G170:operator_test:propagate-True-23`, `G170:operator_test:propagate-False-255`.


## G175-S06 — Módulos, initialization, system e concurrency

**G175-S06-F001 — module-init-order.** Dependencies initialize before consumers, once; reordered unit arguments do not change the plan or executable.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/semantic/modules/module_init_effects.asm`. Proofs: `module:pure-dag-17`, `module:pure-dag-53`, `module:native-init-rollback`.

**G175-S06-F002 — module-init-failure.** Cycles and effectful imported startup fail before publication; native rollback reverses initialized resources.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/semantic/modules/module_init_effects.asm`. Proofs: `module:hidden`, `module:cycle`, `module:native-init-rollback`.

**G175-S06-F003 — pure-constants.** Pure source/interface constants preserve values and typed symbol identity. Interface loading is not execution.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/semantic/modules/pure_module_constants.asm`. Proofs: `module:pure-dag-71`, `G171:pairwise:module-ni-named-17`, `G171:pairwise:module-stale-interface`.

**G175-S06-F004 — tasks-futures.** Supported noncapturing task callbacks execute once; Future is single-consumer and map preserves effects.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `runtime/concurrency/task.asm`. Proofs: `G171:pairwise:task-effects-once`, `G171:pairwise:task-single-17`, `native:task`, `native:future`.

**G175-S06-F005 — channels.** Bounded FIFO transport preserves values, capacity errors and close behavior; source loops compose with independent random states.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `runtime/concurrency/channel.asm`. Proofs: `G171:pairwise:seed-channel-data-17`, `G171:pairwise:seed-channel-data-71`, `native:channel`.

**G175-S06-F006 — cancellation-scheduling.** Cancellation blocks admission; deterministic scheduler/select order is bounded, not a promise of preemptive async source.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `runtime/concurrency/task.asm`. Proofs: `G171:pairwise:task-cancel-admission`, `G171:pairwise:task-select-False`, `G171:pairwise:task-select-True`, `native:scheduler`.

**G175-S06-F007 — resource-closure.** Private filesystem capabilities enforce beneath/no-symlink paths and close resources; synchronization owner is real.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `runtime/core/runtime_core.asm`. Proofs: `G171:pairwise:filesystem-symlink-read`, `G171:pairwise:filesystem-symlink-write`, `native:synchronization`.


## G175-S07 — Limits, determinismo e failure atomicity

**G175-S07-F001 — allocation-budget.** System blocks <=65536 bytes, arena capacity <=1048576; OOM releases earlier successful allocations without publishing a later sink.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `runtime/core/runtime_core.asm`. Proofs: `G170:ownership_test:allocate-65536-return-23`, `G170:ownership_test:arena-1048576-17`, `G171:pairwise:allocation-oom-cleanup`.

**G175-S07-F002 — arithmetic-failures.** Checked integer overflow/division traps do not wrap silently; explicit status preserves canonical return semantics.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/codegen/functions/x86_64/function_codegen.asm`. Proofs: `G170:binding_test:Int-add-overflow`, `G170:binding_test:Int-divide-zero`, `G170:math_return_test:*`.

**G175-S07-F003 — output-capacity.** Tagged publication budget 32 and error text pool 4096 are checked before artifacts/output; plus-one rejects.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/parser/option_result_result_parser.asm`. Proofs: `G170:option_result_test:option-effect-capacity`, `G170:option_result_test:option-effect-capacity-plus-one`, `G170:option_result_test:error-message-pool-boundary`, `G170:option_result_test:error-message-pool-plus-one`.

**G175-S07-F004 — recursion-budget.** At most 64 active supported call frames; depth-boundary programs terminate with a defined trap, never hang.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `compiler/codegen/functions/x86_64/function_codegen.asm`. Proofs: `G170:control_test:recursion-63`, `G170:control_test:recursion-64`.

**G175-S07-F005 — publication-atomicity.** Failure before an atomic sink preserves existing files; rename/capacity/parser failures leave no partial output.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `runtime/core/runtime_core.asm`. Proofs: `G171:pairwise:filesystem-rename-failure`, `G171:pairwise:dict-capacity-failure-no-publish`, `G171:pairwise:scan-abort-no-file`.

**G175-S07-F006 — determinism-pressure.** Independent roots produce identical ASM/ELF/effects; E2E stress observes resources and repeatable output, not a fixed report.

Profile: `BOUNDED_PUBLIC_SOURCE`. Owner: `tests/rf204/G172/soak_test.py`. Proofs: `G172:end-to-end:*`.


## G175-S08 — Closeout do freeze semântico

**G175-S08-F001 — atomic-replay.** Replay all original atomic witnesses and every runtime supplemental family without reopening other catalog documents.

Profile: `GROUP_AUDIT`. Owner: `tests/rf204/G175/replay_worker.py`. Proofs: `G170:atomic:*`.

**G175-S08-F002 — pairwise-replay.** Replay the complete 66-pair covering array and reject missing or failed source observations.

Profile: `GROUP_AUDIT`. Owner: `tests/rf204/G171/inventory.py`. Proofs: `G171:pairwise:*`.

**G175-S08-F003 — end-to-end-replay.** Replay application, live software, synchronization, soak and target profiles; no external service or release operation.

Profile: `GROUP_AUDIT`. Owner: `tests/rf204/G172/runner.py`. Proofs: `G172:end-to-end:*`.

**G175-S08-F004 — independent-closeout.** Exact rule/proof joins, known-bad observations, checksums and live Git scope govern GREEN; file existence alone cannot close a rule.

Profile: `GROUP_AUDIT`. Owner: `tests/rf204/G175/audit.py`. Proofs: `source:extra-unclaimed-statement`, `self:known-bad`.
