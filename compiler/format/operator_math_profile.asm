; FORMATTER-ASCII-MATEMATICO-E-EQUIVALENCIA-SEMANTICA bounded exact mathematical operator formatting.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token_kind.inc"

section .rodata
math_minus: db 0xe2,0x88,0x92
math_slash: db 0xc3,0xb7
math_le: db 0xe2,0x89,0xa4
math_ge: db 0xe2,0x89,0xa5
math_ne: db 0xe2,0x89,0xa0
math_and: db 0xe2,0x88,0xa7
math_or: db 0xe2,0x88,0xa8
math_not: db 0xc2,0xac
math_xor: db 0xe2,0x8a,0xbb

section .text
; format_operator_math(token, out_bytes, capacity, out_length*)
NEBOC_ABI_FUNCTION neboc_format_operator_math
 test rsi,rsi
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp rdi,NEBOC_TOKEN_MINUS
 je .minus
 cmp rdi,NEBOC_TOKEN_SLASH
 je .slash
 cmp rdi,NEBOC_TOKEN_LESS_EQUAL
 je .le
 cmp rdi,NEBOC_TOKEN_GREATER_EQUAL
 je .ge
 cmp rdi,NEBOC_TOKEN_BANG_EQUAL
 je .ne
 cmp rdi,NEBOC_TOKEN_AND_AND
 je .and
 cmp rdi,NEBOC_TOKEN_OR_OR
 je .or
 cmp rdi,NEBOC_TOKEN_BANG
 je .not
 cmp rdi,NEBOC_TOKEN_XOR
 jne .source
 lea r8,[rel math_xor]
 mov r9d,3
 jmp .copy
.minus:
 lea r8,[rel math_minus]
 mov r9d,3
 jmp .copy
.slash:
 lea r8,[rel math_slash]
 mov r9d,2
 jmp .copy
.le:
 lea r8,[rel math_le]
 mov r9d,3
 jmp .copy
.ge:
 lea r8,[rel math_ge]
 mov r9d,3
 jmp .copy
.ne:
 lea r8,[rel math_ne]
 mov r9d,3
 jmp .copy
.and:
 lea r8,[rel math_and]
 mov r9d,3
 jmp .copy
.or:
 lea r8,[rel math_or]
 mov r9d,3
 jmp .copy
.not:
 lea r8,[rel math_not]
 mov r9d,2
.copy:
 cmp rdx,r9
 jb .limit
 xor r10d,r10d
.copy_loop:
 cmp r10,r9
 jae .done
 mov al,[r8+r10]
 mov [rsi+r10],al
 inc r10
 jmp .copy_loop
.done:
 mov [rcx],r9
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
