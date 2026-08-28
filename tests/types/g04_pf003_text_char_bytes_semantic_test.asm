; TEXT-CHAR-UNICODE-E-BYTES-PF003 isolated semantic and abstract IR invariants
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/lexer/text_char_literal_contract.inc"
%include "compiler/parser/text_char_bytes_api_contract.inc"
%include "compiler/semantic/types/text_char_bytes_semantic.inc"
%include "compiler/lowering/textual/text_char_bytes_ir_contract.inc"
extern neboc_char_literal_contract_scan
extern neboc_text_char_bytes_api_contract
extern neboc_text_char_bytes_semantic_analyze
extern neboc_text_char_bytes_ir_lower
extern neboc_host_process_exit

section .rodata
char_a: db 39,65,39
char_cedilla: db 39,0xc3,0xa7,39
char_euro: db 39,0xe2,0x82,0xac,39
char_emoji: db 39,0xf0,0x9f,0x98,0x80,39
char_newline: db 39,92,110,39
char_empty: db 39,39
name_byte_length: db "byteLength"
name_codepoint_count: db "codepointCount"
name_codepoint: db "codepoint"
name_empty: db "empty"
name_len: db "len"

section .bss align=16
char_req: resb NEBOC_CHAR_REQUEST_SIZE
api_req: resb neboc_text_char_unicode_e_bytes_API_REQUEST_SIZE
sem: resb neboc_text_char_unicode_e_bytes_SEM_REQUEST_SIZE_semantic_types
ir: resb neboc_text_char_unicode_e_bytes_IR_REQUEST_SIZE
ctx_source_form: resq 1
ctx_flags: resq 1
ctx_scalar: resq 1
ctx_bytes: resq 1
ctx_codepoints: resq 1
ctx_source_id: resq 1
ctx_node_start: resq 1
ctx_node_end: resq 1
ctx_subject_start: resq 1
ctx_subject_end: resq 1
saved_char_sem_hash: resq 1
saved_char_prov_hash: resq 1
saved_char_ir_hash: resq 1
saved_text_sem_hash: resq 1
saved_text_prov_hash: resq 1
saved_text_ir_hash: resq 1

section .text
%macro SETCTX 10
 mov qword [rel ctx_source_form],%1
 mov qword [rel ctx_flags],%2
 mov qword [rel ctx_scalar],%3
 mov qword [rel ctx_bytes],%4
 mov qword [rel ctx_codepoints],%5
 mov qword [rel ctx_source_id],%6
 mov qword [rel ctx_node_start],%7
 mov qword [rel ctx_node_end],%8
 mov qword [rel ctx_subject_start],%9
 mov qword [rel ctx_subject_end],%10
%endmacro

clear_sem:
 lea rdi,[rel sem]
 mov ecx,neboc_text_char_unicode_e_bytes_SEM_REQUEST_SIZE_semantic_types/8
 xor eax,eax
 rep stosq
 ret

fill_sem_context:
 mov rax,[rel ctx_source_form]
 mov [rel sem+neboc_text_char_unicode_e_bytes_SEM_SOURCE_FORM_OFFSET],rax
 mov rax,[rel ctx_flags]
 mov [rel sem+NEBOC_SEM_VALUE_FLAGS_OFFSET],rax
 mov rax,[rel ctx_scalar]
 mov [rel sem+NEBOC_SEM_SCALAR_VALUE_OFFSET],rax
 mov rax,[rel ctx_bytes]
 mov [rel sem+NEBOC_SEM_BYTE_LENGTH_OFFSET],rax
 mov rax,[rel ctx_codepoints]
 mov [rel sem+NEBOC_SEM_CODEPOINT_COUNT_OFFSET],rax
 mov rax,[rel ctx_source_id]
 mov [rel sem+neboc_text_char_unicode_e_bytes_SEM_SOURCE_ID_OFFSET],rax
 mov rax,[rel ctx_node_start]
 mov [rel sem+neboc_text_char_unicode_e_bytes_SEM_NODE_START_OFFSET],rax
 mov rax,[rel ctx_node_end]
 mov [rel sem+neboc_text_char_unicode_e_bytes_SEM_NODE_END_OFFSET],rax
 mov rax,[rel ctx_subject_start]
 mov [rel sem+neboc_text_char_unicode_e_bytes_SEM_SUBJECT_START_OFFSET],rax
 mov rax,[rel ctx_subject_end]
 mov [rel sem+neboc_text_char_unicode_e_bytes_SEM_SUBJECT_END_OFFSET],rax
 ret

