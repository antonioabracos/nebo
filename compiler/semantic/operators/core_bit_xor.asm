; POTENCIA-XOR-E-COMPARACAO-TOTAL exact-width Int and Bytes xor.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"

%define NEBOC_CORE_BYTES_XOR_MAX_LENGTH 1048576

section .text
NEBOC_ABI_FUNCTION neboc_core_int_xor
 test rdx,rdx
 jz .int_invalid
 xor rdi,rsi
 mov [rdx],rdi
 xor eax,eax
 ret
.int_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; bytes_xor(left*, right*, equal_length, out*)
; Caller owns storage. Exact in-place alias is permitted; partial overlap is
; outside the public lowering contract.
NEBOC_ABI_FUNCTION neboc_core_bytes_xor
 test rcx,rcx
 jz .bytes_invalid
 test rdx,rdx
 jz .bytes_ok
 test rdi,rdi
 jz .bytes_invalid
 test rsi,rsi
 jz .bytes_invalid
 cmp rdx,NEBOC_CORE_BYTES_XOR_MAX_LENGTH
 ja .bytes_limit
 xor r8d,r8d
.bytes_loop:
 cmp r8,rdx
 jae .bytes_ok
 mov al,[rdi+r8]
 xor al,[rsi+r8]
 mov [rcx+r8],al
 inc r8
 jmp .bytes_loop
.bytes_ok:
 xor eax,eax
 ret
.bytes_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.bytes_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
