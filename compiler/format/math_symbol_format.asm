bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/operator_registry.inc"

extern neboc_typed_math_registry_at

section .text

; edi=G130 Registry row, rsi=out byte pointer, rdx=out length.
; Formatting consumes the compiled Registry view and cannot invent spelling.
global nebo_math_symbol_format
nebo_math_symbol_format:
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 push rsi
 push rdx
 sub rsp,8
 call neboc_typed_math_registry_at
 add rsp,8
 pop rdx
 pop rsi
 test rax,rax
 jz .missing
 mov rcx,[rax+NEBOC_OPERATOR_ENTRY_LEXEME_START_OFFSET]
 mov [rsi],rcx
 mov rcx,[rax+NEBOC_OPERATOR_ENTRY_LEXEME_COUNT_OFFSET]
 mov [rdx],rcx
 xor eax,eax
 ret
.missing:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
