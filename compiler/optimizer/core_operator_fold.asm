; ARITMETICA-CHECKED-E-ASSIGNMENT-COMPOSTO deterministic constant folding through canonical checked helpers.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token_kind.inc"

extern neboc_core_checked_add
extern neboc_core_checked_subtract
extern neboc_core_checked_multiply
extern neboc_core_checked_divide
extern neboc_core_checked_remainder

section .text
; core_fold_binary(token, left, right, out*)
NEBOC_ABI_FUNCTION neboc_core_fold_binary
 test rcx,rcx
 jz .invalid
 cmp edi,NEBOC_TOKEN_PLUS
 je .add
 cmp edi,NEBOC_TOKEN_MINUS
 je .subtract
 cmp edi,NEBOC_TOKEN_STAR
 je .multiply
 cmp edi,NEBOC_TOKEN_SLASH
 je .divide
 cmp edi,NEBOC_TOKEN_PERCENT
 je .remainder
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.add:
 mov rdi,rsi
 mov rsi,rdx
 mov rdx,rcx
 jmp neboc_core_checked_add
.subtract:
 mov rdi,rsi
 mov rsi,rdx
 mov rdx,rcx
 jmp neboc_core_checked_subtract
.multiply:
 mov rdi,rsi
 mov rsi,rdx
 mov rdx,rcx
 jmp neboc_core_checked_multiply
.divide:
 mov rdi,rsi
 mov rsi,rdx
 mov rdx,rcx
 jmp neboc_core_checked_divide
.remainder:
 mov rdi,rsi
 mov rsi,rdx
 mov rdx,rcx
 jmp neboc_core_checked_remainder
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; core_fold_prefix(token, value, out*)
NEBOC_ABI_FUNCTION neboc_core_fold_prefix
 test rdx,rdx
 jz .prefix_invalid
 cmp edi,NEBOC_TOKEN_PLUS
 je .identity
 cmp edi,NEBOC_TOKEN_MINUS
 jne .prefix_source
 mov rax,rsi
 neg rax
 jo .prefix_overflow
 mov [rdx],rax
 xor eax,eax
 ret
.identity:
 mov [rdx],rsi
 xor eax,eax
 ret
.prefix_overflow:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.prefix_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.prefix_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
