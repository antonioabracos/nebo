; RF166-G159-F06 public docs build/verify/search/diff/serve/restore gate.
bits 64
default rel
%include "compiler/docs/docs.inc"
global neboc_docs_cli
section .text
align 16
neboc_docs_cli:
 DOCS_VALIDATE_REQUEST NEBOC_DOCS_OP_CLI,.validated
.validated:
 mov rax,[rdi+NEBOC_DOCS_COMMAND_OFFSET]
 cmp rax,NEBOC_DOCS_COMMAND_BUILD
 jb .contract
 cmp rax,NEBOC_DOCS_COMMAND_RESTORE
 ja .contract
 cmp rax,NEBOC_DOCS_COMMAND_SERVE
 jne .verify
 test qword [rdi+NEBOC_DOCS_FLAGS_OFFSET],NEBOC_DOCS_FLAG_LOCAL_ONLY
 jz .policy
.verify:
 cmp rax,NEBOC_DOCS_COMMAND_VERIFY
 jne .compare
 test qword [rdi+NEBOC_DOCS_FLAGS_OFFSET],NEBOC_DOCS_FLAG_VERIFY
 jz .policy
.compare:
 mov rcx,[rdi+NEBOC_DOCS_EXPECTED_OFFSET]
 cmp rcx,[rdi+NEBOC_DOCS_OBSERVED_OFFSET]
 jne .mismatch
 mov rcx,[rdi+NEBOC_DOCS_GRAPH_DIGEST_OFFSET]
 test rcx,rcx
 jnz .publish
 mov rcx,[rdi+NEBOC_DOCS_PRIMARY_DIGEST_OFFSET]
 test rcx,rcx
 jz .contract
.publish:
 DOCS_PUBLISH rcx,NEBOC_DOCS_CLASS_COMMAND,[rdi+NEBOC_DOCS_COMMAND_OFFSET],[rdi+NEBOC_DOCS_EXPECTED_OFFSET],[rdi+NEBOC_DOCS_OBSERVED_OFFSET]
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
