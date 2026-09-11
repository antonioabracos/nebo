; RF166-G159-F02 deterministic Markdown/HTML/JSON render validation.
bits 64
default rel
%include "compiler/docs/docs.inc"
global neboc_docs_render
section .text
align 16
neboc_docs_render:
 DOCS_VALIDATE_REQUEST NEBOC_DOCS_OP_RENDER,.validated
.validated:
 cmp qword [rdi+NEBOC_DOCS_GRAPH_DIGEST_OFFSET],0
 je .contract
 cmp qword [rdi+NEBOC_DOCS_PRIMARY_DIGEST_OFFSET],0
 je .contract
 cmp qword [rdi+NEBOC_DOCS_SECONDARY_DIGEST_OFFSET],0
 je .contract
 cmp qword [rdi+NEBOC_DOCS_TERTIARY_DIGEST_OFFSET],0
 je .contract
 test qword [rdi+NEBOC_DOCS_FLAGS_OFFSET],NEBOC_DOCS_FLAG_OFFLINE_HTML
 jz .policy
 mov rax,[rdi+NEBOC_DOCS_EXPECTED_OFFSET]
 test rax,rax
 jz .contract
 cmp rax,[rdi+NEBOC_DOCS_OBSERVED_OFFSET]
 jne .mismatch
 mov rax,[rdi+NEBOC_DOCS_PRIMARY_DIGEST_OFFSET]
 xor rax,[rdi+NEBOC_DOCS_SECONDARY_DIGEST_OFFSET]
 rol rax,17
 xor rax,[rdi+NEBOC_DOCS_TERTIARY_DIGEST_OFFSET]
 DOCS_PUBLISH rax,NEBOC_DOCS_CLASS_RENDERED,[rdi+NEBOC_DOCS_EXPECTED_OFFSET],[rdi+NEBOC_DOCS_SYMBOL_COUNT_OFFSET],[rdi+NEBOC_DOCS_GRAPH_DIGEST_OFFSET]
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
