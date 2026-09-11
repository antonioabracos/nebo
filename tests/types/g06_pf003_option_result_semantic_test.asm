; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-PF003 isolated Option/Result semantic and abstract IR tests
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/option_result_api_contract.inc"
%include "compiler/semantic/types/option_result_semantic.inc"
%include "compiler/lowering/scalars/option_result_ir_contract.inc"
extern neboc_option_result_api_contract
extern neboc_option_result_semantic_analyze
extern neboc_option_result_ir_lower
extern neboc_host_process_exit

%macro CASE 23
 dq %1,%2,%3,%4,%5,%6,%7,%8,%9,%10,%11,%12,%13,%14,%15,%16,%17,%18,%19,%20,%21,%22,%23
%endmacro
section .rodata
subject: db "OptionResultSemantic"
subject_len equ $-subject
cases:
 ; op,container,typeargc,success,error,variant,varargc,observer,obsargc,apiflags, semcontainer,semsuccess,semerror,value,fallback,semflags, api_status,sem_status,sem_error,hir,lir,result_kind,failure
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,1,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,NEBOC_VARIANT_SOME,1,0,0,neboc_option_result_null_externo_e_erros_tipados_INPUT_EXACT_SPELLING, NEBOC_CONTAINER_OPTION,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,NEBOC_SEM_INPUT_CONTEXT_VALID|NEBOC_SEM_INPUT_VALUE_PRESENT, 0,0,0,NEBOC_SEM_HIR_OPTION_SOME,NEBOC_SEM_LIR_TAGGED_CONSTRUCT,NEBOC_SEM_RESULT_CONTAINER_TYPE,NEBOC_SEM_FAILURE_NONE
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,1,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,NEBOC_VARIANT_NONE_VALUE,0,0,0,neboc_option_result_null_externo_e_erros_tipados_INPUT_EXACT_SPELLING, NEBOC_CONTAINER_OPTION,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,0,NEBOC_SEM_INPUT_CONTEXT_VALID, 0,0,0,NEBOC_SEM_HIR_OPTION_NONE,NEBOC_SEM_LIR_TAGGED_CONSTRUCT,NEBOC_SEM_RESULT_CONTAINER_TYPE,NEBOC_SEM_FAILURE_ABSENCE_VALUE
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,1,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,0,NEBOC_VARIANT_SOME,1,0,0,neboc_option_result_null_externo_e_erros_tipados_INPUT_EXACT_SPELLING, NEBOC_CONTAINER_OPTION,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,0,3, 0,0,0,NEBOC_SEM_HIR_OPTION_SOME,1,1,0
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,1,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT,0,NEBOC_VARIANT_SOME,1,0,0,1, NEBOC_CONTAINER_OPTION,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT,0,3, 0,0,0,1,1,1,0
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,1,neboc_option_result_null_externo_e_erros_tipados_TYPE_CHAR_codegen_scalars_x86_64,0,NEBOC_VARIANT_NONE_VALUE,0,0,0,1, NEBOC_CONTAINER_OPTION,neboc_option_result_null_externo_e_erros_tipados_TYPE_CHAR_codegen_scalars_x86_64,0,0,0,1, 0,0,0,2,1,1,1
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_RESULT,2,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,NEBOC_VARIANT_OK,1,0,0,1, NEBOC_CONTAINER_RESULT,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,3, 0,0,0,3,1,1,0
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_RESULT,2,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,NEBOC_VARIANT_ERR,1,0,0,1, NEBOC_CONTAINER_RESULT,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,0,3, 0,0,0,4,1,1,2
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_RESULT,2,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT,neboc_option_result_null_externo_e_erros_tipados_TYPE_CHAR_codegen_scalars_x86_64,NEBOC_VARIANT_OK,1,0,0,1, NEBOC_CONTAINER_RESULT,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT,neboc_option_result_null_externo_e_erros_tipados_TYPE_CHAR_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT,0,3, 0,0,0,3,1,1,0
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_OPTION,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,0,NEBOC_OBSERVER_IS_SOME,0,0, NEBOC_CONTAINER_OPTION,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,0,1, 0,0,0,5,2,2,0
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_OPTION,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,0,NEBOC_OBSERVER_IS_NONE,0,0, NEBOC_CONTAINER_OPTION,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,0,1, 0,0,0,5,2,2,0
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_RESULT,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,0,0,NEBOC_OBSERVER_IS_OK,0,0, NEBOC_CONTAINER_RESULT,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,0,0,1, 0,0,0,6,2,2,0
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_RESULT,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,0,0,NEBOC_OBSERVER_IS_ERR,0,0, NEBOC_CONTAINER_RESULT,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,0,0,1, 0,0,0,6,2,2,0
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_OPTION,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,0,NEBOC_OBSERVER_UNWRAP_OR,1,0, NEBOC_CONTAINER_OPTION,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,5, 0,0,0,7,3,3,0
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_RESULT,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,0,0,NEBOC_OBSERVER_UNWRAP_OR,1,0, NEBOC_CONTAINER_RESULT,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,5, 0,0,0,7,3,3,0
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_OPTION,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT,0,0,0,NEBOC_OBSERVER_UNWRAP_OR,1,0, NEBOC_CONTAINER_OPTION,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT,0,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT,5, 0,0,0,7,3,3,0
 ; duplicate of case 1 with distinct provenance: semantic/type/IR hashes must match case 1.
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,1,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,NEBOC_VARIANT_SOME,1,0,0,1, NEBOC_CONTAINER_OPTION,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,3, 0,0,0,1,1,1,0
 ; semantic failures after successful PF002 contract
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,1,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,NEBOC_VARIANT_SOME,1,0,0,1, NEBOC_CONTAINER_OPTION,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,0,3, 0,4,3,0,0,0,0
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,1,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,NEBOC_VARIANT_NONE_VALUE,0,0,0,1, NEBOC_CONTAINER_OPTION,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,3, 0,4,5,0,0,0,0
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,1,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,NEBOC_VARIANT_NONE_VALUE,0,0,0,1, NEBOC_CONTAINER_OPTION,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,0,0, 0,4,8,0,0,0,0
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_RESULT,2,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,NEBOC_VARIANT_OK,1,0,0,1, NEBOC_CONTAINER_RESULT,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,0,3, 0,4,3,0,0,0,0
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_RESULT,2,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,NEBOC_VARIANT_ERR,1,0,0,1, NEBOC_CONTAINER_RESULT,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,3, 0,4,3,0,0,0,0
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_RESULT,2,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,NEBOC_VARIANT_OK,1,0,0,1, NEBOC_CONTAINER_RESULT,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,3, 0,4,2,0,0,0,0
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,1,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,NEBOC_VARIANT_SOME,1,0,0,1, NEBOC_CONTAINER_OPTION,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,3, 0,4,2,0,0,0,0
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_OPTION,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,0,NEBOC_OBSERVER_UNWRAP_OR,1,0, NEBOC_CONTAINER_OPTION,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,5, 0,4,4,0,0,0,0
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_OPTION,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,0,NEBOC_OBSERVER_UNWRAP_OR,1,0, NEBOC_CONTAINER_OPTION,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,0,1, 0,4,4,0,0,0,0
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_RESULT,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,0,0,NEBOC_OBSERVER_UNWRAP_OR,1,0, NEBOC_CONTAINER_RESULT,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_CHAR_codegen_scalars_x86_64,5, 0,4,4,0,0,0,0
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_OPTION,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,0,NEBOC_OBSERVER_IS_SOME,0,0, NEBOC_CONTAINER_RESULT,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,0,0,1, 0,4,2,0,0,0,0
 ; observer structural-context failures: Option carries no error type; Result requires a scalar error type
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_OPTION,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,0,NEBOC_OBSERVER_UNWRAP_OR,1,0, NEBOC_CONTAINER_OPTION,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,5, 0,4,2,0,0,0,0
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_RESULT,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,0,0,NEBOC_OBSERVER_UNWRAP_OR,1,0, NEBOC_CONTAINER_RESULT,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_TEXT_parser,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,5, 0,4,2,0,0,0,0
 ; PF002 source diagnostic propagation
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,1,neboc_option_result_null_externo_e_erros_tipados_TYPE_TEXT_parser,0,NEBOC_VARIANT_SOME,1,0,0,1, NEBOC_CONTAINER_OPTION,neboc_option_result_null_externo_e_erros_tipados_TYPE_TEXT_parser,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_TEXT_parser,0,3, 4,4,1,0,0,0,0
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_OPTION,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,0,NEBOC_OBSERVER_IS_OK,0,0, NEBOC_CONTAINER_OPTION,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,0,1, 4,4,1,0,0,0,0
 ; semantic span and flag invariants
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,1,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,NEBOC_VARIANT_SOME,1,0,0,1, NEBOC_CONTAINER_OPTION,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,3, 0,4,6,0,0,0,0
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,1,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,NEBOC_VARIANT_SOME,1,0,0,1, NEBOC_CONTAINER_OPTION,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,11, 0,4,5,0,0,0,0
 CASE NEBOC_OP_NULL_LITERAL,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0, 4,4,1,0,0,0,0
