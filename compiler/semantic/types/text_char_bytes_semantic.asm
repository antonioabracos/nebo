; Nebo Assembly — TEXT-CHAR-UNICODE-E-BYTES-PF003 isolated Text/Char/Bytes semantic model
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/lexer/text_char_literal_contract.inc"
%include "compiler/parser/text_char_bytes_api_contract.inc"
%include "compiler/semantic/types/text_char_bytes_semantic.inc"

section .text
NEBOC_ABI_FUNCTION neboc_text_char_bytes_semantic_analyze
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 test r12,r12
 jz .invalid_argument
 mov r13,[r12+neboc_text_char_unicode_e_bytes_SEM_SYNTAX_REQUEST_OFFSET]
 test r13,r13
 jz .invalid_argument
 lea rdi,[r12+neboc_text_char_unicode_e_bytes_SEM_OPERATION_OFFSET]
 mov ecx,(neboc_text_char_unicode_e_bytes_SEM_REQUEST_SIZE_semantic_types-neboc_text_char_unicode_e_bytes_SEM_OPERATION_OFFSET)/8
 xor eax,eax
 rep stosq

 ; PF002 source diagnostics are propagated before success-only span invariants.
 mov rax,[r12+NEBOC_SEM_CONTRACT_KIND_OFFSET]
 cmp rax,NEBOC_SEM_CONTRACT_CHAR_LITERAL
 je .pre_char
 cmp rax,NEBOC_SEM_CONTRACT_API
 je .pre_api
 jmp .contract_invariant
.pre_char:
 cmp qword [r13+NEBOC_CHAR_DIAGNOSTIC_OFFSET],NEBOC_CHAR_DIAG_NONE
 jne .char_invalid
 jmp .generic_invariants
.pre_api:
 cmp qword [r13+neboc_text_char_unicode_e_bytes_API_DIAGNOSTIC_OFFSET],neboc_text_char_unicode_e_bytes_API_DIAG_NONE
 jne .api_invalid
.generic_invariants:
 ; Generic source/span invariants for successful syntax requests.
 mov rax,[r12+neboc_text_char_unicode_e_bytes_SEM_SOURCE_FORM_OFFSET]
 cmp rax,NEBOC_SEM_SOURCE_CHAR_LITERAL
 jb .source_form_invariant
 cmp rax,NEBOC_SEM_SOURCE_BYTES_VALUE
 ja .source_form_invariant
 mov r14,[r12+neboc_text_char_unicode_e_bytes_SEM_NODE_START_OFFSET]
 mov r15,[r12+neboc_text_char_unicode_e_bytes_SEM_NODE_END_OFFSET]
 cmp r15,r14
 jbe .span_invariant
 mov rbx,[r12+neboc_text_char_unicode_e_bytes_SEM_SUBJECT_START_OFFSET]
 cmp rbx,r14
 jb .span_invariant
 mov rax,[r12+neboc_text_char_unicode_e_bytes_SEM_SUBJECT_END_OFFSET]
 cmp rax,rbx
 jbe .span_invariant
 cmp rax,r15
 ja .span_invariant

 mov rax,[r12+NEBOC_SEM_CONTRACT_KIND_OFFSET]
 cmp rax,NEBOC_SEM_CONTRACT_CHAR_LITERAL
 je .char_literal
 cmp rax,NEBOC_SEM_CONTRACT_API
 je .api
 jmp .contract_invariant

