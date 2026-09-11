; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-PF002 isolated Option/Result syntax/API/diagnostics contract tests
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/option_result_api_contract.inc"
extern neboc_option_result_api_contract
extern neboc_host_process_exit
%macro CASE 13
 dq %1,%2,%3,%4,%5,%6,%7,%8,%9,%10,%11,%12,%13
%endmacro
section .rodata
subject: db "subject"
subject_len equ $-subject
section .data align=8
cases:
 ; op,container,typec,success,error,variant,vargc,observer,obargc,flags,status,ast,diag
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,1,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,NEBOC_VARIANT_SOME,1,0,0,neboc_option_result_null_externo_e_erros_tipados_INPUT_EXACT_SPELLING,NEBOC_STATUS_OK,NEBOC_AST_OPTION_CONSTRUCTOR,0
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,1,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,NEBOC_VARIANT_NONE_VALUE,0,0,0,neboc_option_result_null_externo_e_erros_tipados_INPUT_EXACT_SPELLING,NEBOC_STATUS_OK,NEBOC_AST_OPTION_CONSTRUCTOR,0
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,1,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT,0,NEBOC_VARIANT_SOME,1,0,0,neboc_option_result_null_externo_e_erros_tipados_INPUT_EXACT_SPELLING,NEBOC_STATUS_OK,NEBOC_AST_OPTION_CONSTRUCTOR,0
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,1,neboc_option_result_null_externo_e_erros_tipados_TYPE_CHAR_codegen_scalars_x86_64,0,NEBOC_VARIANT_NONE_VALUE,0,0,0,neboc_option_result_null_externo_e_erros_tipados_INPUT_EXACT_SPELLING,NEBOC_STATUS_OK,NEBOC_AST_OPTION_CONSTRUCTOR,0
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_RESULT,2,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,NEBOC_VARIANT_OK,1,0,0,neboc_option_result_null_externo_e_erros_tipados_INPUT_EXACT_SPELLING,NEBOC_STATUS_OK,NEBOC_AST_RESULT_CONSTRUCTOR,0
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_RESULT,2,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,NEBOC_VARIANT_ERR,1,0,0,neboc_option_result_null_externo_e_erros_tipados_INPUT_EXACT_SPELLING,NEBOC_STATUS_OK,NEBOC_AST_RESULT_CONSTRUCTOR,0
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_OPTION,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,0,NEBOC_OBSERVER_IS_SOME,0,0,NEBOC_STATUS_OK,NEBOC_AST_OBSERVER_CALL,0
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_OPTION,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,0,NEBOC_OBSERVER_IS_NONE,0,0,NEBOC_STATUS_OK,NEBOC_AST_OBSERVER_CALL,0
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_RESULT,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,0,0,NEBOC_OBSERVER_IS_OK,0,0,NEBOC_STATUS_OK,NEBOC_AST_OBSERVER_CALL,0
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_RESULT,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,0,0,NEBOC_OBSERVER_IS_ERR,0,0,NEBOC_STATUS_OK,NEBOC_AST_OBSERVER_CALL,0
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_OPTION,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,0,NEBOC_OBSERVER_UNWRAP_OR,1,0,NEBOC_STATUS_OK,NEBOC_AST_OBSERVER_CALL,0
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_RESULT,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,0,0,NEBOC_OBSERVER_UNWRAP_OR,1,0,NEBOC_STATUS_OK,NEBOC_AST_OBSERVER_CALL,0
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,NEBOC_VARIANT_SOME,1,0,0,1,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_TYPE_ARITY
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,2,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,NEBOC_VARIANT_SOME,1,0,0,1,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_TYPE_ARITY
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_RESULT,1,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,NEBOC_VARIANT_OK,1,0,0,1,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_TYPE_ARITY
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_RESULT,3,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,NEBOC_VARIANT_OK,1,0,0,1,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_TYPE_ARITY
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,1,NEBOC_TYPE_VOID,0,NEBOC_VARIANT_NONE_VALUE,0,0,0,1,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_VOID_PAYLOAD_FORBIDDEN
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_RESULT,2,neboc_option_result_null_externo_e_erros_tipados_TYPE_TEXT_parser,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,NEBOC_VARIANT_OK,1,0,0,1,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_PAYLOAD_TYPE_UNAVAILABLE
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,1,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,NEBOC_VARIANT_OK,1,0,0,1,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_VARIANT_MISMATCH
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_RESULT,2,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,NEBOC_VARIANT_SOME,1,0,0,1,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_VARIANT_MISMATCH
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,1,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,NEBOC_VARIANT_SOME,0,0,0,1,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_VARIANT_ARITY
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_OPTION,1,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,NEBOC_VARIANT_NONE_VALUE,1,0,0,1,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_VARIANT_ARITY
 CASE NEBOC_OP_CONSTRUCT,NEBOC_CONTAINER_RESULT,2,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64,NEBOC_VARIANT_ERR,0,0,0,1,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_VARIANT_ARITY
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_OPTION,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,0,NEBOC_OBSERVER_IS_OK,0,0,NEBOC_STATUS_INVALID_SOURCE,0,neboc_option_result_null_externo_e_erros_tipados_DIAG_OBSERVER_WRONG_DOMAIN
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_OPTION,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,0,NEBOC_OBSERVER_IS_SOME,1,0,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_OBSERVER_ARITY
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_OPTION,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,0,NEBOC_OBSERVER_UNWRAP_OR,0,0,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_UNWRAP_OR_ARITY
 CASE NEBOC_OP_NULL_LITERAL,0,0,0,0,0,0,0,0,0,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_NULL_FORBIDDEN
 CASE NEBOC_OP_PROPAGATION,0,0,0,0,0,0,0,0,0,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_PROPAGATION_DEFERRED
 CASE NEBOC_OP_TRY_CATCH,0,0,0,0,0,0,0,0,0,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_TRY_CATCH_DEFERRED
 CASE NEBOC_OP_FATAL_UNWRAP,0,0,0,0,0,0,0,0,0,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_FATAL_UNWRAP_DEFERRED
 CASE NEBOC_OP_PATTERN_MATCH,0,0,0,0,0,0,0,0,0,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_PATTERN_MATCH_DEFERRED
 CASE neboc_option_result_null_externo_e_erros_tipados_OP_ALIAS,0,0,0,0,0,0,0,0,0,NEBOC_STATUS_INVALID_SOURCE,0,neboc_option_result_null_externo_e_erros_tipados_DIAG_ALIAS_FORBIDDEN
 CASE NEBOC_OP_CONSTRUCT,99,1,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,NEBOC_VARIANT_SOME,1,0,0,neboc_option_result_null_externo_e_erros_tipados_INPUT_EXACT_SPELLING,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_UNKNOWN_CONTAINER
 CASE NEBOC_OP_OBSERVER,NEBOC_CONTAINER_OPTION,0,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64,0,0,0,99,0,0,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_OBSERVER_UNKNOWN
 CASE NEBOC_OP_GENERAL_GENERIC,0,0,0,0,0,0,0,0,0,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_GENERAL_GENERICS_DEFERRED
