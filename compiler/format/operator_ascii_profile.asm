; FORMATTER-ASCII-MATEMATICO-E-EQUIVALENCIA-SEMANTICA bounded canonical ASCII operator formatting.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token_kind.inc"

section .rodata
ascii_minus: db '-'
ascii_slash: db '/'
ascii_le: db '<='
ascii_ge: db '>='
ascii_ne: db '!='
ascii_and: db '&&'
ascii_or: db '||'
ascii_not: db '!'
ascii_xor: db 'xor'

section .text
; format_operator_ascii(token, out_bytes, capacity, out_length*)
NEBOC_ABI_FUNCTION neboc_format_operator_ascii
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
 lea r8,[rel ascii_xor]
 mov r9d,3
 jmp .copy
.minus:
 lea r8,[rel ascii_minus]
 mov r9d,1
 jmp .copy
.slash:
 lea r8,[rel ascii_slash]
 mov r9d,1
 jmp .copy
.le:
 lea r8,[rel ascii_le]
 mov r9d,2
 jmp .copy
.ge:
 lea r8,[rel ascii_ge]
 mov r9d,2
 jmp .copy
.ne:
 lea r8,[rel ascii_ne]
 mov r9d,2
 jmp .copy
.and:
 lea r8,[rel ascii_and]
 mov r9d,2
 jmp .copy
.or:
 lea r8,[rel ascii_or]
 mov r9d,2
 jmp .copy
.not:
 lea r8,[rel ascii_not]
 mov r9d,1
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