.char_literal:
 cmp qword [r13+NEBOC_CHAR_DIAGNOSTIC_OFFSET],NEBOC_CHAR_DIAG_NONE
 jne .char_invalid
 cmp qword [r13+NEBOC_CHAR_TOKEN_KIND_OFFSET],NEBOC_TOKEN_CHAR_PROVISIONAL
 jne .contract_invariant
 cmp qword [r13+NEBOC_CHAR_TOKEN_FLAGS_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TOKEN_FLAG_CHAR_DECODED|neboc_text_char_unicode_e_bytes_TOKEN_FLAG_SYNTAX_ONLY
 jne .contract_invariant
 cmp qword [r13+NEBOC_CHAR_SCALAR_COUNT_OFFSET],1
 jne .scalar_invariant
 cmp qword [r12+neboc_text_char_unicode_e_bytes_SEM_SOURCE_FORM_OFFSET],NEBOC_SEM_SOURCE_CHAR_LITERAL
 jne .source_form_invariant
 cmp qword [r12+neboc_text_char_unicode_e_bytes_SEM_RECEIVER_TYPE_OFFSET],0
 jne .type_invariant
 cmp qword [r12+NEBOC_SEM_VALUE_FLAGS_OFFSET],NEBOC_SEM_VALUE_FLAGS_CHAR
 jne .flag_invariant
 mov rax,[r13+NEBOC_CHAR_SOURCE_ID_OFFSET]
 cmp rax,[r12+neboc_text_char_unicode_e_bytes_SEM_SOURCE_ID_OFFSET]
 jne .span_invariant
 mov rax,[r13+NEBOC_CHAR_TOKEN_START_OFFSET]
 cmp rax,[r12+neboc_text_char_unicode_e_bytes_SEM_NODE_START_OFFSET]
 jne .span_invariant
 mov rax,[r13+NEBOC_CHAR_TOKEN_END_OFFSET]
 cmp rax,[r12+neboc_text_char_unicode_e_bytes_SEM_NODE_END_OFFSET]
 jne .span_invariant
 mov rax,[r13+NEBOC_CHAR_PAYLOAD_START_OFFSET]
 cmp rax,[r12+neboc_text_char_unicode_e_bytes_SEM_SUBJECT_START_OFFSET]
 jne .span_invariant
 mov rax,[r13+NEBOC_CHAR_PAYLOAD_END_OFFSET]
 cmp rax,[r12+neboc_text_char_unicode_e_bytes_SEM_SUBJECT_END_OFFSET]
 jne .span_invariant
 mov rax,[r13+NEBOC_CHAR_SCALAR_OFFSET]
 cmp rax,[r12+NEBOC_SEM_SCALAR_VALUE_OFFSET]
 jne .scalar_invariant
 call .validate_scalar
 test eax,eax
 jnz .scalar_invariant
 cmp qword [r12+NEBOC_SEM_BYTE_LENGTH_OFFSET],0
 jne .length_invariant
 cmp qword [r12+NEBOC_SEM_CODEPOINT_COUNT_OFFSET],1
 jne .length_invariant
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_OPERATION_OFFSET],NEBOC_SEM_OPERATION_CHAR_LITERAL
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_OPERAND_TYPE_OFFSET],0
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_RESULT_TYPE_OFFSET_lowering_textual],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_CHAR
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEMANTIC_KIND_OFFSET],NEBOC_SEM_KIND_VALUE
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_EFFECT_FLAGS_OFFSET],NEBOC_SEM_EFFECTS_VALUE
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_CHAR_CONSTANT
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_IMMEDIATE_U32
 mov qword [r12+NEBOC_SEM_OPERAND_REPR_OFFSET],neboc_text_char_unicode_e_bytes_SEM_REPR_NONE
 mov qword [r12+NEBOC_SEM_RESULT_REPR_OFFSET],NEBOC_SEM_REPR_UNICODE_SCALAR_U32
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_POLICY_OFFSET],NEBOC_SEM_POLICY_CHAR_SCALAR_U32
 jmp .success

.api:
 cmp qword [r13+neboc_text_char_unicode_e_bytes_API_OPERATION_OFFSET],neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD
 jne .contract_invariant
 cmp qword [r13+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],0
 jne .contract_invariant
 mov rax,[r13+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET]
 cmp rax,[r12+neboc_text_char_unicode_e_bytes_SEM_RECEIVER_TYPE_OFFSET]
 jne .type_invariant
 mov rax,[r13+NEBOC_API_RECEIVER_FORM_OFFSET]
 cmp rax,[r12+NEBOC_SEM_RECEIVER_FORM_OFFSET]
 jne .type_invariant
 mov rax,[r13+neboc_text_char_unicode_e_bytes_API_SOURCE_ID_OFFSET]
 cmp rax,[r12+neboc_text_char_unicode_e_bytes_SEM_SOURCE_ID_OFFSET]
 jne .span_invariant
 mov rax,[r13+neboc_text_char_unicode_e_bytes_API_ABSOLUTE_START_OFFSET]
 cmp rax,[r12+neboc_text_char_unicode_e_bytes_SEM_SUBJECT_START_OFFSET]
 jne .span_invariant
 mov rbx,rax
 add rbx,[r13+neboc_text_char_unicode_e_bytes_API_SUBJECT_LENGTH_OFFSET]
 cmp rbx,[r12+neboc_text_char_unicode_e_bytes_SEM_SUBJECT_END_OFFSET]
 jne .span_invariant
 mov rax,[r13+neboc_text_char_unicode_e_bytes_API_METHOD_ID_OFFSET]
 cmp rax,NEBOC_API_METHOD_TEXT_BYTE_LENGTH
 je .text_byte_length
 cmp rax,NEBOC_API_METHOD_TEXT_CODEPOINT_COUNT
 je .text_codepoint_count
 cmp rax,NEBOC_API_METHOD_CHAR_CODEPOINT
 je .char_codepoint
 cmp rax,NEBOC_API_METHOD_BYTES_EMPTY
 je .bytes_empty
 cmp rax,NEBOC_API_METHOD_BYTES_BYTE_LENGTH
 je .bytes_byte_length
 jmp .method_invariant

