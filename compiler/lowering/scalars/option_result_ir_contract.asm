; Nebo Assembly — OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-PF003 abstract Option/Result HIR/LIR contract
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/option_result_semantic.inc"
%include "compiler/lowering/scalars/option_result_ir_contract.inc"
section .text
NEBOC_ABI_FUNCTION neboc_option_result_ir_lower
 push rbx
 push r12
 mov r12,rdi
 test r12,r12
 jz .invalid_argument
 mov rbx,[r12+neboc_option_result_null_externo_e_erros_tipados_IR_SEMANTIC_REQUEST_OFFSET]
 test rbx,rbx
 jz .invalid_argument
 lea rdi,[r12+neboc_option_result_null_externo_e_erros_tipados_IR_HIR_KIND_OFFSET]
 mov ecx,(neboc_option_result_null_externo_e_erros_tipados_IR_REQUEST_SIZE-neboc_option_result_null_externo_e_erros_tipados_IR_HIR_KIND_OFFSET)/8
 xor eax,eax
 rep stosq
 cmp qword [rbx+neboc_option_result_null_externo_e_erros_tipados_SEM_ERROR_CODE_OFFSET],neboc_option_result_null_externo_e_erros_tipados_SEM_ERROR_NONE
 jne .semantic_error
 cmp qword [rbx+NEBOC_SEM_LAYOUT_STATE_OFFSET],NEBOC_SEM_LAYOUT_DEFERRED_PF004
 jne .invariant_error
 mov rax,[rbx+neboc_option_result_null_externo_e_erros_tipados_SEM_HIR_KIND_OFFSET]
 test rax,rax
 jz .invariant_error
 mov [r12+neboc_option_result_null_externo_e_erros_tipados_IR_HIR_KIND_OFFSET],rax
 mov rax,[rbx+NEBOC_SEM_RESULT_CONTAINER_OFFSET]
 mov [r12+NEBOC_IR_CONTAINER_OFFSET],rax
 mov rax,[rbx+NEBOC_SEM_RESULT_SUCCESS_TYPE_OFFSET]
 mov [r12+NEBOC_IR_SUCCESS_TYPE_OFFSET],rax
 mov rax,[rbx+NEBOC_SEM_RESULT_ERROR_TYPE_OFFSET]
 mov [r12+NEBOC_IR_ERROR_TYPE_OFFSET],rax
 mov rax,[rbx+NEBOC_SEM_RESULT_TYPE_KIND_OFFSET]
 mov [r12+NEBOC_IR_RESULT_TYPE_KIND_OFFSET],rax
 mov rax,[rbx+NEBOC_SEM_VARIANT_OBSERVER_OFFSET]
 mov [r12+NEBOC_IR_VARIANT_OBSERVER_OFFSET],rax
 mov rax,[rbx+neboc_option_result_null_externo_e_erros_tipados_SEM_LIR_KIND_OFFSET]
 test rax,rax
 jz .invariant_error
 mov [r12+neboc_option_result_null_externo_e_erros_tipados_IR_LIR_KIND_OFFSET],rax
 mov rax,[rbx+NEBOC_SEM_PAYLOAD_REPR_OFFSET]
 mov [r12+NEBOC_IR_PAYLOAD_REPR_OFFSET],rax
 mov rax,[rbx+NEBOC_SEM_FALLBACK_REPR_OFFSET]
 mov [r12+NEBOC_IR_FALLBACK_REPR_OFFSET],rax
 mov rax,[rbx+NEBOC_SEM_FAILURE_EDGE_OFFSET]
 mov [r12+NEBOC_IR_FAILURE_EDGE_OFFSET],rax
 mov rax,[rbx+neboc_option_result_null_externo_e_erros_tipados_SEM_EFFECT_FLAGS_OFFSET]
 mov [r12+neboc_option_result_null_externo_e_erros_tipados_IR_EFFECT_FLAGS_OFFSET],rax
 mov rax,[rbx+NEBOC_SEM_TYPE_IDENTITY_HASH_OFFSET]
 mov [r12+NEBOC_IR_TYPE_IDENTITY_HASH_OFFSET],rax
 mov rax,[rbx+neboc_option_result_null_externo_e_erros_tipados_SEM_RUNTIME_METADATA_OFFSET]
 mov [r12+neboc_option_result_null_externo_e_erros_tipados_IR_RUNTIME_METADATA_OFFSET],rax
 mov rax,[rbx+NEBOC_SEM_LAYOUT_STATE_OFFSET]
 mov [r12+NEBOC_IR_LAYOUT_STATE_OFFSET],rax
 mov r10,neboc_option_result_null_externo_e_erros_tipados_SEM_HASH_PRIME
 mov rax,neboc_option_result_null_externo_e_erros_tipados_SEM_HASH_OFFSET_BASIS
 %assign off neboc_option_result_null_externo_e_erros_tipados_IR_HIR_KIND_OFFSET
 %rep 14
 xor rax,[r12+off]
 imul rax,r10
 %assign off off+8
 %endrep
 mov [r12+neboc_option_result_null_externo_e_erros_tipados_IR_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.semantic_error:
 mov qword [r12+NEBOC_IR_ERROR_OFFSET],NEBOC_IR_ERROR_SEMANTIC
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invariant_error:
 mov qword [r12+NEBOC_IR_ERROR_OFFSET],NEBOC_IR_ERROR_INVARIANT
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r12
 pop rbx
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
