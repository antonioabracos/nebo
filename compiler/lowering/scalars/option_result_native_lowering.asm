; Nebo Assembly — OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-PF004 isolated Option/Result native lowering prototype
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/option_result_api_contract.inc"
%include "compiler/semantic/types/option_result_semantic.inc"
%include "compiler/lowering/scalars/option_result_ir_contract.inc"
%include "compiler/lowering/scalars/option_result_native_lowering.inc"

section .text

; rax=TypeId -> eax=repr, edx=size, ecx=alignment, ebx=ABI class; zero repr if unsupported.
native_type_profile:
 xor edx,edx
 xor ecx,ecx
 xor ebx,ebx
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
.bool:
 mov eax,neboc_option_result_null_externo_e_erros_tipados_NATIVE_REPR_BOOL_U8
 mov edx,1
 mov ecx,1
 mov ebx,neboc_option_result_null_externo_e_erros_tipados_NATIVE_ABI_CLASS_INTEGER
 ret
.int:
 mov eax,NEBOC_NATIVE_REPR_INT_I64
 mov edx,8
 mov ecx,8
 mov ebx,neboc_option_result_null_externo_e_erros_tipados_NATIVE_ABI_CLASS_INTEGER
 ret
.float:
 mov eax,NEBOC_NATIVE_REPR_FLOAT_BINARY64
 mov edx,8
 mov ecx,8
 mov ebx,neboc_option_result_null_externo_e_erros_tipados_NATIVE_ABI_CLASS_SSE
 ret
.char:
 mov eax,NEBOC_NATIVE_REPR_CHAR_U32
 mov edx,4
 mov ecx,4
 mov ebx,neboc_option_result_null_externo_e_erros_tipados_NATIVE_ABI_CLASS_INTEGER
 ret