.text_common:
 cmp qword [r13+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 jne .text_common_type
 cmp qword [r13+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .text_common_type
 mov rax,[r12+neboc_text_char_unicode_e_bytes_SEM_SOURCE_FORM_OFFSET]
 cmp rax,NEBOC_SEM_SOURCE_TEXT_LITERAL
 je .text_form_ok
 cmp rax,NEBOC_SEM_SOURCE_TEXT_EXPLICIT
 jne .text_common_source
.text_form_ok:
 cmp qword [r12+NEBOC_SEM_VALUE_FLAGS_OFFSET],NEBOC_SEM_VALUE_FLAGS_TEXT
 jne .text_common_flag
 mov rax,[r12+NEBOC_SEM_BYTE_LENGTH_OFFSET]
 test rax,rax
 js .text_common_length
 mov rbx,[r12+NEBOC_SEM_CODEPOINT_COUNT_OFFSET]
 test rbx,rbx
 js .text_common_length
 cmp rbx,rax
 ja .text_common_length
 xor eax,eax
 ret
.text_common_type:
 mov eax,1
 ret
.text_common_source:
 mov eax,2
 ret
.text_common_flag:
 mov eax,3
 ret
.text_common_length:
 mov eax,4
 ret
.text_common_dispatch_error:
 cmp eax,1
 je .type_invariant
 cmp eax,2
 je .source_form_invariant
 cmp eax,3
 je .flag_invariant
 jmp .length_invariant

.text_byte_length:
 call .text_common
 test eax,eax
 jnz .text_common_dispatch_error
 cmp qword [r13+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_INT
 jne .result_invariant
 cmp qword [r13+neboc_text_char_unicode_e_bytes_API_FLAGS_OFFSET],NEBOC_API_FLAG_INSTANCE|neboc_text_char_unicode_e_bytes_API_FLAG_TOTAL|neboc_text_char_unicode_e_bytes_API_FLAG_ALLOCATION_FREE|neboc_text_char_unicode_e_bytes_API_FLAG_SYNTAX_ONLY
 jne .flag_invariant
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_OPERATION_OFFSET],NEBOC_SEM_OPERATION_TEXT_BYTE_LENGTH
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_OPERAND_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_RESULT_TYPE_OFFSET_lowering_textual],NEBOC_TYPE_ID_INT
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEMANTIC_KIND_OFFSET],NEBOC_SEM_KIND_COUNT
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_EFFECT_FLAGS_OFFSET],NEBOC_SEM_EFFECTS_COUNT
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_TEXT_BYTE_LENGTH
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_TEXT_DESCRIPTOR_BYTE_LENGTH
 mov qword [r12+NEBOC_SEM_OPERAND_REPR_OFFSET],NEBOC_SEM_REPR_TEXT_DESCRIPTOR_24
 mov qword [r12+NEBOC_SEM_RESULT_REPR_OFFSET],NEBOC_SEM_REPR_NONNEGATIVE_I64
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_POLICY_OFFSET],NEBOC_SEM_POLICY_TEXT_BYTE_LENGTH_O1
 jmp .success

