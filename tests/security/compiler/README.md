# Compiler/toolchain security cases — MF056

Security checks operate on the locally rebuilt `build/bin/neboc` and verify System V stack alignment, non-executable stack, absence of writable+executable regions, structured argv behavior and output-path traversal rejection.
