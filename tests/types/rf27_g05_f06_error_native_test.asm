; BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-F06 authenticated structured-Error lowering vectors.
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
 mov qword [rel request+NEBOC_RESULT_OUTPUT_VALUE_OFFSET],101
 mov qword [rel request+NEBOC_RESULT_LAYOUT_SIZE_OFFSET],NEBOC_ERROR_LAYOUT_SIZE
 mov qword [rel request+NEBOC_RESULT_LAYOUT_ALIGN_OFFSET],NEBOC_ERROR_LAYOUT_ALIGN
 mov qword [rel request+NEBOC_RESULT_DROP_COUNT_OFFSET],1
 mov qword [rel request+NEBOC_RESULT_SEMANTIC_HASH_OFFSET],0x12345678
 mov qword [rel request+NEBOC_RESULT_ACTIVE_TAG_OFFSET],NEBOC_OPTION_RESULT_PLAN_RESULT_TAG_ERR
 mov qword [rel request+NEBOC_RESULT_ERROR_COUNT_OFFSET],1
 ret

lower:
 lea rdi,[rel request]
 lea rsi,[rel plan]
 jmp neboc_result_lower

reject:
 call lower
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 ret

_start:
 ; V01-V03: base, maximum context, and maximum cause depth are accepted.
 call reset_valid
 call lower
 test eax,eax
 jnz .fail1
 cmp qword [rel plan+NEBOC_RESULT_PLAN_OUTPUT_VALUE_OFFSET],101
 jne .fail1
 call reset_valid
 mov qword [rel request+NEBOC_RESULT_ERROR_CONTEXT_COUNT_OFFSET],NEBOC_ERROR_MAX_CONTEXT
 call lower
 test eax,eax
 jnz .fail2
 call reset_valid
 mov qword [rel request+NEBOC_RESULT_ERROR_CAUSE_DEPTH_OFFSET],NEBOC_ERROR_MAX_BINDINGS
 call lower
 test eax,eax
 jnz .fail3

 ; V04-V11: malformed bounded Error proofs are rejected by lowering. Bool is
 ; a valid Error observer result (notably cause().isSome()); zero remains an
 ; invalid output type.
 call reset_valid
 mov qword [rel request+NEBOC_RESULT_ERROR_COUNT_OFFSET],NEBOC_ERROR_MAX_BINDINGS+1
 call reject
 jne .fail4
 call reset_valid
 mov qword [rel request+NEBOC_RESULT_ERROR_CONTEXT_COUNT_OFFSET],NEBOC_ERROR_MAX_CONTEXT+1
 call reject
 jne .fail5
 call reset_valid
 mov qword [rel request+NEBOC_RESULT_ERROR_CAUSE_DEPTH_OFFSET],NEBOC_ERROR_MAX_BINDINGS+1
 call reject
 jne .fail6
 call reset_valid
 mov qword [rel request+NEBOC_RESULT_LAYOUT_SIZE_OFFSET],63
 call reject
 jne .fail7
 call reset_valid
 mov qword [rel request+NEBOC_RESULT_LAYOUT_ALIGN_OFFSET],16
 call reject
 jne .fail8
 call reset_valid
 mov qword [rel request+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],NEBOC_RESULT_TYPE_BOOL
 call lower
 test eax,eax
 jnz .fail9
 cmp qword [rel plan+NEBOC_RESULT_PLAN_OUTPUT_TYPE_OFFSET],NEBOC_RESULT_TYPE_BOOL
 jne .fail9
 call reset_valid
 mov qword [rel request+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],0
 call reject
 jne .fail9
 call reset_valid
 mov qword [rel request+NEBOC_RESULT_ACTIVE_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_RESULT_TAG_OK
 call reject
 jne .fail10
 call reset_valid
 mov qword [rel request+NEBOC_RESULT_SEMANTIC_HASH_OFFSET],0
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
