# x86-64 ABI Adapter v0

```txt
Internal ABI version: 0
Target ABI: System V AMD64
Integer arguments: RDI, RSI, RDX, RCX, R8, R9
Additional arguments: stack, right-to-left at call sites
Scalar return: RAX
Status return: EAX
Stack alignment before CALL: 16 bytes
Red zone: forbidden
Callee-saved: RBX, RBP, R12, R13, R14, R15
Direction flag: clear through the internal ABI function contract
Runtime ABI version: 0
```

Function signatures freeze parameter, stack, frame, return and call counts and
carry a canonical FNV-1a hash. Frames use 8-byte slots rounded to 16 bytes.
Recursion, SIMD/floating arguments and aggressive register allocation are not
implemented in MF033.
