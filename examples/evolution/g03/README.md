# G03 numeric-safety foundation examples

`numeric-safety-foundation.no` is the stable public example for the bounded G03
candidate. It demonstrates explicit `Int.toFloat()` through both implicit Int
literal and explicit `Int(...)` source forms. The conformance fixtures cover the
four Float classifiers and exceptional IEEE values.

The candidate is executable only for `x86_64-systemv-elf-linux`. It does not
publish Nebo v0.2, change `neboc --version`, introduce Float-to-Int conversion,
casts, implicit coercion, wrapping, saturation, parsing or approximate equality.
