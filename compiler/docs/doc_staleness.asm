; RF166-G158-F05 signature staleness and explicit SymbolId refactor mapping.
bits 64
default rel
%include "compiler/docs/doc_examples.inc"
global neboc_doc_staleness
global neboc_doc_record_detect_staleness
global neboc_doc_refactor_map_apply
section .text
neboc_doc_staleness:
neboc_doc_record_detect_staleness:
neboc_doc_refactor_map_apply:
 DOCX_VALIDATE_REQUEST NEBOC_DOCX_OP_STALENESS,.validated
.validated:
 mov r8,[rdi+NEBOC_DOCX_CURRENT_SIGNATURE_OFFSET]
 test r8,r8
 jz .contract
 mov r9,[rdi+NEBOC_DOCX_NEW_SYMBOL_ID_OFFSET]
 test r9,r9
 jz .contract
 mov r10,[rdi+NEBOC_DOCX_PREVIOUS_SIGNATURE_OFFSET]
 test r10,r10
 jz .fresh
 mov r11,[rdi+NEBOC_DOCX_OLD_SYMBOL_ID_OFFSET]
 cmp r8,r10
 jne .changed
 test r11,r11
 jz .fresh
 cmp r11,r9
 je .fresh
.changed:
 test qword [rdi+NEBOC_DOCX_FLAGS_OFFSET],NEBOC_DOCX_FLAG_REFACTOR_MAP
 jz .stale
 test r11,r11
 jz .stale
 mov rax,[rdi+NEBOC_DOCX_OLD_DOC_REVISION_OFFSET]
 cmp rax,[rdi+NEBOC_DOCX_DOC_REVISION_OFFSET]
 jne .stale
 mov rax,r8
 xor rax,r10
 DOCX_PUBLISH rax,NEBOC_DOCX_CLASS_PRESERVED,r10,r8
.fresh:
 mov rax,r8
 xor rax,[rdi+NEBOC_DOCX_DOC_REVISION_OFFSET]
 DOCX_PUBLISH rax,NEBOC_DOCX_CLASS_FRESH,r8,r8
.stale:
 mov rax,r8
 xor rax,r10
 DOCX_PUBLISH rax,NEBOC_DOCX_CLASS_STALE,r10,r8
.contract:
 mov eax,NEBOC_DOCX_STATUS_CONTRACT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
