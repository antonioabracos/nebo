# Nebo Language Specification 1.0

Status: current normative Edition 1 bounded specification, G182.
Target: x86_64 Linux System V ELF. This document changes no product version.

The chapters, normative rule registry and structural grammar jointly define the
language/profile obligations. “Must” denotes a requirement. Exact current
lexical contexts, type constraints, maturity, targets and bounds remain binding.
Implementation mechanics are identified separately and do not declare source
APIs. Tests are evidence; observations are never used to invent their expected
values. See the trace for exact test identities and the functional reference for
individual public declarations.

- [Source, lexical structure, trivia and comments](01-source-lexical-trivia.md)
- [Types, bindings, constants and ownership](02-types-bindings-ownership.md)
- [Expressions, operators and control flow](03-expressions-operators-control-flow.md)
- [Functions, modules, imports, interfaces and doc blocks](04-functions-modules-imports-interfaces-doc.md)
- [Errors, effects, capabilities and concurrency](05-errors-effects-capabilities-concurrency.md)
- [Text, format, Console and Scan](06-text-format-console-scan.md)
- [Limits, targets, Edition and diagnostics](07-limits-targets-edition-diagnostics.md)

- [Structural grammar](NEBO-GRAMMAR-1.0.ebnf)
- [Normative rules](NORMATIVE-RULE-REGISTRY.tsv)
- [Exact rule-to-test trace](SPEC-TO-TEST-TRACE.tsv)
- [Public behavior coverage and lifecycle boundaries](PUBLIC-BEHAVIOR-TO-RULE.tsv)
- [Implementation-defined profiles and limits](IMPLEMENTATION-DEFINED-REGISTRY.tsv)
- [Resolved ambiguities](SPEC-AMBIGUITY-REGISTER.tsv)
- [Current lexical freeze](../../../../reference/language/NEBO-1.0-LEXICAL-SPEC.md)
- [Current semantic freeze](../../../../reference/language/NEBO-1.0-SEMANTIC-SPEC.md)
- [Current functional reference](../../../../../sdk/contracts/stdlib/STDLIB-REFERENCE.md)

Changing a normative row requires an explicit compatibility/Edition decision
and updated tests. Reserved, experimental, target-gated and historical proposals
remain outside the stable claim. Validation only compares; it never silently
rewrites this baseline. Run `bash tests/rf204/G182/validate.sh` from the repository.