case_count equ ($-cases)/(23*8)
section .bss align=16
api: resb neboc_option_result_null_externo_e_erros_tipados_REQUEST_SIZE
sem: resb neboc_option_result_null_externo_e_erros_tipados_SEM_REQUEST_SIZE
ir: resb neboc_option_result_null_externo_e_erros_tipados_IR_REQUEST_SIZE
saved_sem_hash: resq 1
saved_prov_hash: resq 1
saved_type_hash: resq 1
saved_ir_hash: resq 1
option_int_type_hash: resq 1
result_int_bool_type_hash: resq 1
section .text
global _start
_start:
 lea r14,[rel cases]
 mov r15d,case_count
 mov r13d,1
.loop:
 lea rdi,[rel api]
 mov ecx,neboc_option_result_null_externo_e_erros_tipados_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 %assign i 0
 %rep 10
 mov rax,[r14+i*8]
 mov [rel api+i*8],rax
 %assign i i+1
 %endrep
 lea rax,[rel subject]
 mov [rel api+NEBOC_SUBJECT_PTR_OFFSET],rax
 mov qword [rel api+NEBOC_SUBJECT_LENGTH_OFFSET],subject_len
 mov qword [rel api+NEBOC_ABSOLUTE_START_OFFSET],700
 lea rdi,[rel api]
 call neboc_option_result_api_contract
 cmp rax,[r14+16*8]
 jne .fail
 lea rdi,[rel sem]
 mov ecx,neboc_option_result_null_externo_e_erros_tipados_SEM_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rel api]
 mov [rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_API_REQUEST_OFFSET],rax
 mov rax,[r14+10*8]
 mov [rel sem+NEBOC_SEM_CONTAINER_OFFSET],rax
 mov rax,[r14+11*8]
 mov [rel sem+NEBOC_SEM_SUCCESS_TYPE_OFFSET],rax
 mov rax,[r14+12*8]
 mov [rel sem+NEBOC_SEM_ERROR_TYPE_OFFSET],rax
 mov rax,[r14+13*8]
 mov [rel sem+NEBOC_SEM_VALUE_TYPE_OFFSET],rax
 mov rax,[r14+14*8]
 mov [rel sem+NEBOC_SEM_FALLBACK_TYPE_OFFSET],rax
 mov [rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_SOURCE_ID_OFFSET],r13
 mov qword [rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_NODE_START_OFFSET],690
 mov qword [rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_NODE_END_OFFSET],730
 mov qword [rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_SUBJECT_START_OFFSET],700
 mov qword [rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_SUBJECT_END_OFFSET],700+subject_len
 mov rax,[r14+15*8]
 mov [rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_INPUT_FLAGS_OFFSET],rax
 cmp r13d,32
 jne .span_ready
 mov qword [rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_NODE_END_OFFSET],690
