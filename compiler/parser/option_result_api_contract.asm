; Nebo Assembly — OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-PF002 isolated Option/Result syntax/API/diagnostics contract
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/option_result_api_contract.inc"

section .text

scalar_allowed:
 cmp rax,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64
 je .yes
 cmp rax,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64
 je .yes
 cmp rax,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT
 je .yes
 cmp rax,neboc_option_result_null_externo_e_erros_tipados_TYPE_CHAR_codegen_scalars_x86_64
 je .yes
 xor eax,eax
 ret
.yes:
 mov eax,1
 ret

option_result_null_externo_e_erros_tipados_hash:
 mov r8,[rdi+NEBOC_SUBJECT_PTR_OFFSET]
 mov r9,[rdi+NEBOC_SUBJECT_LENGTH_OFFSET]
 mov rax,1469598103934665603
 mov r10,1099511628211
 xor ecx,ecx
.bytes:
 cmp rcx,r9
 jae .fields
 movzx edx,byte [r8+rcx]
 xor rax,rdx
 imul rax,r10
 inc rcx
 jmp .bytes
.fields:
 %assign off 0
 %rep 17
 xor rax,[rdi+off]
 imul rax,r10
 %assign off off+8
 %endrep
 mov [rdi+NEBOC_HASH_OFFSET],rax
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
option_result_null_externo_e_erros_tipados_error:
 mov [rdi+neboc_option_result_null_externo_e_erros_tipados_DIAGNOSTIC_OFFSET],rsi
 mov rax,[rdi+NEBOC_ABSOLUTE_START_OFFSET]
 mov [rdi+NEBOC_ERROR_START_OFFSET],rax
 add rax,[rdi+NEBOC_SUBJECT_LENGTH_OFFSET]
 mov [rdi+NEBOC_ERROR_END_OFFSET],rax
 call option_result_null_externo_e_erros_tipados_hash
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
option_result_null_externo_e_erros_tipados_success:
 call option_result_null_externo_e_erros_tipados_hash
 xor eax,eax
 ret

%undef call
NEBOC_ABI_FUNCTION neboc_option_result_api_contract
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 test r12,r12
 jz .invalid_argument
 mov r13,[r12+NEBOC_SUBJECT_PTR_OFFSET]
 mov r14,[r12+NEBOC_SUBJECT_LENGTH_OFFSET]
 test r13,r13
 jz .invalid_argument
 test r14,r14
 jz .invalid_argument
 lea rdi,[r12+NEBOC_AST_FORM_OFFSET]
 mov ecx,(neboc_option_result_null_externo_e_erros_tipados_REQUEST_SIZE-NEBOC_AST_FORM_OFFSET)/8
 xor eax,eax
 rep stosq
 mov rax,[r12+neboc_option_result_null_externo_e_erros_tipados_OPERATION_OFFSET]
 cmp rax,NEBOC_OP_CONSTRUCT
 je .construct
 cmp rax,NEBOC_OP_OBSERVER
 je .observer
 cmp rax,NEBOC_OP_NULL_LITERAL
 je .null_literal
 cmp rax,NEBOC_OP_PROPAGATION
 je .propagation
 cmp rax,NEBOC_OP_TRY_CATCH
 je .try_catch
 cmp rax,NEBOC_OP_FATAL_UNWRAP
 je .fatal_unwrap
 cmp rax,NEBOC_OP_PATTERN_MATCH
 je .pattern
 cmp rax,neboc_option_result_null_externo_e_erros_tipados_OP_ALIAS
 je .alias
 cmp rax,NEBOC_OP_GENERAL_GENERIC
 je .general_generic
 jmp .invalid_argument
.construct:
 test qword [r12+NEBOC_INPUT_FLAGS_OFFSET],neboc_option_result_null_externo_e_erros_tipados_INPUT_EXACT_SPELLING
 jz .alias
 mov rbx,[r12+NEBOC_CONTAINER_OFFSET]
 cmp rbx,NEBOC_CONTAINER_OPTION
 je .option
 cmp rbx,NEBOC_CONTAINER_RESULT
 je .result
 mov esi,NEBOC_DIAG_UNKNOWN_CONTAINER
 jmp .diag
