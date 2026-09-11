bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "compiler/semantic/types/text_semantic.inc"

extern neboc_text_type_id
extern neboc_char_type_id
extern neboc_bytes_type_id
extern neboc_char_validate
extern neboc_text_validate_descriptor
extern neboc_text_semantic_kind
extern neboc_text_type_info

section .rodata
sample: db 'N','e','b','o'
align 8
valid_text: dq sample,4,NEBO_TEXT_FLAG_ASCII | NEBO_TEXT_FLAG_VALID_UTF8,0
empty_text: dq 0,0,0,0
bad_data: dq 0,1,0,0
bad_flags: dq sample,4,32,0

section .bss
align 8
type_info: resb NEBO_TEXT_TYPE_INFO_SIZE

section .text
%macro REQUIRE_EQ 2
 cmp %1,%2
 jne fail
%endmacro

global _start
_start:
 call neboc_text_type_id
 REQUIRE_EQ eax,nebo_text_core_TYPE_TEXT
 mov edi,eax
 call neboc_text_semantic_kind
 REQUIRE_EQ eax,NEBO_SEMANTIC_TEXT
 call neboc_char_type_id
 REQUIRE_EQ eax,nebo_text_core_TYPE_CHAR
 call neboc_bytes_type_id
 REQUIRE_EQ eax,nebo_text_core_TYPE_BYTES
 mov edi,NEBO_TEXT_CORE_TYPE_TEXT_VIEW
 call neboc_text_semantic_kind
 REQUIRE_EQ eax,NEBO_SEMANTIC_TEXT_VIEW
 mov edi,NEBO_TEXT_CORE_TYPE_OWNED_TEXT
 call neboc_text_semantic_kind
 REQUIRE_EQ eax,NEBO_SEMANTIC_OWNED_TEXT
 mov edi,NEBO_TEXT_CORE_TYPE_STATIC_TEXT
 call neboc_text_semantic_kind
 REQUIRE_EQ eax,NEBO_SEMANTIC_STATIC_TEXT
 mov edi,NEBO_TEXT_CORE_TYPE_TEXT_BUILDER
 call neboc_text_semantic_kind
 REQUIRE_EQ eax,NEBO_SEMANTIC_TEXT_BUILDER

 mov edi,NEBO_TEXT_CORE_TYPE_STATIC_TEXT
 mov esi,NEBO_TEXT_STORAGE_STATIC
 mov edx,NEBO_TEXT_FLAG_STATIC | NEBO_TEXT_FLAG_VALID_UTF8 | NEBO_TEXT_FLAG_PRIVATE
 lea rcx,[rel type_info]
 call neboc_text_type_info
 REQUIRE_EQ eax,NEBO_TEXT_OK
 REQUIRE_EQ qword [rel type_info+NEBO_TEXT_TYPE_INFO_KIND_OFFSET],NEBO_SEMANTIC_STATIC_TEXT
 REQUIRE_EQ qword [rel type_info+NEBO_TEXT_TYPE_INFO_ENCODING_OFFSET],NEBO_TEXT_ENCODING_UTF8
 REQUIRE_EQ qword [rel type_info+NEBO_TEXT_TYPE_INFO_PRIVACY_OFFSET],NEBO_TEXT_FLAG_PRIVATE
 REQUIRE_EQ qword [rel type_info+NEBO_TEXT_TYPE_INFO_FLAGS_OFFSET],NEBO_TEXT_TYPE_INFO_FLAGS

 mov edi,nebo_text_core_TYPE_BYTES
 mov esi,NEBO_TEXT_STORAGE_STATIC
 xor edx,edx
 lea rcx,[rel type_info]
 call neboc_text_type_info
 REQUIRE_EQ eax,NEBO_TEXT_ERROR_POLICY

 xor edi,edi
 call neboc_char_validate
 REQUIRE_EQ eax,NEBO_TEXT_OK
 mov edi,0x10ffff
 call neboc_char_validate
 REQUIRE_EQ eax,NEBO_TEXT_OK
 mov edi,0xd800
 call neboc_char_validate
 REQUIRE_EQ eax,NEBO_TEXT_ERROR_INVALID_CHAR
 mov edi,0x110000
 call neboc_char_validate
 REQUIRE_EQ eax,NEBO_TEXT_ERROR_INVALID_CHAR

 lea rdi,[rel valid_text]
 call neboc_text_validate_descriptor
 REQUIRE_EQ eax,NEBO_TEXT_OK
 lea rdi,[rel empty_text]
 call neboc_text_validate_descriptor
 REQUIRE_EQ eax,NEBO_TEXT_OK
 xor edi,edi
 call neboc_text_validate_descriptor
 REQUIRE_EQ eax,NEBO_TEXT_ERROR_NULL
 lea rdi,[rel bad_data]
 call neboc_text_validate_descriptor
 REQUIRE_EQ eax,NEBO_TEXT_ERROR_NULL
 lea rdi,[rel bad_flags]
 call neboc_text_validate_descriptor
 REQUIRE_EQ eax,NEBO_TEXT_ERROR_INVALID_FLAGS

 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,1
 mov eax,60
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
