; RF166-G159-F07 clean/incremental/archive/restore byte-identity owner.
bits 64
default rel
%include "compiler/docs/docs.inc"
global neboc_docs_archive
section .text
align 16
neboc_docs_archive:
 DOCS_VALIDATE_REQUEST NEBOC_DOCS_OP_ARCHIVE,.validated
.validated:
 test qword [rdi+NEBOC_DOCS_FLAGS_OFFSET],NEBOC_DOCS_FLAG_ARCHIVE
 jz .policy
 cmp qword [rdi+NEBOC_DOCS_GRAPH_DIGEST_OFFSET],0
 je .contract
 mov rax,[rdi+NEBOC_DOCS_PRIMARY_DIGEST_OFFSET]
 test rax,rax
 jz .contract
 cmp rax,[rdi+NEBOC_DOCS_SECONDARY_DIGEST_OFFSET]
 jne .mismatch
 mov rcx,[rdi+NEBOC_DOCS_ARCHIVE_DIGEST_OFFSET]
 test rcx,rcx
 jz .contract
 cmp rcx,[rdi+NEBOC_DOCS_RESTORE_DIGEST_OFFSET]
 jne .mismatch
 mov rdx,[rdi+NEBOC_DOCS_CHANGED_NODES_OFFSET]
 cmp rdx,[rdi+NEBOC_DOCS_TOTAL_NODES_OFFSET]
 ja .contract
 xor rax,rcx
 DOCS_PUBLISH rax,NEBOC_DOCS_CLASS_ARCHIVE,[rdi+NEBOC_DOCS_CHANGED_NODES_OFFSET],[rdi+NEBOC_DOCS_TOTAL_NODES_OFFSET],[rdi+NEBOC_DOCS_ARCHIVE_DIGEST_OFFSET]
.contract:
 mov eax,NEBOC_DOCS_STATUS_CONTRACT
 ret
.policy:
 mov eax,NEBOC_DOCS_STATUS_POLICY
 ret
.mismatch:
 mov eax,NEBOC_DOCS_STATUS_MISMATCH
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
