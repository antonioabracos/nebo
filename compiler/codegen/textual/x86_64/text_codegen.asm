bits 64
default rel
%include "compiler/lowering/textual/text_ir.inc"
%include "compiler/codegen/textual/x86_64/text_codegen.inc"
global neboc_text_codegen
section .text
align 16
neboc_text_codegen:
 cmp edi,NEBO_LIR_TEXT_DESCRIPTOR
 jne .error
 mov eax,NEBO_CODEGEN_STATIC_DESCRIPTOR
 ret
.error:
 mov eax,NEBO_CODEGEN_ERROR
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
