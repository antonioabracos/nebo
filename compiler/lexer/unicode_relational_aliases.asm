; ALIASES-UNICODE-MATEMATICOS-EXATOS exact U+2264/U+2265 relational alias matcher.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/unicode_alias_contract.inc"

section .text
; unicode_relational_alias_match(bytes, length, out_result*) -> StatusCode
NEBOC_ABI_FUNCTION neboc_unicode_relational_alias_match
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,3
 jne .source
 cmp byte [rdi],0xe2
 jne .source
 cmp byte [rdi+1],0x89
 jne .source
 cmp byte [rdi+2],0xa4
 je .less_equal
 cmp byte [rdi+2],0xa5
 jne .source
 mov r8d,NEBOC_UNICODE_ALIAS_GREATER_EQUAL_TOKEN
 mov r9d,NEBOC_UNICODE_ALIAS_GREATER_EQUAL_CODEPOINT
 mov r11d,NEBOC_UNICODE_ALIAS_GREATER_EQUAL_ID
 jmp .store
.less_equal:
 mov r8d,NEBOC_UNICODE_ALIAS_LESS_EQUAL_TOKEN
 mov r9d,NEBOC_UNICODE_ALIAS_LESS_EQUAL_CODEPOINT
 mov r11d,NEBOC_UNICODE_ALIAS_LESS_EQUAL_ID
.store:
 mov qword [rdx+NEBOC_UNICODE_ALIAS_RESULT_BYTE_LENGTH_OFFSET],3
 mov [rdx+NEBOC_UNICODE_ALIAS_RESULT_TOKEN_OFFSET],r8
 mov [rdx+NEBOC_UNICODE_ALIAS_RESULT_CODEPOINT_OFFSET],r9
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
