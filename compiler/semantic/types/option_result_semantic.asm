; Nebo Assembly — OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-PF003 isolated Option/Result semantic model
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/option_result_api_contract.inc"
%include "compiler/semantic/types/option_result_semantic.inc"

section .text

sem_scalar_repr:
 cmp rax,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64
 je .bool
 cmp rax,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64
 je .int
 cmp rax,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT
 je .float
 cmp rax,neboc_option_result_null_externo_e_erros_tipados_TYPE_CHAR_codegen_scalars_x86_64
 je .char
 xor eax,eax
 ret
.bool: mov eax,NEBOC_SEM_REPR_BOOL_U8
 ret
.int: mov eax,NEBOC_SEM_REPR_INT_I64
 ret
.float: mov eax,NEBOC_SEM_REPR_FLOAT_BINARY64
 ret
.char: mov eax,NEBOC_SEM_REPR_CHAR_U32
 ret

NEBOC_ABI_FUNCTION neboc_option_result_semantic_analyze
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 test r12,r12
 jz .invalid_argument
 mov r13,[r12+neboc_option_result_null_externo_e_erros_tipados_SEM_API_REQUEST_OFFSET]
 test r13,r13
 jz .invalid_argument
 lea rdi,[r12+NEBOC_SEM_RESULT_CONTAINER_OFFSET]
 mov ecx,(neboc_option_result_null_externo_e_erros_tipados_SEM_REQUEST_SIZE-NEBOC_SEM_RESULT_CONTAINER_OFFSET)/8
 xor eax,eax
 rep stosq

 mov rax,[r13+neboc_option_result_null_externo_e_erros_tipados_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .api_invalid
 mov rax,[r12+neboc_option_result_null_externo_e_erros_tipados_SEM_INPUT_FLAGS_OFFSET]
 test rax,~neboc_option_result_null_externo_e_erros_tipados_SEM_INPUT_ALLOWED_MASK
 jnz .flag_error
 test rax,NEBOC_SEM_INPUT_CONTEXT_VALID
 jz .context_required
 mov r14,[r12+neboc_option_result_null_externo_e_erros_tipados_SEM_NODE_START_OFFSET]
 mov r15,[r12+neboc_option_result_null_externo_e_erros_tipados_SEM_NODE_END_OFFSET]
 cmp r15,r14
 jbe .span_error
 mov rbx,[r12+neboc_option_result_null_externo_e_erros_tipados_SEM_SUBJECT_START_OFFSET]
 cmp rbx,r14
 jb .span_error
 mov rax,[r12+neboc_option_result_null_externo_e_erros_tipados_SEM_SUBJECT_END_OFFSET]
 cmp rax,rbx
 jbe .span_error
 cmp rax,r15
 ja .span_error

 mov rax,[r13+neboc_option_result_null_externo_e_erros_tipados_OPERATION_OFFSET]
 cmp rax,NEBOC_OP_CONSTRUCT
 je .construct
 cmp rax,NEBOC_OP_OBSERVER
 je .observer
 jmp .operation_error

.construct:
 mov rax,[r13+NEBOC_CONTAINER_OFFSET]
 cmp rax,[r12+NEBOC_SEM_CONTAINER_OFFSET]
 jne .context_error
 mov [r12+NEBOC_SEM_RESULT_CONTAINER_OFFSET],rax
 mov rbx,[r12+NEBOC_SEM_SUCCESS_TYPE_OFFSET]
 cmp rbx,[r13+NEBOC_SUCCESS_TYPE_OFFSET]
 jne .context_error
 mov [r12+NEBOC_SEM_RESULT_SUCCESS_TYPE_OFFSET],rbx
 mov rax,[r12+NEBOC_SEM_ERROR_TYPE_OFFSET]
 cmp rax,[r13+NEBOC_ERROR_TYPE_OFFSET]
 jne .context_error
 mov [r12+NEBOC_SEM_RESULT_ERROR_TYPE_OFFSET],rax
 mov qword [r12+NEBOC_SEM_RESULT_TYPE_KIND_OFFSET],NEBOC_SEM_RESULT_CONTAINER_TYPE
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEMANTIC_KIND_OFFSET],NEBOC_SEM_KIND_CONSTRUCT
 mov rax,[r13+NEBOC_VARIANT_OFFSET]
 mov [r12+NEBOC_SEM_VARIANT_OBSERVER_OFFSET],rax
 cmp qword [r13+NEBOC_CONTAINER_OFFSET],NEBOC_CONTAINER_OPTION
 je .option_construct
 cmp qword [r13+NEBOC_CONTAINER_OFFSET],NEBOC_CONTAINER_RESULT
 je .result_construct
 jmp .context_error