; rdi source, rsi length. Returns semantic status.
prepare_char:
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 lea rdi,[rel char_req]
 mov ecx,NEBOC_CHAR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov [rel char_req+NEBOC_CHAR_SOURCE_OFFSET],r12
 mov [rel char_req+NEBOC_CHAR_LENGTH_OFFSET],r13
 mov rax,[rel ctx_source_id]
 mov [rel char_req+NEBOC_CHAR_SOURCE_ID_OFFSET],rax
 mov rax,[rel ctx_node_start]
 mov [rel char_req+NEBOC_CHAR_ABSOLUTE_START_OFFSET],rax
 lea rdi,[rel char_req]
 call neboc_char_literal_contract_scan
 call clear_sem
 mov qword [rel sem+NEBOC_SEM_CONTRACT_KIND_OFFSET],NEBOC_SEM_CONTRACT_CHAR_LITERAL
 lea rax,[rel char_req]
 mov [rel sem+neboc_text_char_unicode_e_bytes_SEM_SYNTAX_REQUEST_OFFSET],rax
 call fill_sem_context
 lea rdi,[rel sem]
 call neboc_text_char_bytes_semantic_analyze
 pop r13
 pop r12
 ret

; rdi name, rsi len, rdx receiver type, rcx receiver form. Returns semantic status.
prepare_api:
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 lea rdi,[rel api_req]
 mov ecx,neboc_text_char_unicode_e_bytes_API_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov qword [rel api_req+neboc_text_char_unicode_e_bytes_API_OPERATION_OFFSET],neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD
 mov [rel api_req+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],r14
 mov [rel api_req+NEBOC_API_RECEIVER_FORM_OFFSET],r15
 mov [rel api_req+neboc_text_char_unicode_e_bytes_API_SUBJECT_PTR_OFFSET],r12
 mov [rel api_req+neboc_text_char_unicode_e_bytes_API_SUBJECT_LENGTH_OFFSET],r13
 mov qword [rel api_req+neboc_text_char_unicode_e_bytes_API_ARGUMENT_COUNT_OFFSET],0
 mov rax,[rel ctx_source_id]
 mov [rel api_req+neboc_text_char_unicode_e_bytes_API_SOURCE_ID_OFFSET],rax
 mov rax,[rel ctx_subject_start]
 mov [rel api_req+neboc_text_char_unicode_e_bytes_API_ABSOLUTE_START_OFFSET],rax
 lea rdi,[rel api_req]
 call neboc_text_char_bytes_api_contract
 call clear_sem
 mov qword [rel sem+NEBOC_SEM_CONTRACT_KIND_OFFSET],NEBOC_SEM_CONTRACT_API
 lea rax,[rel api_req]
 mov [rel sem+neboc_text_char_unicode_e_bytes_SEM_SYNTAX_REQUEST_OFFSET],rax
 mov [rel sem+neboc_text_char_unicode_e_bytes_SEM_RECEIVER_TYPE_OFFSET],r14
 mov [rel sem+NEBOC_SEM_RECEIVER_FORM_OFFSET],r15
 mov qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_RECEIVER_VALUE_ID_OFFSET],77
 call fill_sem_context
 lea rdi,[rel sem]
 call neboc_text_char_bytes_semantic_analyze
 pop r15
 pop r14
 pop r13
 pop r12
 ret

lower_ir:
 lea rdi,[rel ir]
 mov ecx,neboc_text_char_unicode_e_bytes_IR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rel sem]
 mov [rel ir+neboc_text_char_unicode_e_bytes_IR_SEMANTIC_REQUEST_OFFSET],rax
 lea rdi,[rel ir]
 jmp neboc_text_char_bytes_ir_lower

