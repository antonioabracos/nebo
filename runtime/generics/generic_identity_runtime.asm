; Nebo Assembly — GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-PF004 statically selected scalar identity specializations
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/generics/generic_identity_runtime.inc"

section .text
NEBOC_ABI_FUNCTION neboc_identity_Bool
 mov rax,rdi
 ret

NEBOC_ABI_FUNCTION neboc_identity_Int
 mov rax,rdi
 ret

NEBOC_ABI_FUNCTION neboc_identity_Float
 ret

NEBOC_ABI_FUNCTION neboc_identity_Char
 mov rax,rdi
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
