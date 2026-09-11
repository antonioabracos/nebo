bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "compiler/semantic/types/text_semantic.inc"

global neboc_text_semantic_kind
global neboc_text_type_info

section .text
align 16
neboc_text_semantic_kind:
 cmp edi,nebo_text_core_TYPE_TEXT
 je .text
 cmp edi,nebo_text_core_TYPE_CHAR
 je .char
 cmp edi,nebo_text_core_TYPE_BYTES
 je .bytes
 cmp edi,NEBO_TEXT_CORE_TYPE_TEXT_VIEW
 je .view
 cmp edi,NEBO_TEXT_CORE_TYPE_OWNED_TEXT
 je .owned
 cmp edi,NEBO_TEXT_CORE_TYPE_STATIC_TEXT
 je .static
 cmp edi,NEBO_TEXT_CORE_TYPE_TEXT_BUILDER
 je .builder
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
.view:
 mov eax,NEBO_SEMANTIC_TEXT_VIEW
 ret
.owned:
 mov eax,NEBO_SEMANTIC_OWNED_TEXT
 ret
.static:
 mov eax,NEBO_SEMANTIC_STATIC_TEXT
 ret
.builder:
 mov eax,NEBO_SEMANTIC_TEXT_BUILDER
 ret

; edi=Text-family type id, esi=storage class, edx=TextFlags, rcx=out
; TextTypeInfo.  Invalid inputs leave the output untouched.
align 16
neboc_text_type_info:
 test rcx,rcx
 jz .info_invalid
 mov esi,esi
 mov edx,edx
 cmp esi,NEBO_TEXT_STORAGE_OWNED
 ja .info_invalid
 mov eax,edx
 and eax,~NEBO_TEXT_FLAG_MASK
 jnz .info_invalid
 cmp edi,nebo_text_core_TYPE_TEXT
 je .info_text
 cmp edi,NEBO_TEXT_CORE_TYPE_TEXT_VIEW
 je .info_view
 cmp edi,NEBO_TEXT_CORE_TYPE_OWNED_TEXT
 je .info_owned
 cmp edi,NEBO_TEXT_CORE_TYPE_STATIC_TEXT
 jne .info_invalid
 mov eax,NEBO_SEMANTIC_STATIC_TEXT
 jmp .info_commit
.info_text:
 mov eax,NEBO_SEMANTIC_TEXT
 jmp .info_commit
.info_view:
 mov eax,NEBO_SEMANTIC_TEXT_VIEW
 jmp .info_commit
.info_owned:
 mov eax,NEBO_SEMANTIC_OWNED_TEXT
.info_commit:
 mov [rcx+NEBO_TEXT_TYPE_INFO_KIND_OFFSET],rax
 mov [rcx+NEBO_TEXT_TYPE_INFO_STORAGE_OFFSET],rsi
 mov qword [rcx+NEBO_TEXT_TYPE_INFO_ENCODING_OFFSET],NEBO_TEXT_ENCODING_UTF8
 mov r8,rdx
 and r8,NEBO_TEXT_FLAG_PRIVATE | NEBO_TEXT_FLAG_SENSITIVE
 mov [rcx+NEBO_TEXT_TYPE_INFO_PRIVACY_OFFSET],r8
 mov [rcx+NEBO_TEXT_TYPE_INFO_OWNERSHIP_OFFSET],rsi
 mov qword [rcx+NEBO_TEXT_TYPE_INFO_FLAGS_OFFSET],NEBO_TEXT_TYPE_INFO_FLAGS
 xor eax,eax
 ret
.info_invalid:
 mov eax,NEBO_TEXT_ERROR_POLICY
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