NEBOC_ABI_FUNCTION neboc_option_result_native_lower
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 test r12,r12
 jz .invalid_argument
 mov r13,[r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_SEMANTIC_REQUEST_OFFSET]
 mov r14,[r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_IR_REQUEST_OFFSET]
 test r13,r13
 jz .invalid_argument
 test r14,r14
 jz .invalid_argument
 lea rdi,[r12+NEBOC_NATIVE_CONTAINER_OFFSET]
 mov ecx,(neboc_option_result_null_externo_e_erros_tipados_NATIVE_REQUEST_SIZE-NEBOC_NATIVE_CONTAINER_OFFSET)/8
 xor eax,eax
 rep stosq
 cmp qword [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_TARGET_ID_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_TARGET_X86_64_SYSTEMV_ELF_LINUX
 jne .target_error
 cmp qword [r13+neboc_option_result_null_externo_e_erros_tipados_SEM_ERROR_CODE_OFFSET],neboc_option_result_null_externo_e_erros_tipados_SEM_ERROR_NONE
 jne .semantic_error
 cmp qword [r14+NEBOC_IR_ERROR_OFFSET],neboc_option_result_null_externo_e_erros_tipados_IR_ERROR_NONE
 jne .ir_error
 cmp qword [r13+neboc_option_result_null_externo_e_erros_tipados_SEM_RUNTIME_METADATA_OFFSET],neboc_option_result_null_externo_e_erros_tipados_SEM_RUNTIME_METADATA_NONE
 jne .metadata_error
 cmp qword [r14+neboc_option_result_null_externo_e_erros_tipados_IR_RUNTIME_METADATA_OFFSET],neboc_option_result_null_externo_e_erros_tipados_SEM_RUNTIME_METADATA_NONE
 jne .metadata_error
 cmp qword [r13+NEBOC_SEM_LAYOUT_STATE_OFFSET],NEBOC_SEM_LAYOUT_DEFERRED_PF004
 jne .contract_error
 cmp qword [r14+NEBOC_IR_LAYOUT_STATE_OFFSET],NEBOC_SEM_LAYOUT_DEFERRED_PF004
 jne .contract_error
 mov rax,[r13+neboc_option_result_null_externo_e_erros_tipados_SEM_SEMANTIC_HASH_OFFSET]
 test rax,rax
 jz .contract_error
 mov [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_SEMANTIC_HASH_OFFSET],rax
 mov rax,[r14+neboc_option_result_null_externo_e_erros_tipados_IR_HASH_OFFSET]
 test rax,rax
 jz .contract_error
 mov [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_IR_HASH_OFFSET],rax
 mov rax,[r13+neboc_option_result_null_externo_e_erros_tipados_SEM_HIR_KIND_OFFSET]
 cmp rax,[r14+neboc_option_result_null_externo_e_erros_tipados_IR_HIR_KIND_OFFSET]
 jne .contract_error
 mov r15,rax
 mov rax,[r13+neboc_option_result_null_externo_e_erros_tipados_SEM_LIR_KIND_OFFSET]
 cmp rax,[r14+neboc_option_result_null_externo_e_erros_tipados_IR_LIR_KIND_OFFSET]
 jne .contract_error
 mov rax,[r13+NEBOC_SEM_RESULT_CONTAINER_OFFSET]
 cmp rax,[r14+NEBOC_IR_CONTAINER_OFFSET]
 jne .contract_error
 cmp rax,NEBOC_CONTAINER_OPTION
 je .container_ok
 cmp rax,NEBOC_CONTAINER_RESULT
 jne .contract_error
.container_ok:
 mov [r12+NEBOC_NATIVE_CONTAINER_OFFSET],rax
 mov r10,rax
 mov rax,[r13+NEBOC_SEM_RESULT_SUCCESS_TYPE_OFFSET]
 cmp rax,[r14+NEBOC_IR_SUCCESS_TYPE_OFFSET]
 jne .contract_error
 mov [r12+NEBOC_NATIVE_SUCCESS_TYPE_OFFSET],rax
 call native_type_profile
 test eax,eax
 jz .type_error
 mov [r12+NEBOC_NATIVE_SUCCESS_REPR_OFFSET],rax
 mov [r12+NEBOC_NATIVE_ACTIVE_PAYLOAD_SIZE_OFFSET],rdx
 mov [r12+NEBOC_NATIVE_ACTIVE_PAYLOAD_ALIGNMENT_OFFSET],rcx
 mov r8d,ebx
 mov rax,[r13+NEBOC_SEM_RESULT_ERROR_TYPE_OFFSET]
 cmp rax,[r14+NEBOC_IR_ERROR_TYPE_OFFSET]
 jne .contract_error
 mov [r12+NEBOC_NATIVE_ERROR_TYPE_OFFSET],rax
 xor r9d,r9d
 cmp r10,NEBOC_CONTAINER_OPTION
 je .error_profile_done
 call native_type_profile
 test eax,eax
 jz .type_error
 mov [r12+NEBOC_NATIVE_ERROR_REPR_OFFSET],rax
 mov r9d,ebx
.error_profile_done:
 ; Fixed canonical layout: u8 tag, seven zero bytes, eight-byte payload.
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_SLOT_SIZE_OFFSET],16
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_SLOT_ALIGNMENT_OFFSET],8
 mov qword [r12+NEBOC_NATIVE_TAG_OFFSET_OFFSET],0
 mov qword [r12+NEBOC_NATIVE_TAG_SIZE_OFFSET],1
 mov qword [r12+NEBOC_NATIVE_PADDING_OFFSET_OFFSET],1
 mov qword [r12+NEBOC_NATIVE_PADDING_SIZE_OFFSET],7
 mov qword [r12+NEBOC_NATIVE_PAYLOAD_OFFSET_OFFSET],8
 mov qword [r12+NEBOC_NATIVE_PAYLOAD_STORAGE_SIZE_OFFSET],8
 mov qword [r12+NEBOC_NATIVE_FIRST_EIGHTBYTE_CLASS_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_ABI_CLASS_INTEGER
 ; Option<T> uses T class. Result<T,E> merges classes: SSE only when both are SSE.
 mov eax,r8d
 cmp r10,NEBOC_CONTAINER_OPTION
 je .merged_class_ready
 cmp r8d,neboc_option_result_null_externo_e_erros_tipados_NATIVE_ABI_CLASS_SSE
 jne .merged_integer
 cmp r9d,neboc_option_result_null_externo_e_erros_tipados_NATIVE_ABI_CLASS_SSE
 jne .merged_integer
 mov eax,neboc_option_result_null_externo_e_erros_tipados_NATIVE_ABI_CLASS_SSE
 jmp .merged_class_ready
.merged_integer:
 mov eax,neboc_option_result_null_externo_e_erros_tipados_NATIVE_ABI_CLASS_INTEGER
.merged_class_ready:
 mov [r12+NEBOC_NATIVE_SECOND_EIGHTBYTE_CLASS_OFFSET],rax
 mov qword [r12+NEBOC_NATIVE_ARGUMENT_TAG_REGISTER_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_REGISTER_RDI
 cmp eax,neboc_option_result_null_externo_e_erros_tipados_NATIVE_ABI_CLASS_SSE
 jne .aggregate_integer_regs
 mov qword [r12+NEBOC_NATIVE_ARGUMENT_PAYLOAD_REGISTER_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_REGISTER_XMM0
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_RETURN_PAYLOAD_REGISTER_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_REGISTER_XMM0
 jmp .aggregate_regs_done
.aggregate_integer_regs:
 mov qword [r12+NEBOC_NATIVE_ARGUMENT_PAYLOAD_REGISTER_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_REGISTER_RSI
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_RETURN_PAYLOAD_REGISTER_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_REGISTER_RDX
.aggregate_regs_done:
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_RETURN_TAG_REGISTER_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_REGISTER_RAX
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_FLAGS_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_FLAGS_COMMON
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_RUNTIME_METADATA_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_RUNTIME_METADATA_NONE

 cmp r15,NEBOC_SEM_HIR_OPTION_SOME
 je .option_some
 cmp r15,NEBOC_SEM_HIR_OPTION_NONE
 je .option_none
 cmp r15,NEBOC_SEM_HIR_RESULT_OK
 je .result_ok
 cmp r15,NEBOC_SEM_HIR_RESULT_ERR
 je .result_err
 cmp r15,NEBOC_SEM_HIR_OPTION_PREDICATE
 je .predicate
 cmp r15,NEBOC_SEM_HIR_RESULT_PREDICATE
 je .predicate
 cmp r15,NEBOC_SEM_HIR_UNWRAP_OR
 je .unwrap
 jmp .operation_error
.option_some:
 cmp r10,NEBOC_CONTAINER_OPTION
 jne .contract_error
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_OPERATION_OFFSET],NEBOC_NATIVE_OPERATION_CONSTRUCT
 mov qword [r12+NEBOC_NATIVE_TAG_VALUE_OFFSET],NEBOC_NATIVE_TAG_OPTION_SOME
 mov qword [r12+NEBOC_NATIVE_SUCCESS_TAG_OFFSET],NEBOC_NATIVE_TAG_OPTION_SOME
 mov rax,[r12+NEBOC_NATIVE_SUCCESS_REPR_OFFSET]
 jmp .construct_active
.option_none:
 cmp r10,NEBOC_CONTAINER_OPTION
 jne .contract_error
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_OPERATION_OFFSET],NEBOC_NATIVE_OPERATION_CONSTRUCT
 mov qword [r12+NEBOC_NATIVE_TAG_VALUE_OFFSET],NEBOC_NATIVE_TAG_OPTION_NONE
 mov qword [r12+NEBOC_NATIVE_SUCCESS_TAG_OFFSET],NEBOC_NATIVE_TAG_OPTION_SOME
 mov rax,[r12+NEBOC_NATIVE_SUCCESS_REPR_OFFSET]
 mov [r12+NEBOC_NATIVE_ACTIVE_REPR_OFFSET],rax
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_RUNTIME_HELPER_OFFSET],NEBOC_NATIVE_HELPER_STORE_ZERO_PAYLOAD
 jmp .finish
.result_ok:
 cmp r10,NEBOC_CONTAINER_RESULT
 jne .contract_error
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_OPERATION_OFFSET],NEBOC_NATIVE_OPERATION_CONSTRUCT
 mov qword [r12+NEBOC_NATIVE_TAG_VALUE_OFFSET],NEBOC_NATIVE_TAG_RESULT_OK
 mov qword [r12+NEBOC_NATIVE_SUCCESS_TAG_OFFSET],NEBOC_NATIVE_TAG_RESULT_OK
 mov rax,[r12+NEBOC_NATIVE_SUCCESS_REPR_OFFSET]
 jmp .construct_active
