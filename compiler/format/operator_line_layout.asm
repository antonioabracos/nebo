; FORMATTER-ASCII-MATEMATICO-E-EQUIVALENCIA-SEMANTICA bounded line breaking, indentation and template preservation.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/format/symbol_style_profile.inc"

section .text
; operator_line_layout(column, indent, width, spelling_len, out_layout*)
NEBOC_ABI_FUNCTION neboc_operator_line_layout
 test r8,r8
 jz .invalid
 test rdx,rdx
 jz .source
 cmp rdx,NEBOC_OPERATOR_LAYOUT_MAX_WIDTH
 ja .limit
 cmp rsi,NEBOC_OPERATOR_LAYOUT_MAX_INDENT
 ja .limit
 cmp rcx,NEBOC_SYMBOL_FORMAT_MAX_OUTPUT_BYTES
 ja .limit
 mov r9,rdi
 add r9,rcx
 jc .limit
 xor r10d,r10d
 xor r11d,r11d
 cmp r9,rdx
 jbe .store
 mov r10d,1
 mov r11,rsi
 mov r9,rsi
 add r9,rcx
 jc .limit
.store:
 mov [r8+NEBOC_OPERATOR_LAYOUT_BREAK_OFFSET],r10
 mov [r8+NEBOC_OPERATOR_LAYOUT_INDENT_OFFSET],r11
 mov [r8+NEBOC_OPERATOR_LAYOUT_COLUMN_OFFSET],r9
 mov qword [r8+NEBOC_OPERATOR_LAYOUT_TEMPLATE_PRESERVED_OFFSET],1
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
