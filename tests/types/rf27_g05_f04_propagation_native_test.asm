; BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-F04 authenticated typed-propagation and cleanup-proof vectors.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/option_result_parser.inc"
%include "compiler/lowering/scalars/option_result_plan.inc"

extern neboc_result_lower
extern neboc_host_process_exit

section .bss align=16
request: resb NEBOC_RESULT_REQUEST_SIZE
plan: resb NEBOC_RESULT_PLAN_SIZE

section .text
global _start

reset_valid:
 lea rdi,[rel request]
 mov ecx,NEBOC_RESULT_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel plan]
 mov ecx,NEBOC_RESULT_PLAN_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel request+NEBOC_RESULT_FOUND_OFFSET],1
 mov qword [rel request+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],NEBOC_RESULT_TYPE_INT
 mov qword [rel request+NEBOC_RESULT_OUTPUT_VALUE_OFFSET],42
 mov qword [rel request+NEBOC_RESULT_LAYOUT_SIZE_OFFSET],16
 mov qword [rel request+NEBOC_RESULT_LAYOUT_ALIGN_OFFSET],8
 mov qword [rel request+NEBOC_RESULT_DROP_COUNT_OFFSET],2
 mov rax,0x1122334455667788
 mov [rel request+NEBOC_RESULT_SEMANTIC_HASH_OFFSET],rax
 mov qword [rel request+NEBOC_RESULT_ACTIVE_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_RESULT_TAG_OK
 mov qword [rel request+NEBOC_RESULT_PROPAGATION_COUNT_OFFSET],1
 mov qword [rel request+NEBOC_RESULT_CLEANUP_COUNT_OFFSET],2
 mov rax,0x8877665544332211
 mov [rel request+NEBOC_RESULT_CLEANUP_HASH_OFFSET],rax
 mov qword [rel request+NEBOC_RESULT_CONTEXT_OK_TYPE_OFFSET],NEBOC_RESULT_TYPE_INT
 mov qword [rel request+NEBOC_RESULT_CONTEXT_ERR_TYPE_OFFSET],NEBOC_RESULT_TYPE_INT
 mov qword [rel request+NEBOC_RESULT_VALUE_OK_TYPE_OFFSET],NEBOC_RESULT_TYPE_INT
 mov qword [rel request+NEBOC_RESULT_VALUE_ERR_TYPE_OFFSET],NEBOC_RESULT_TYPE_INT
 mov qword [rel request+NEBOC_RESULT_CONTEXT_STATE_OFFSET],NEBOC_RESULT_STATE_DROPPED
 mov qword [rel request+NEBOC_RESULT_GUARD_COUNT_OFFSET],1
 ret

lower:
 lea rdi,[rel request]
 lea rsi,[rel plan]
 jmp neboc_result_lower

expect_rejected:
 call lower
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 ret

_start:
 ; V01: Ok continuation publishes an authenticated pointerless plan.
 call reset_valid
 call lower
 test eax,eax
 jnz .fail1
 mov rax,NEBOC_RESULT_PLAN_MAGIC
 cmp [rel plan+NEBOC_RESULT_PLAN_MAGIC_OFFSET],rax
 jne .fail1
 cmp qword [rel plan+NEBOC_RESULT_PLAN_HASH_OFFSET],0
 je .fail1

 ; V02: Err early return is a valid tag-preserving propagation edge.
 call reset_valid
 mov qword [rel request+NEBOC_RESULT_ACTIVE_TAG_OFFSET],NEBOC_OPTION_RESULT_PLAN_RESULT_TAG_ERR
 mov qword [rel request+NEBOC_RESULT_EARLY_RETURN_OFFSET],1
 call lower
 test eax,eax
 jnz .fail2
 cmp qword [rel plan+NEBOC_RESULT_PLAN_ACTIVE_TAG_OFFSET],NEBOC_OPTION_RESULT_PLAN_RESULT_TAG_ERR
 jne .fail2

 ; V03-V11: malformed propagation or cleanup proof never lowers.
 call reset_valid
 mov qword [rel request+NEBOC_RESULT_PROPAGATION_COUNT_OFFSET],2
 call expect_rejected
 jne .fail3
 call reset_valid
 mov qword [rel request+NEBOC_RESULT_CLEANUP_COUNT_OFFSET],0
 call expect_rejected
 jne .fail4
 call reset_valid
 mov qword [rel request+NEBOC_RESULT_CLEANUP_HASH_OFFSET],0
 call expect_rejected
 jne .fail5
 call reset_valid
 mov qword [rel request+NEBOC_RESULT_CONTEXT_STATE_OFFSET],NEBOC_RESULT_STATE_LIVE
 call expect_rejected
 jne .fail6
 call reset_valid
 mov qword [rel request+NEBOC_RESULT_VALUE_OK_TYPE_OFFSET],NEBOC_RESULT_TYPE_BOOL
 call expect_rejected
 jne .fail7
 call reset_valid
 mov qword [rel request+NEBOC_RESULT_VALUE_ERR_TYPE_OFFSET],NEBOC_RESULT_TYPE_BOOL
 call expect_rejected
 jne .fail8
 call reset_valid
 mov qword [rel request+NEBOC_RESULT_GUARD_COUNT_OFFSET],17
 call expect_rejected
 jne .fail9
 call reset_valid
 mov qword [rel request+NEBOC_RESULT_DROP_COUNT_OFFSET],1
 call expect_rejected
 jne .fail10
 call reset_valid
 mov qword [rel request+NEBOC_RESULT_EARLY_RETURN_OFFSET],2
 call expect_rejected
 jne .fail11

 xor edi,edi
 jmp neboc_host_process_exit
.fail1: mov edi,1
 jmp neboc_host_process_exit
.fail2: mov edi,2
 jmp neboc_host_process_exit
.fail3: mov edi,3
 jmp neboc_host_process_exit
.fail4: mov edi,4
 jmp neboc_host_process_exit
.fail5: mov edi,5
 jmp neboc_host_process_exit
.fail6: mov edi,6
 jmp neboc_host_process_exit
.fail7: mov edi,7
 jmp neboc_host_process_exit
.fail8: mov edi,8
 jmp neboc_host_process_exit
.fail9: mov edi,9
 jmp neboc_host_process_exit
.fail10: mov edi,10
 jmp neboc_host_process_exit
.fail11: mov edi,11
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
