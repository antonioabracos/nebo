; Nebo Assembly — SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-PF003 semantic model and abstract IR invariants
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/parser/numeric_safety_api_contract.inc"
%include "compiler/semantic/types/numeric_safety_semantic.inc"
%include "compiler/lowering/scalars/numeric_safety_ir_contract.inc"

extern neboc_numeric_safety_api_contract
extern neboc_numeric_safety_semantic_analyze
extern neboc_numeric_safety_ir_lower
extern neboc_host_process_exit

%macro SET_CONTEXT 5
 mov qword [rel current_source_form],%1
 mov qword [rel current_source_id],%2
 mov qword [rel current_call_start],%3
 mov qword [rel current_method_start],%4
 mov qword [rel current_method_end],%4+%5
 mov qword [rel current_call_end],%4+%5+2
%endmacro

section .rodata
name_to_float: db "toFloat"
name_is_finite: db "isFinite"
name_is_nan: db "isNaN"
name_is_infinite: db "isInfinite"
name_is_negative_zero: db "isNegativeZero"

section .bss align=16
api: resb neboc_seguranca_numerica_conversoes_e_overflow_API_REQUEST_SIZE
sem: resb neboc_seguranca_numerica_conversoes_e_overflow_SEM_REQUEST_SIZE
ir: resb neboc_seguranca_numerica_conversoes_e_overflow_IR_REQUEST_SIZE
current_source_form: resq 1
current_source_id: resq 1
current_call_start: resq 1
current_call_end: resq 1
current_method_start: resq 1
current_method_end: resq 1
semantic_hash_saved: resq 1
provenance_hash_saved: resq 1
ir_hash_saved: resq 1
negative_zero_hash: resq 1

section .text

; prepare(name,len,receiver_type,value_id,constant_state,constant_bits)
; -> status from semantic analysis. Context/spans are loaded from globals.
prepare:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov [rsp],r9
 lea rdi,[rel api]
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_API_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov qword [rel api+neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_METHOD
 mov [rel api+neboc_seguranca_numerica_conversoes_e_overflow_API_RECEIVER_TYPE_OFFSET],r14
 mov [rel api+neboc_seguranca_numerica_conversoes_e_overflow_API_SUBJECT_PTR_OFFSET],r12
 mov [rel api+neboc_seguranca_numerica_conversoes_e_overflow_API_SUBJECT_LENGTH_OFFSET],r13
 mov qword [rel api+neboc_seguranca_numerica_conversoes_e_overflow_API_ARGUMENT_COUNT_OFFSET],0
 mov rax,[rel current_source_id]
 mov [rel api+neboc_seguranca_numerica_conversoes_e_overflow_API_SOURCE_ID_OFFSET],rax
 mov rax,[rel current_method_start]
 mov [rel api+neboc_seguranca_numerica_conversoes_e_overflow_API_ABSOLUTE_START_OFFSET],rax
 lea rdi,[rel api]
 call neboc_numeric_safety_api_contract
 lea rdi,[rel sem]
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_SEM_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rel api]
 mov [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_API_REQUEST_OFFSET],rax
 mov [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RECEIVER_TYPE_OFFSET],r14
 mov [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RECEIVER_VALUE_ID_OFFSET],r15
 mov [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_CONSTANT_STATE_OFFSET],rbx
 mov rax,[rsp]
 mov [rel sem+NEBOC_SEM_CONSTANT_BITS_OFFSET],rax
 mov rax,[rel current_source_form]
 mov [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_SOURCE_FORM_OFFSET],rax
 mov rax,[rel current_source_id]
 mov [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_AST_SOURCE_ID_OFFSET],rax
 mov rax,[rel current_call_start]
 mov [rel sem+NEBOC_SEM_AST_CALL_START_OFFSET],rax
 mov rax,[rel current_call_end]
 mov [rel sem+NEBOC_SEM_AST_CALL_END_OFFSET],rax
 mov rax,[rel current_method_start]
 mov [rel sem+NEBOC_SEM_AST_METHOD_START_OFFSET],rax
 mov rax,[rel current_method_end]
 mov [rel sem+NEBOC_SEM_AST_METHOD_END_OFFSET],rax
 lea rdi,[rel sem]
 call neboc_numeric_safety_semantic_analyze
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

lower_ir:
 lea rdi,[rel ir]
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_IR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rel sem]
 mov [rel ir+neboc_seguranca_numerica_conversoes_e_overflow_IR_SEMANTIC_REQUEST_OFFSET],rax
 lea rdi,[rel ir]
 jmp neboc_numeric_safety_ir_lower