.option:
 cmp qword [r12+NEBOC_TYPE_ARG_COUNT_OFFSET],1
 jne .type_arity
 cmp qword [r12+NEBOC_ERROR_TYPE_OFFSET],NEBOC_TYPE_NONE
 jne .type_arity
 mov rax,[r12+NEBOC_SUCCESS_TYPE_OFFSET]
 cmp rax,NEBOC_TYPE_VOID
 je .void_payload
 call scalar_allowed
 test eax,eax
 jz .payload_unavailable
 mov rax,[r12+NEBOC_VARIANT_OFFSET]
 cmp rax,NEBOC_VARIANT_SOME
 je .option_some
 cmp rax,NEBOC_VARIANT_NONE_VALUE
 je .option_none
 jmp .variant_mismatch
.option_some:
 cmp qword [r12+NEBOC_VARIANT_ARG_COUNT_OFFSET],1
 jne .variant_arity
 mov qword [r12+NEBOC_AST_FORM_OFFSET],NEBOC_AST_OPTION_CONSTRUCTOR
 mov qword [r12+NEBOC_RESULT_TYPE_OFFSET],NEBOC_CONTAINER_OPTION
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_RESULT_FLAGS_OFFSET],NEBOC_FLAG_SYNTAX_ONLY|NEBOC_FLAG_EXPLICIT_CONTAINER|NEBOC_FLAG_SOME
 jmp .ok
.option_none:
 cmp qword [r12+NEBOC_VARIANT_ARG_COUNT_OFFSET],0
 jne .variant_arity
 mov qword [r12+NEBOC_AST_FORM_OFFSET],NEBOC_AST_OPTION_CONSTRUCTOR
 mov qword [r12+NEBOC_RESULT_TYPE_OFFSET],NEBOC_CONTAINER_OPTION
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_RESULT_FLAGS_OFFSET],NEBOC_FLAG_SYNTAX_ONLY|NEBOC_FLAG_EXPLICIT_CONTAINER|NEBOC_FLAG_NONE
 jmp .ok
.result:
 cmp qword [r12+NEBOC_TYPE_ARG_COUNT_OFFSET],2
 jne .type_arity
 mov rax,[r12+NEBOC_SUCCESS_TYPE_OFFSET]
 cmp rax,NEBOC_TYPE_VOID
 je .void_payload
 call scalar_allowed
 test eax,eax
 jz .payload_unavailable
 mov rax,[r12+NEBOC_ERROR_TYPE_OFFSET]
 cmp rax,NEBOC_TYPE_VOID
 je .void_payload
 call scalar_allowed
 test eax,eax
 jz .payload_unavailable
 mov rax,[r12+NEBOC_VARIANT_OFFSET]
 cmp rax,NEBOC_VARIANT_OK
 je .result_ok
 cmp rax,NEBOC_VARIANT_ERR
 je .result_err
 jmp .variant_mismatch
.result_ok:
 cmp qword [r12+NEBOC_VARIANT_ARG_COUNT_OFFSET],1
 jne .variant_arity
 mov qword [r12+NEBOC_AST_FORM_OFFSET],NEBOC_AST_RESULT_CONSTRUCTOR
 mov qword [r12+NEBOC_RESULT_TYPE_OFFSET],NEBOC_CONTAINER_RESULT
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_RESULT_FLAGS_OFFSET],NEBOC_FLAG_SYNTAX_ONLY|NEBOC_FLAG_EXPLICIT_CONTAINER|NEBOC_FLAG_OK
 jmp .ok
.result_err:
 cmp qword [r12+NEBOC_VARIANT_ARG_COUNT_OFFSET],1
 jne .variant_arity
 mov qword [r12+NEBOC_AST_FORM_OFFSET],NEBOC_AST_RESULT_CONSTRUCTOR
 mov qword [r12+NEBOC_RESULT_TYPE_OFFSET],NEBOC_CONTAINER_RESULT
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_RESULT_FLAGS_OFFSET],NEBOC_FLAG_SYNTAX_ONLY|NEBOC_FLAG_EXPLICIT_CONTAINER|NEBOC_FLAG_ERR
 jmp .ok
.observer:
 mov rbx,[r12+NEBOC_CONTAINER_OFFSET]
 cmp rbx,NEBOC_CONTAINER_OPTION
 je .observer_kind
 cmp rbx,NEBOC_CONTAINER_RESULT
 je .observer_kind
 mov esi,NEBOC_DIAG_UNKNOWN_CONTAINER
 jmp .diag
