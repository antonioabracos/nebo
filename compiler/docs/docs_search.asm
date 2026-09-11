; RF166-G159-F03 bounded deterministic JSON/full-text/receiver index.
bits 64
default rel
%include "compiler/docs/docs.inc"
global neboc_docs_search
section .text
align 16
neboc_docs_search:
 DOCS_VALIDATE_REQUEST NEBOC_DOCS_OP_SEARCH,.validated
.validated:
 cmp qword [rdi+NEBOC_DOCS_GRAPH_DIGEST_OFFSET],0
 je .contract
 cmp qword [rdi+NEBOC_DOCS_PRIMARY_DIGEST_OFFSET],0
 je .contract
 cmp qword [rdi+NEBOC_DOCS_QUERY_DIGEST_OFFSET],0
 je .contract
 mov rax,[rdi+NEBOC_DOCS_BUDGET_OFFSET]
 test rax,rax
 jz .limit
 cmp rax,NEBOC_DOCS_MAX_SEARCH_RESULTS
 ja .limit
 mov rcx,[rdi+NEBOC_DOCS_MATCH_COUNT_OFFSET]
 cmp rcx,rax
 ja .limit
 cmp rcx,[rdi+NEBOC_DOCS_SYMBOL_COUNT_OFFSET]
 ja .contract
 DOCS_PUBLISH [rdi+NEBOC_DOCS_PRIMARY_DIGEST_OFFSET],NEBOC_DOCS_CLASS_INDEXED,[rdi+NEBOC_DOCS_MATCH_COUNT_OFFSET],[rdi+NEBOC_DOCS_BUDGET_OFFSET],[rdi+NEBOC_DOCS_QUERY_DIGEST_OFFSET]
.contract:
 mov eax,NEBOC_DOCS_STATUS_CONTRACT
 ret
.limit:
 mov eax,NEBOC_DOCS_STATUS_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