assert_to_float:
 cmp qword [rel sem+NEBOC_SEM_METHOD_ID_OFFSET],NEBOC_API_METHOD_INT_TO_FLOAT
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_OPERAND_TYPE_OFFSET],NEBOC_TYPE_ID_INT
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_FLOAT
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEMANTIC_KIND_OFFSET],NEBOC_SEM_KIND_CONVERSION
 jne fail
 cmp qword [rel sem+NEBOC_SEM_CONVERSION_POLICY_OFFSET],NEBOC_SEM_CONVERSION_I64_TO_F64_ROUND_TIES_EVEN
 jne fail
 cmp qword [rel sem+NEBOC_SEM_CLASSIFIER_KIND_OFFSET],NEBOC_SEM_CLASSIFIER_NONE
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_EFFECT_FLAGS_OFFSET],NEBOC_SEM_EFFECTS_CONVERSION
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_NUMERIC_CONVERSION
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_ABSTRACT_I64_TO_F64
 jne fail
 cmp qword [rel sem+NEBOC_SEM_LIR_OPERAND_REPR_OFFSET],NEBOC_SEM_REPR_SIGNED_I64
 jne fail
 cmp qword [rel sem+NEBOC_SEM_LIR_RESULT_REPR_OFFSET],NEBOC_SEM_REPR_IEEE_BINARY64_BITS
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RUNTIME_METADATA_OFFSET],0
 jne fail
 ret

; rdi = expected classifier kind
assert_classifier:
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_OPERAND_TYPE_OFFSET],NEBOC_TYPE_ID_FLOAT
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_BOOL
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEMANTIC_KIND_OFFSET],NEBOC_SEM_KIND_CLASSIFIER
 jne fail
 cmp qword [rel sem+NEBOC_SEM_CONVERSION_POLICY_OFFSET],NEBOC_SEM_CONVERSION_NONE
 jne fail
 cmp [rel sem+NEBOC_SEM_CLASSIFIER_KIND_OFFSET],rdi
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_EFFECT_FLAGS_OFFSET],NEBOC_SEM_EFFECTS_CLASSIFIER
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_FLOAT_CLASSIFIER
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_ABSTRACT_F64_CLASSIFY
 jne fail
 cmp qword [rel sem+NEBOC_SEM_LIR_OPERAND_REPR_OFFSET],NEBOC_SEM_REPR_IEEE_BINARY64_BITS
 jne fail
 cmp qword [rel sem+NEBOC_SEM_LIR_RESULT_REPR_OFFSET],NEBOC_SEM_REPR_CANONICAL_BOOL
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RUNTIME_METADATA_OFFSET],0
 jne fail
 ret

