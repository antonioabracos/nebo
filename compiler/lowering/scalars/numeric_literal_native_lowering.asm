; Nebo Assembly — LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-PF004 isolated native Int literal lowering prototype
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/semantic/types/numeric_literal_semantic.inc"
%include "compiler/lowering/scalars/numeric_literal_ir_contract.inc"
%include "compiler/lowering/scalars/numeric_literal_native_lowering.inc"

section .text

; neboc_numeric_literal_native_lower(request*) -> StatusCode
; Consumes the isolated PF003 semantic/abstract IR contracts and selects the
; certified x86-64 System V signed-Int representation. No instruction emission
; or public CLI integration is performed in PF004.
NEBOC_ABI_FUNCTION neboc_numeric_literal_native_lower
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 test r12,r12
 jz .invalid_argument
 mov r13,[r12+neboc_literais_numericos_bases_e_representacao_NATIVE_SEMANTIC_REQUEST_OFFSET]
 mov r14,[r12+neboc_literais_numericos_bases_e_representacao_NATIVE_IR_REQUEST_OFFSET]
 test r13,r13
 jz .invalid_argument
 test r14,r14
 jz .invalid_argument
 lea rdi,[r12+neboc_literais_numericos_bases_e_representacao_NATIVE_TYPE_ID_OFFSET]
 mov ecx,(neboc_literais_numericos_bases_e_representacao_NATIVE_REQUEST_SIZE-neboc_literais_numericos_bases_e_representacao_NATIVE_TYPE_ID_OFFSET)/8
 xor eax,eax
 rep stosq
 cmp qword [r12+neboc_literais_numericos_bases_e_representacao_NATIVE_TARGET_ID_OFFSET],neboc_literais_numericos_bases_e_representacao_NATIVE_TARGET_X86_64_SYSTEMV_ELF_LINUX
 jne .target_error
 cmp qword [r13+neboc_literais_numericos_bases_e_representacao_SEM_ERROR_CODE_OFFSET],neboc_literais_numericos_bases_e_representacao_SEM_ERROR_NONE
 jne .semantic_invalid
 cmp qword [r13+neboc_literais_numericos_bases_e_representacao_SEM_CONSTANT_STATE_OFFSET],NEBOC_SEM_CONSTANT_VALID
 jne .semantic_invalid
 cmp qword [r13+NEBOC_SEM_TYPE_ID_OFFSET],NEBOC_TYPE_ID_INT
 jne .invariant_error
 cmp qword [r13+neboc_literais_numericos_bases_e_representacao_SEM_RUNTIME_METADATA_OFFSET],neboc_literais_numericos_bases_e_representacao_SEM_RUNTIME_METADATA_NONE
 jne .metadata_error
 cmp qword [r14+neboc_literais_numericos_bases_e_representacao_IR_ERROR_CODE_OFFSET],neboc_literais_numericos_bases_e_representacao_IR_ERROR_NONE
 jne .ir_invalid
 cmp qword [r14+NEBOC_IR_HIR_TYPE_ID_OFFSET],NEBOC_TYPE_ID_INT
 jne .invariant_error
 cmp qword [r14+neboc_literais_numericos_bases_e_representacao_IR_LIR_KIND_OFFSET],NEBOC_IR_LIR_IMMEDIATE_I64
 jne .invariant_error
 cmp qword [r14+NEBOC_IR_LIR_WIDTH_OFFSET],NEBOC_IR_WIDTH_64
 jne .invariant_error
 cmp qword [r14+NEBOC_IR_LIR_SIGNED_OFFSET],NEBOC_IR_SIGNED_YES
 jne .invariant_error
 cmp qword [r14+neboc_literais_numericos_bases_e_representacao_IR_RUNTIME_METADATA_OFFSET],neboc_literais_numericos_bases_e_representacao_IR_RUNTIME_METADATA_NONE
 jne .metadata_error
 mov rax,[r13+NEBOC_SEM_SIGNED_VALUE_OFFSET]
 cmp rax,[r14+NEBOC_IR_LIR_VALUE_OFFSET]
 jne .value_error

 mov qword [r12+neboc_literais_numericos_bases_e_representacao_NATIVE_TYPE_ID_OFFSET],NEBOC_TYPE_ID_INT
 mov [r12+NEBOC_NATIVE_SIGNED_VALUE_OFFSET],rax
 mov qword [r12+NEBOC_NATIVE_BIT_WIDTH_OFFSET],64
 mov qword [r12+NEBOC_NATIVE_STORAGE_SIZE_OFFSET],8
 mov qword [r12+NEBOC_NATIVE_STORAGE_ALIGNMENT_OFFSET],8
 mov qword [r12+neboc_literais_numericos_bases_e_representacao_NATIVE_ABI_CLASS_OFFSET],neboc_literais_numericos_bases_e_representacao_NATIVE_ABI_CLASS_INTEGER
 mov qword [r12+neboc_literais_numericos_bases_e_representacao_NATIVE_PARAMETER_REGISTER_OFFSET],neboc_literais_numericos_bases_e_representacao_NATIVE_REGISTER_RDI
 mov qword [r12+neboc_literais_numericos_bases_e_representacao_NATIVE_RETURN_REGISTER_OFFSET],neboc_literais_numericos_bases_e_representacao_NATIVE_REGISTER_RAX
 mov qword [r12+NEBOC_NATIVE_STACK_SLOT_SIZE_OFFSET],8
 mov qword [r12+NEBOC_NATIVE_STACK_SLOT_ALIGNMENT_OFFSET],8
 mov qword [r12+neboc_literais_numericos_bases_e_representacao_NATIVE_RUNTIME_METADATA_OFFSET],neboc_literais_numericos_bases_e_representacao_NATIVE_RUNTIME_METADATA_NONE
 mov rdx,rax
 movsxd rcx,eax
 cmp rcx,rdx
 jne .immediate_i64
 mov qword [r12+NEBOC_NATIVE_IMMEDIATE_ENCODING_OFFSET],NEBOC_NATIVE_IMMEDIATE_SIGN_EXTENDED_I32
 jmp .flags