.text_codepoint_count:
 call .text_common
 test eax,eax
 jnz .text_common_dispatch_error
 cmp qword [r13+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_INT
 jne .result_invariant
 cmp qword [r13+neboc_text_char_unicode_e_bytes_API_FLAGS_OFFSET],NEBOC_API_FLAG_INSTANCE|neboc_text_char_unicode_e_bytes_API_FLAG_TOTAL|neboc_text_char_unicode_e_bytes_API_FLAG_ALLOCATION_FREE|neboc_text_char_unicode_e_bytes_API_FLAG_SYNTAX_ONLY
 jne .flag_invariant
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_OPERATION_OFFSET],NEBOC_SEM_OPERATION_TEXT_CODEPOINT_COUNT
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_OPERAND_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_RESULT_TYPE_OFFSET_lowering_textual],NEBOC_TYPE_ID_INT
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEMANTIC_KIND_OFFSET],NEBOC_SEM_KIND_COUNT
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_EFFECT_FLAGS_OFFSET],NEBOC_SEM_EFFECTS_COUNT
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_TEXT_CODEPOINT_COUNT
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_UTF8_CODEPOINT_COUNT
 mov qword [r12+NEBOC_SEM_OPERAND_REPR_OFFSET],NEBOC_SEM_REPR_TEXT_DESCRIPTOR_24
 mov qword [r12+NEBOC_SEM_RESULT_REPR_OFFSET],NEBOC_SEM_REPR_NONNEGATIVE_I64
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_POLICY_OFFSET],NEBOC_SEM_POLICY_TEXT_CODEPOINT_COUNT_UTF8_ON
 jmp .success

.char_codepoint:
 cmp qword [r13+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_CHAR
 jne .type_invariant
 cmp qword [r13+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_INT
 jne .result_invariant
 cmp qword [r13+neboc_text_char_unicode_e_bytes_API_FLAGS_OFFSET],NEBOC_API_FLAG_INSTANCE|neboc_text_char_unicode_e_bytes_API_FLAG_TOTAL|neboc_text_char_unicode_e_bytes_API_FLAG_ALLOCATION_FREE|neboc_text_char_unicode_e_bytes_API_FLAG_SYNTAX_ONLY
 jne .flag_invariant
 cmp qword [r12+neboc_text_char_unicode_e_bytes_SEM_SOURCE_FORM_OFFSET],NEBOC_SEM_SOURCE_CHAR_LITERAL
 jne .source_form_invariant
 cmp qword [r12+NEBOC_SEM_VALUE_FLAGS_OFFSET],NEBOC_SEM_VALUE_FLAGS_CHAR
 jne .flag_invariant
 mov rax,[r12+NEBOC_SEM_SCALAR_VALUE_OFFSET]
 call .validate_scalar
 test eax,eax
 jnz .scalar_invariant
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_OPERATION_OFFSET],NEBOC_SEM_OPERATION_CHAR_CODEPOINT
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_OPERAND_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_CHAR
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_RESULT_TYPE_OFFSET_lowering_textual],NEBOC_TYPE_ID_INT
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEMANTIC_KIND_OFFSET],NEBOC_SEM_KIND_SCALAR_EXTRACT
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_EFFECT_FLAGS_OFFSET],NEBOC_SEM_EFFECTS_COUNT
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_CHAR_CODEPOINT
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_ZERO_EXTEND_U32_TO_I64
 mov qword [r12+NEBOC_SEM_OPERAND_REPR_OFFSET],NEBOC_SEM_REPR_UNICODE_SCALAR_U32
 mov qword [r12+NEBOC_SEM_RESULT_REPR_OFFSET],NEBOC_SEM_REPR_NONNEGATIVE_I64
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_POLICY_OFFSET],NEBOC_SEM_POLICY_CHAR_CODEPOINT_ZERO_EXTEND
 jmp .success

.bytes_common:
 cmp qword [r12+NEBOC_SEM_VALUE_FLAGS_OFFSET],NEBOC_SEM_VALUE_FLAGS_BYTES_EMPTY
 jne .bytes_common_bad
 cmp qword [r12+NEBOC_SEM_BYTE_LENGTH_OFFSET],0
 jne .bytes_common_bad
 cmp qword [r12+NEBOC_SEM_CODEPOINT_COUNT_OFFSET],0
 jne .bytes_common_bad
 xor eax,eax
 ret
.bytes_common_bad:
 mov eax,1
 ret

