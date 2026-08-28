# G02 numeric literal examples

`int-bases-and-separators.no` is the stable public example for the bounded G02
foundation slice. It demonstrates the existing `Int` type written in decimal,
binary, octal and hexadecimal forms, controlled `_` separators, and the
explicit `Int(...)` form.

Expected behavior on the certified target:

```txt
neboc check: PASS
neboc emit-asm: PASS
neboc build: PASS
native stdout: empty
native stderr: empty
native exit code: 0
```

The example does not authorize suffixes, presentation converters, ranges,
Float separators/exponents, additional numeric types or other native targets.
