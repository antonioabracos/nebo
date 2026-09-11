# Limits, targets, Edition and diagnostics

Edition 1.0 · current G182 normative bounded profile.

The executable target is x86_64 Linux System V ELF. Edition is a language
selection, not the runtime/tool version. Edition 1 freezes current admitted
forms; compatible Edition 2 selection and mechanical migration preview do not
activate reserved forms or authorize rewriting a source file.

Limits are finite and declared by subject/profile. Parser depth 511 is accepted;
512 rejects with NEBO_PARSE_NESTING_LIMIT. Block comments allow 64 levels.
A bound failure must retain its specified compile diagnostic, runtime error or
trap and failure atomicity; these channels are not interchangeable. Tool and
campaign timeout budgets are listed separately from language limits.

Linux process status observes the low byte of the integer source return;
SIGPIPE is signal 13, not exit 141. Diagnostics preserve code/severity/phase,
source identity and half-open UTF-8 byte spans. JSON-lines schema 1, SARIF and
UTF-16 LSP locations are consistent projections. Usage, source and internal
failures have different exit contracts. Message prose alone is not identity.
The public check command accepts --max-errors 1..64 and one of --fail-fast or
--keep-going. --show-fixes is for human/short output; --path-style selects
relative/workspace/absolute. The native owner rejects duplicates, incompatible
formats and these check-only options on emit/build before artifact publication.


## N1-allocation-budget

System blocks <=65536 bytes, arena capacity <=1048576; OOM releases earlier successful allocations without publishing a later sink.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S07-F001`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-arithmetic-failures

Checked integer overflow/division traps do not wrap silently; explicit status preserves canonical return semantics.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S07-F002`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-output-capacity

Tagged publication budget 32 and error text pool 4096 are checked before artifacts/output; plus-one rejects.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S07-F003`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-recursion-budget

At most 64 active supported call frames; depth-boundary programs terminate with a defined trap, never hang.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S07-F004`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-publication-atomicity

Failure before an atomic sink preserves existing files; rename/capacity/parser failures leave no partial output.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md#G175-S07-F005`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-diagnostic-contract

Invalid source must reject before executable publication. Diagnostic code, severity, phase and half-open UTF-8 byte spans are contractual; JSON-lines schema 1 and SARIF/LSP projections preserve that identity. LSP positions use UTF-16.

Authority: `sdk/contracts/compatibility/DIAGNOSTIC-COMPATIBILITY-REGISTRY.tsv`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-diagnostic-options

The public check command forwards bounded --max-errors (1..64), exclusive --fail-fast/--keep-going, human/short --show-fixes and --path-style relative/workspace/absolute to the native diagnostic owner. Duplicated options, incompatible modes and out-of-range arguments reject as usage errors before artifact publication.

Authority: `compiler/driver/cli/linux-x86_64/cli_driver.asm`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-process-status

The supported Linux process interface observes the low byte of the explicit integer return. Signal termination is distinct from an ordinary exit; a mathematical intermediate must not replace the return.

Authority: `docs/reference/language/NEBO-1.0-SEMANTIC-SPEC.md`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-edition-and-compatibility

Edition 1 specifies the admitted bounded profile. The current selector also accepts Edition 2 for compatible forms; unknown IDs reject. Neither selector nor migration preview activates a reserved form or changes files.

Authority: `docs/reference/language/EDITION-POLICY.md`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

## N1-declared-target-and-limits

Executable conformance here is x86_64 Linux System V ELF. Other targets and wider profiles acquire no guarantee by name. Public bounds and failure policies are enumerated in IMPLEMENTATION-DEFINED-REGISTRY.tsv; compiler and test-harness budgets are distinguished.

Authority: `docs/reference/interfaces/NI-SCHEMA-AND-FINGERPRINT-FREEZE.md`. Exact tests: [SPEC-TO-TEST-TRACE.tsv](SPEC-TO-TEST-TRACE.tsv).

The [rule registry](NORMATIVE-RULE-REGISTRY.tsv) also lists this chapter’s 188 lexical, grammar or declaration obligations. Their linked authority rows retain exact source forms, bounds and negative associations.