.option_construct:
 cmp qword [r12+NEBOC_SEM_ERROR_TYPE_OFFSET],NEBOC_TYPE_NONE
 jne .context_error
 mov rax,[r12+NEBOC_SEM_SUCCESS_TYPE_OFFSET]
 call sem_scalar_repr
 test eax,eax
 jz .context_error
 mov [r12+NEBOC_SEM_PAYLOAD_REPR_OFFSET],rax
 cmp qword [r13+NEBOC_VARIANT_OFFSET],NEBOC_VARIANT_SOME
 je .some
 cmp qword [r13+NEBOC_VARIANT_OFFSET],NEBOC_VARIANT_NONE_VALUE
 je .none
 jmp .operation_error
.some:
 test qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_INPUT_FLAGS_OFFSET],NEBOC_SEM_INPUT_VALUE_PRESENT
 jz .flag_error
 mov rax,[r12+NEBOC_SEM_VALUE_TYPE_OFFSET]
 cmp rax,[r12+NEBOC_SEM_SUCCESS_TYPE_OFFSET]
 jne .payload_error
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_EFFECT_FLAGS_OFFSET],neboc_option_result_null_externo_e_erros_tipados_SEM_EFFECTS_BASE
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_OPTION_SOME
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_TAGGED_CONSTRUCT
 mov qword [r12+NEBOC_SEM_FAILURE_EDGE_OFFSET],NEBOC_SEM_FAILURE_NONE
 jmp .success
.none:
 test qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_INPUT_FLAGS_OFFSET],NEBOC_SEM_INPUT_VALUE_PRESENT
 jnz .flag_error
 cmp qword [r12+NEBOC_SEM_VALUE_TYPE_OFFSET],NEBOC_TYPE_NONE
 jne .flag_error
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_EFFECT_FLAGS_OFFSET],neboc_option_result_null_externo_e_erros_tipados_SEM_EFFECTS_BASE|NEBOC_SEM_EFFECT_ABSENCE_AS_VALUE
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_OPTION_NONE
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_TAGGED_CONSTRUCT
 mov qword [r12+NEBOC_SEM_FAILURE_EDGE_OFFSET],NEBOC_SEM_FAILURE_ABSENCE_VALUE
 jmp .success

.result_construct:
 mov rax,[r12+NEBOC_SEM_SUCCESS_TYPE_OFFSET]
 call sem_scalar_repr
 test eax,eax
 jz .context_error
 mov [r12+NEBOC_SEM_PAYLOAD_REPR_OFFSET],rax
 mov rax,[r12+NEBOC_SEM_ERROR_TYPE_OFFSET]
 call sem_scalar_repr
 test eax,eax
 jz .context_error
 cmp qword [r13+NEBOC_VARIANT_OFFSET],NEBOC_VARIANT_OK
 je .ok
 cmp qword [r13+NEBOC_VARIANT_OFFSET],NEBOC_VARIANT_ERR
 je .err
 jmp .operation_error
.ok:
 test qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_INPUT_FLAGS_OFFSET],NEBOC_SEM_INPUT_VALUE_PRESENT
 jz .flag_error
 mov rax,[r12+NEBOC_SEM_VALUE_TYPE_OFFSET]
 cmp rax,[r12+NEBOC_SEM_SUCCESS_TYPE_OFFSET]
 jne .payload_error
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_EFFECT_FLAGS_OFFSET],neboc_option_result_null_externo_e_erros_tipados_SEM_EFFECTS_BASE
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_RESULT_OK
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_TAGGED_CONSTRUCT
 mov qword [r12+NEBOC_SEM_FAILURE_EDGE_OFFSET],NEBOC_SEM_FAILURE_NONE
 jmp .success
.err:
 test qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_INPUT_FLAGS_OFFSET],NEBOC_SEM_INPUT_VALUE_PRESENT
 jz .flag_error
 mov rax,[r12+NEBOC_SEM_VALUE_TYPE_OFFSET]
 cmp rax,[r12+NEBOC_SEM_ERROR_TYPE_OFFSET]
 jne .payload_error
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_EFFECT_FLAGS_OFFSET],neboc_option_result_null_externo_e_erros_tipados_SEM_EFFECTS_BASE|NEBOC_SEM_EFFECT_ERROR_AS_VALUE
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_RESULT_ERR
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_TAGGED_CONSTRUCT
 mov qword [r12+NEBOC_SEM_FAILURE_EDGE_OFFSET],NEBOC_SEM_FAILURE_RECOVERABLE_ERROR_VALUE
 jmp .success

