# NEBOC_INTERNAL_ABI_v0

The first physical mapping is defined in:

```txt
compiler/abi/internal/x86_64/neboc_internal_abi.inc
```

```txt
Version:
0

Architecture:
x86-64

Integer arguments:
RDI, RSI, RDX, RCX, R8, R9

Scalar return:
RAX

Status:
EAX

Fallible result:
explicit out-parameter

Stack alignment before CALL:
16 bytes

Red zone:
forbidden

Callee-saved:
RBX, RBP, R12, R13, R14, R15

Direction flag:
clear on function entry and return

Exceptions:
none

Global errno:
none
```

This internal ABI is OS-independent as a compiler-module contract. Thunks and
host/target adapters translate external platform conventions when necessary.