.immediate_i64:
 mov qword [r12+NEBOC_NATIVE_IMMEDIATE_ENCODING_OFFSET],NEBOC_NATIVE_IMMEDIATE_I64
.flags:
 mov rax,neboc_literais_numericos_bases_e_representacao_NATIVE_REQUIRED_FLAGS
 test qword [r13+neboc_literais_numericos_bases_e_representacao_SEM_FLAGS_OFFSET],NEBOC_SEM_FLAG_INT64_MIN
 jz .store_flags
 or rax,NEBOC_NATIVE_FLAG_INT64_MIN
.store_flags:
 mov [r12+neboc_literais_numericos_bases_e_representacao_NATIVE_FLAGS_OFFSET],rax

 ; Native hash intentionally excludes source base, spelling and separators.
 mov rax,1469598103934665603
 mov rcx,1099511628211
 xor rax,[r12+neboc_literais_numericos_bases_e_representacao_NATIVE_TYPE_ID_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_NATIVE_SIGNED_VALUE_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_NATIVE_BIT_WIDTH_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_literais_numericos_bases_e_representacao_NATIVE_ABI_CLASS_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_literais_numericos_bases_e_representacao_NATIVE_PARAMETER_REGISTER_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_literais_numericos_bases_e_representacao_NATIVE_RETURN_REGISTER_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_NATIVE_IMMEDIATE_ENCODING_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_literais_numericos_bases_e_representacao_NATIVE_FLAGS_OFFSET]
 imul rax,rcx
 mov [r12+neboc_literais_numericos_bases_e_representacao_NATIVE_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.semantic_invalid:
 mov qword [r12+neboc_literais_numericos_bases_e_representacao_NATIVE_ERROR_CODE_OFFSET],neboc_literais_numericos_bases_e_representacao_NATIVE_ERROR_SEMANTIC_NOT_VALID
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ir_invalid:
 mov qword [r12+neboc_literais_numericos_bases_e_representacao_NATIVE_ERROR_CODE_OFFSET],neboc_literais_numericos_bases_e_representacao_NATIVE_ERROR_IR_NOT_VALID
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.value_error:
 mov qword [r12+neboc_literais_numericos_bases_e_representacao_NATIVE_ERROR_CODE_OFFSET],NEBOC_NATIVE_ERROR_VALUE_MISMATCH
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.target_error:
 mov qword [r12+neboc_literais_numericos_bases_e_representacao_NATIVE_ERROR_CODE_OFFSET],neboc_literais_numericos_bases_e_representacao_NATIVE_ERROR_TARGET_UNSUPPORTED
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.metadata_error:
 mov qword [r12+neboc_literais_numericos_bases_e_representacao_NATIVE_ERROR_CODE_OFFSET],neboc_literais_numericos_bases_e_representacao_NATIVE_ERROR_RUNTIME_METADATA
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invariant_error:
 mov qword [r12+neboc_literais_numericos_bases_e_representacao_NATIVE_ERROR_CODE_OFFSET],NEBOC_NATIVE_ERROR_INTERNAL_INVARIANT
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 cld
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
