; ALIASES-UNICODE-MATEMATICOS-EXATOS canonical AST/HIR/LIR alias provenance record.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/unicode_alias_contract.inc"

section .text
; unicode_alias_provenance(token, codepoint, start, end, out*) -> StatusCode
NEBOC_ABI_FUNCTION neboc_unicode_alias_provenance
 test r8,r8
 jz .invalid
 cmp rdx,rcx
 ja .source
 cmp rsi,NEBOC_UNICODE_ALIAS_MINUS_CODEPOINT
 je .minus
 cmp rsi,NEBOC_UNICODE_ALIAS_DIVIDE_CODEPOINT
 je .divide
 cmp rsi,NEBOC_UNICODE_ALIAS_LESS_EQUAL_CODEPOINT
 je .less_equal
 cmp rsi,NEBOC_UNICODE_ALIAS_GREATER_EQUAL_CODEPOINT
 je .greater_equal
 cmp rsi,NEBOC_UNICODE_ALIAS_NOT_EQUAL_CODEPOINT
 je .not_equal
 cmp rsi,NEBOC_UNICODE_ALIAS_AND_CODEPOINT
 je .and
 cmp rsi,NEBOC_UNICODE_ALIAS_OR_CODEPOINT
 je .or
 cmp rsi,NEBOC_UNICODE_ALIAS_NOT_CODEPOINT
 je .not
 cmp rsi,NEBOC_UNICODE_ALIAS_XOR_CODEPOINT
 je .xor
 jmp .source
.minus:
 mov r9d,NEBOC_UNICODE_ALIAS_MINUS_TOKEN
 mov r10d,NEBOC_UNICODE_ALIAS_MINUS_ID
 jmp .verify
.divide:
 mov r9d,NEBOC_UNICODE_ALIAS_DIVIDE_TOKEN
 mov r10d,NEBOC_UNICODE_ALIAS_DIVIDE_ID
 jmp .verify
.less_equal:
 mov r9d,NEBOC_UNICODE_ALIAS_LESS_EQUAL_TOKEN
 mov r10d,NEBOC_UNICODE_ALIAS_LESS_EQUAL_ID
 jmp .verify
.greater_equal:
 mov r9d,NEBOC_UNICODE_ALIAS_GREATER_EQUAL_TOKEN
 mov r10d,NEBOC_UNICODE_ALIAS_GREATER_EQUAL_ID
 jmp .verify
.not_equal:
 mov r9d,NEBOC_UNICODE_ALIAS_NOT_EQUAL_TOKEN
 mov r10d,NEBOC_UNICODE_ALIAS_NOT_EQUAL_ID
 jmp .verify
.and:
 mov r9d,NEBOC_UNICODE_ALIAS_AND_TOKEN
 mov r10d,NEBOC_UNICODE_ALIAS_AND_ID
 jmp .verify
.or:
 mov r9d,NEBOC_UNICODE_ALIAS_OR_TOKEN
 mov r10d,NEBOC_UNICODE_ALIAS_OR_ID
 jmp .verify
.not:
 mov r9d,NEBOC_UNICODE_ALIAS_NOT_TOKEN
 mov r10d,NEBOC_UNICODE_ALIAS_NOT_ID
 jmp .verify
.xor:
 mov r9d,NEBOC_UNICODE_ALIAS_XOR_TOKEN
 mov r10d,NEBOC_UNICODE_ALIAS_XOR_ID
.verify:
 cmp rdi,r9
 jne .source
 mov [r8+NEBOC_UNICODE_PROVENANCE_TOKEN_OFFSET],r9
 mov [r8+NEBOC_UNICODE_PROVENANCE_CODEPOINT_OFFSET],rsi
 mov [r8+NEBOC_UNICODE_PROVENANCE_REGISTRY_ID_OFFSET],r10
 mov [r8+NEBOC_UNICODE_PROVENANCE_SOURCE_START_OFFSET],rdx
 mov [r8+NEBOC_UNICODE_PROVENANCE_SOURCE_END_OFFSET],rcx
 mov qword [r8+NEBOC_UNICODE_PROVENANCE_SPELLING_OFFSET],NEBOC_UNICODE_ALIAS_PROVENANCE_UNICODE
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; The semantic pipeline compares canonical token kinds, never source spelling.
NEBOC_ABI_FUNCTION neboc_unicode_alias_same_semantic
 xor eax,eax
 cmp rdi,rsi
 sete al
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
