; RF166-G158-F06 old/new API and documentation compatibility classification.
bits 64
default rel
%include "compiler/docs/doc_examples.inc"
global neboc_doc_compatibility
global neboc_doc_compatibility_compare
section .text
neboc_doc_compatibility:
neboc_doc_compatibility_compare:
 DOCX_VALIDATE_REQUEST NEBOC_DOCX_OP_COMPATIBILITY,.validated
.validated:
 mov r8,[rdi+NEBOC_DOCX_FLAGS_OFFSET]
 mov r9,r8
 and r9,NEBOC_DOCX_FLAG_OLD_PRESENT | NEBOC_DOCX_FLAG_NEW_PRESENT
 cmp r9,NEBOC_DOCX_FLAG_NEW_PRESENT
 je .additive
 cmp r9,NEBOC_DOCX_FLAG_OLD_PRESENT
 je .breaking
 cmp r9,NEBOC_DOCX_FLAG_OLD_PRESENT | NEBOC_DOCX_FLAG_NEW_PRESENT
 jne .unknown
 mov r10,[rdi+NEBOC_DOCX_OLD_API_DIGEST_OFFSET]
 mov r11,[rdi+NEBOC_DOCX_NEW_API_DIGEST_OFFSET]
 test r10,r10
 jz .unknown
 test r11,r11
 jz .unknown
 cmp r10,r11
 jne .breaking
 mov rax,r10
 xor rax,[rdi+NEBOC_DOCX_DOC_REVISION_OFFSET]
 DOCX_PUBLISH rax,NEBOC_DOCX_CLASS_COMPATIBLE,r10,r11
.additive:
 mov rax,[rdi+NEBOC_DOCX_NEW_API_DIGEST_OFFSET]
 DOCX_PUBLISH rax,NEBOC_DOCX_CLASS_ADDITIVE,0,rax
.breaking:
 mov rax,[rdi+NEBOC_DOCX_OLD_API_DIGEST_OFFSET]
 xor rax,[rdi+NEBOC_DOCX_NEW_API_DIGEST_OFFSET]
 DOCX_PUBLISH rax,NEBOC_DOCX_CLASS_BREAKING,[rdi+NEBOC_DOCX_OLD_API_DIGEST_OFFSET],[rdi+NEBOC_DOCX_NEW_API_DIGEST_OFFSET]
.unknown:
 xor eax,eax
 DOCX_PUBLISH rax,NEBOC_DOCX_CLASS_UNKNOWN,0,0
section .note.GNU-stack noalloc noexec nowrite progbits
