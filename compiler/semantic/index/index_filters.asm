; RF166-G160-F06: edition, target, visibility, effect and capability filters.
bits 64
default rel
%include "compiler/semantic/index/symbol_index.inc"
global neboc_index_filter
section .text
align 16
neboc_index_filter:
 INDEX_VALIDATE_REQUEST NEBOC_INDEX_OP_FILTER,.validated
.validated:
 INDEX_REQUIRE_FLAGS NEBOC_INDEX_FLAG_PRIVATE_FILTERED|NEBOC_INDEX_FLAG_NO_CAPABILITY_GRANT|NEBOC_INDEX_FLAG_DEADLINE,.policy
 mov rax,[rdi+NEBOC_INDEX_FILTERED_ENTRIES_OFFSET]
 cmp rax,[rdi+NEBOC_INDEX_PUBLIC_ENTRIES_OFFSET]
 ja .mismatch
 mov rcx,[rdi+NEBOC_INDEX_PUBLIC_ENTRIES_OFFSET]
 sub rcx,rax
 mov rax,[rdi+NEBOC_INDEX_RESULT_ENTRIES_OFFSET]
 cmp rax,rcx
 ja .mismatch
 mov r8,[rdi+NEBOC_INDEX_QUERY_LIMIT_OFFSET]
 test r8,r8
 jz .limit
 cmp r8,NEBOC_INDEX_MAX_QUERY_RESULTS
 ja .limit
 cmp rax,r8
 ja .limit
 mov rdx,[rdi+NEBOC_INDEX_NAME_QUERY_OFFSET]
 or rdx,[rdi+NEBOC_INDEX_RECEIVER_QUERY_OFFSET]
 or rdx,[rdi+NEBOC_INDEX_MODULE_QUERY_OFFSET]
 jnz .bounded_query
 cmp rcx,r8
 cmova rcx,r8
 cmp rax,rcx
 jne .mismatch
 jmp .publish
.bounded_query:
.publish:
 INDEX_PUBLISH [rdi+NEBOC_INDEX_COLD_DIGEST_OFFSET],0
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
