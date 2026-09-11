; RF166-G160 structured native conformance and failure-atomicity checks.
bits 64
default rel
%include "compiler/semantic/index/symbol_index.inc"

global _start
extern neboc_symbol_index_new
extern neboc_index_source
extern neboc_index_interface
extern neboc_index_workspace
extern neboc_index_update
extern neboc_index_filter
extern neboc_index_cache

%define SENTINEL 0xa5a5a5a5a5a5a5a5
%define ALL_FLAGS NEBOC_INDEX_FLAG_COLD|NEBOC_INDEX_FLAG_INCREMENTAL|NEBOC_INDEX_FLAG_SOURCE_VALIDATED|NEBOC_INDEX_FLAG_INTERFACE_VALIDATED|NEBOC_INDEX_FLAG_PACKAGE_LOCAL|NEBOC_INDEX_FLAG_PRIVATE_FILTERED|NEBOC_INDEX_FLAG_NO_CAPABILITY_GRANT|NEBOC_INDEX_FLAG_DEADLINE|NEBOC_INDEX_FLAG_ATOMIC|NEBOC_INDEX_FLAG_VERIFY

%macro RUN_OK 2
 call reset_request
 mov qword [rel request+NEBOC_INDEX_OPERATION_OFFSET],%1
 lea rdi,[rel request]
 lea rsi,[rel result_a]
 call %2
 test eax,eax
 jnz fail
 cmp qword [rel result_a+NEBOC_INDEX_OUTPUT_STATUS_OFFSET],0
 jne fail
 cmp qword [rel result_a+NEBOC_INDEX_OUTPUT_OPERATION_OFFSET],%1
 jne fail
 cmp qword [rel result_a+NEBOC_INDEX_OUTPUT_DIGEST_OFFSET],0x99
 jne fail
 cmp qword [rel result_a+NEBOC_INDEX_OUTPUT_ENTRIES_OFFSET],8
 jne fail
 cmp qword [rel result_a+NEBOC_INDEX_OUTPUT_MATCHES_OFFSET],6
 jne fail
 cmp qword [rel result_a+NEBOC_INDEX_OUTPUT_BYTES_OFFSET],4096
 jne fail
 cmp qword [rel result_a+NEBOC_INDEX_OUTPUT_REVISION_OFFSET],77
 jne fail
%endmacro