.observer:
 mov rax,[r13+NEBOC_CONTAINER_OFFSET]
 cmp rax,[r12+NEBOC_SEM_CONTAINER_OFFSET]
 jne .context_error
 mov [r12+NEBOC_SEM_RESULT_CONTAINER_OFFSET],rax
 mov rbx,[r12+NEBOC_SEM_SUCCESS_TYPE_OFFSET]
 mov [r12+NEBOC_SEM_RESULT_SUCCESS_TYPE_OFFSET],rbx
 mov rax,[r12+NEBOC_SEM_ERROR_TYPE_OFFSET]
 mov [r12+NEBOC_SEM_RESULT_ERROR_TYPE_OFFSET],rax
 mov rax,rbx
 call sem_scalar_repr
 test eax,eax
 jz .context_error
 mov [r12+NEBOC_SEM_PAYLOAD_REPR_OFFSET],rax
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEMANTIC_KIND_OFFSET],NEBOC_SEM_KIND_OBSERVER
 mov rax,[r13+NEBOC_OBSERVER_OFFSET]
 mov [r12+NEBOC_SEM_VARIANT_OBSERVER_OFFSET],rax
 cmp rax,NEBOC_OBSERVER_UNWRAP_OR
 je .unwrap_or
 cmp rax,NEBOC_OBSERVER_IS_SOME
 je .option_predicate
 cmp rax,NEBOC_OBSERVER_IS_NONE
 je .option_predicate
 cmp rax,NEBOC_OBSERVER_IS_OK
 je .result_predicate
 cmp rax,NEBOC_OBSERVER_IS_ERR
 je .result_predicate
 jmp .operation_error
.option_predicate:
 cmp qword [r12+NEBOC_SEM_CONTAINER_OFFSET],NEBOC_CONTAINER_OPTION
 jne .context_error
 cmp qword [r12+NEBOC_SEM_ERROR_TYPE_OFFSET],NEBOC_TYPE_NONE
 jne .context_error
 mov qword [r12+NEBOC_SEM_RESULT_TYPE_KIND_OFFSET],NEBOC_SEM_RESULT_BOOL
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_EFFECT_FLAGS_OFFSET],neboc_option_result_null_externo_e_erros_tipados_SEM_EFFECTS_BASE
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_OPTION_PREDICATE
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_TAG_TEST
 jmp .success
.result_predicate:
 cmp qword [r12+NEBOC_SEM_CONTAINER_OFFSET],NEBOC_CONTAINER_RESULT
 jne .context_error
 mov rax,[r12+NEBOC_SEM_ERROR_TYPE_OFFSET]
 call sem_scalar_repr
 test eax,eax
 jz .context_error
 mov qword [r12+NEBOC_SEM_RESULT_TYPE_KIND_OFFSET],NEBOC_SEM_RESULT_BOOL
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_EFFECT_FLAGS_OFFSET],neboc_option_result_null_externo_e_erros_tipados_SEM_EFFECTS_BASE
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_RESULT_PREDICATE
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_TAG_TEST
 jmp .success
.unwrap_or:
 cmp qword [r12+NEBOC_SEM_CONTAINER_OFFSET],NEBOC_CONTAINER_OPTION
 je .unwrap_option_context
 cmp qword [r12+NEBOC_SEM_CONTAINER_OFFSET],NEBOC_CONTAINER_RESULT
 je .unwrap_result_context
 jmp .context_error
.unwrap_option_context:
 cmp qword [r12+NEBOC_SEM_ERROR_TYPE_OFFSET],NEBOC_TYPE_NONE
 jne .context_error
 jmp .unwrap_fallback
.unwrap_result_context:
 mov rax,[r12+NEBOC_SEM_ERROR_TYPE_OFFSET]
 call sem_scalar_repr
 test eax,eax
 jz .context_error
.unwrap_fallback:
 test qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_INPUT_FLAGS_OFFSET],NEBOC_SEM_INPUT_FALLBACK_PRESENT
 jz .fallback_error
 mov rax,[r12+NEBOC_SEM_FALLBACK_TYPE_OFFSET]
 cmp rax,[r12+NEBOC_SEM_SUCCESS_TYPE_OFFSET]
 jne .fallback_error
 call sem_scalar_repr
 test eax,eax
 jz .fallback_error
 mov [r12+NEBOC_SEM_FALLBACK_REPR_OFFSET],rax
 mov qword [r12+NEBOC_SEM_RESULT_TYPE_KIND_OFFSET],NEBOC_SEM_RESULT_PAYLOAD
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_EFFECT_FLAGS_OFFSET],neboc_option_result_null_externo_e_erros_tipados_SEM_EFFECTS_BASE
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_UNWRAP_OR
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_PAYLOAD_OR_FALLBACK
 jmp .success

.success:
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_RUNTIME_METADATA_OFFSET],neboc_option_result_null_externo_e_erros_tipados_SEM_RUNTIME_METADATA_NONE
 mov qword [r12+NEBOC_SEM_LAYOUT_STATE_OFFSET],NEBOC_SEM_LAYOUT_DEFERRED_PF004
 call .compute_hashes
 xor eax,eax
 jmp .done

