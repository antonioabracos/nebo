bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "compiler/semantic/types/text_semantic.inc"

global neboc_text_semantic_kind

section .text
align 16
neboc_text_semantic_kind:
 cmp edi,nebo_text_core_TYPE_TEXT
 je .text
 cmp edi,nebo_text_core_TYPE_CHAR
 je .char
 cmp edi,nebo_text_core_TYPE_BYTES
 je .bytes
 xor eax,eax
 ret
.text:
 mov eax,NEBO_SEMANTIC_TEXT
 ret
.char:
 mov eax,NEBO_SEMANTIC_CHAR
 ret
.bytes:
 mov eax,NEBO_SEMANTIC_BYTES
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
