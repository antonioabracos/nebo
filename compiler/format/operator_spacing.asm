; FORMATTER-ASCII-MATEMATICO-E-EQUIVALENCIA-SEMANTICA spacing derived from canonical fixity and delimiters.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/parser/expression/operator_precedence.inc"
%include "compiler/format/symbol_style_profile.inc"

section .text
; operator_spacing(token, fixity, left_delimiter, right_delimiter, out*)
NEBOC_ABI_FUNCTION neboc_operator_spacing
 test r8,r8
 jz .invalid
 cmp rdx,1
 ja .source
 cmp rcx,1
 ja .source
 cmp rsi,NEBOC_OPERATOR_PARSE_FIXITY_PREFIX
 je .prefix
 cmp rsi,NEBOC_OPERATOR_PARSE_FIXITY_INFIX
 jne .source
 mov r9d,1
 mov r10d,1
 test rcx,rcx
 jz .store
 xor r10d,r10d
 jmp .store
.prefix:
 xor r9d,r9d
 xor r10d,r10d
.store:
 test rdx,rdx
 jz .left_ready
 xor r9d,r9d
.left_ready:
 mov [r8+NEBOC_OPERATOR_SPACING_BEFORE_OFFSET],r9
 mov [r8+NEBOC_OPERATOR_SPACING_AFTER_OFFSET],r10
 mov [r8+NEBOC_OPERATOR_SPACING_FIXITY_OFFSET],rsi
 mov [r8+NEBOC_OPERATOR_SPACING_TOKEN_OFFSET],rdi
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