section .text
_start:
 RUN_OK NEBOC_INDEX_OP_NEW,neboc_symbol_index_new
 RUN_OK NEBOC_INDEX_OP_SOURCE,neboc_index_source
 RUN_OK NEBOC_INDEX_OP_INTERFACE,neboc_index_interface
 RUN_OK NEBOC_INDEX_OP_WORKSPACE,neboc_index_workspace
 RUN_OK NEBOC_INDEX_OP_INCREMENTAL,neboc_index_update
 RUN_OK NEBOC_INDEX_OP_FILTER,neboc_index_filter
 RUN_OK NEBOC_INDEX_OP_CACHE,neboc_index_cache

 ; A named query may return a strict bounded subset without changing the index.
 call reset_request
 mov qword [rel request+NEBOC_INDEX_OPERATION_OFFSET],NEBOC_INDEX_OP_FILTER
 mov qword [rel request+NEBOC_INDEX_NAME_QUERY_OFFSET],0x42
 mov qword [rel request+NEBOC_INDEX_RESULT_ENTRIES_OFFSET],2
 lea rdi,[rel request]
 lea rsi,[rel result_a]
 call neboc_index_filter
 test eax,eax
 jnz fail
 cmp qword [rel result_a+NEBOC_INDEX_OUTPUT_MATCHES_OFFSET],2
 jne fail

 ; A stale revision is rejected without publishing any partial result.
 call reset_request
 call fill_sentinel
 mov qword [rel request+NEBOC_INDEX_OPERATION_OFFSET],NEBOC_INDEX_OP_NEW
 mov qword [rel request+NEBOC_INDEX_STALE_OFFSET],1
 lea rdi,[rel request]
 lea rsi,[rel result_b]
 call neboc_symbol_index_new
 cmp eax,NEBOC_INDEX_STATUS_POLICY
 jne fail
 call check_sentinel
 test eax,eax
 jnz fail

 ; Count disagreement is a causal mismatch, also failure-atomic.
 call reset_request
 call fill_sentinel
 mov qword [rel request+NEBOC_INDEX_OPERATION_OFFSET],NEBOC_INDEX_OP_NEW
 mov qword [rel request+NEBOC_INDEX_TOTAL_ENTRIES_OFFSET],9
 lea rdi,[rel request]
 lea rsi,[rel result_b]
 call neboc_symbol_index_new
 cmp eax,NEBOC_INDEX_STATUS_MISMATCH
 jne fail
 call check_sentinel
 test eax,eax
 jnz fail

 ; Incremental state must be byte-equivalent to the cold rebuild.
 call reset_request
 call fill_sentinel
 mov qword [rel request+NEBOC_INDEX_OPERATION_OFFSET],NEBOC_INDEX_OP_INCREMENTAL
 mov qword [rel request+NEBOC_INDEX_INCREMENTAL_DIGEST_OFFSET],0x98
 lea rdi,[rel request]
 lea rsi,[rel result_b]
 call neboc_index_update
 cmp eax,NEBOC_INDEX_STATUS_MISMATCH
 jne fail
 call check_sentinel
 test eax,eax
 jnz fail

 ; Memory budgets and malformed facts fail before result publication.
 call reset_request
 call fill_sentinel
 mov qword [rel request+NEBOC_INDEX_OPERATION_OFFSET],NEBOC_INDEX_OP_CACHE
 mov qword [rel request+NEBOC_INDEX_MEMORY_BYTES_OFFSET],8193
 lea rdi,[rel request]
 lea rsi,[rel result_b]
 call neboc_index_cache
 cmp eax,NEBOC_INDEX_STATUS_LIMIT
 jne fail
 call check_sentinel
 test eax,eax
 jnz fail

 call reset_request
 call fill_sentinel
 mov qword [rel request+NEBOC_INDEX_OPERATION_OFFSET],NEBOC_INDEX_OP_SOURCE
 mov qword [rel request+NEBOC_INDEX_MALFORMED_OFFSET],1
 lea rdi,[rel request]
 lea rsi,[rel result_b]
 call neboc_index_source
 cmp eax,NEBOC_INDEX_STATUS_CONTRACT
 jne fail
 call check_sentinel
 test eax,eax
 jnz fail

 xor edi,edi
 jmp exit
fail:
 mov edi,1
exit:
 mov eax,60
 syscall

reset_request:
 lea rsi,[rel base_request]
 lea rdi,[rel request]
 mov ecx,NEBOC_INDEX_REQUEST_QWORDS
 rep movsq
 lea rdi,[rel result_a]
 mov ecx,8
 xor eax,eax
 rep stosq
 ret

fill_sentinel:
 lea rdi,[rel result_b]
 mov ecx,8
 mov rax,SENTINEL
 rep stosq
 ret

check_sentinel:
 lea rsi,[rel result_b]
 mov ecx,8
 mov rax,SENTINEL
.loop:
 cmp [rsi],rax
 jne .bad
 add rsi,8
 loop .loop
 xor eax,eax
 ret
.bad:
 mov eax,1
 ret

section .rodata
align 8
base_request:
 dq NEBOC_INDEX_MAGIC,NEBOC_INDEX_VERSION,NEBOC_INDEX_OP_NEW,ALL_FLAGS
 dq 0x11,77
 dq 5,1,2,8
 dq 7,1,6
 dq 0,0,0,256
 dq 0x22,1,0x33,0x44
 dq 1,1,1,1
 dq 0x99,0x99
 dq 4096,8192
 dq 4,4,1
 dq 1000,1,0,0

section .bss
align 8
request: resq NEBOC_INDEX_REQUEST_QWORDS
result_a: resq 8
result_b: resq 8
section .note.GNU-stack noalloc noexec nowrite progbits
