; SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-F02 semantic, six-register ABI and pointerless-plan vectors.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/parameters_parser.inc"
%include "compiler/lowering/functions/parameters_plan.inc"

extern neboc_parameters_analyze
extern neboc_parameters_lower
extern neboc_host_process_exit

section .bss align=16
request: resb NEBOC_PARAM_REQUEST_SIZE
records: resb NEBOC_PARAM_MAX*NEBOC_PARAM_RECORD_SIZE
plan: resb neboc_seguranca_numerica_conversoes_e_overflow_PLAN_SIZE

section .text
global _start

reset:
 lea rdi,[rel request]
 mov ecx,NEBOC_PARAM_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel records]
 mov ecx,(NEBOC_PARAM_MAX*NEBOC_PARAM_RECORD_SIZE)/8
 xor eax,eax
 rep stosq
 lea rdi,[rel plan]
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_PLAN_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel records]
 mov [rel request+NEBOC_PARAM_RECORDS_OFFSET],rax
 mov qword [rel request+NEBOC_PARAM_CAPACITY_OFFSET],NEBOC_PARAM_MAX
 mov qword [rel request+NEBOC_PARAM_FOUND_OFFSET],1
 mov qword [rel request+NEBOC_PARAM_VARIADIC_INDEX_OFFSET],-1
 mov qword [rel request+NEBOC_PARAM_RECEIVER_TYPE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_TYPE_INT
 mov qword [rel request+NEBOC_PARAM_FUNCTION_NAME_OFFSET],7
 mov qword [rel request+NEBOC_PARAM_COUNT_OFFSET],2
 mov qword [rel request+NEBOC_PARAM_REQUIRED_COUNT_OFFSET],1
 mov qword [rel request+NEBOC_PARAM_EXPLICIT_COUNT_OFFSET],1
 mov qword [rel request+NEBOC_PARAM_DEFAULT_COUNT_OFFSET],1
 mov qword [rel request+NEBOC_PARAM_NAMED_COUNT_OFFSET],1
 mov qword [rel request+NEBOC_PARAM_RETURN_ARITY_OFFSET],1
 mov qword [rel request+NEBOC_PARAM_OUTPUT_TYPE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_TYPE_INT
 mov qword [rel request+NEBOC_PARAM_OUTPUT_VALUE_OFFSET],42
 mov qword [rel records+NEBOC_PARAM_NAME_OFFSET],11
 mov qword [rel records+NEBOC_PARAM_TYPE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_TYPE_INT
 mov qword [rel records+NEBOC_PARAM_BOUND_OFFSET],1
 mov qword [rel records+NEBOC_PARAM_BOUND_VALUE_OFFSET],3
 mov qword [rel records+NEBOC_PARAM_RECORD_SIZE+NEBOC_PARAM_NAME_OFFSET],13
 mov qword [rel records+NEBOC_PARAM_RECORD_SIZE+NEBOC_PARAM_TYPE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_TYPE_INT
 mov qword [rel records+NEBOC_PARAM_RECORD_SIZE+NEBOC_PARAM_HAS_DEFAULT_OFFSET],1
 mov qword [rel records+NEBOC_PARAM_RECORD_SIZE+NEBOC_PARAM_DEFAULT_VALUE_OFFSET],2
 mov qword [rel records+NEBOC_PARAM_RECORD_SIZE+NEBOC_PARAM_BOUND_OFFSET],1
 mov qword [rel records+NEBOC_PARAM_RECORD_SIZE+NEBOC_PARAM_BOUND_VALUE_OFFSET],2
 ret

analyze:
 lea rdi,[rel request]
 jmp neboc_parameters_analyze

lower:
 lea rdi,[rel request]
 lea rsi,[rel plan]
 jmp neboc_parameters_lower

_start:
 ; V01: required/default/named facts authenticate a valid bounded call.
 call reset
 call analyze
 test eax,eax
 jnz .fail1
 mov r12,[rel request+NEBOC_PARAM_SEMANTIC_HASH_OFFSET]
 test r12,r12
 jz .fail1
 mov r13,[rel request+NEBOC_PARAM_ABI_HASH_OFFSET]
 test r13,r13
 jz .fail1

 ; V02: identical semantic facts reproduce both hashes exactly.
 call analyze
 test eax,eax
 jnz .fail2
 cmp r12,[rel request+NEBOC_PARAM_SEMANTIC_HASH_OFFSET]
 jne .fail2
 cmp r13,[rel request+NEBOC_PARAM_ABI_HASH_OFFSET]
 jne .fail2

 ; V03: a parameter type changes the logical ABI identity.
 mov qword [rel records+NEBOC_PARAM_RECORD_SIZE+NEBOC_PARAM_TYPE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_TYPE_BOOL
 call analyze
 test eax,eax
 jnz .fail3
 cmp r13,[rel request+NEBOC_PARAM_ABI_HASH_OFFSET]
 je .fail3

 ; V04: receiver plus five parameters is the exact six-register ceiling.
 call reset
 mov qword [rel request+NEBOC_PARAM_COUNT_OFFSET],5
 mov qword [rel request+NEBOC_PARAM_REQUIRED_COUNT_OFFSET],5
 mov qword [rel request+NEBOC_PARAM_EXPLICIT_COUNT_OFFSET],5
 mov qword [rel request+NEBOC_PARAM_DEFAULT_COUNT_OFFSET],0
 mov qword [rel request+NEBOC_PARAM_NAMED_COUNT_OFFSET],0
 mov qword [rel request+NEBOC_PARAM_RETURN_ARITY_OFFSET],5
 mov qword [rel records+NEBOC_PARAM_RECORD_SIZE+NEBOC_PARAM_HAS_DEFAULT_OFFSET],0
 lea rdi,[rel records]
 mov ecx,5
.v04_records:
 mov qword [rdi+NEBOC_PARAM_TYPE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_TYPE_INT
 mov qword [rdi+NEBOC_PARAM_BOUND_OFFSET],1
 add rdi,NEBOC_PARAM_RECORD_SIZE
 loop .v04_records
 call analyze
 test eax,eax
 jnz .fail4

 ; V05: a required parameter after a default is rejected.
 call reset
 mov qword [rel records+NEBOC_PARAM_HAS_DEFAULT_OFFSET],1
 mov qword [rel records+NEBOC_PARAM_RECORD_SIZE+NEBOC_PARAM_HAS_DEFAULT_OFFSET],0
 call analyze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail5

 ; V06: every canonical parameter must be bound before semantic publication.
 call reset
 mov qword [rel records+NEBOC_PARAM_BOUND_OFFSET],0
 call analyze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail6

 ; V07: more than five explicit parameters reports the frozen ABI boundary.
 call reset
 mov qword [rel request+NEBOC_PARAM_COUNT_OFFSET],6
 call analyze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail7
 cmp qword [rel request+NEBOC_PARAM_DIAGNOSTIC_OFFSET],NEBOC_DIAG_ABI_BOUND
 jne .fail7

 ; V08: explicit plus defaulted arguments must cover the canonical parameter set.
 call reset
 mov qword [rel request+NEBOC_PARAM_DEFAULT_COUNT_OFFSET],0
 call analyze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail8

 ; V09: valid semantics lower to a non-pointer plan with authenticated ABI.
 call reset
 call analyze
 test eax,eax
 jnz .fail9
 call lower
 test eax,eax
 jnz .fail9
 mov rax,neboc_seguranca_numerica_conversoes_e_overflow_PLAN_MAGIC
 cmp [rel plan+neboc_seguranca_numerica_conversoes_e_overflow_PLAN_MAGIC_OFFSET],rax
 jne .fail9
 mov rax,NEBOC_ABI_PROFILE_ID
 cmp [rel plan+NEBOC_PLAN_PROFILE_OFFSET],rax
 jne .fail9
 cmp qword [rel plan+NEBOC_PLAN_OUTPUT_VALUE_OFFSET],42
 jne .fail9
 cmp qword [rel plan+neboc_seguranca_numerica_conversoes_e_overflow_PLAN_HASH_OFFSET],0
 je .fail9

 ; V10: a missing semantic authenticator never lowers.
 mov qword [rel request+NEBOC_PARAM_SEMANTIC_HASH_OFFSET],0
 call lower
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail10

 ; V11: a forged output type never reaches code generation.
 call reset
 call analyze
 test eax,eax
 jnz .fail11
 mov qword [rel request+NEBOC_PARAM_OUTPUT_TYPE_OFFSET],4
 call lower
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail11

 ; V12: explicit ownership and a three-word variadic pack survive semantic
 ; authentication and pointerless lowering without pointer identity.
 call reset
 mov qword [rel request+NEBOC_PARAM_COUNT_OFFSET],3
 mov qword [rel request+NEBOC_PARAM_REQUIRED_COUNT_OFFSET],1
 mov qword [rel request+NEBOC_PARAM_EXPLICIT_COUNT_OFFSET],2
 mov qword [rel request+NEBOC_PARAM_DEFAULT_COUNT_OFFSET],1
 mov qword [rel request+NEBOC_PARAM_BORROW_MASK_OFFSET],1
 mov qword [rel request+NEBOC_PARAM_OWNED_MASK_OFFSET],2
 mov qword [rel request+NEBOC_PARAM_VARIADIC_INDEX_OFFSET],2
 mov qword [rel request+NEBOC_PARAM_VARIADIC_COUNT_OFFSET],3
 mov qword [rel request+NEBOC_PARAM_VARIADIC_VALUES_OFFSET],7
 mov qword [rel request+NEBOC_PARAM_VARIADIC_VALUES_OFFSET+8],11
 mov qword [rel request+NEBOC_PARAM_VARIADIC_VALUES_OFFSET+16],13
 mov qword [rel records+NEBOC_PARAM_OWNERSHIP_OFFSET],NEBOC_PARAM_OWNERSHIP_BORROWED
 mov qword [rel records+NEBOC_PARAM_RECORD_SIZE+NEBOC_PARAM_OWNERSHIP_OFFSET],NEBOC_PARAM_OWNERSHIP_OWNED
 mov qword [rel records+2*NEBOC_PARAM_RECORD_SIZE+NEBOC_PARAM_TYPE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_TYPE_INT
 mov qword [rel records+2*NEBOC_PARAM_RECORD_SIZE+NEBOC_PARAM_BOUND_OFFSET],1
 mov qword [rel records+2*NEBOC_PARAM_RECORD_SIZE+NEBOC_PARAM_FLAGS_OFFSET],NEBOC_PARAM_FLAG_VARIADIC
 call analyze
 test eax,eax
 jnz .fail12
 call lower
 test eax,eax
 jnz .fail12
 cmp qword [rel plan+NEBOC_PLAN_BORROW_MASK_OFFSET],1
 jne .fail12
 cmp qword [rel plan+NEBOC_PLAN_OWNED_MASK_OFFSET],2
 jne .fail12
 cmp qword [rel plan+NEBOC_PLAN_VARIADIC_COUNT_OFFSET],3
 jne .fail12
 cmp qword [rel plan+NEBOC_PLAN_VARIADIC_VALUES_OFFSET+16],13
 jne .fail12

 ; V13: ownership masks cannot be forged independently of parameter records.
 mov qword [rel request+NEBOC_PARAM_BORROW_MASK_OFFSET],0
 call analyze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail13

 ; V14: a mask bit on an implicit parameter is also a forged ownership fact.
 call reset
 mov qword [rel request+NEBOC_PARAM_BORROW_MASK_OFFSET],2
 call analyze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail14

 ; V15: semantic publication independently enforces a trailing variadic pack.
 call reset
 mov qword [rel request+NEBOC_PARAM_VARIADIC_INDEX_OFFSET],0
 mov qword [rel records+NEBOC_PARAM_FLAGS_OFFSET],NEBOC_PARAM_FLAG_VARIADIC
 call analyze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail15

 ; V16: payload words cannot exist without a declared variadic parameter.
 call reset
 mov qword [rel request+NEBOC_PARAM_VARIADIC_COUNT_OFFSET],1
 mov qword [rel request+NEBOC_PARAM_VARIADIC_VALUES_OFFSET],9
 call analyze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail16

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
.fail12: mov edi,12
 jmp neboc_host_process_exit
.fail13: mov edi,13
 jmp neboc_host_process_exit
.fail14: mov edi,14
 jmp neboc_host_process_exit
.fail15: mov edi,15
 jmp neboc_host_process_exit
.fail16: mov edi,16
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
