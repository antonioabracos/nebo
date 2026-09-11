; RF166-G160-F05: atomic incremental replacement with cold parity.
bits 64
default rel
%include "compiler/semantic/index/symbol_index.inc"
global neboc_index_update
section .text
align 16
neboc_index_update:
 INDEX_VALIDATE_REQUEST NEBOC_INDEX_OP_INCREMENTAL,.validated
.validated:
 INDEX_REQUIRE_FLAGS NEBOC_INDEX_FLAG_INCREMENTAL|NEBOC_INDEX_FLAG_ATOMIC|NEBOC_INDEX_FLAG_VERIFY,.policy
 mov rax,[rdi+NEBOC_INDEX_COLD_DIGEST_OFFSET]
 test rax,rax
 jz .contract
 cmp rax,[rdi+NEBOC_INDEX_INCREMENTAL_DIGEST_OFFSET]
 jne .mismatch
 mov rax,[rdi+NEBOC_INDEX_ADDED_OFFSET]
 add rax,[rdi+NEBOC_INDEX_REMOVED_OFFSET]
 jc .limit
 add rax,[rdi+NEBOC_INDEX_UPDATED_OFFSET]
 jc .limit
 cmp rax,NEBOC_INDEX_MAX_ENTRIES*3
 ja .limit
 INDEX_PUBLISH [rdi+NEBOC_INDEX_INCREMENTAL_DIGEST_OFFSET],0
.contract:
 mov eax,NEBOC_INDEX_STATUS_CONTRACT
 ret
.policy:
 mov eax,NEBOC_INDEX_STATUS_POLICY
 ret
.mismatch:
 mov eax,NEBOC_INDEX_STATUS_MISMATCH
 ret
.limit:
 mov eax,NEBOC_INDEX_STATUS_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
