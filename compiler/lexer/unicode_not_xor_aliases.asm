; ALIASES-UNICODE-MATEMATICOS-EXATOS exact U+00AC/U+22BB NOT/XOR alias matcher.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/unicode_alias_contract.inc"

section .text
NEBOC_ABI_FUNCTION neboc_unicode_not_xor_alias_match
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,2
 je .not
 cmp rsi,3
 jne .source
 cmp byte [rdi],0xe2
 jne .source
 cmp byte [rdi+1],0x8a
 jne .source
 cmp byte [rdi+2],0xbb
 jne .source
 mov r8d,NEBOC_UNICODE_ALIAS_XOR_TOKEN
 mov r9d,NEBOC_UNICODE_ALIAS_XOR_CODEPOINT
 mov r10d,3
 mov r11d,NEBOC_UNICODE_ALIAS_XOR_ID
 jmp .store
.not:
 cmp byte [rdi],0xc2
 jne .source
 cmp byte [rdi+1],0xac
 jne .source
 mov r8d,NEBOC_UNICODE_ALIAS_NOT_TOKEN
 mov r9d,NEBOC_UNICODE_ALIAS_NOT_CODEPOINT
 mov r10d,2
 mov r11d,NEBOC_UNICODE_ALIAS_NOT_ID
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