assert_char:
 cmp qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_OPERATION_OFFSET],NEBOC_SEM_OPERATION_CHAR_LITERAL
 jne fail
 cmp qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_RESULT_TYPE_OFFSET_lowering_textual],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_CHAR
 jne fail
 cmp qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_CHAR_CONSTANT
 jne fail
 cmp qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_IMMEDIATE_U32
 jne fail
 cmp qword [rel sem+NEBOC_SEM_RESULT_REPR_OFFSET],NEBOC_SEM_REPR_UNICODE_SCALAR_U32
 jne fail
 cmp qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_EFFECT_FLAGS_OFFSET],NEBOC_SEM_EFFECTS_VALUE
 jne fail
 cmp qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_RUNTIME_METADATA_OFFSET],0
 jne fail
 call lower_ir
 test eax,eax
 jnz fail
 cmp qword [rel ir+neboc_text_char_unicode_e_bytes_IR_LIR_KIND_OFFSET],NEBOC_SEM_LIR_IMMEDIATE_U32
 jne fail
 ret

assert_count:
 ; rdi operation, rsi HIR, rdx LIR, rcx operand repr, r8 policy
 cmp [rel sem+neboc_text_char_unicode_e_bytes_SEM_OPERATION_OFFSET],rdi
 jne fail
 cmp [rel sem+neboc_text_char_unicode_e_bytes_SEM_HIR_KIND_OFFSET],rsi
 jne fail
 cmp [rel sem+neboc_text_char_unicode_e_bytes_SEM_LIR_KIND_OFFSET],rdx
 jne fail
 cmp [rel sem+NEBOC_SEM_OPERAND_REPR_OFFSET],rcx
 jne fail
 cmp [rel sem+neboc_text_char_unicode_e_bytes_SEM_POLICY_OFFSET],r8
 jne fail
 cmp qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_RESULT_TYPE_OFFSET_lowering_textual],NEBOC_TYPE_ID_INT
 jne fail
 cmp qword [rel sem+NEBOC_SEM_RESULT_REPR_OFFSET],NEBOC_SEM_REPR_NONNEGATIVE_I64
 jne fail
 cmp qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_EFFECT_FLAGS_OFFSET],NEBOC_SEM_EFFECTS_COUNT
 jne fail
 call lower_ir
 test eax,eax
 jnz fail
 ret

assert_internal_error:
 ; edi expected error code; eax status from analyzer
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 jne fail
 cmp [rel sem+neboc_text_char_unicode_e_bytes_SEM_ERROR_CODE_OFFSET],rdi
 jne fail
 ret