.observer_kind:
 mov rax,[r12+NEBOC_OBSERVER_OFFSET]
 cmp rax,NEBOC_OBSERVER_IS_SOME
 je .option_zero
 cmp rax,NEBOC_OBSERVER_IS_NONE
 je .option_zero
 cmp rax,NEBOC_OBSERVER_IS_OK
 je .result_zero
 cmp rax,NEBOC_OBSERVER_IS_ERR
 je .result_zero
 cmp rax,NEBOC_OBSERVER_UNWRAP_OR
 je .unwrap_or
 mov esi,NEBOC_DIAG_OBSERVER_UNKNOWN
 jmp .diag
.option_zero:
 cmp rbx,NEBOC_CONTAINER_OPTION
 jne .observer_domain
 cmp qword [r12+NEBOC_OBSERVER_ARG_COUNT_OFFSET],0
 jne .observer_arity
 mov qword [r12+NEBOC_AST_FORM_OFFSET],NEBOC_AST_OBSERVER_CALL
 mov qword [r12+NEBOC_RESULT_TYPE_OFFSET],neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_RESULT_FLAGS_OFFSET],NEBOC_FLAG_SYNTAX_ONLY|NEBOC_FLAG_TOTAL
 jmp .ok
.result_zero:
 cmp rbx,NEBOC_CONTAINER_RESULT
 jne .observer_domain
 cmp qword [r12+NEBOC_OBSERVER_ARG_COUNT_OFFSET],0
 jne .observer_arity
 mov qword [r12+NEBOC_AST_FORM_OFFSET],NEBOC_AST_OBSERVER_CALL
 mov qword [r12+NEBOC_RESULT_TYPE_OFFSET],neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_RESULT_FLAGS_OFFSET],NEBOC_FLAG_SYNTAX_ONLY|NEBOC_FLAG_TOTAL
 jmp .ok
.unwrap_or:
 cmp qword [r12+NEBOC_OBSERVER_ARG_COUNT_OFFSET],1
 jne .unwrap_arity
 mov qword [r12+NEBOC_AST_FORM_OFFSET],NEBOC_AST_OBSERVER_CALL
 mov rax,[r12+NEBOC_SUCCESS_TYPE_OFFSET]
 mov [r12+NEBOC_RESULT_TYPE_OFFSET],rax
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_RESULT_FLAGS_OFFSET],NEBOC_FLAG_SYNTAX_ONLY|NEBOC_FLAG_TOTAL|NEBOC_FLAG_FALLBACK
 jmp .ok
.null_literal: mov esi,NEBOC_DIAG_NULL_FORBIDDEN
 jmp .diag
.propagation: mov esi,NEBOC_DIAG_PROPAGATION_DEFERRED
 jmp .diag
.try_catch: mov esi,NEBOC_DIAG_TRY_CATCH_DEFERRED
 jmp .diag
.fatal_unwrap: mov esi,NEBOC_DIAG_FATAL_UNWRAP_DEFERRED
 jmp .diag
.pattern: mov esi,NEBOC_DIAG_PATTERN_MATCH_DEFERRED
 jmp .diag
.alias: mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_ALIAS_FORBIDDEN
 jmp .diag
.general_generic: mov esi,NEBOC_DIAG_GENERAL_GENERICS_DEFERRED
 jmp .diag
.type_arity: mov esi,NEBOC_DIAG_TYPE_ARITY
 jmp .diag
.payload_unavailable: mov esi,NEBOC_DIAG_PAYLOAD_TYPE_UNAVAILABLE
 jmp .diag
.variant_mismatch: mov esi,NEBOC_DIAG_VARIANT_MISMATCH
 jmp .diag
.variant_arity: mov esi,NEBOC_DIAG_VARIANT_ARITY
 jmp .diag
.observer_domain: mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_OBSERVER_WRONG_DOMAIN
 jmp .diag
.observer_arity: mov esi,NEBOC_DIAG_OBSERVER_ARITY
 jmp .diag
.unwrap_arity: mov esi,NEBOC_DIAG_UNWRAP_OR_ARITY
 jmp .diag
.void_payload: mov esi,NEBOC_DIAG_VOID_PAYLOAD_FORBIDDEN
.diag:
 mov rdi,r12
 call option_result_null_externo_e_erros_tipados_error
 jmp .done
.ok:
 mov rdi,r12
 call option_result_null_externo_e_erros_tipados_success
 jmp .done
.invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