case_count equ ($-cases)/(13*8)
section .bss align=16
request: resb neboc_option_result_null_externo_e_erros_tipados_REQUEST_SIZE
first_hash: resq 1
section .text
global _start
_start:
 lea r14,[rel cases]
 mov r15d,case_count
 mov r13d,1
.loop:
 lea rdi,[rel request]
 mov ecx,neboc_option_result_null_externo_e_erros_tipados_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 %assign i 0
 %rep 10
 mov rax,[r14+i*8]
 mov [rel request+i*8],rax
 %assign i i+1
 %endrep
 lea rax,[rel subject]
 mov [rel request+NEBOC_SUBJECT_PTR_OFFSET],rax
 mov qword [rel request+NEBOC_SUBJECT_LENGTH_OFFSET],subject_len
 mov qword [rel request+NEBOC_ABSOLUTE_START_OFFSET],600
 lea rdi,[rel request]
 call neboc_option_result_api_contract
 cmp rax,[r14+10*8]
 jne .fail
 mov rax,[rel request+NEBOC_AST_FORM_OFFSET]
 cmp rax,[r14+11*8]
 jne .fail
 mov rax,[rel request+neboc_option_result_null_externo_e_erros_tipados_DIAGNOSTIC_OFFSET]
 cmp rax,[r14+12*8]
 jne .fail
 cmp qword [r14+10*8],NEBOC_STATUS_OK
 je .span_ok
 cmp qword [rel request+NEBOC_ERROR_START_OFFSET],600
 jne .fail
 cmp qword [rel request+NEBOC_ERROR_END_OFFSET],600+subject_len
 jne .fail
 jmp .next
.span_ok:
 cmp qword [rel request+NEBOC_ERROR_START_OFFSET],0
 jne .fail
 cmp qword [rel request+NEBOC_ERROR_END_OFFSET],0
 jne .fail
.next:
 add r14,13*8
 inc r13d
 dec r15d
 jnz .loop
 ; deterministic hash of identical valid request
 lea rdi,[rel request]
 mov ecx,neboc_option_result_null_externo_e_erros_tipados_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov qword [rel request+neboc_option_result_null_externo_e_erros_tipados_OPERATION_OFFSET],NEBOC_OP_CONSTRUCT
 mov qword [rel request+NEBOC_CONTAINER_OFFSET],NEBOC_CONTAINER_OPTION
 mov qword [rel request+NEBOC_TYPE_ARG_COUNT_OFFSET],1
 mov qword [rel request+NEBOC_SUCCESS_TYPE_OFFSET],neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64
 mov qword [rel request+NEBOC_VARIANT_OFFSET],NEBOC_VARIANT_SOME
 mov qword [rel request+NEBOC_VARIANT_ARG_COUNT_OFFSET],1
 mov qword [rel request+NEBOC_INPUT_FLAGS_OFFSET],neboc_option_result_null_externo_e_erros_tipados_INPUT_EXACT_SPELLING
 lea rax,[rel subject]
 mov [rel request+NEBOC_SUBJECT_PTR_OFFSET],rax
 mov qword [rel request+NEBOC_SUBJECT_LENGTH_OFFSET],subject_len
 lea rdi,[rel request]
 call neboc_option_result_api_contract
 test eax,eax
 jnz .fail
 mov rax,[rel request+NEBOC_HASH_OFFSET]
 mov [rel first_hash],rax
 lea rdi,[rel request]
 call neboc_option_result_api_contract
 test eax,eax
 jnz .fail
 mov rax,[rel first_hash]
 cmp rax,[rel request+NEBOC_HASH_OFFSET]
 jne .fail
 xor edi,edi
 call neboc_option_result_api_contract
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 jmp neboc_host_process_exit
.fail:
 mov edi,r13d
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
