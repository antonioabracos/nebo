# G01 Float foundation examples

`float-foundation.no` is the public, executable documentation example for the
bounded Float surface completed by `G01-PF005` and documented by `G01-PF006`.

Classification:

```txt
DOCUMENTATION_EXAMPLE
EXECUTABLE_POSITIVE
Target: x86_64-systemv-elf-linux
Expected neboc check: PASS
Expected neboc emit-asm: PASS
Expected neboc build: PASS
Expected native stdout: empty
Expected native stderr: empty
Expected native exit code: 0
```

The example demonstrates only the approved foundation slice:

- explicit `Float(3.5)` and implicit `3.5` bindings;
- unary negative Float values;
- homogeneous Float `+`, `-`, `*` and `/` constant expressions inside
  `start()`;
- IEEE 754 infinity, NaN and negative zero values.

It deliberately does not demonstrate implicit `Int` conversion, exponent
notation, `%`, comparisons, reusable Float identifiers, Float function
parameters/returns, formatting or printing. Those surfaces remain unavailable.
