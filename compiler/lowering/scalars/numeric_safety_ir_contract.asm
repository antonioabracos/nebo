; Nebo Assembly — SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-PF003 abstract numeric safety HIR/LIR contract
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/parser/numeric_safety_api_contract.inc"
%include "compiler/semantic/types/numeric_safety_semantic.inc"
%include "compiler/lowering/scalars/numeric_safety_ir_contract.inc"

section .text

; neboc_numeric_safety_ir_lower(request*) -> StatusCode
; Abstract semantic-to-IR contract only. No target instruction, register,
; runtime helper or public compiler integration is selected by PF003.
NEBOC_ABI_FUNCTION neboc_numeric_safety_ir_lower
 push r12
 push r13
 mov r12,rdi
 test r12,r12
 jz .invalid_argument
 mov r13,[r12+neboc_seguranca_numerica_conversoes_e_overflow_IR_SEMANTIC_REQUEST_OFFSET]
 test r13,r13
 jz .invalid_argument
 lea rdi,[r12+neboc_seguranca_numerica_conversoes_e_overflow_IR_HIR_KIND_OFFSET]
 mov ecx,(neboc_seguranca_numerica_conversoes_e_overflow_IR_REQUEST_SIZE-neboc_seguranca_numerica_conversoes_e_overflow_IR_HIR_KIND_OFFSET)/8
 xor eax,eax
 rep stosq
 cmp qword [r13+neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_NONE
 jne .semantic_invalid
 cmp qword [r13+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RUNTIME_METADATA_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_SEM_RUNTIME_METADATA_NONE
 jne .semantic_invariant

 mov rax,[r13+neboc_seguranca_numerica_conversoes_e_overflow_SEMANTIC_KIND_OFFSET]
 cmp rax,NEBOC_SEM_KIND_CONVERSION
 je .conversion
 cmp rax,NEBOC_SEM_KIND_CLASSIFIER
 je .classifier
 jmp .semantic_invariant

.conversion:
 cmp qword [r13+NEBOC_SEM_METHOD_ID_OFFSET],NEBOC_API_METHOD_INT_TO_FLOAT
 jne .semantic_invariant
 cmp qword [r13+neboc_seguranca_numerica_conversoes_e_overflow_SEM_OPERAND_TYPE_OFFSET],NEBOC_TYPE_ID_INT
 jne .semantic_invariant
 cmp qword [r13+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_FLOAT
 jne .semantic_invariant
 cmp qword [r13+neboc_seguranca_numerica_conversoes_e_overflow_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_NUMERIC_CONVERSION
 jne .semantic_invariant
 cmp qword [r13+neboc_seguranca_numerica_conversoes_e_overflow_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_ABSTRACT_I64_TO_F64
 jne .semantic_invariant
 cmp qword [r13+NEBOC_SEM_CONVERSION_POLICY_OFFSET],NEBOC_SEM_CONVERSION_I64_TO_F64_ROUND_TIES_EVEN
 jne .semantic_invariant
 jmp .copy

.classifier:
 cmp qword [r13+NEBOC_SEM_METHOD_ID_OFFSET],NEBOC_API_METHOD_FLOAT_IS_FINITE
 jb .semantic_invariant
 cmp qword [r13+NEBOC_SEM_METHOD_ID_OFFSET],NEBOC_API_METHOD_FLOAT_IS_NEGATIVE_ZERO
 ja .semantic_invariant
 cmp qword [r13+neboc_seguranca_numerica_conversoes_e_overflow_SEM_OPERAND_TYPE_OFFSET],NEBOC_TYPE_ID_FLOAT
 jne .semantic_invariant
 cmp qword [r13+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_BOOL
 jne .semantic_invariant
 cmp qword [r13+neboc_seguranca_numerica_conversoes_e_overflow_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_FLOAT_CLASSIFIER
 jne .semantic_invariant
 cmp qword [r13+neboc_seguranca_numerica_conversoes_e_overflow_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_ABSTRACT_F64_CLASSIFY
 jne .semantic_invariant
 mov rax,[r13+NEBOC_SEM_METHOD_ID_OFFSET]
 dec rax
 cmp rax,[r13+NEBOC_SEM_CLASSIFIER_KIND_OFFSET]
 jne .semantic_invariant

.copy:
 mov rax,[r13+neboc_seguranca_numerica_conversoes_e_overflow_SEM_HIR_KIND_OFFSET]
 mov [r12+neboc_seguranca_numerica_conversoes_e_overflow_IR_HIR_KIND_OFFSET],rax
 mov rax,[r13+neboc_seguranca_numerica_conversoes_e_overflow_SEM_OPERAND_TYPE_OFFSET]
 mov [r12+NEBOC_IR_HIR_OPERAND_TYPE_OFFSET],rax
 mov rax,[r13+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RECEIVER_VALUE_ID_OFFSET]
 mov [r12+NEBOC_IR_HIR_OPERAND_VALUE_ID_OFFSET],rax
 mov rax,[r13+neboc_seguranca_numerica_conversoes_e_overflow_SEM_CONSTANT_STATE_OFFSET]
 mov [r12+NEBOC_IR_HIR_CONSTANT_STATE_OFFSET],rax
 mov rax,[r13+NEBOC_SEM_CONSTANT_BITS_OFFSET]
 mov [r12+NEBOC_IR_HIR_CONSTANT_BITS_OFFSET],rax
 mov rax,[r13+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RESULT_TYPE_OFFSET]
 mov [r12+NEBOC_IR_HIR_RESULT_TYPE_OFFSET],rax
 mov rax,[r13+NEBOC_SEM_METHOD_ID_OFFSET]
 mov [r12+NEBOC_IR_HIR_OPERATION_OFFSET],rax
 mov rax,[r13+neboc_seguranca_numerica_conversoes_e_overflow_SEM_AST_SOURCE_ID_OFFSET]
 mov [r12+neboc_seguranca_numerica_conversoes_e_overflow_IR_HIR_SOURCE_ID_OFFSET],rax
 mov rax,[r13+NEBOC_SEM_AST_CALL_START_OFFSET]
 mov [r12+NEBOC_IR_HIR_CALL_START_OFFSET],rax
 mov rax,[r13+NEBOC_SEM_AST_CALL_END_OFFSET]
 mov [r12+NEBOC_IR_HIR_CALL_END_OFFSET],rax
 mov rax,[r13+NEBOC_SEM_AST_METHOD_START_OFFSET]
 mov [r12+NEBOC_IR_HIR_METHOD_START_OFFSET],rax
 mov rax,[r13+NEBOC_SEM_AST_METHOD_END_OFFSET]
 mov [r12+NEBOC_IR_HIR_METHOD_END_OFFSET],rax
 mov rax,[r13+neboc_seguranca_numerica_conversoes_e_overflow_SEM_PROVENANCE_HASH_OFFSET]
 mov [r12+neboc_seguranca_numerica_conversoes_e_overflow_IR_HIR_PROVENANCE_HASH_OFFSET],rax
 mov rax,[r13+neboc_seguranca_numerica_conversoes_e_overflow_SEM_LIR_KIND_OFFSET]
 mov [r12+neboc_seguranca_numerica_conversoes_e_overflow_IR_LIR_KIND_OFFSET],rax
 mov rax,[r13+NEBOC_SEM_LIR_OPERAND_REPR_OFFSET]
 mov [r12+NEBOC_IR_LIR_OPERAND_REPR_OFFSET],rax
 mov rax,[r13+NEBOC_SEM_LIR_RESULT_REPR_OFFSET]
 mov [r12+NEBOC_IR_LIR_RESULT_REPR_OFFSET],rax
 mov rax,[r13+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RECEIVER_VALUE_ID_OFFSET]
 mov [r12+NEBOC_IR_LIR_OPERAND_VALUE_ID_OFFSET],rax
 mov rax,[r13+neboc_seguranca_numerica_conversoes_e_overflow_SEM_CONSTANT_STATE_OFFSET]
 mov [r12+NEBOC_IR_LIR_CONSTANT_STATE_OFFSET],rax
 mov rax,[r13+NEBOC_SEM_CONSTANT_BITS_OFFSET]
 mov [r12+NEBOC_IR_LIR_CONSTANT_BITS_OFFSET],rax
 mov rax,[r13+NEBOC_SEM_CONVERSION_POLICY_OFFSET]
 test rax,rax
 jnz .policy_ready
 mov rax,[r13+NEBOC_SEM_CLASSIFIER_KIND_OFFSET]
.policy_ready:
 mov [r12+NEBOC_IR_LIR_POLICY_OFFSET],rax
 mov rax,[r13+neboc_seguranca_numerica_conversoes_e_overflow_SEM_EFFECT_FLAGS_OFFSET]
 mov [r12+NEBOC_IR_LIR_FLAGS_OFFSET],rax
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_IR_RUNTIME_METADATA_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_IR_RUNTIME_METADATA_NONE

 ; Deterministic IR hash excludes spelling/spans and target lowering.
 mov rax,1469598103934665603
 mov rcx,1099511628211
 xor rax,[r13+neboc_seguranca_numerica_conversoes_e_overflow_SEM_SEMANTIC_HASH_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_IR_HIR_KIND_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_IR_HIR_OPERAND_TYPE_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_IR_HIR_OPERAND_VALUE_ID_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_IR_HIR_CONSTANT_STATE_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_IR_HIR_CONSTANT_BITS_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_IR_HIR_RESULT_TYPE_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_IR_HIR_OPERATION_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_IR_LIR_KIND_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_IR_LIR_OPERAND_REPR_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_IR_LIR_RESULT_REPR_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_IR_LIR_POLICY_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_IR_LIR_FLAGS_OFFSET]
 imul rax,rcx
 mov [r12+neboc_seguranca_numerica_conversoes_e_overflow_IR_HASH_OFFSET],rax
 xor eax,eax
 jmp .done

.semantic_invalid:
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_IR_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_IR_ERROR_SEMANTIC_NOT_VALID
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.semantic_invariant:
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_IR_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_IR_ERROR_SEMANTIC_INVARIANT
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r13
 pop r12
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
