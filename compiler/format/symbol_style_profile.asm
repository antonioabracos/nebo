; FORMATTER-ASCII-MATEMATICO-E-EQUIVALENCIA-SEMANTICA SymbolStyleProfile with preserve default.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/format/symbol_style_profile.inc"

section .text
; symbol_style_profile(requested_profile, source_spelling, out_result*)
NEBOC_ABI_FUNCTION neboc_symbol_style_profile
 test rdx,rdx
 jz .invalid
 cmp rdi,NEBOC_SYMBOL_STYLE_MATH
 ja .source
 cmp rsi,NEBOC_SYMBOL_SPELLING_MATH
 ja .source
 mov r8,rsi
 cmp rdi,NEBOC_SYMBOL_STYLE_PRESERVE
 je .resolved
 xor r8d,r8d
 cmp rdi,NEBOC_SYMBOL_STYLE_MATH
 jne .resolved
 mov r8d,NEBOC_SYMBOL_SPELLING_MATH
.resolved:
 xor r9d,r9d
 cmp r8,rsi
 setne r9b
 mov [rdx+NEBOC_SYMBOL_STYLE_RESULT_PROFILE_OFFSET],rdi
 mov [rdx+NEBOC_SYMBOL_STYLE_RESULT_SPELLING_OFFSET],r8
 mov [rdx+NEBOC_SYMBOL_STYLE_RESULT_CHANGED_OFFSET],r9
 mov qword [rdx+NEBOC_SYMBOL_STYLE_RESULT_FLAGS_OFFSET],NEBOC_SYMBOL_STYLE_FLAG_SEMANTIC_IDENTITY_REQUIRED|NEBOC_SYMBOL_STYLE_FLAG_SOURCE_MAP_REQUIRED
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
