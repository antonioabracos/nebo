; Nebo Assembly — SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-PF003 isolated numeric safety semantic model
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/parser/numeric_safety_api_contract.inc"
%include "compiler/semantic/types/numeric_safety_semantic.inc"

section .text

; neboc_numeric_safety_semantic_analyze(request*) -> StatusCode
; Consumes a successful SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-PF002 API request. The model is isolated from the
; public typechecker, constant evaluator, CLI and target lowering in PF003.
NEBOC_ABI_FUNCTION neboc_numeric_safety_semantic_analyze
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 test r12,r12
 jz .invalid_argument
 mov r13,[r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_API_REQUEST_OFFSET]
 test r13,r13
 jz .invalid_argument
 lea rdi,[r12+NEBOC_SEM_METHOD_ID_OFFSET]
 mov ecx,(neboc_seguranca_numerica_conversoes_e_overflow_SEM_REQUEST_SIZE-NEBOC_SEM_METHOD_ID_OFFSET)/8
 xor eax,eax
 rep stosq

 ; PF002 diagnostics are propagated as source failures with exact method span.
 cmp qword [r13+neboc_seguranca_numerica_conversoes_e_overflow_API_DIAGNOSTIC_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_API_DIAG_NONE
 jne .api_invalid
 cmp qword [r13+neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_METHOD
 jne .api_invariant
 cmp qword [r13+neboc_seguranca_numerica_conversoes_e_overflow_API_ARGUMENT_COUNT_OFFSET],0
 jne .api_invariant

 ; Receiver, source and span provenance must be exact.
 mov rax,[r13+neboc_seguranca_numerica_conversoes_e_overflow_API_RECEIVER_TYPE_OFFSET]
 cmp rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RECEIVER_TYPE_OFFSET]
 jne .type_invariant
 mov rax,[r13+neboc_seguranca_numerica_conversoes_e_overflow_API_SOURCE_ID_OFFSET]
 cmp rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_AST_SOURCE_ID_OFFSET]
 jne .span_invariant
 mov r14,[r13+neboc_seguranca_numerica_conversoes_e_overflow_API_ABSOLUTE_START_OFFSET]
 cmp r14,[r12+NEBOC_SEM_AST_METHOD_START_OFFSET]
 jne .span_invariant
 mov r15,r14
 add r15,[r13+neboc_seguranca_numerica_conversoes_e_overflow_API_SUBJECT_LENGTH_OFFSET]
 cmp r15,[r12+NEBOC_SEM_AST_METHOD_END_OFFSET]
 jne .span_invariant
 mov rbx,[r12+NEBOC_SEM_AST_CALL_START_OFFSET]
 mov rax,[r12+NEBOC_SEM_AST_CALL_END_OFFSET]
 cmp rax,rbx
 jbe .span_invariant
 cmp r14,rbx
 jb .span_invariant
 cmp r15,rax
 ja .span_invariant

 cmp qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_SOURCE_FORM_OFFSET],NEBOC_SEM_SOURCE_EXPLICIT_CONSTRUCTOR
 ja .source_form_invariant
 cmp qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_CONSTANT_STATE_OFFSET],NEBOC_SEM_CONSTANT_KNOWN
 ja .constant_invariant
 cmp qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_CONSTANT_STATE_OFFSET],NEBOC_SEM_CONSTANT_UNKNOWN
 jne .dispatch
 cmp qword [r12+NEBOC_SEM_CONSTANT_BITS_OFFSET],0
 jne .constant_invariant

.dispatch:
 mov rax,[r13+neboc_seguranca_numerica_conversoes_e_overflow_API_METHOD_ID_OFFSET]
 cmp rax,NEBOC_API_METHOD_INT_TO_FLOAT
 je .int_to_float
 cmp rax,NEBOC_API_METHOD_FLOAT_IS_FINITE
 je .is_finite
 cmp rax,NEBOC_API_METHOD_FLOAT_IS_NAN
 je .is_nan
 cmp rax,NEBOC_API_METHOD_FLOAT_IS_INFINITE
 je .is_infinite
 cmp rax,NEBOC_API_METHOD_FLOAT_IS_NEGATIVE_ZERO
 je .is_negative_zero
 jmp .method_invariant

.int_to_float:
 cmp qword [r13+neboc_seguranca_numerica_conversoes_e_overflow_API_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_ID_INT
 jne .type_invariant
 cmp qword [r13+neboc_seguranca_numerica_conversoes_e_overflow_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_FLOAT
 jne .result_invariant
 cmp qword [r13+neboc_seguranca_numerica_conversoes_e_overflow_API_FLAGS_OFFSET],NEBOC_API_FLAGS_TO_FLOAT
 jne .flag_invariant
 mov qword [r12+NEBOC_SEM_METHOD_ID_OFFSET],NEBOC_API_METHOD_INT_TO_FLOAT
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_OPERAND_TYPE_OFFSET],NEBOC_TYPE_ID_INT
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_FLOAT
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEMANTIC_KIND_OFFSET],NEBOC_SEM_KIND_CONVERSION
 mov qword [r12+NEBOC_SEM_CONVERSION_POLICY_OFFSET],NEBOC_SEM_CONVERSION_I64_TO_F64_ROUND_TIES_EVEN
 mov qword [r12+NEBOC_SEM_CLASSIFIER_KIND_OFFSET],NEBOC_SEM_CLASSIFIER_NONE
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_EFFECT_FLAGS_OFFSET],NEBOC_SEM_EFFECTS_CONVERSION
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_NUMERIC_CONVERSION
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_ABSTRACT_I64_TO_F64
 mov qword [r12+NEBOC_SEM_LIR_OPERAND_REPR_OFFSET],NEBOC_SEM_REPR_SIGNED_I64
 mov qword [r12+NEBOC_SEM_LIR_RESULT_REPR_OFFSET],NEBOC_SEM_REPR_IEEE_BINARY64_BITS
 jmp .success

