bits 64
default rel
%include "compiler/parser/text_contract.inc"
%include "compiler/lowering/textual/text_ir.inc"
global neboc_text_lower
section .text
align 16
neboc_text_lower:
 cmp edi,NEBO_AST_TEXT_LITERAL
 jne .error
 mov eax,NEBO_LIR_TEXT_DESCRIPTOR
 ret
.error:
 mov eax,NEBO_LIR_ERROR
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
