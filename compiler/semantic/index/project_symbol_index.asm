; RF166-G160-F01: revision-bound ProjectSymbolIndex construction.
bits 64
default rel
%include "compiler/semantic/index/symbol_index.inc"
global neboc_symbol_index_new
section .text
align 16
neboc_symbol_index_new:
 INDEX_VALIDATE_REQUEST NEBOC_INDEX_OP_NEW,.validated
.validated:
 INDEX_REQUIRE_FLAGS NEBOC_INDEX_FLAG_COLD|NEBOC_INDEX_FLAG_ATOMIC|NEBOC_INDEX_FLAG_NO_CAPABILITY_GRANT|NEBOC_INDEX_FLAG_DEADLINE,.policy
 cmp qword [rdi+NEBOC_INDEX_WORKSPACE_OFFSET],0
 je .contract
 cmp qword [rdi+NEBOC_INDEX_REVISION_OFFSET],0
 je .contract
 cmp qword [rdi+NEBOC_INDEX_COLD_DIGEST_OFFSET],0
 je .contract
 mov rax,[rdi+NEBOC_INDEX_PUBLIC_ENTRIES_OFFSET]
 sub rax,[rdi+NEBOC_INDEX_FILTERED_ENTRIES_OFFSET]
 jc .mismatch
 cmp rax,[rdi+NEBOC_INDEX_RESULT_ENTRIES_OFFSET]
 jne .mismatch
 INDEX_PUBLISH [rdi+NEBOC_INDEX_COLD_DIGEST_OFFSET],0
.contract:
 mov eax,NEBOC_INDEX_STATUS_CONTRACT
 ret
.policy:
 mov eax,NEBOC_INDEX_STATUS_POLICY
 ret
.mismatch:
 mov eax,NEBOC_INDEX_STATUS_MISMATCH
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
