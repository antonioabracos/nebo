; RF166-G159-F05 Edition/target/stability availability view owner.
bits 64
default rel
%include "compiler/docs/docs.inc"
global neboc_docs_views
section .text
align 16
neboc_docs_views:
 DOCS_VALIDATE_REQUEST NEBOC_DOCS_OP_VIEWS,.validated
.validated:
 cmp qword [rdi+NEBOC_DOCS_GRAPH_DIGEST_OFFSET],0
 je .contract
 cmp qword [rdi+NEBOC_DOCS_EDITION_OFFSET],1
 jne .policy
 cmp qword [rdi+NEBOC_DOCS_TARGET_OFFSET],0
 je .policy
 mov rax,[rdi+NEBOC_DOCS_STABILITY_COUNT_OFFSET]
 cmp rax,[rdi+NEBOC_DOCS_SYMBOL_COUNT_OFFSET]
 ja .contract
 mov rax,[rdi+NEBOC_DOCS_GRAPH_DIGEST_OFFSET]
 xor rax,[rdi+NEBOC_DOCS_TARGET_OFFSET]
 xor rax,[rdi+NEBOC_DOCS_EDITION_OFFSET]
 DOCS_PUBLISH rax,NEBOC_DOCS_CLASS_VIEW,[rdi+NEBOC_DOCS_EDITION_OFFSET],[rdi+NEBOC_DOCS_TARGET_OFFSET],[rdi+NEBOC_DOCS_STABILITY_COUNT_OFFSET]
.contract:
 mov eax,NEBOC_DOCS_STATUS_CONTRACT
 ret
.policy:
 mov eax,NEBOC_DOCS_STATUS_POLICY
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
