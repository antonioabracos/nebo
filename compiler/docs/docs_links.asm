; RF166-G159-F04 SymbolId cross-link and redacted local source-link owner.
bits 64
default rel
%include "compiler/docs/docs.inc"
global neboc_docs_links
section .text
align 16
neboc_docs_links:
 DOCS_VALIDATE_REQUEST NEBOC_DOCS_OP_LINKS,.validated
.validated:
 cmp qword [rdi+NEBOC_DOCS_GRAPH_DIGEST_OFFSET],0
 je .contract
 mov rax,[rdi+NEBOC_DOCS_LINK_COUNT_OFFSET]
 cmp rax,NEBOC_DOCS_MAX_LINKS
 ja .limit
 cmp rax,[rdi+NEBOC_DOCS_RESOLVED_LINKS_OFFSET]
 jne .mismatch
 test qword [rdi+NEBOC_DOCS_FLAGS_OFFSET],NEBOC_DOCS_FLAG_PATHS_REDACTED
 jz .policy
 DOCS_PUBLISH [rdi+NEBOC_DOCS_GRAPH_DIGEST_OFFSET],NEBOC_DOCS_CLASS_LINKED,[rdi+NEBOC_DOCS_LINK_COUNT_OFFSET],[rdi+NEBOC_DOCS_RESOLVED_LINKS_OFFSET],[rdi+NEBOC_DOCS_SYMBOL_COUNT_OFFSET]
.contract:
 mov eax,NEBOC_DOCS_STATUS_CONTRACT
 ret
.policy:
 mov eax,NEBOC_DOCS_STATUS_POLICY
 ret
.mismatch:
 mov eax,NEBOC_DOCS_STATUS_MISMATCH
 ret
.limit:
 mov eax,NEBOC_DOCS_STATUS_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