assert_ir_to_float:
 call lower_ir
 test eax,eax
 jnz fail
 cmp qword [rel ir+neboc_seguranca_numerica_conversoes_e_overflow_IR_HIR_KIND_OFFSET],NEBOC_IR_HIR_NUMERIC_CONVERSION
 jne fail
 cmp qword [rel ir+NEBOC_IR_HIR_OPERAND_TYPE_OFFSET],NEBOC_TYPE_ID_INT
 jne fail
 cmp qword [rel ir+NEBOC_IR_HIR_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_FLOAT
 jne fail
 cmp qword [rel ir+neboc_seguranca_numerica_conversoes_e_overflow_IR_LIR_KIND_OFFSET],NEBOC_IR_LIR_ABSTRACT_I64_TO_F64
 jne fail
 cmp qword [rel ir+NEBOC_IR_LIR_OPERAND_REPR_OFFSET],NEBOC_IR_REPR_SIGNED_I64
 jne fail
 cmp qword [rel ir+NEBOC_IR_LIR_RESULT_REPR_OFFSET],NEBOC_IR_REPR_IEEE_BINARY64_BITS
 jne fail
 cmp qword [rel ir+NEBOC_IR_LIR_POLICY_OFFSET],NEBOC_SEM_CONVERSION_I64_TO_F64_ROUND_TIES_EVEN
 jne fail
 cmp qword [rel ir+neboc_seguranca_numerica_conversoes_e_overflow_IR_RUNTIME_METADATA_OFFSET],0
 jne fail
 ret

; rdi = expected classifier policy
assert_ir_classifier:
 push rdi
 call lower_ir
 pop rdi
 test eax,eax
 jnz fail
 cmp qword [rel ir+neboc_seguranca_numerica_conversoes_e_overflow_IR_HIR_KIND_OFFSET],NEBOC_IR_HIR_FLOAT_CLASSIFIER
 jne fail
 cmp qword [rel ir+NEBOC_IR_HIR_OPERAND_TYPE_OFFSET],NEBOC_TYPE_ID_FLOAT
 jne fail
 cmp qword [rel ir+NEBOC_IR_HIR_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_BOOL
 jne fail
 cmp qword [rel ir+neboc_seguranca_numerica_conversoes_e_overflow_IR_LIR_KIND_OFFSET],NEBOC_IR_LIR_ABSTRACT_F64_CLASSIFY
 jne fail
 cmp qword [rel ir+NEBOC_IR_LIR_OPERAND_REPR_OFFSET],NEBOC_IR_REPR_IEEE_BINARY64_BITS
 jne fail
 cmp qword [rel ir+NEBOC_IR_LIR_RESULT_REPR_OFFSET],NEBOC_IR_REPR_CANONICAL_BOOL
 jne fail
 cmp [rel ir+NEBOC_IR_LIR_POLICY_OFFSET],rdi
 jne fail
 cmp qword [rel ir+neboc_seguranca_numerica_conversoes_e_overflow_IR_RUNTIME_METADATA_OFFSET],0
 jne fail
 ret

global _start
_start:
 mov r13d,1
 ; 1. Implicit Int literal toFloat establishes normalized semantic and IR hashes.
 SET_CONTEXT NEBOC_SEM_SOURCE_IMPLICIT_LITERAL,301,100,103,7
 lea rdi,[rel name_to_float]
 mov esi,7
 mov edx,NEBOC_TYPE_ID_INT
 mov ecx,42
 mov r8d,NEBOC_SEM_CONSTANT_KNOWN
 mov r9d,42
 call prepare
 test eax,eax
 jnz fail
 call assert_to_float
 call assert_ir_to_float
 mov rax,[rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_SEMANTIC_HASH_OFFSET]
 mov [rel semantic_hash_saved],rax
 mov rax,[rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_PROVENANCE_HASH_OFFSET]
 mov [rel provenance_hash_saved],rax
 mov rax,[rel ir+neboc_seguranca_numerica_conversoes_e_overflow_IR_HASH_OFFSET]
 mov [rel ir_hash_saved],rax

 inc r13d
 ; 2. Explicit Int(42) is semantically/IR equivalent but provenance-distinct.
 SET_CONTEXT NEBOC_SEM_SOURCE_EXPLICIT_CONSTRUCTOR,302,200,210,7
 lea rdi,[rel name_to_float]
 mov esi,7
 mov edx,NEBOC_TYPE_ID_INT
 mov ecx,42
 mov r8d,NEBOC_SEM_CONSTANT_KNOWN
 mov r9d,42
 call prepare
 test eax,eax
 jnz fail
 call assert_to_float
 call assert_ir_to_float
 mov rax,[rel semantic_hash_saved]
 cmp rax,[rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_SEMANTIC_HASH_OFFSET]
 jne fail
 mov rax,[rel ir_hash_saved]
 cmp rax,[rel ir+neboc_seguranca_numerica_conversoes_e_overflow_IR_HASH_OFFSET]
 jne fail
 mov rax,[rel provenance_hash_saved]
 cmp rax,[rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_PROVENANCE_HASH_OFFSET]
 je fail

 inc r13d
 ; 3. Non-constant expression remains abstract and carries a stable value ID.
 SET_CONTEXT NEBOC_SEM_SOURCE_EXPRESSION,303,300,306,7
 lea rdi,[rel name_to_float]
 mov esi,7
 mov edx,NEBOC_TYPE_ID_INT
 mov ecx,77
 mov r8d,NEBOC_SEM_CONSTANT_UNKNOWN
 xor r9d,r9d
 call prepare
 test eax,eax
 jnz fail
 call assert_to_float
 call assert_ir_to_float
 cmp qword [rel ir+NEBOC_IR_HIR_OPERAND_VALUE_ID_OFFSET],77
 jne fail
 cmp qword [rel ir+NEBOC_IR_HIR_CONSTANT_STATE_OFFSET],NEBOC_SEM_CONSTANT_UNKNOWN
 jne fail

 inc r13d
 ; 4. INT64_MAX is accepted as bits; conversion is not constant-folded in PF003.
 SET_CONTEXT NEBOC_SEM_SOURCE_IMPLICIT_LITERAL,304,400,403,7
 lea rdi,[rel name_to_float]
 mov esi,7
 mov edx,NEBOC_TYPE_ID_INT
 mov ecx,88
 mov r8d,NEBOC_SEM_CONSTANT_KNOWN
 mov r9,0x7fffffffffffffff
 call prepare
 test eax,eax
 jnz fail
 call assert_to_float
 call assert_ir_to_float
 mov rax,0x7fffffffffffffff
 cmp [rel ir+NEBOC_IR_LIR_CONSTANT_BITS_OFFSET],rax
 jne fail

 inc r13d
 ; 5. Finite classifier produces canonical Bool abstract IR.
 SET_CONTEXT NEBOC_SEM_SOURCE_IMPLICIT_LITERAL,305,500,504,8
 lea rdi,[rel name_is_finite]
 mov esi,8
 mov edx,NEBOC_TYPE_ID_FLOAT
 mov ecx,501
 mov r8d,NEBOC_SEM_CONSTANT_KNOWN
 mov r9,0x3ff8000000000000
 call prepare
 test eax,eax
 jnz fail
 mov edi,NEBOC_SEM_CLASSIFIER_FINITE
 call assert_classifier
 mov edi,NEBOC_SEM_CLASSIFIER_FINITE
 call assert_ir_classifier

 inc r13d
 ; 6. NaN classifier preserves the exact IEEE payload bits.
 SET_CONTEXT NEBOC_SEM_SOURCE_EXPRESSION,306,600,606,5
 lea rdi,[rel name_is_nan]
 mov esi,5
 mov edx,NEBOC_TYPE_ID_FLOAT
 mov ecx,601
 mov r8d,NEBOC_SEM_CONSTANT_KNOWN
 mov r9,0x7ff8000000000001
 call prepare
 test eax,eax
 jnz fail
 mov edi,NEBOC_SEM_CLASSIFIER_NAN
 call assert_classifier
 mov edi,NEBOC_SEM_CLASSIFIER_NAN
 call assert_ir_classifier
 mov rax,0x7ff8000000000001
 cmp [rel ir+NEBOC_IR_LIR_CONSTANT_BITS_OFFSET],rax
 jne fail

 inc r13d
 ; 7. Infinite classifier is an abstract operation, not a runtime helper call.
 SET_CONTEXT NEBOC_SEM_SOURCE_EXPRESSION,307,700,706,10
 lea rdi,[rel name_is_infinite]
 mov esi,10
 mov edx,NEBOC_TYPE_ID_FLOAT
 mov ecx,701
 mov r8d,NEBOC_SEM_CONSTANT_KNOWN
 mov r9,0x7ff0000000000000
 call prepare
 test eax,eax
 jnz fail
 mov edi,NEBOC_SEM_CLASSIFIER_INFINITE
 call assert_classifier
 mov edi,NEBOC_SEM_CLASSIFIER_INFINITE
 call assert_ir_classifier

 inc r13d
 ; 8. Negative zero is preserved by its exact binary64 bit pattern.
 SET_CONTEXT NEBOC_SEM_SOURCE_EXPRESSION,308,800,807,14
 lea rdi,[rel name_is_negative_zero]
 mov esi,14
 mov edx,NEBOC_TYPE_ID_FLOAT
 mov ecx,801
 mov r8d,NEBOC_SEM_CONSTANT_KNOWN
 mov r9,0x8000000000000000
 call prepare
 test eax,eax
 jnz fail
 mov edi,NEBOC_SEM_CLASSIFIER_NEGATIVE_ZERO
 call assert_classifier
 mov edi,NEBOC_SEM_CLASSIFIER_NEGATIVE_ZERO
 call assert_ir_classifier
 mov rax,[rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_SEMANTIC_HASH_OFFSET]
 mov [rel negative_zero_hash],rax

 inc r13d
 ; 9. Positive zero has distinct semantics because IEEE operand bits differ.
 SET_CONTEXT NEBOC_SEM_SOURCE_IMPLICIT_LITERAL,309,900,904,14
 lea rdi,[rel name_is_negative_zero]
 mov esi,14
 mov edx,NEBOC_TYPE_ID_FLOAT
 mov ecx,801
 mov r8d,NEBOC_SEM_CONSTANT_KNOWN
 xor r9d,r9d
 call prepare
 test eax,eax
 jnz fail
 mov edi,NEBOC_SEM_CLASSIFIER_NEGATIVE_ZERO
 call assert_classifier
 mov rax,[rel negative_zero_hash]
 cmp rax,[rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_SEMANTIC_HASH_OFFSET]
 je fail

 inc r13d
 ; 10. PF002 receiver diagnostic is propagated with exact method span.
 SET_CONTEXT NEBOC_SEM_SOURCE_IMPLICIT_LITERAL,310,1000,1004,7
 lea rdi,[rel name_to_float]
 mov esi,7
 mov edx,NEBOC_TYPE_ID_FLOAT
 mov ecx,1001
 mov r8d,NEBOC_SEM_CONSTANT_KNOWN
 mov r9,0x3ff0000000000000
 call prepare
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_API_INVALID
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_SOURCE_DIAG_OFFSET],NEBOC_API_DIAG_RECEIVER_MUST_BE_INT
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_START_OFFSET],1004
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_END_OFFSET],1011
 jne fail

 inc r13d
 ; 11. A successful API request with tampered flags is an internal invariant error.
 SET_CONTEXT NEBOC_SEM_SOURCE_IMPLICIT_LITERAL,311,1100,1103,7
 lea rdi,[rel name_to_float]
 mov esi,7
 mov edx,NEBOC_TYPE_ID_INT
 mov ecx,42
 mov r8d,NEBOC_SEM_CONSTANT_KNOWN
 mov r9d,42
 call prepare
 test eax,eax
 jnz fail
 mov qword [rel api+neboc_seguranca_numerica_conversoes_e_overflow_API_FLAGS_OFFSET],0
 lea rdi,[rel sem]
 call neboc_numeric_safety_semantic_analyze
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_FLAG_INVARIANT
 jne fail

 inc r13d
 ; 12. Receiver type disagreement between API and semantic request is rejected.
 SET_CONTEXT NEBOC_SEM_SOURCE_IMPLICIT_LITERAL,312,1200,1203,7
 lea rdi,[rel name_to_float]
 mov esi,7
 mov edx,NEBOC_TYPE_ID_INT
 mov ecx,42
 mov r8d,NEBOC_SEM_CONSTANT_KNOWN
 mov r9d,42
 call prepare
 test eax,eax
 jnz fail
 mov qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_ID_FLOAT
 lea rdi,[rel sem]
 call neboc_numeric_safety_semantic_analyze
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_TYPE_INVARIANT
 jne fail

 inc r13d
 ; 13. Method-end tampering is an exact span invariant failure.
 SET_CONTEXT NEBOC_SEM_SOURCE_IMPLICIT_LITERAL,313,1300,1303,7
 lea rdi,[rel name_to_float]
 mov esi,7
 mov edx,NEBOC_TYPE_ID_INT
 mov ecx,42
 mov r8d,NEBOC_SEM_CONSTANT_KNOWN
 mov r9d,42
 call prepare
 test eax,eax
 jnz fail
 inc qword [rel sem+NEBOC_SEM_AST_METHOD_END_OFFSET]
 lea rdi,[rel sem]
 call neboc_numeric_safety_semantic_analyze
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_SPAN_INVARIANT
 jne fail

 inc r13d
 ; 14. Call span must encompass the method span.
 SET_CONTEXT NEBOC_SEM_SOURCE_IMPLICIT_LITERAL,314,1400,1403,7
 lea rdi,[rel name_to_float]
 mov esi,7
 mov edx,NEBOC_TYPE_ID_INT
 mov ecx,42
 mov r8d,NEBOC_SEM_CONSTANT_KNOWN
 mov r9d,42
 call prepare
 test eax,eax
 jnz fail
 mov qword [rel sem+NEBOC_SEM_AST_CALL_START_OFFSET],1404
 lea rdi,[rel sem]
 call neboc_numeric_safety_semantic_analyze
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_SPAN_INVARIANT
 jne fail

 inc r13d
 ; 15. Unknown source-form provenance is rejected.
 SET_CONTEXT NEBOC_SEM_SOURCE_IMPLICIT_LITERAL,315,1500,1503,7
 lea rdi,[rel name_to_float]
 mov esi,7
 mov edx,NEBOC_TYPE_ID_INT
 mov ecx,42
 mov r8d,NEBOC_SEM_CONSTANT_KNOWN
 mov r9d,42
 call prepare
 test eax,eax
 jnz fail
 mov qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_SOURCE_FORM_OFFSET],3
 lea rdi,[rel sem]
 call neboc_numeric_safety_semantic_analyze
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_SOURCE_FORM_INVARIANT
 jne fail

 inc r13d
 ; 16. Unknown constant-state enum is rejected.
 SET_CONTEXT NEBOC_SEM_SOURCE_IMPLICIT_LITERAL,316,1600,1603,7
 lea rdi,[rel name_to_float]
 mov esi,7
 mov edx,NEBOC_TYPE_ID_INT
 mov ecx,42
 mov r8d,2
 mov r9d,42
 call prepare
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_CODE_OFFSET],NEBOC_SEM_ERROR_CONSTANT_INVARIANT
 jne fail

 inc r13d
 ; 17. Unknown constants cannot carry hidden bits.
 SET_CONTEXT NEBOC_SEM_SOURCE_EXPRESSION,317,1700,1703,7
 lea rdi,[rel name_to_float]
 mov esi,7
 mov edx,NEBOC_TYPE_ID_INT
 mov ecx,77
 mov r8d,NEBOC_SEM_CONSTANT_UNKNOWN
 mov r9d,1
 call prepare
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 jne fail
 cmp qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_ERROR_CODE_OFFSET],NEBOC_SEM_ERROR_CONSTANT_INVARIANT
 jne fail

 inc r13d
 ; 18. IR lowering propagates a semantic source failure and emits no IR.
 SET_CONTEXT NEBOC_SEM_SOURCE_IMPLICIT_LITERAL,318,1800,1804,7
 lea rdi,[rel name_to_float]
 mov esi,7
 mov edx,NEBOC_TYPE_ID_FLOAT
 mov ecx,1801
 mov r8d,NEBOC_SEM_CONSTANT_KNOWN
 mov r9,0x3ff0000000000000
 call prepare
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 call lower_ir
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel ir+neboc_seguranca_numerica_conversoes_e_overflow_IR_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_IR_ERROR_SEMANTIC_NOT_VALID
 jne fail

 inc r13d
 ; 19. IR rejects a tampered semantic LIR invariant.
 SET_CONTEXT NEBOC_SEM_SOURCE_IMPLICIT_LITERAL,319,1900,1903,7
 lea rdi,[rel name_to_float]
 mov esi,7
 mov edx,NEBOC_TYPE_ID_INT
 mov ecx,42
 mov r8d,NEBOC_SEM_CONSTANT_KNOWN
 mov r9d,42
 call prepare
 test eax,eax
 jnz fail
 mov qword [rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_LIR_KIND_OFFSET],99
 call lower_ir
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 jne fail
 cmp qword [rel ir+neboc_seguranca_numerica_conversoes_e_overflow_IR_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_IR_ERROR_SEMANTIC_INVARIANT
 jne fail

 inc r13d
 ; 20. Repeated exact semantic and IR requests are deterministic.
 SET_CONTEXT NEBOC_SEM_SOURCE_IMPLICIT_LITERAL,320,2000,2003,7
 lea rdi,[rel name_to_float]
 mov esi,7
 mov edx,NEBOC_TYPE_ID_INT
 mov ecx,42
 mov r8d,NEBOC_SEM_CONSTANT_KNOWN
 mov r9d,42
 call prepare
 test eax,eax
 jnz fail
 call lower_ir
 test eax,eax
 jnz fail
 mov rax,[rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_SEMANTIC_HASH_OFFSET]
 mov [rel semantic_hash_saved],rax
 mov rax,[rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_PROVENANCE_HASH_OFFSET]
 mov [rel provenance_hash_saved],rax
 mov rax,[rel ir+neboc_seguranca_numerica_conversoes_e_overflow_IR_HASH_OFFSET]
 mov [rel ir_hash_saved],rax
 lea rdi,[rel sem]
 call neboc_numeric_safety_semantic_analyze
 test eax,eax
 jnz fail
 mov rax,[rel semantic_hash_saved]
 cmp rax,[rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_SEMANTIC_HASH_OFFSET]
 jne fail
 mov rax,[rel provenance_hash_saved]
 cmp rax,[rel sem+neboc_seguranca_numerica_conversoes_e_overflow_SEM_PROVENANCE_HASH_OFFSET]
 jne fail
 call lower_ir
 test eax,eax
 jnz fail
 mov rax,[rel ir_hash_saved]
 cmp rax,[rel ir+neboc_seguranca_numerica_conversoes_e_overflow_IR_HASH_OFFSET]
 jne fail

 xor edi,edi
 jmp neboc_host_process_exit
fail:
 mov edi,r13d
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
