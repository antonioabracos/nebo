; SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-PF002 isolated API and provisional diagnostic contract tests
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/parser/numeric_safety_api_contract.inc"
extern neboc_numeric_safety_api_contract
extern neboc_host_process_exit

section .rodata
s_to_float: db "toFloat"
s_is_finite: db "isFinite"
s_is_nan: db "isNaN"
s_is_infinite: db "isInfinite"
s_is_negative_zero: db "isNegativeZero"
s_as_float: db "asFloat"
s_to_double: db "toDouble"
s_is_inf: db "isInf"
s_is_neg_zero: db "isNegZero"
s_to_int: db "toInt"
s_wrapping_add: db "wrappingAdd"
s_saturating_add: db "saturatingAdd"
s_plus: db "+"
s_as: db "as"
s_float: db "Float"
s_number: db "number"

%macro CASE 12
 dq %1,%2,%3,%4,%5,%6,%7,%8,%9,%10,%11,%12
%endmacro
; operation, receiver, target, subject, length, args, status, method, result,
; flags, diagnostic, error_end_delta
cases:
 CASE neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_METHOD,NEBOC_TYPE_ID_INT,0,s_to_float,7,0,NEBOC_STATUS_OK,NEBOC_API_METHOD_INT_TO_FLOAT,NEBOC_TYPE_ID_FLOAT,NEBOC_API_FLAGS_TO_FLOAT,neboc_seguranca_numerica_conversoes_e_overflow_API_DIAG_NONE,0
 CASE neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_METHOD,NEBOC_TYPE_ID_FLOAT,0,s_is_finite,8,0,NEBOC_STATUS_OK,NEBOC_API_METHOD_FLOAT_IS_FINITE,NEBOC_TYPE_ID_BOOL,NEBOC_API_FLAGS_CLASSIFIER,neboc_seguranca_numerica_conversoes_e_overflow_API_DIAG_NONE,0
 CASE neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_METHOD,NEBOC_TYPE_ID_FLOAT,0,s_is_nan,5,0,NEBOC_STATUS_OK,NEBOC_API_METHOD_FLOAT_IS_NAN,NEBOC_TYPE_ID_BOOL,NEBOC_API_FLAGS_CLASSIFIER,neboc_seguranca_numerica_conversoes_e_overflow_API_DIAG_NONE,0
 CASE neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_METHOD,NEBOC_TYPE_ID_FLOAT,0,s_is_infinite,10,0,NEBOC_STATUS_OK,NEBOC_API_METHOD_FLOAT_IS_INFINITE,NEBOC_TYPE_ID_BOOL,NEBOC_API_FLAGS_CLASSIFIER,neboc_seguranca_numerica_conversoes_e_overflow_API_DIAG_NONE,0
 CASE neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_METHOD,NEBOC_TYPE_ID_FLOAT,0,s_is_negative_zero,14,0,NEBOC_STATUS_OK,NEBOC_API_METHOD_FLOAT_IS_NEGATIVE_ZERO,NEBOC_TYPE_ID_BOOL,NEBOC_API_FLAGS_CLASSIFIER,neboc_seguranca_numerica_conversoes_e_overflow_API_DIAG_NONE,0
 CASE neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_METHOD,NEBOC_TYPE_ID_INT,0,s_to_float,7,1,NEBOC_STATUS_INVALID_SOURCE,NEBOC_API_METHOD_INT_TO_FLOAT,NEBOC_TYPE_ID_FLOAT,NEBOC_API_FLAGS_TO_FLOAT,neboc_seguranca_numerica_conversoes_e_overflow_API_DIAG_ARGUMENTS_NOT_ALLOWED,7
 CASE neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_METHOD,NEBOC_TYPE_ID_FLOAT,0,s_to_float,7,0,NEBOC_STATUS_INVALID_SOURCE,NEBOC_API_METHOD_INT_TO_FLOAT,NEBOC_TYPE_ID_FLOAT,NEBOC_API_FLAGS_TO_FLOAT,NEBOC_API_DIAG_RECEIVER_MUST_BE_INT,7
 CASE neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_METHOD,NEBOC_TYPE_ID_INT,0,s_is_finite,8,0,NEBOC_STATUS_INVALID_SOURCE,NEBOC_API_METHOD_FLOAT_IS_FINITE,NEBOC_TYPE_ID_BOOL,NEBOC_API_FLAGS_CLASSIFIER,NEBOC_API_DIAG_RECEIVER_MUST_BE_FLOAT,8
 CASE neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_METHOD,NEBOC_TYPE_ID_INT,0,s_as_float,7,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,neboc_seguranca_numerica_conversoes_e_overflow_API_DIAG_ALIAS_FORBIDDEN,7
 CASE neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_METHOD,NEBOC_TYPE_ID_INT,0,s_to_double,8,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,neboc_seguranca_numerica_conversoes_e_overflow_API_DIAG_ALIAS_FORBIDDEN,8
 CASE neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_METHOD,NEBOC_TYPE_ID_FLOAT,0,s_is_inf,5,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,neboc_seguranca_numerica_conversoes_e_overflow_API_DIAG_ALIAS_FORBIDDEN,5
 CASE neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_METHOD,NEBOC_TYPE_ID_FLOAT,0,s_is_neg_zero,9,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,neboc_seguranca_numerica_conversoes_e_overflow_API_DIAG_ALIAS_FORBIDDEN,9
 CASE neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_METHOD,NEBOC_TYPE_ID_FLOAT,0,s_to_int,5,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,neboc_seguranca_numerica_conversoes_e_overflow_API_DIAG_DEFERRED_API,5
 CASE neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_METHOD,NEBOC_TYPE_ID_INT,0,s_wrapping_add,11,1,NEBOC_STATUS_OK,NEBOC_API_METHOD_INT_WRAPPING_ADD,NEBOC_TYPE_ID_INT,NEBOC_API_FLAGS_OVERFLOW_POLICY,neboc_seguranca_numerica_conversoes_e_overflow_API_DIAG_NONE,0
 CASE neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_METHOD,NEBOC_TYPE_ID_INT,0,s_saturating_add,13,1,NEBOC_STATUS_OK,NEBOC_API_METHOD_INT_SATURATING_ADD,NEBOC_TYPE_ID_INT,NEBOC_API_FLAGS_OVERFLOW_POLICY,neboc_seguranca_numerica_conversoes_e_overflow_API_DIAG_NONE,0
 CASE NEBOC_API_OPERATION_IMPLICIT_COERCION,NEBOC_TYPE_ID_INT,NEBOC_TYPE_ID_FLOAT,s_plus,1,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,NEBOC_API_DIAG_IMPLICIT_COERCION_FORBIDDEN,1
 CASE NEBOC_API_OPERATION_CAST_SYNTAX,NEBOC_TYPE_ID_INT,NEBOC_TYPE_ID_FLOAT,s_as,2,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,NEBOC_API_DIAG_CAST_SYNTAX_UNAVAILABLE,2
 CASE NEBOC_API_OPERATION_CROSS_TYPE_CONSTRUCTOR,NEBOC_TYPE_ID_INT,NEBOC_TYPE_ID_FLOAT,s_float,5,1,NEBOC_STATUS_INVALID_SOURCE,0,0,0,NEBOC_API_DIAG_CROSS_TYPE_CONSTRUCTOR_FORBIDDEN,5
 CASE neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_METHOD,NEBOC_TYPE_ID_INT,0,s_number,6,0,NEBOC_STATUS_INVALID_SOURCE,0,0,0,NEBOC_API_DIAG_UNKNOWN_API,6