.is_finite:
 mov ebx,NEBOC_SEM_CLASSIFIER_FINITE
 jmp .classifier
.is_nan:
 mov ebx,NEBOC_SEM_CLASSIFIER_NAN
 jmp .classifier
.is_infinite:
 mov ebx,NEBOC_SEM_CLASSIFIER_INFINITE
 jmp .classifier
.is_negative_zero:
 mov ebx,NEBOC_SEM_CLASSIFIER_NEGATIVE_ZERO
.classifier:
 cmp qword [r13+neboc_seguranca_numerica_conversoes_e_overflow_API_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_ID_FLOAT
 jne .type_invariant
 cmp qword [r13+neboc_seguranca_numerica_conversoes_e_overflow_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_BOOL
 jne .result_invariant
 cmp qword [r13+neboc_seguranca_numerica_conversoes_e_overflow_API_FLAGS_OFFSET],NEBOC_API_FLAGS_CLASSIFIER
 jne .flag_invariant
 mov rax,[r13+neboc_seguranca_numerica_conversoes_e_overflow_API_METHOD_ID_OFFSET]
 mov [r12+NEBOC_SEM_METHOD_ID_OFFSET],rax
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_OPERAND_TYPE_OFFSET],NEBOC_TYPE_ID_FLOAT
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_BOOL
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEMANTIC_KIND_OFFSET],NEBOC_SEM_KIND_CLASSIFIER
 mov qword [r12+NEBOC_SEM_CONVERSION_POLICY_OFFSET],NEBOC_SEM_CONVERSION_NONE
 mov [r12+NEBOC_SEM_CLASSIFIER_KIND_OFFSET],rbx
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_EFFECT_FLAGS_OFFSET],NEBOC_SEM_EFFECTS_CLASSIFIER
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_FLOAT_CLASSIFIER
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_ABSTRACT_F64_CLASSIFY
 mov qword [r12+NEBOC_SEM_LIR_OPERAND_REPR_OFFSET],NEBOC_SEM_REPR_IEEE_BINARY64_BITS
 mov qword [r12+NEBOC_SEM_LIR_RESULT_REPR_OFFSET],NEBOC_SEM_REPR_CANONICAL_BOOL

.success:
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RUNTIME_METADATA_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_SEM_RUNTIME_METADATA_NONE
 call .compute_hashes
 xor eax,eax
 jmp .done

.api_invalid:
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_API_INVALID
 mov rax,[r13+neboc_seguranca_numerica_conversoes_e_overflow_API_DIAGNOSTIC_OFFSET]
 mov [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_SOURCE_DIAG_OFFSET],rax
 mov rax,[r13+neboc_seguranca_numerica_conversoes_e_overflow_API_ERROR_START_OFFSET]
 mov [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_START_OFFSET],rax
 mov rax,[r13+neboc_seguranca_numerica_conversoes_e_overflow_API_ERROR_END_OFFSET]
 mov [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_END_OFFSET],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.api_invariant:
 mov ecx,NEBOC_SEM_ERROR_API_INVARIANT
 jmp .internal_error
.type_invariant:
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_TYPE_INVARIANT
 jmp .internal_error
.flag_invariant:
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_FLAG_INVARIANT
 jmp .internal_error
.span_invariant:
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_SPAN_INVARIANT
 jmp .internal_error
.source_form_invariant:
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_SOURCE_FORM_INVARIANT
 jmp .internal_error
.constant_invariant:
 mov ecx,NEBOC_SEM_ERROR_CONSTANT_INVARIANT
 jmp .internal_error
.method_invariant:
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_METHOD_INVARIANT
 jmp .internal_error
.result_invariant:
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_RESULT_INVARIANT
.internal_error:
 mov [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_CODE_OFFSET],rcx
 mov rax,[r12+NEBOC_SEM_AST_METHOD_START_OFFSET]
 mov [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_START_OFFSET],rax
 mov rax,[r12+NEBOC_SEM_AST_METHOD_END_OFFSET]
 mov [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_END_OFFSET],rax
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done

.compute_hashes:
 mov rax,neboc_seguranca_numerica_conversoes_e_overflow_SEM_HASH_OFFSET_BASIS
 mov rcx,neboc_seguranca_numerica_conversoes_e_overflow_SEM_HASH_PRIME
 xor rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RECEIVER_TYPE_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RECEIVER_VALUE_ID_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_CONSTANT_STATE_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_SEM_CONSTANT_BITS_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_SEM_METHOD_ID_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RESULT_TYPE_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_SEMANTIC_KIND_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_SEM_CONVERSION_POLICY_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_SEM_CLASSIFIER_KIND_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_EFFECT_FLAGS_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_HIR_KIND_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_LIR_KIND_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_SEM_LIR_OPERAND_REPR_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_SEM_LIR_RESULT_REPR_OFFSET]
 imul rax,rcx
 mov [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_SEMANTIC_HASH_OFFSET],rax
 xor rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_SOURCE_FORM_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_AST_SOURCE_ID_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_SEM_AST_CALL_START_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_SEM_AST_CALL_END_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_SEM_AST_METHOD_START_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_SEM_AST_METHOD_END_OFFSET]
 imul rax,rcx
 mov [r12+neboc_seguranca_numerica_conversoes_e_overflow_SEM_PROVENANCE_HASH_OFFSET],rax
 ret

.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
