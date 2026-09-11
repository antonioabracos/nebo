# G01-PF005 Float vertical conformance fixtures

This corpus proves only the authorized `G01-PF005` slice:

- strict decimal `Float` literals in explicit and implicit binding forms;
- homogeneous constant `Float` arithmetic with `+`, `-`, `*`, `/` inside `start()`;
- deterministic NASM/SSE2 emission, static ELF64 linking and native exit `0`;
- IEEE 754 preservation for division by zero, NaN and signed zero;
- stable rejection of implicit `Int` coercion and contexts outside this front.

Functions carrying `Float`, identifier reuse, comparisons, `%`, exponent notation,
formatting and other APIs are deliberately `PROPOSED_NOT_EXECUTABLE`.
