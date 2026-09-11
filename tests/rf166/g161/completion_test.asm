; RF166-G161 structured owners, policy checks and failure atomicity.
bits 64
default rel
%include "compiler/lsp/completion.inc"

global _start
extern neboc_completion_context
extern neboc_completion_receiver
extern neboc_completion_members
extern neboc_completion_auto_import
extern neboc_completion_filter
extern neboc_completion_rank
extern neboc_completion_resolve

%define SENTINEL 0xa5a5a5a5a5a5a5a5
%define ALL_FLAGS NEBOC_COMPLETION_FLAG_SNAPSHOT|NEBOC_COMPLETION_FLAG_TYPECHECKED|NEBOC_COMPLETION_FLAG_INDEX|NEBOC_COMPLETION_FLAG_PRIVATE_FILTERED|NEBOC_COMPLETION_FLAG_NO_GRANTS|NEBOC_COMPLETION_FLAG_DETERMINISTIC|NEBOC_COMPLETION_FLAG_ATOMIC|NEBOC_COMPLETION_FLAG_EXPLICIT_EDIT|NEBOC_COMPLETION_FLAG_DOC|NEBOC_COMPLETION_FLAG_RECOVERY

%macro RUN_OK 2
 call reset_request
 mov qword [rel request+NEBOC_COMPLETION_OPERATION_OFFSET],%1
 lea rdi,[rel request]
 lea rsi,[rel result_a]
 call %2
 test eax,eax
 jnz fail
 cmp qword [rel result_a+NEBOC_COMPLETION_OUTPUT_STATUS_OFFSET],0
 jne fail
 cmp qword [rel result_a+NEBOC_COMPLETION_OUTPUT_OPERATION_OFFSET],%1
 jne fail
 cmp qword [rel result_a+NEBOC_COMPLETION_OUTPUT_RECEIVER_TYPE_OFFSET],0x54455854
 jne fail
 cmp qword [rel result_a+NEBOC_COMPLETION_OUTPUT_CANDIDATES_OFFSET],10
 jne fail
 cmp qword [rel result_a+NEBOC_COMPLETION_OUTPUT_ELIGIBLE_OFFSET],6
 jne fail
 cmp qword [rel result_a+NEBOC_COMPLETION_OUTPUT_RANK_DIGEST_OFFSET],0x99
 jne fail
 cmp qword [rel result_a+NEBOC_COMPLETION_OUTPUT_REVISION_OFFSET],77
 jne fail
%endmacro

section .text
_start:
 RUN_OK NEBOC_COMPLETION_OP_CONTEXT,neboc_completion_context
 RUN_OK NEBOC_COMPLETION_OP_RECEIVER,neboc_completion_receiver
 RUN_OK NEBOC_COMPLETION_OP_MEMBERS,neboc_completion_members
 RUN_OK NEBOC_COMPLETION_OP_AUTO_IMPORT,neboc_completion_auto_import
 RUN_OK NEBOC_COMPLETION_OP_FILTER,neboc_completion_filter
 RUN_OK NEBOC_COMPLETION_OP_RANK,neboc_completion_rank
 RUN_OK NEBOC_COMPLETION_OP_RESOLVE,neboc_completion_resolve

 call reset_request
 call fill_sentinel
 mov qword [rel request+NEBOC_COMPLETION_OPERATION_OFFSET],NEBOC_COMPLETION_OP_RECEIVER
 mov qword [rel request+NEBOC_COMPLETION_RECEIVER_EVALUATIONS_OFFSET],2
 lea rdi,[rel request]
 lea rsi,[rel result_b]
 call neboc_completion_receiver
 cmp eax,NEBOC_COMPLETION_STATUS_CONTRACT
 jne fail
 call check_sentinel
 test eax,eax
 jnz fail

 call reset_request
 call fill_sentinel
 mov qword [rel request+NEBOC_COMPLETION_OPERATION_OFFSET],NEBOC_COMPLETION_OP_FILTER
 inc qword [rel request+NEBOC_COMPLETION_PRIVATE_REJECTED_OFFSET]
 lea rdi,[rel request]
 lea rsi,[rel result_b]
 call neboc_completion_filter
 cmp eax,NEBOC_COMPLETION_STATUS_MISMATCH
 jne fail
 call check_sentinel
 test eax,eax
 jnz fail

 call reset_request
 call fill_sentinel
 mov qword [rel request+NEBOC_COMPLETION_OPERATION_OFFSET],NEBOC_COMPLETION_OP_RESOLVE
 mov qword [rel request+NEBOC_COMPLETION_STALE_OFFSET],1
 lea rdi,[rel request]
 lea rsi,[rel result_b]
 call neboc_completion_resolve
 cmp eax,NEBOC_COMPLETION_STATUS_POLICY
 jne fail
 call check_sentinel
 test eax,eax
 jnz fail

 call reset_request
 call fill_sentinel
 mov qword [rel request+NEBOC_COMPLETION_OPERATION_OFFSET],NEBOC_COMPLETION_OP_RESOLVE
 and qword [rel request+NEBOC_COMPLETION_FLAGS_OFFSET],~NEBOC_COMPLETION_FLAG_EXPLICIT_EDIT
 lea rdi,[rel request]
 lea rsi,[rel result_b]
 call neboc_completion_resolve
 cmp eax,NEBOC_COMPLETION_STATUS_POLICY
 jne fail
 call check_sentinel
 test eax,eax
 jnz fail

 call reset_request
 call fill_sentinel
 mov qword [rel request+NEBOC_COMPLETION_OPERATION_OFFSET],NEBOC_COMPLETION_OP_CONTEXT
 mov qword [rel request+NEBOC_COMPLETION_OBSERVED_MS_OFFSET],101
 mov qword [rel request+NEBOC_COMPLETION_DEADLINE_MS_OFFSET],100
 lea rdi,[rel request]
 lea rsi,[rel result_b]
 call neboc_completion_context
 cmp eax,NEBOC_COMPLETION_STATUS_LIMIT
 jne fail
 call check_sentinel
 test eax,eax
 jnz fail

 call reset_request
 call fill_sentinel
 mov qword [rel request+NEBOC_COMPLETION_OPERATION_OFFSET],NEBOC_COMPLETION_OP_MEMBERS
 mov qword [rel request+NEBOC_COMPLETION_MEMORY_BYTES_OFFSET],8193
 mov qword [rel request+NEBOC_COMPLETION_MEMORY_BUDGET_OFFSET],8192
 lea rdi,[rel request]
 lea rsi,[rel result_b]
 call neboc_completion_members
 cmp eax,NEBOC_COMPLETION_STATUS_LIMIT
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
 mov ecx,NEBOC_COMPLETION_REQUEST_QWORDS
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
 dq NEBOC_COMPLETION_MAGIC,NEBOC_COMPLETION_VERSION,NEBOC_COMPLETION_OP_CONTEXT,ALL_FLAGS
 dq 0x11,77,19,128
 dq 0x54455854,0x33,10
 dq 3,1,2,4,2,10,6
 dq 1,1,1,1,0,0
 dq 0x99,0x7001,0x8001,0x9001
 dq 4096,8192,100,1,1,0,0,0

section .bss
align 8
request: resq NEBOC_COMPLETION_REQUEST_QWORDS
result_a: resq 8
result_b: resq 8
section .note.GNU-stack noalloc noexec nowrite progbits