case_count equ ($-cases)/(12*8)

section .bss align=16
request: resb neboc_seguranca_numerica_conversoes_e_overflow_API_REQUEST_SIZE
first_hash: resq 1

section .text
global _start
_start:
 lea r14,[rel cases]
 mov r15d,case_count
 mov r13d,1
.case_loop:
 lea rdi,[rel request]
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_API_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,[r14]
 mov [rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_OFFSET],rax
 mov rax,[r14+8]
 mov [rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_RECEIVER_TYPE_OFFSET],rax
 mov rax,[r14+16]
 mov [rel request+NEBOC_API_TARGET_TYPE_OFFSET],rax
 mov rax,[r14+24]
 mov [rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_SUBJECT_PTR_OFFSET],rax
 mov rax,[r14+32]
 mov [rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_SUBJECT_LENGTH_OFFSET],rax
 mov rax,[r14+40]
 mov [rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_ARGUMENT_COUNT_OFFSET],rax
 mov qword [rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_SOURCE_ID_OFFSET],303
 mov qword [rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_ABSOLUTE_START_OFFSET],1000
 lea rdi,[rel request]
 call neboc_numeric_safety_api_contract
 cmp rax,[r14+48]
 jne .fail
 mov rax,[rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_METHOD_ID_OFFSET]
 cmp rax,[r14+56]
 jne .fail
 mov rax,[rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_RESULT_TYPE_OFFSET]
 cmp rax,[r14+64]
 jne .fail
 mov rax,[rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_FLAGS_OFFSET]
 cmp rax,[r14+72]
 jne .fail
 mov rax,[rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_DIAGNOSTIC_OFFSET]
 cmp rax,[r14+80]
 jne .fail
 cmp qword [r14+48],NEBOC_STATUS_OK
 je .success_span
 cmp qword [rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_ERROR_START_OFFSET],1000
 jne .fail
 mov rax,1000
 add rax,[r14+88]
 cmp [rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_ERROR_END_OFFSET],rax
 jne .fail
 jmp .next
.success_span:
 cmp qword [rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_ERROR_START_OFFSET],0
 jne .fail
 cmp qword [rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_ERROR_END_OFFSET],0
 jne .fail
.next:
 add r14,96
 inc r13d
 dec r15d
 jnz .case_loop

 ; Same request must produce the same hash.
 lea rdi,[rel request]
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_API_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov qword [rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_METHOD
 mov qword [rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_ID_INT
 lea rax,[rel s_to_float]
 mov [rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_SUBJECT_PTR_OFFSET],rax
 mov qword [rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_SUBJECT_LENGTH_OFFSET],7
 mov qword [rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_SOURCE_ID_OFFSET],303
 mov qword [rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_ABSOLUTE_START_OFFSET],44
 lea rdi,[rel request]
 call neboc_numeric_safety_api_contract
 test eax,eax
 jnz .fail
 mov rax,[rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_HASH_OFFSET]
 mov [rel first_hash],rax
 lea rdi,[rel request]
 call neboc_numeric_safety_api_contract
 test eax,eax
 jnz .fail
 mov rax,[rel first_hash]
 cmp rax,[rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_HASH_OFFSET]
 jne .fail

 xor edi,edi
 call neboc_numeric_safety_api_contract
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 lea rdi,[rel request]
 mov qword [rel request+neboc_seguranca_numerica_conversoes_e_overflow_API_SUBJECT_PTR_OFFSET],0
 call neboc_numeric_safety_api_contract
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 jmp neboc_host_process_exit
.fail:
 mov edi,r13d
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
