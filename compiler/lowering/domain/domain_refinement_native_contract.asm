; Nebo Assembly — TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-PF004 x86-64 System V native plan
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/domain/domain_refinement_native_contract.inc"

section .text
tipos_semanticos_refinamentos_unidades_e_opaque_types_native_hash:
 mov rax,1469598103934665603
 mov rcx,1099511628211
 %assign off 0
 %rep 19
 xor rax,[rdi+off]
 imul rax,rcx
 %assign off off+8
 %endrep
 mov [rdi+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_HASH_OFFSET],rax
 ret
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
native_error:
 mov [rdi+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_DIAGNOSTIC_OFFSET],rsi
 call tipos_semanticos_refinamentos_unidades_e_opaque_types_native_hash
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

%undef call
NEBOC_ABI_FUNCTION neboc_domain_refinement_native_plan
 push r12
 mov r12,rdi
 test r12,r12
 jz .invalid
 lea rdi,[r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_SLOT_SIZE_OFFSET]
 mov ecx,12
 xor eax,eax
 rep stosq
 mov rax,[r12+NEBOC_NATIVE_IR_PTR_OFFSET]
 test rax,rax
 jz .ir
 cmp qword [rax+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_DIAGNOSTIC_OFFSET],NEBOC_IR_DIAG_NONE
 jne .ir
 mov rcx,[rax+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_HASH_OFFSET]
 cmp rcx,[r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_IR_HASH_OFFSET]
 jne .hash
 cmp qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_TARGET_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_TARGET_X86_64_SYSV
 jne .target
 mov rax,[r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_OPERATION_OFFSET]
 cmp rax,NEBOC_NATIVE_OP_TRY
 je .try
 cmp rax,NEBOC_NATIVE_OP_IS_OK
 je .is_ok
 cmp rax,NEBOC_NATIVE_OP_IS_ERR
 je .is_err
 cmp rax,NEBOC_NATIVE_OP_UNWRAP_OR
 je .unwrap
 jmp .operation
.try:
 cmp qword [r12+NEBOC_NATIVE_INPUT_TYPE_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_TYPE_INT
 jne .types
 cmp qword [r12+NEBOC_NATIVE_OUTPUT_TYPE_OFFSET],NEBOC_TYPE_RESULT_POSITIVE_INT_INT
 jne .types
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_SLOT_SIZE_OFFSET],16
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_SLOT_ALIGNMENT_OFFSET],8
 mov qword [r12+NEBOC_NATIVE_ARGUMENT1_REGISTER_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_REGISTER_RDI
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_RETURN_TAG_REGISTER_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_REGISTER_RAX
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_RETURN_PAYLOAD_REGISTER_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_REGISTER_RDX
 mov qword [r12+NEBOC_NATIVE_HELPER_OFFSET],NEBOC_NATIVE_HELPER_TRY
 jmp .common
.is_ok:
 mov eax,NEBOC_NATIVE_HELPER_IS_OK
 jmp .predicate
.is_err:
 mov eax,NEBOC_NATIVE_HELPER_IS_ERR
.predicate:
 cmp qword [r12+NEBOC_NATIVE_INPUT_TYPE_OFFSET],NEBOC_TYPE_RESULT_POSITIVE_INT_INT
 jne .types
 cmp qword [r12+NEBOC_NATIVE_OUTPUT_TYPE_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_TYPE_BOOL
 jne .types
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_SLOT_SIZE_OFFSET],1
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_SLOT_ALIGNMENT_OFFSET],1
 mov qword [r12+NEBOC_NATIVE_ARGUMENT1_REGISTER_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_REGISTER_RDI
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_RETURN_PAYLOAD_REGISTER_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_REGISTER_RAX
 mov [r12+NEBOC_NATIVE_HELPER_OFFSET],rax
 jmp .common
.unwrap:
 cmp qword [r12+NEBOC_NATIVE_INPUT_TYPE_OFFSET],NEBOC_TYPE_RESULT_POSITIVE_INT_INT
 jne .types
 cmp qword [r12+NEBOC_NATIVE_OUTPUT_TYPE_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_TYPE_POSITIVE_INT
 jne .types
 cmp qword [r12+NEBOC_NATIVE_PAYLOAD_OFFSET],0
 jle .tag
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_SLOT_SIZE_OFFSET],8
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_SLOT_ALIGNMENT_OFFSET],8
 mov qword [r12+NEBOC_NATIVE_ARGUMENT1_REGISTER_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_REGISTER_RDI
 mov qword [r12+NEBOC_NATIVE_ARGUMENT2_REGISTER_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_REGISTER_RSI
 mov qword [r12+NEBOC_NATIVE_ARGUMENT3_REGISTER_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_REGISTER_RDX
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_RETURN_PAYLOAD_REGISTER_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_REGISTER_RAX
 mov qword [r12+NEBOC_NATIVE_HELPER_OFFSET],NEBOC_NATIVE_HELPER_UNWRAP_OR
.common:
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_FLAGS_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_FLAGS_REQUIRED
 mov qword [r12+NEBOC_NATIVE_METADATA_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_METADATA_NONE
 mov rdi,r12
 call tipos_semanticos_refinamentos_unidades_e_opaque_types_native_hash
 xor eax,eax
 jmp .done
.ir: mov esi,NEBOC_NATIVE_DIAG_IR_INVALID
 jmp .diag
.hash: mov esi,NEBOC_NATIVE_DIAG_IR_HASH_MISMATCH
 jmp .diag
.target: mov esi,NEBOC_NATIVE_DIAG_TARGET_UNSUPPORTED
 jmp .diag
.operation: mov esi,NEBOC_NATIVE_DIAG_OPERATION_UNSUPPORTED
 jmp .diag
.types: mov esi,NEBOC_NATIVE_DIAG_TYPE_INVARIANT
 jmp .diag
.tag: mov esi,NEBOC_NATIVE_DIAG_TAG_INVARIANT
.diag:
 mov rdi,r12
 call native_error
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r12
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