.bytes_empty:
 cmp qword [r13+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
 jne .type_invariant
 cmp qword [r13+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_TYPE
 jne .type_invariant
 cmp qword [r13+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
 jne .result_invariant
 cmp qword [r13+neboc_text_char_unicode_e_bytes_API_FLAGS_OFFSET],NEBOC_API_FLAG_STATIC|neboc_text_char_unicode_e_bytes_API_FLAG_TOTAL|neboc_text_char_unicode_e_bytes_API_FLAG_ALLOCATION_FREE|neboc_text_char_unicode_e_bytes_API_FLAG_SYNTAX_ONLY
 jne .flag_invariant
 cmp qword [r12+neboc_text_char_unicode_e_bytes_SEM_SOURCE_FORM_OFFSET],NEBOC_SEM_SOURCE_BYTES_STATIC
 jne .source_form_invariant
 call .bytes_common
 test eax,eax
 jnz .bytes_state_invariant
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_OPERATION_OFFSET],NEBOC_SEM_OPERATION_BYTES_EMPTY
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_OPERAND_TYPE_OFFSET],0
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_RESULT_TYPE_OFFSET_lowering_textual],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEMANTIC_KIND_OFFSET],NEBOC_SEM_KIND_STATIC_FACTORY
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_EFFECT_FLAGS_OFFSET],NEBOC_SEM_EFFECTS_VALUE
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_BYTES_EMPTY
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_STATIC_EMPTY_BYTES_DESCRIPTOR
 mov qword [r12+NEBOC_SEM_OPERAND_REPR_OFFSET],neboc_text_char_unicode_e_bytes_SEM_REPR_NONE
 mov qword [r12+NEBOC_SEM_RESULT_REPR_OFFSET],NEBOC_SEM_REPR_BYTES_DESCRIPTOR
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_POLICY_OFFSET],NEBOC_SEM_POLICY_BYTES_EMPTY_STATIC
 jmp .success

.bytes_byte_length:
 cmp qword [r13+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
 jne .type_invariant
 cmp qword [r13+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 jne .type_invariant
 cmp qword [r13+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_INT
 jne .result_invariant
 cmp qword [r13+neboc_text_char_unicode_e_bytes_API_FLAGS_OFFSET],NEBOC_API_FLAG_INSTANCE|neboc_text_char_unicode_e_bytes_API_FLAG_TOTAL|neboc_text_char_unicode_e_bytes_API_FLAG_ALLOCATION_FREE|neboc_text_char_unicode_e_bytes_API_FLAG_SYNTAX_ONLY
 jne .flag_invariant
 cmp qword [r12+neboc_text_char_unicode_e_bytes_SEM_SOURCE_FORM_OFFSET],NEBOC_SEM_SOURCE_BYTES_VALUE
 jne .source_form_invariant
 call .bytes_common
 test eax,eax
 jnz .bytes_state_invariant
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_OPERATION_OFFSET],NEBOC_SEM_OPERATION_BYTES_BYTE_LENGTH
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_OPERAND_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_RESULT_TYPE_OFFSET_lowering_textual],NEBOC_TYPE_ID_INT
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEMANTIC_KIND_OFFSET],NEBOC_SEM_KIND_COUNT
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_EFFECT_FLAGS_OFFSET],NEBOC_SEM_EFFECTS_COUNT
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_BYTES_BYTE_LENGTH
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_BYTES_DESCRIPTOR_LENGTH
 mov qword [r12+NEBOC_SEM_OPERAND_REPR_OFFSET],NEBOC_SEM_REPR_BYTES_DESCRIPTOR
 mov qword [r12+NEBOC_SEM_RESULT_REPR_OFFSET],NEBOC_SEM_REPR_NONNEGATIVE_I64
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_POLICY_OFFSET],NEBOC_SEM_POLICY_BYTES_BYTE_LENGTH_O1
 jmp .success

.success:
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_RUNTIME_METADATA_OFFSET],neboc_text_char_unicode_e_bytes_SEM_RUNTIME_METADATA_NONE
 call .compute_hashes
 xor eax,eax
 jmp .done

.char_invalid:
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_SEM_ERROR_CONTRACT_INVALID
 mov rax,[r13+NEBOC_CHAR_DIAGNOSTIC_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_SEM_SOURCE_DIAG_OFFSET],rax
 mov rax,[r13+NEBOC_CHAR_ERROR_START_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_SEM_ERROR_START_OFFSET_semantic_types],rax
 mov rax,[r13+NEBOC_CHAR_ERROR_END_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_SEM_ERROR_END_OFFSET_semantic_types],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.api_invalid:
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_SEM_ERROR_CONTRACT_INVALID
 mov rax,[r13+neboc_text_char_unicode_e_bytes_API_DIAGNOSTIC_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_SEM_SOURCE_DIAG_OFFSET],rax
 mov rax,[r13+neboc_text_char_unicode_e_bytes_API_ERROR_START_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_SEM_ERROR_START_OFFSET_semantic_types],rax
 mov rax,[r13+neboc_text_char_unicode_e_bytes_API_ERROR_END_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_SEM_ERROR_END_OFFSET_semantic_types],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done