.span_ready:
 lea rdi,[rel sem]
 call neboc_option_result_semantic_analyze
 cmp rax,[r14+17*8]
 jne .fail
 mov rax,[rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_ERROR_CODE_OFFSET]
 cmp rax,[r14+18*8]
 jne .fail
 cmp qword [r14+17*8],0
 jne .error_assert
 mov rax,[rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_HIR_KIND_OFFSET]
 cmp rax,[r14+19*8]
 jne .fail
 mov rax,[rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_LIR_KIND_OFFSET]
 cmp rax,[r14+20*8]
 jne .fail
 mov rax,[rel sem+NEBOC_SEM_RESULT_TYPE_KIND_OFFSET]
 cmp rax,[r14+21*8]
 jne .fail
 mov rax,[rel sem+NEBOC_SEM_FAILURE_EDGE_OFFSET]
 cmp rax,[r14+22*8]
 jne .fail
 cmp qword [rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_RUNTIME_METADATA_OFFSET],0
 jne .fail
 cmp qword [rel sem+NEBOC_SEM_LAYOUT_STATE_OFFSET],NEBOC_SEM_LAYOUT_DEFERRED_PF004
 jne .fail
 cmp qword [rel sem+NEBOC_SEM_TYPE_IDENTITY_HASH_OFFSET],0
 je .fail
 lea rdi,[rel ir]
 mov ecx,neboc_option_result_null_externo_e_erros_tipados_IR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rel sem]
 mov [rel ir+neboc_option_result_null_externo_e_erros_tipados_IR_SEMANTIC_REQUEST_OFFSET],rax
 lea rdi,[rel ir]
 call neboc_option_result_ir_lower
 test eax,eax
 jnz .fail
 mov rax,[rel ir+neboc_option_result_null_externo_e_erros_tipados_IR_HIR_KIND_OFFSET]
 cmp rax,[r14+19*8]
 jne .fail
 mov rax,[rel ir+neboc_option_result_null_externo_e_erros_tipados_IR_LIR_KIND_OFFSET]
 cmp rax,[r14+20*8]
 jne .fail
 cmp qword [rel ir+NEBOC_IR_LAYOUT_STATE_OFFSET],NEBOC_SEM_LAYOUT_DEFERRED_PF004
 jne .fail
 cmp r13d,1
 jne .case3
 mov rax,[rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_SEMANTIC_HASH_OFFSET]
 mov [rel saved_sem_hash],rax
 mov rax,[rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_PROVENANCE_HASH_OFFSET]
 mov [rel saved_prov_hash],rax
 mov rax,[rel sem+NEBOC_SEM_TYPE_IDENTITY_HASH_OFFSET]
 mov [rel saved_type_hash],rax
 mov [rel option_int_type_hash],rax
 mov rax,[rel ir+neboc_option_result_null_externo_e_erros_tipados_IR_HASH_OFFSET]
 mov [rel saved_ir_hash],rax
 jmp .next