.result_err:
 cmp r10,NEBOC_CONTAINER_RESULT
 jne .contract_error
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_OPERATION_OFFSET],NEBOC_NATIVE_OPERATION_CONSTRUCT
 mov qword [r12+NEBOC_NATIVE_TAG_VALUE_OFFSET],NEBOC_NATIVE_TAG_RESULT_ERR
 mov qword [r12+NEBOC_NATIVE_SUCCESS_TAG_OFFSET],NEBOC_NATIVE_TAG_RESULT_OK
 mov rax,[r12+NEBOC_NATIVE_ERROR_REPR_OFFSET]
 mov [r12+NEBOC_NATIVE_ACTIVE_REPR_OFFSET],rax
 ; Recompute active payload width/alignment for E.
 mov rax,[r12+NEBOC_NATIVE_ERROR_TYPE_OFFSET]
 call native_type_profile
 mov [r12+NEBOC_NATIVE_ACTIVE_PAYLOAD_SIZE_OFFSET],rdx
 mov [r12+NEBOC_NATIVE_ACTIVE_PAYLOAD_ALIGNMENT_OFFSET],rcx
 mov rax,[r12+NEBOC_NATIVE_ACTIVE_REPR_OFFSET]
.construct_active:
 mov [r12+NEBOC_NATIVE_ACTIVE_REPR_OFFSET],rax
 cmp rax,NEBOC_NATIVE_REPR_FLOAT_BINARY64
 je .construct_float
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_RUNTIME_HELPER_OFFSET],NEBOC_NATIVE_HELPER_STORE_INTEGER
 jmp .finish