.contract_invariant: mov ecx,NEBOC_SEM_ERROR_CONTRACT_INVARIANT
 jmp .internal_error
.type_invariant: mov ecx,neboc_text_char_unicode_e_bytes_SEM_ERROR_TYPE_INVARIANT
 jmp .internal_error
.flag_invariant: mov ecx,neboc_text_char_unicode_e_bytes_SEM_ERROR_FLAG_INVARIANT
 jmp .internal_error
.span_invariant: mov ecx,neboc_text_char_unicode_e_bytes_SEM_ERROR_SPAN_INVARIANT
 jmp .internal_error
.source_form_invariant: mov ecx,neboc_text_char_unicode_e_bytes_SEM_ERROR_SOURCE_FORM_INVARIANT
 jmp .internal_error
.scalar_invariant: mov ecx,NEBOC_SEM_ERROR_SCALAR_INVARIANT
 jmp .internal_error
.length_invariant: mov ecx,NEBOC_SEM_ERROR_LENGTH_INVARIANT
 jmp .internal_error
.bytes_state_invariant: mov ecx,NEBOC_SEM_ERROR_BYTES_STATE_INVARIANT
 jmp .internal_error
.method_invariant: mov ecx,neboc_text_char_unicode_e_bytes_SEM_ERROR_METHOD_INVARIANT
 jmp .internal_error
.result_invariant: mov ecx,neboc_text_char_unicode_e_bytes_SEM_ERROR_RESULT_INVARIANT
.internal_error:
 mov [r12+neboc_text_char_unicode_e_bytes_SEM_ERROR_CODE_OFFSET],rcx
 mov rax,[r12+neboc_text_char_unicode_e_bytes_SEM_SUBJECT_START_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_SEM_ERROR_START_OFFSET_semantic_types],rax
 mov rax,[r12+neboc_text_char_unicode_e_bytes_SEM_SUBJECT_END_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_SEM_ERROR_END_OFFSET_semantic_types],rax
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done

.validate_scalar:
 cmp rax,0x10ffff
 ja .bad_scalar
 cmp rax,0xd800
 jb .good_scalar
 cmp rax,0xdfff
 jbe .bad_scalar
.good_scalar: xor eax,eax
 ret
.bad_scalar: mov eax,1
 ret

.compute_hashes:
 mov rax,neboc_text_char_unicode_e_bytes_SEM_HASH_OFFSET_BASIS
 mov rcx,neboc_text_char_unicode_e_bytes_SEM_HASH_PRIME
 xor rax,[r12+neboc_text_char_unicode_e_bytes_SEM_OPERATION_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_text_char_unicode_e_bytes_SEM_OPERAND_TYPE_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_text_char_unicode_e_bytes_SEM_RESULT_TYPE_OFFSET_lowering_textual]
 imul rax,rcx
 xor rax,[r12+neboc_text_char_unicode_e_bytes_SEMANTIC_KIND_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_text_char_unicode_e_bytes_SEM_EFFECT_FLAGS_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_text_char_unicode_e_bytes_SEM_HIR_KIND_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_text_char_unicode_e_bytes_SEM_LIR_KIND_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_SEM_OPERAND_REPR_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_SEM_RESULT_REPR_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_text_char_unicode_e_bytes_SEM_POLICY_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_SEM_SCALAR_VALUE_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_SEM_BYTE_LENGTH_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_SEM_CODEPOINT_COUNT_OFFSET]
 imul rax,rcx
 mov [r12+neboc_text_char_unicode_e_bytes_SEM_SEMANTIC_HASH_OFFSET],rax
 mov rdx,rax
 xor rdx,[r12+neboc_text_char_unicode_e_bytes_SEM_SOURCE_FORM_OFFSET]
 imul rdx,rcx
 xor rdx,[r12+neboc_text_char_unicode_e_bytes_SEM_SOURCE_ID_OFFSET]
 imul rdx,rcx
 xor rdx,[r12+neboc_text_char_unicode_e_bytes_SEM_NODE_START_OFFSET]
 imul rdx,rcx
 xor rdx,[r12+neboc_text_char_unicode_e_bytes_SEM_NODE_END_OFFSET]
 imul rdx,rcx
 mov [r12+neboc_text_char_unicode_e_bytes_SEM_PROVENANCE_HASH_OFFSET],rdx
 ret
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
