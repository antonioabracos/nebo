; POTENCIA-XOR-E-COMPARACAO-TOTAL exact Bool xor; ASCII `xor`, never caret.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"

section .text
; bool_xor(left_bool, right_bool, out_bool*)
NEBOC_ABI_FUNCTION neboc_core_bool_xor
 test rdx,rdx
 jz .invalid
 cmp rdi,1
 ja .source
 cmp rsi,1
 ja .source
 xor rdi,rsi
 mov [rdx],rdi
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
