; ALIASES-UNICODE-MATEMATICOS-EXATOS exact U+2260 inequality alias matcher.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/unicode_alias_contract.inc"

section .text
NEBOC_ABI_FUNCTION neboc_unicode_inequality_alias_match
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
 cmp byte [rdi+2],0xa0
 jne .source
 mov qword [rdx+NEBOC_UNICODE_ALIAS_RESULT_TOKEN_OFFSET],NEBOC_UNICODE_ALIAS_NOT_EQUAL_TOKEN
 mov qword [rdx+NEBOC_UNICODE_ALIAS_RESULT_CODEPOINT_OFFSET],NEBOC_UNICODE_ALIAS_NOT_EQUAL_CODEPOINT
 mov qword [rdx+NEBOC_UNICODE_ALIAS_RESULT_BYTE_LENGTH_OFFSET],3
 mov qword [rdx+NEBOC_UNICODE_ALIAS_RESULT_REGISTRY_ID_OFFSET],NEBOC_UNICODE_ALIAS_NOT_EQUAL_ID
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
