; SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-F04 authenticated callable/capture lowering vectors.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/parameters_parser.inc"
%include "compiler/lowering/functions/parameters_plan.inc"

extern neboc_parameters_lower
extern neboc_host_process_exit

section .bss align=16
request: resb NEBOC_PARAM_REQUEST_SIZE
plan: resb neboc_seguranca_numerica_conversoes_e_overflow_PLAN_SIZE
argument: resb NEBOC_PARAM_RECORD_SIZE

section .text
global _start

reset_valid:
 lea rdi,[rel request]
 mov ecx,NEBOC_PARAM_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel plan]
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_PLAN_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel request+NEBOC_PARAM_FOUND_OFFSET],1
 mov qword [rel request+NEBOC_PARAM_SEMANTIC_HASH_OFFSET],0x1111
 mov qword [rel request+NEBOC_PARAM_ABI_HASH_OFFSET],0x2222
 mov qword [rel request+NEBOC_PARAM_OUTPUT_TYPE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_TYPE_INT
 mov qword [rel request+NEBOC_PARAM_OUTPUT_VALUE_OFFSET],12
 mov qword [rel request+NEBOC_PARAM_COUNT_OFFSET],1
 mov qword [rel request+NEBOC_PARAM_EXPLICIT_COUNT_OFFSET],1
 mov qword [rel request+NEBOC_CALLABLE_COUNT_OFFSET],1
 mov qword [rel request+NEBOC_CALLABLE_CAPTURE_MODE_OFFSET],NEBOC_CAPTURE_COPY
 mov qword [rel request+NEBOC_CALLABLE_CALL_COUNT_OFFSET],1
 mov qword [rel request+NEBOC_CALLABLE_DROP_COUNT_OFFSET],1
 mov qword [rel request+NEBOC_CALLABLE_ENV_SIZE_OFFSET],NEBOC_CALLABLE_ENV_SIZE
 mov qword [rel request+NEBOC_CALLABLE_SELECTED_INDEX_OFFSET],0
 mov qword [rel request+NEBOC_CALLABLE_HASH_OFFSET],0x3333
 mov qword [rel request+NEBOC_CALLABLE_SELECTED_BODY_OFFSET],NEBOC_CALLABLE_BODY_SUM
 mov qword [rel request+NEBOC_CALLABLE_CAPTURE_VALUE_OFFSET],5
 lea rax,[rel argument]
 mov [rel request+NEBOC_PARAM_RECORDS_OFFSET],rax
 mov qword [rel argument+NEBOC_PARAM_TYPE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_TYPE_INT
 mov qword [rel argument+NEBOC_PARAM_BOUND_VALUE_OFFSET],7
 ret

lower:
 lea rdi,[rel request]
 lea rsi,[rel plan]
 jmp neboc_parameters_lower

reject:
 call lower
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 ret

_start:
 ; V01-V03: copy, pointerless direct callable, and lexical borrow lower.
 call reset_valid
 call lower
 test eax,eax
 jnz .fail1
 cmp qword [rel plan+NEBOC_PLAN_CALLABLE_COUNT_OFFSET],1
 jne .fail1
 cmp qword [rel plan+NEBOC_PLAN_CALLABLE_BODY_OFFSET],NEBOC_CALLABLE_BODY_SUM
 jne .fail1
 cmp qword [rel plan+NEBOC_PLAN_CALLABLE_ARGUMENT_VALUE_OFFSET],7
 jne .fail1
 cmp qword [rel plan+NEBOC_PLAN_CALLABLE_CAPTURE_VALUE_OFFSET],5
 jne .fail1
 call reset_valid
 mov qword [rel request+NEBOC_CALLABLE_CAPTURE_MODE_OFFSET],NEBOC_CAPTURE_NONE
 mov qword [rel request+NEBOC_CALLABLE_DROP_COUNT_OFFSET],0
 mov qword [rel request+NEBOC_CALLABLE_ENV_SIZE_OFFSET],0
 mov qword [rel request+NEBOC_CALLABLE_SELECTED_BODY_OFFSET],NEBOC_CALLABLE_BODY_VALUE
 call lower
 test eax,eax
 jnz .fail2
 call reset_valid
 mov qword [rel request+NEBOC_CALLABLE_CAPTURE_MODE_OFFSET],NEBOC_CAPTURE_BORROW
 call lower
 test eax,eax
 jnz .fail3

 ; V04-V11: forged count, selection, capture, cleanup and env are rejected.
 call reset_valid
 mov qword [rel request+NEBOC_CALLABLE_COUNT_OFFSET],NEBOC_CALLABLE_MAX+1
 call reject
 jne .fail4
 call reset_valid
 mov qword [rel request+NEBOC_CALLABLE_SELECTED_INDEX_OFFSET],1
 call reject
 jne .fail5
 call reset_valid
 mov qword [rel request+NEBOC_CALLABLE_CAPTURE_MODE_OFFSET],NEBOC_CAPTURE_BORROW+1
 call reject
 jne .fail6
 call reset_valid
 mov qword [rel request+NEBOC_CALLABLE_CALL_COUNT_OFFSET],0
 call reject
 jne .fail7
 call reset_valid
 mov qword [rel request+NEBOC_CALLABLE_DROP_COUNT_OFFSET],2
 call reject
 jne .fail8
 call reset_valid
 mov qword [rel request+NEBOC_CALLABLE_ENV_SIZE_OFFSET],0
 call reject
 jne .fail9
 call reset_valid
 mov qword [rel request+NEBOC_CALLABLE_CAPTURE_MODE_OFFSET],NEBOC_CAPTURE_BORROW
 mov qword [rel request+NEBOC_CALLABLE_DROP_COUNT_OFFSET],0
 call reject
 jne .fail10
 call reset_valid
 mov qword [rel request+NEBOC_CALLABLE_HASH_OFFSET],0
 call reject
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
