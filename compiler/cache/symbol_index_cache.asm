; RF166-G160-F07/F08: bounded cache accounting and cold/incremental parity.
bits 64
default rel
%include "compiler/semantic/index/symbol_index.inc"
global neboc_index_cache
section .text
align 16
neboc_index_cache:
 INDEX_VALIDATE_REQUEST NEBOC_INDEX_OP_CACHE,.validated
.validated:
 INDEX_REQUIRE_FLAGS NEBOC_INDEX_FLAG_ATOMIC|NEBOC_INDEX_FLAG_DEADLINE,.policy
 mov rax,[rdi+NEBOC_INDEX_COLD_DIGEST_OFFSET]
 test rax,rax
 jz .contract
 cmp rax,[rdi+NEBOC_INDEX_INCREMENTAL_DIGEST_OFFSET]
 jne .mismatch
 mov rax,[rdi+NEBOC_INDEX_CACHE_HITS_OFFSET]
 add rax,[rdi+NEBOC_INDEX_CACHE_MISSES_OFFSET]
 jc .limit
 cmp rax,[rdi+NEBOC_INDEX_TOTAL_ENTRIES_OFFSET]
 jne .mismatch
 mov rax,[rdi+NEBOC_INDEX_EVICTIONS_OFFSET]
 cmp rax,[rdi+NEBOC_INDEX_TOTAL_ENTRIES_OFFSET]
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
