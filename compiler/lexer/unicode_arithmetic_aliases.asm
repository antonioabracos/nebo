; ALIASES-UNICODE-MATEMATICOS-EXATOS exact U+2212/U+00F7 arithmetic alias matcher.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/unicode_alias_contract.inc"

section .text
; unicode_arithmetic_alias_match(bytes, length, out_result*) -> StatusCode
; The output is written only after an exact, complete match.
NEBOC_ABI_FUNCTION neboc_unicode_arithmetic_alias_match
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,2
 je .divide
 cmp rsi,3
 jne .source
 cmp byte [rdi],0xe2
 jne .source
 cmp byte [rdi+1],0x88
 jne .source
 cmp byte [rdi+2],0x92
 jne .source
 mov r8d,NEBOC_UNICODE_ALIAS_MINUS_TOKEN
 mov r9d,NEBOC_UNICODE_ALIAS_MINUS_CODEPOINT
 mov r10d,3
 mov r11d,NEBOC_UNICODE_ALIAS_MINUS_ID
 jmp .store
.divide:
 cmp byte [rdi],0xc3
 jne .source
 cmp byte [rdi+1],0xb7
 jne .source
 mov r8d,NEBOC_UNICODE_ALIAS_DIVIDE_TOKEN
 mov r9d,NEBOC_UNICODE_ALIAS_DIVIDE_CODEPOINT
 mov r10d,2
 mov r11d,NEBOC_UNICODE_ALIAS_DIVIDE_ID
.store:
 mov [rdx+NEBOC_UNICODE_ALIAS_RESULT_TOKEN_OFFSET],r8
 mov [rdx+NEBOC_UNICODE_ALIAS_RESULT_CODEPOINT_OFFSET],r9
 mov [rdx+NEBOC_UNICODE_ALIAS_RESULT_BYTE_LENGTH_OFFSET],r10
 mov [rdx+NEBOC_UNICODE_ALIAS_RESULT_REGISTRY_ID_OFFSET],r11
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
