; RF166-G159-F01 DocsGraph contract over canonical interface/DocRecord facts.
bits 64
default rel
%include "compiler/docs/docs.inc"
global neboc_docs_graph
section .text
align 16
neboc_docs_graph:
 DOCS_VALIDATE_REQUEST NEBOC_DOCS_OP_GRAPH,.validated
.validated:
 cmp qword [rdi+NEBOC_DOCS_GRAPH_DIGEST_OFFSET],0
 je .contract
 mov rax,[rdi+NEBOC_DOCS_SYMBOL_COUNT_OFFSET]
 test rax,rax
 jz .contract
 cmp rax,NEBOC_DOCS_MAX_SYMBOLS
 ja .limit
 mov rcx,[rdi+NEBOC_DOCS_MODULE_COUNT_OFFSET]
 test rcx,rcx
 jz .contract
 cmp rcx,NEBOC_DOCS_MAX_MODULES
 ja .limit
 cmp rcx,rax
 ja .contract
 mov rdx,[rdi+NEBOC_DOCS_PACKAGE_COUNT_OFFSET]
 test rdx,rdx
 jz .contract
 cmp rdx,NEBOC_DOCS_MAX_PACKAGES
 ja .limit
 cmp rdx,rcx
 ja .contract
 mov r8,[rdi+NEBOC_DOCS_PUBLIC_COUNT_OFFSET]
 add r8,[rdi+NEBOC_DOCS_PRIVATE_COUNT_OFFSET]
 jc .contract
 cmp r8,rax
 jne .contract
 test qword [rdi+NEBOC_DOCS_FLAGS_OFFSET],NEBOC_DOCS_FLAG_PUBLIC_ONLY
 jz .publish
 cmp qword [rdi+NEBOC_DOCS_PRIVATE_COUNT_OFFSET],0
 jne .policy
.publish:
 DOCS_PUBLISH [rdi+NEBOC_DOCS_GRAPH_DIGEST_OFFSET],NEBOC_DOCS_CLASS_GRAPH,[rdi+NEBOC_DOCS_SYMBOL_COUNT_OFFSET],[rdi+NEBOC_DOCS_MODULE_COUNT_OFFSET],[rdi+NEBOC_DOCS_PACKAGE_COUNT_OFFSET]
.contract:
 mov eax,NEBOC_DOCS_STATUS_CONTRACT
 ret
.policy:
 mov eax,NEBOC_DOCS_STATUS_POLICY
 ret
.limit:
 mov eax,NEBOC_DOCS_STATUS_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