section .text
global _start
_start:
 mov r13d,1
 ; 1 ASCII Char
 SETCTX NEBOC_SEM_SOURCE_CHAR_LITERAL,NEBOC_SEM_VALUE_FLAGS_CHAR,65,0,1,401,100,103,101,102
 lea rdi,[rel char_a]
 mov esi,3
 call prepare_char
 test eax,eax
 jnz fail
 call assert_char
 mov rax,[rel sem+neboc_text_char_unicode_e_bytes_SEM_SEMANTIC_HASH_OFFSET]
 mov [rel saved_char_sem_hash],rax
 mov rax,[rel sem+neboc_text_char_unicode_e_bytes_SEM_PROVENANCE_HASH_OFFSET]
 mov [rel saved_char_prov_hash],rax
 mov rax,[rel ir+neboc_text_char_unicode_e_bytes_IR_HASH_OFFSET]
 mov [rel saved_char_ir_hash],rax

 inc r13d
 ; 2 two-byte scalar
 SETCTX NEBOC_SEM_SOURCE_CHAR_LITERAL,NEBOC_SEM_VALUE_FLAGS_CHAR,0xe7,0,1,402,200,204,201,203
 lea rdi,[rel char_cedilla]
 mov esi,4
 call prepare_char
 test eax,eax
 jnz fail
 call assert_char

 inc r13d
 ; 3 three-byte scalar
 SETCTX NEBOC_SEM_SOURCE_CHAR_LITERAL,NEBOC_SEM_VALUE_FLAGS_CHAR,0x20ac,0,1,403,300,305,301,304
 lea rdi,[rel char_euro]
 mov esi,5
 call prepare_char
 test eax,eax
 jnz fail
 call assert_char

 inc r13d
 ; 4 four-byte scalar
 SETCTX NEBOC_SEM_SOURCE_CHAR_LITERAL,NEBOC_SEM_VALUE_FLAGS_CHAR,0x1f600,0,1,404,400,406,401,405
 lea rdi,[rel char_emoji]
 mov esi,6
 call prepare_char
 test eax,eax
 jnz fail
 call assert_char

 inc r13d
 ; 5 escaped newline
 SETCTX NEBOC_SEM_SOURCE_CHAR_LITERAL,NEBOC_SEM_VALUE_FLAGS_CHAR,10,0,1,405,500,504,501,503
 lea rdi,[rel char_newline]
 mov esi,4
 call prepare_char
 test eax,eax
 jnz fail
 call assert_char

 inc r13d
 ; 6 implicit Text.byteLength
 SETCTX NEBOC_SEM_SOURCE_TEXT_LITERAL,NEBOC_SEM_VALUE_FLAGS_TEXT,0,9,8,406,600,620,606,616
 lea rdi,[rel name_byte_length]
 mov esi,10
 mov edx,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 mov ecx,NEBOC_RECEIVER_INSTANCE
 call prepare_api
 test eax,eax
 jnz fail
 mov edi,NEBOC_SEM_OPERATION_TEXT_BYTE_LENGTH
 mov esi,NEBOC_SEM_HIR_TEXT_BYTE_LENGTH
 mov edx,NEBOC_SEM_LIR_TEXT_DESCRIPTOR_BYTE_LENGTH
 mov ecx,NEBOC_SEM_REPR_TEXT_DESCRIPTOR_24
 mov r8d,NEBOC_SEM_POLICY_TEXT_BYTE_LENGTH_O1
 call assert_count
 mov rax,[rel sem+neboc_text_char_unicode_e_bytes_SEM_SEMANTIC_HASH_OFFSET]
 mov [rel saved_text_sem_hash],rax
 mov rax,[rel sem+neboc_text_char_unicode_e_bytes_SEM_PROVENANCE_HASH_OFFSET]
 mov [rel saved_text_prov_hash],rax
 mov rax,[rel ir+neboc_text_char_unicode_e_bytes_IR_HASH_OFFSET]
 mov [rel saved_text_ir_hash],rax

 inc r13d
 ; 7 explicit Text constructor is semantically/IR equivalent, provenance distinct
 SETCTX NEBOC_SEM_SOURCE_TEXT_EXPLICIT,NEBOC_SEM_VALUE_FLAGS_TEXT,0,9,8,407,700,724,712,722
 lea rdi,[rel name_byte_length]
 mov esi,10
 mov edx,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 mov ecx,NEBOC_RECEIVER_INSTANCE
 call prepare_api
 test eax,eax
 jnz fail
 mov edi,NEBOC_SEM_OPERATION_TEXT_BYTE_LENGTH
 mov esi,NEBOC_SEM_HIR_TEXT_BYTE_LENGTH
 mov edx,NEBOC_SEM_LIR_TEXT_DESCRIPTOR_BYTE_LENGTH
 mov ecx,NEBOC_SEM_REPR_TEXT_DESCRIPTOR_24
 mov r8d,NEBOC_SEM_POLICY_TEXT_BYTE_LENGTH_O1
 call assert_count
 mov rax,[rel saved_text_sem_hash]
 cmp rax,[rel sem+neboc_text_char_unicode_e_bytes_SEM_SEMANTIC_HASH_OFFSET]
 jne fail
 mov rax,[rel saved_text_ir_hash]
 cmp rax,[rel ir+neboc_text_char_unicode_e_bytes_IR_HASH_OFFSET]
 jne fail
 mov rax,[rel saved_text_prov_hash]
 cmp rax,[rel sem+neboc_text_char_unicode_e_bytes_SEM_PROVENANCE_HASH_OFFSET]
 je fail

 inc r13d
 ; 8 Text.codepointCount
 SETCTX NEBOC_SEM_SOURCE_TEXT_LITERAL,NEBOC_SEM_VALUE_FLAGS_TEXT,0,9,8,408,800,824,808,822
 lea rdi,[rel name_codepoint_count]
 mov esi,14
 mov edx,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 mov ecx,NEBOC_RECEIVER_INSTANCE
 call prepare_api
 test eax,eax
 jnz fail
 mov edi,NEBOC_SEM_OPERATION_TEXT_CODEPOINT_COUNT
 mov esi,NEBOC_SEM_HIR_TEXT_CODEPOINT_COUNT
 mov edx,NEBOC_SEM_LIR_UTF8_CODEPOINT_COUNT
 mov ecx,NEBOC_SEM_REPR_TEXT_DESCRIPTOR_24
 mov r8d,NEBOC_SEM_POLICY_TEXT_CODEPOINT_COUNT_UTF8_ON
 call assert_count

 inc r13d
 ; 9 Char.codepoint
 SETCTX NEBOC_SEM_SOURCE_CHAR_LITERAL,NEBOC_SEM_VALUE_FLAGS_CHAR,0x1f600,0,1,409,900,919,908,917
 lea rdi,[rel name_codepoint]
 mov esi,9
 mov edx,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_CHAR
 mov ecx,NEBOC_RECEIVER_INSTANCE
 call prepare_api
 test eax,eax
 jnz fail
 mov edi,NEBOC_SEM_OPERATION_CHAR_CODEPOINT
 mov esi,NEBOC_SEM_HIR_CHAR_CODEPOINT
 mov edx,NEBOC_SEM_LIR_ZERO_EXTEND_U32_TO_I64
 mov ecx,NEBOC_SEM_REPR_UNICODE_SCALAR_U32
 mov r8d,NEBOC_SEM_POLICY_CHAR_CODEPOINT_ZERO_EXTEND
 call assert_count

 inc r13d
 ; 10 Bytes.empty
 SETCTX NEBOC_SEM_SOURCE_BYTES_STATIC,NEBOC_SEM_VALUE_FLAGS_BYTES_EMPTY,0,0,0,410,1000,1015,1006,1011
 lea rdi,[rel name_empty]
 mov esi,5
 mov edx,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
 mov ecx,NEBOC_RECEIVER_TYPE
 call prepare_api
 test eax,eax
 jnz fail
 cmp qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_OPERATION_OFFSET],NEBOC_SEM_OPERATION_BYTES_EMPTY
 jne fail
 cmp qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_RESULT_TYPE_OFFSET_lowering_textual],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
 jne fail
 cmp qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_BYTES_EMPTY
 jne fail
 cmp qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_STATIC_EMPTY_BYTES_DESCRIPTOR
 jne fail
 call lower_ir
 test eax,eax
 jnz fail

 inc r13d
 ; 11 Bytes.byteLength empty value
 SETCTX NEBOC_SEM_SOURCE_BYTES_VALUE,NEBOC_SEM_VALUE_FLAGS_BYTES_EMPTY,0,0,0,411,1100,1120,1108,1118
 lea rdi,[rel name_byte_length]
 mov esi,10
 mov edx,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
 mov ecx,NEBOC_RECEIVER_INSTANCE
 call prepare_api
 test eax,eax
 jnz fail
 mov edi,NEBOC_SEM_OPERATION_BYTES_BYTE_LENGTH
 mov esi,NEBOC_SEM_HIR_BYTES_BYTE_LENGTH
 mov edx,NEBOC_SEM_LIR_BYTES_DESCRIPTOR_LENGTH
 mov ecx,NEBOC_SEM_REPR_BYTES_DESCRIPTOR
 mov r8d,NEBOC_SEM_POLICY_BYTES_BYTE_LENGTH_O1
 call assert_count

 inc r13d
 ; 12 Char diagnostic propagation
 SETCTX NEBOC_SEM_SOURCE_CHAR_LITERAL,NEBOC_SEM_VALUE_FLAGS_CHAR,0,0,1,412,1200,1202,1201,1201
 lea rdi,[rel char_empty]
 mov esi,2
 call prepare_char
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_SOURCE_DIAG_OFFSET],NEBOC_CHAR_DIAG_EMPTY
 jne fail
 cmp qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_SEM_ERROR_CONTRACT_INVALID
 jne fail

 inc r13d
 ; 13 API alias diagnostic propagation
 SETCTX NEBOC_SEM_SOURCE_TEXT_LITERAL,NEBOC_SEM_VALUE_FLAGS_TEXT,0,1,1,413,1300,1313,1306,1309
 lea rdi,[rel name_len]
 mov esi,3
 mov edx,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 mov ecx,NEBOC_RECEIVER_INSTANCE
 call prepare_api
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_SOURCE_DIAG_OFFSET],neboc_text_char_unicode_e_bytes_API_DIAG_ALIAS_FORBIDDEN
 jne fail

 inc r13d
 ; 14 semantic receiver mismatch after successful API contract
 SETCTX NEBOC_SEM_SOURCE_TEXT_LITERAL,NEBOC_SEM_VALUE_FLAGS_TEXT,0,1,1,414,1400,1420,1406,1416
 lea rdi,[rel name_byte_length]
 mov esi,10
 mov edx,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 mov ecx,NEBOC_RECEIVER_INSTANCE
 call prepare_api
 test eax,eax
 jnz fail
 mov qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_RECEIVER_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_CHAR
 lea rdi,[rel sem]
 call neboc_text_char_bytes_semantic_analyze
 mov edi,neboc_text_char_unicode_e_bytes_SEM_ERROR_TYPE_INVARIANT
 call assert_internal_error

 inc r13d
 ; 15 invalid Text flags
 SETCTX NEBOC_SEM_SOURCE_TEXT_LITERAL,NEBOC_SEM_VALUE_IMMUTABLE|NEBOC_SEM_VALUE_NO_BOM,0,1,1,415,1500,1520,1506,1516
 lea rdi,[rel name_byte_length]
 mov esi,10
 mov edx,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 mov ecx,NEBOC_RECEIVER_INSTANCE
 call prepare_api
 mov edi,neboc_text_char_unicode_e_bytes_SEM_ERROR_FLAG_INVARIANT
 call assert_internal_error

 inc r13d
 ; 16 signed overflow-like byte length is invalid
 SETCTX NEBOC_SEM_SOURCE_TEXT_LITERAL,NEBOC_SEM_VALUE_FLAGS_TEXT,0,0,0,416,1600,1620,1606,1616
 mov rax,0x8000000000000000
 mov [rel ctx_bytes],rax
 lea rdi,[rel name_byte_length]
 mov esi,10
 mov edx,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 mov ecx,NEBOC_RECEIVER_INSTANCE
 call prepare_api
 mov edi,NEBOC_SEM_ERROR_LENGTH_INVARIANT
 call assert_internal_error

 inc r13d
 ; 17 codepoint count cannot exceed byte length
 SETCTX NEBOC_SEM_SOURCE_TEXT_LITERAL,NEBOC_SEM_VALUE_FLAGS_TEXT,0,2,3,417,1700,1724,1708,1722
 lea rdi,[rel name_codepoint_count]
 mov esi,14
 mov edx,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 mov ecx,NEBOC_RECEIVER_INSTANCE
 call prepare_api
 mov edi,NEBOC_SEM_ERROR_LENGTH_INVARIANT
 call assert_internal_error

 inc r13d
 ; 18 surrogate Char state is forbidden
 SETCTX NEBOC_SEM_SOURCE_CHAR_LITERAL,NEBOC_SEM_VALUE_FLAGS_CHAR,0xd800,0,1,418,1800,1819,1808,1817
 lea rdi,[rel name_codepoint]
 mov esi,9
 mov edx,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_CHAR
 mov ecx,NEBOC_RECEIVER_INSTANCE
 call prepare_api
 mov edi,NEBOC_SEM_ERROR_SCALAR_INVARIANT
 call assert_internal_error

 inc r13d
 ; 19 Bytes foundation rejects non-empty state
 SETCTX NEBOC_SEM_SOURCE_BYTES_VALUE,NEBOC_SEM_VALUE_IMMUTABLE,0,1,0,419,1900,1920,1908,1918
 lea rdi,[rel name_byte_length]
 mov esi,10
 mov edx,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
 mov ecx,NEBOC_RECEIVER_INSTANCE
 call prepare_api
 mov edi,NEBOC_SEM_ERROR_BYTES_STATE_INVARIANT
 call assert_internal_error

 inc r13d
 ; 20 exact method span required
 SETCTX NEBOC_SEM_SOURCE_TEXT_LITERAL,NEBOC_SEM_VALUE_FLAGS_TEXT,0,1,1,420,2000,2020,2007,2017
 lea rdi,[rel name_byte_length]
 mov esi,10
 mov edx,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 mov ecx,NEBOC_RECEIVER_INSTANCE
 call prepare_api
 test eax,eax
 jnz fail
 inc qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_SUBJECT_START_OFFSET]
 lea rdi,[rel sem]
 call neboc_text_char_bytes_semantic_analyze
 mov edi,neboc_text_char_unicode_e_bytes_SEM_ERROR_SPAN_INVARIANT
 call assert_internal_error

 inc r13d
 ; 21 source form invariant
 SETCTX 9,NEBOC_SEM_VALUE_FLAGS_TEXT,0,1,1,421,2100,2120,2106,2116
 lea rdi,[rel name_byte_length]
 mov esi,10
 mov edx,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 mov ecx,NEBOC_RECEIVER_INSTANCE
 call prepare_api
 mov edi,neboc_text_char_unicode_e_bytes_SEM_ERROR_SOURCE_FORM_INVARIANT
 call assert_internal_error

 inc r13d
 ; 22 result invariant after successful API request mutation
 SETCTX NEBOC_SEM_SOURCE_TEXT_LITERAL,NEBOC_SEM_VALUE_FLAGS_TEXT,0,1,1,422,2200,2220,2206,2216
 lea rdi,[rel name_byte_length]
 mov esi,10
 mov edx,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 mov ecx,NEBOC_RECEIVER_INSTANCE
 call prepare_api
 test eax,eax
 jnz fail
 mov qword [rel api_req+neboc_text_char_unicode_e_bytes_API_RESULT_TYPE_OFFSET],NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_BYTES
 lea rdi,[rel sem]
 call neboc_text_char_bytes_semantic_analyze
 mov edi,neboc_text_char_unicode_e_bytes_SEM_ERROR_RESULT_INVARIANT
 call assert_internal_error

 inc r13d
 ; 23 deterministic semantic/IR hashes for same Char contract
 SETCTX NEBOC_SEM_SOURCE_CHAR_LITERAL,NEBOC_SEM_VALUE_FLAGS_CHAR,65,0,1,401,100,103,101,102
 lea rdi,[rel char_a]
 mov esi,3
 call prepare_char
 test eax,eax
 jnz fail
 call assert_char
 mov rax,[rel saved_char_sem_hash]
 cmp rax,[rel sem+neboc_text_char_unicode_e_bytes_SEM_SEMANTIC_HASH_OFFSET]
 jne fail
 mov rax,[rel saved_char_prov_hash]
 cmp rax,[rel sem+neboc_text_char_unicode_e_bytes_SEM_PROVENANCE_HASH_OFFSET]
 jne fail
 mov rax,[rel saved_char_ir_hash]
 cmp rax,[rel ir+neboc_text_char_unicode_e_bytes_IR_HASH_OFFSET]
 jne fail

 inc r13d
 ; 24 IR rejects a semantic record with an invalid HIR invariant
 mov qword [rel sem+neboc_text_char_unicode_e_bytes_SEM_HIR_KIND_OFFSET],0
 call lower_ir
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 jne fail
 cmp qword [rel ir+neboc_text_char_unicode_e_bytes_IR_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_IR_ERROR_SEMANTIC_INVARIANT
 jne fail

 xor edi,edi
 jmp neboc_host_process_exit
fail:
 mov edi,r13d
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