.construct_float:
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_RUNTIME_HELPER_OFFSET],NEBOC_NATIVE_HELPER_STORE_FLOAT
 jmp .finish
.predicate:
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_OPERATION_OFFSET],NEBOC_NATIVE_OPERATION_PREDICATE
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_RUNTIME_HELPER_OFFSET],NEBOC_NATIVE_HELPER_TAG_TEST
 mov qword [r12+NEBOC_NATIVE_SCALAR_RETURN_REGISTER_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_REGISTER_RAX
 mov rax,[r13+NEBOC_SEM_VARIANT_OBSERVER_OFFSET]
 cmp rax,NEBOC_OBSERVER_IS_SOME
 je .expect_one
 cmp rax,NEBOC_OBSERVER_IS_ERR
 je .expect_one
 cmp rax,NEBOC_OBSERVER_IS_NONE
 je .expect_zero
 cmp rax,NEBOC_OBSERVER_IS_OK
 je .expect_zero
 jmp .operation_error
.expect_one:
 mov qword [r12+NEBOC_NATIVE_TAG_VALUE_OFFSET],1
 jmp .finish
.expect_zero:
 mov qword [r12+NEBOC_NATIVE_TAG_VALUE_OFFSET],0
 jmp .finish
.unwrap:
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_OPERATION_OFFSET],NEBOC_NATIVE_OPERATION_UNWRAP_OR
 cmp r10,NEBOC_CONTAINER_OPTION
 je .unwrap_option
 mov qword [r12+NEBOC_NATIVE_SUCCESS_TAG_OFFSET],NEBOC_NATIVE_TAG_RESULT_OK
 jmp .unwrap_type
.unwrap_option:
 mov qword [r12+NEBOC_NATIVE_SUCCESS_TAG_OFFSET],NEBOC_NATIVE_TAG_OPTION_SOME
.unwrap_type:
 mov rax,[r12+NEBOC_NATIVE_SUCCESS_REPR_OFFSET]
 mov [r12+NEBOC_NATIVE_ACTIVE_REPR_OFFSET],rax
 cmp rax,NEBOC_NATIVE_REPR_FLOAT_BINARY64
 je .unwrap_float
 mov qword [r12+NEBOC_NATIVE_FALLBACK_REGISTER_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_REGISTER_RDX
 mov qword [r12+NEBOC_NATIVE_SCALAR_RETURN_REGISTER_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_REGISTER_RAX
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_RUNTIME_HELPER_OFFSET],NEBOC_NATIVE_HELPER_UNWRAP_INTEGER
 jmp .finish
.unwrap_float:
 mov qword [r12+NEBOC_NATIVE_FALLBACK_REGISTER_OFFSET],NEBOC_NATIVE_REGISTER_XMM1
 mov qword [r12+NEBOC_NATIVE_SCALAR_RETURN_REGISTER_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_REGISTER_XMM0
 mov qword [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_RUNTIME_HELPER_OFFSET],NEBOC_NATIVE_HELPER_UNWRAP_FLOAT
.finish:
 ; FNV-1a over stable output fields from container through flags.
 mov rax,1469598103934665603
 lea rsi,[r12+NEBOC_NATIVE_CONTAINER_OFFSET]
 mov ecx,(neboc_option_result_null_externo_e_erros_tipados_NATIVE_RUNTIME_METADATA_OFFSET-NEBOC_NATIVE_CONTAINER_OFFSET)/8
.hash_loop:
 xor rax,[rsi]
 mov rdx,1099511628211
 imul rax,rdx
 add rsi,8
 loop .hash_loop
 mov [r12+neboc_option_result_null_externo_e_erros_tipados_NATIVE_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.semantic_error:
 mov qword [r12+NEBOC_NATIVE_ERROR_OFFSET],NEBOC_NATIVE_ERROR_SEMANTIC_INVALID
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ir_error:
 mov qword [r12+NEBOC_NATIVE_ERROR_OFFSET],NEBOC_NATIVE_ERROR_IR_INVALID
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.target_error:
 mov qword [r12+NEBOC_NATIVE_ERROR_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_ERROR_TARGET_UNSUPPORTED
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.contract_error:
 mov qword [r12+NEBOC_NATIVE_ERROR_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_ERROR_CONTRACT_MISMATCH
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.type_error:
 mov qword [r12+NEBOC_NATIVE_ERROR_OFFSET],NEBOC_NATIVE_ERROR_TYPE_UNSUPPORTED
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.operation_error:
 mov qword [r12+NEBOC_NATIVE_ERROR_OFFSET],NEBOC_NATIVE_ERROR_OPERATION_UNSUPPORTED
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.metadata_error:
 mov qword [r12+NEBOC_NATIVE_ERROR_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_ERROR_RUNTIME_METADATA
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
