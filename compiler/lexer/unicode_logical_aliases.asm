; ALIASES-UNICODE-MATEMATICOS-EXATOS exact U+2227/U+2228 short-circuit logical alias matcher.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/unicode_alias_contract.inc"

section .text
NEBOC_ABI_FUNCTION neboc_unicode_logical_alias_match
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,3
 jne .source
 cmp byte [rdi],0xe2
 jne .source
 cmp byte [rdi+1],0x88
 jne .source
 cmp byte [rdi+2],0xa7
 je .and
 cmp byte [rdi+2],0xa8
 jne .source
 mov r8d,NEBOC_UNICODE_ALIAS_OR_TOKEN
 mov r9d,NEBOC_UNICODE_ALIAS_OR_CODEPOINT
 mov r11d,NEBOC_UNICODE_ALIAS_OR_ID
 jmp .store
.and:
 mov r8d,NEBOC_UNICODE_ALIAS_AND_TOKEN
 mov r9d,NEBOC_UNICODE_ALIAS_AND_CODEPOINT
 mov r11d,NEBOC_UNICODE_ALIAS_AND_ID
.store:
 mov [rdx+NEBOC_UNICODE_ALIAS_RESULT_TOKEN_OFFSET],r8
 mov [rdx+NEBOC_UNICODE_ALIAS_RESULT_CODEPOINT_OFFSET],r9
 mov qword [rdx+NEBOC_UNICODE_ALIAS_RESULT_BYTE_LENGTH_OFFSET],3
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