.api_invalid:
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_ERROR_CODE_OFFSET],neboc_option_result_null_externo_e_erros_tipados_SEM_ERROR_API_INVALID
 mov rax,[r13+neboc_option_result_null_externo_e_erros_tipados_DIAGNOSTIC_OFFSET]
 mov [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_SOURCE_DIAG_OFFSET],rax
 mov rax,[r13+NEBOC_ERROR_START_OFFSET]
 mov [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_ERROR_START_OFFSET],rax
 mov rax,[r13+NEBOC_ERROR_END_OFFSET]
 mov [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_ERROR_END_OFFSET],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.context_error: mov ebx,neboc_option_result_null_externo_e_erros_tipados_SEM_ERROR_CONTEXT_INVARIANT
 jmp .semantic_error
.payload_error: mov ebx,NEBOC_SEM_ERROR_PAYLOAD_TYPE_MISMATCH
 jmp .semantic_error
.fallback_error: mov ebx,NEBOC_SEM_ERROR_FALLBACK_TYPE_MISMATCH
 jmp .semantic_error
.flag_error: mov ebx,neboc_option_result_null_externo_e_erros_tipados_SEM_ERROR_FLAG_INVARIANT
 jmp .semantic_error
.span_error: mov ebx,neboc_option_result_null_externo_e_erros_tipados_SEM_ERROR_SPAN_INVARIANT
 jmp .semantic_error
.operation_error: mov ebx,NEBOC_SEM_ERROR_OPERATION_INVARIANT
 jmp .semantic_error
.context_required: mov ebx,NEBOC_SEM_ERROR_CONTEXT_REQUIRED
.semantic_error:
 mov [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_ERROR_CODE_OFFSET],rbx
 mov rax,[r12+neboc_option_result_null_externo_e_erros_tipados_SEM_SUBJECT_START_OFFSET]
 mov [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_ERROR_START_OFFSET],rax
 mov rax,[r12+neboc_option_result_null_externo_e_erros_tipados_SEM_SUBJECT_END_OFFSET]
 mov [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_ERROR_END_OFFSET],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done

.compute_hashes:
 mov r10,neboc_option_result_null_externo_e_erros_tipados_SEM_HASH_PRIME
 mov rax,neboc_option_result_null_externo_e_erros_tipados_SEM_HASH_OFFSET_BASIS
 xor rax,[r12+NEBOC_SEM_RESULT_CONTAINER_OFFSET]
 imul rax,r10
 xor rax,[r12+NEBOC_SEM_RESULT_SUCCESS_TYPE_OFFSET]
 imul rax,r10
 xor rax,[r12+NEBOC_SEM_RESULT_ERROR_TYPE_OFFSET]
 imul rax,r10
 mov [r12+NEBOC_SEM_TYPE_IDENTITY_HASH_OFFSET],rax
 xor rax,[r12+NEBOC_SEM_RESULT_TYPE_KIND_OFFSET]
 imul rax,r10
 xor rax,[r12+neboc_option_result_null_externo_e_erros_tipados_SEMANTIC_KIND_OFFSET]
 imul rax,r10
 xor rax,[r12+NEBOC_SEM_VARIANT_OBSERVER_OFFSET]
 imul rax,r10
 xor rax,[r12+neboc_option_result_null_externo_e_erros_tipados_SEM_EFFECT_FLAGS_OFFSET]
 imul rax,r10
 xor rax,[r12+neboc_option_result_null_externo_e_erros_tipados_SEM_HIR_KIND_OFFSET]
 imul rax,r10
 xor rax,[r12+neboc_option_result_null_externo_e_erros_tipados_SEM_LIR_KIND_OFFSET]
 imul rax,r10
 xor rax,[r12+NEBOC_SEM_FAILURE_EDGE_OFFSET]
 imul rax,r10
 mov [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_SEMANTIC_HASH_OFFSET],rax
 xor rax,[r12+neboc_option_result_null_externo_e_erros_tipados_SEM_SOURCE_ID_OFFSET]
 imul rax,r10
 xor rax,[r12+neboc_option_result_null_externo_e_erros_tipados_SEM_NODE_START_OFFSET]
 imul rax,r10
 xor rax,[r12+neboc_option_result_null_externo_e_erros_tipados_SEM_NODE_END_OFFSET]
 imul rax,r10
 xor rax,[r12+neboc_option_result_null_externo_e_erros_tipados_SEM_SUBJECT_START_OFFSET]
 imul rax,r10
 xor rax,[r12+neboc_option_result_null_externo_e_erros_tipados_SEM_SUBJECT_END_OFFSET]
 imul rax,r10
 mov [r12+neboc_option_result_null_externo_e_erros_tipados_SEM_PROVENANCE_HASH_OFFSET],rax
 ret
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