.case3:
 cmp r13d,3
 jne .case6
 mov rax,[rel option_int_type_hash]
 cmp rax,[rel sem+NEBOC_SEM_TYPE_IDENTITY_HASH_OFFSET]
 je .fail
 jmp .next
.case6:
 cmp r13d,6
 jne .case8
 mov rax,[rel sem+NEBOC_SEM_TYPE_IDENTITY_HASH_OFFSET]
 mov [rel result_int_bool_type_hash],rax
 jmp .next
.case8:
 cmp r13d,8
 jne .case16
 mov rax,[rel result_int_bool_type_hash]
 cmp rax,[rel sem+NEBOC_SEM_TYPE_IDENTITY_HASH_OFFSET]
 je .fail
 jmp .next
.case16:
 cmp r13d,16
 jne .next
 mov rax,[rel saved_sem_hash]
 cmp rax,[rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_SEMANTIC_HASH_OFFSET]
 jne .fail
 mov rax,[rel saved_type_hash]
 cmp rax,[rel sem+NEBOC_SEM_TYPE_IDENTITY_HASH_OFFSET]
 jne .fail
 mov rax,[rel saved_ir_hash]
 cmp rax,[rel ir+neboc_option_result_null_externo_e_erros_tipados_IR_HASH_OFFSET]
 jne .fail
 mov rax,[rel saved_prov_hash]
 cmp rax,[rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_PROVENANCE_HASH_OFFSET]
 je .fail
 jmp .next
.error_assert:
 cmp qword [rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_ERROR_START_OFFSET],700
 jne .fail
 cmp qword [rel sem+neboc_option_result_null_externo_e_erros_tipados_SEM_ERROR_END_OFFSET],700+subject_len
 jne .fail
.next:
 add r14,23*8
 inc r13d
 dec r15d
 jnz .loop
 xor edi,edi
 call neboc_option_result_semantic_analyze
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 call neboc_option_result_ir_lower
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 jmp neboc_host_process_exit
.fail:
 mov edi,r13d
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
