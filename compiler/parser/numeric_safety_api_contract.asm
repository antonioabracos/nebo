; Nebo Assembly — SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-PF002 isolated syntax/API/diagnostics contract
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/parser/numeric_safety_api_contract.inc"

section .rodata
name_to_float: db "toFloat"
name_to_float_len equ $-name_to_float
name_is_finite: db "isFinite"
name_is_finite_len equ $-name_is_finite
name_is_nan: db "isNaN"
name_is_nan_len equ $-name_is_nan
name_is_infinite: db "isInfinite"
name_is_infinite_len equ $-name_is_infinite
name_is_negative_zero: db "isNegativeZero"
name_is_negative_zero_len equ $-name_is_negative_zero

name_as_float: db "asFloat"
name_as_float_len equ $-name_as_float
name_to_double: db "toDouble"
name_to_double_len equ $-name_to_double
name_is_inf: db "isInf"
name_is_inf_len equ $-name_is_inf
name_is_neg_zero: db "isNegZero"
name_is_neg_zero_len equ $-name_is_neg_zero

name_to_int: db "toInt"
name_to_int_len equ $-name_to_int
name_to_int_checked: db "toIntChecked"
name_to_int_checked_len equ $-name_to_int_checked
name_to_int_unchecked: db "toIntUnchecked"
name_to_int_unchecked_len equ $-name_to_int_unchecked
name_to_float_checked: db "toFloatChecked"
name_to_float_checked_len equ $-name_to_float_checked
name_wrapping_add: db "wrappingAdd"
name_wrapping_add_len equ $-name_wrapping_add
name_saturating_add: db "saturatingAdd"
name_saturating_add_len equ $-name_saturating_add
name_parse_int: db "parseInt"
name_parse_int_len equ $-name_parse_int
name_parse_float: db "parseFloat"
name_parse_float_len equ $-name_parse_float
name_approximately_equal: db "approximatelyEqual"
name_approximately_equal_len equ $-name_approximately_equal

section .text

; seguranca_numerica_conversoes_e_overflow_name_equal(candidate_ptr, candidate_len, expected_ptr, expected_len)
; Returns 1 for byte-exact ASCII equality, 0 otherwise.
seguranca_numerica_conversoes_e_overflow_name_equal:
 cmp rsi,rcx
 jne .no
 test rsi,rsi
 jz .no
 mov rcx,rsi
 mov rsi,rdi
 mov rdi,rdx
 repe cmpsb
 sete al
 movzx eax,al
 ret
.no:
 xor eax,eax
 ret

; hash_request(request*) -> stable FNV-1a-derived 64-bit contract hash.
hash_request:
 mov r8,[rdi+neboc_seguranca_numerica_conversoes_e_overflow_API_SUBJECT_PTR_OFFSET]
 mov r9,[rdi+neboc_seguranca_numerica_conversoes_e_overflow_API_SUBJECT_LENGTH_OFFSET]
 mov rax,1469598103934665603
 mov r10,1099511628211
 xor ecx,ecx
.bytes:
 cmp rcx,r9
 jae .fields
 movzx edx,byte [r8+rcx]
 xor rax,rdx
 imul rax,r10
 inc rcx
 jmp .bytes
.fields:
 xor rax,[rdi+neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_OFFSET]
 imul rax,r10
 xor rax,[rdi+neboc_seguranca_numerica_conversoes_e_overflow_API_RECEIVER_TYPE_OFFSET]
 imul rax,r10
 xor rax,[rdi+NEBOC_API_TARGET_TYPE_OFFSET]
 imul rax,r10
 xor rax,[rdi+neboc_seguranca_numerica_conversoes_e_overflow_API_ARGUMENT_COUNT_OFFSET]
 imul rax,r10
 xor rax,[rdi+neboc_seguranca_numerica_conversoes_e_overflow_API_METHOD_ID_OFFSET]
 imul rax,r10
 xor rax,[rdi+neboc_seguranca_numerica_conversoes_e_overflow_API_RESULT_TYPE_OFFSET]
 imul rax,r10
 xor rax,[rdi+neboc_seguranca_numerica_conversoes_e_overflow_API_FLAGS_OFFSET]
 imul rax,r10
 xor rax,[rdi+neboc_seguranca_numerica_conversoes_e_overflow_API_DIAGNOSTIC_OFFSET]
 imul rax,r10
 mov [rdi+neboc_seguranca_numerica_conversoes_e_overflow_API_HASH_OFFSET],rax
 ret

; neboc_numeric_safety_api_contract(request*) -> StatusCode
; The routine is isolated from neboc_parser_parse, neboc_type_checker_check and
; the public CLI until later explicitly authorized seguranca_numerica_conversoes_e_overflow fronts.
NEBOC_ABI_FUNCTION neboc_numeric_safety_api_contract
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 cld
 test r12,r12
 jz .invalid_argument
 mov r13,[r12+neboc_seguranca_numerica_conversoes_e_overflow_API_SUBJECT_PTR_OFFSET]
 mov r14,[r12+neboc_seguranca_numerica_conversoes_e_overflow_API_SUBJECT_LENGTH_OFFSET]
 test r13,r13
 jz .invalid_argument
 test r14,r14
 jz .invalid_argument
 lea rdi,[r12+neboc_seguranca_numerica_conversoes_e_overflow_API_METHOD_ID_OFFSET]
 mov ecx,(neboc_seguranca_numerica_conversoes_e_overflow_API_REQUEST_SIZE-neboc_seguranca_numerica_conversoes_e_overflow_API_METHOD_ID_OFFSET)/8
 xor eax,eax
 rep stosq
 mov rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_OFFSET]
 cmp rax,neboc_seguranca_numerica_conversoes_e_overflow_API_OPERATION_METHOD
 je .method
 cmp rax,NEBOC_API_OPERATION_IMPLICIT_COERCION
 je .implicit_coercion
 cmp rax,NEBOC_API_OPERATION_CAST_SYNTAX
 je .cast_syntax
 cmp rax,NEBOC_API_OPERATION_CROSS_TYPE_CONSTRUCTOR
 je .cross_type_constructor
 jmp .invalid_argument

.method:
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel name_to_float]
 mov ecx,name_to_float_len
 call seguranca_numerica_conversoes_e_overflow_name_equal
 test eax,eax
 jnz .to_float
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel name_is_finite]
 mov ecx,name_is_finite_len
 call seguranca_numerica_conversoes_e_overflow_name_equal
 test eax,eax
 jnz .is_finite
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel name_is_nan]
 mov ecx,name_is_nan_len
 call seguranca_numerica_conversoes_e_overflow_name_equal
 test eax,eax
 jnz .is_nan
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel name_is_infinite]
 mov ecx,name_is_infinite_len
 call seguranca_numerica_conversoes_e_overflow_name_equal
 test eax,eax
 jnz .is_infinite
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel name_is_negative_zero]
 mov ecx,name_is_negative_zero_len
 call seguranca_numerica_conversoes_e_overflow_name_equal
 test eax,eax
 jnz .is_negative_zero

 ; Explicitly forbidden aliases.
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel name_as_float]
 mov ecx,name_as_float_len
 call seguranca_numerica_conversoes_e_overflow_name_equal
 test eax,eax
 jnz .alias_forbidden
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel name_to_double]
 mov ecx,name_to_double_len
 call seguranca_numerica_conversoes_e_overflow_name_equal
 test eax,eax
 jnz .alias_forbidden
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel name_is_inf]
 mov ecx,name_is_inf_len
 call seguranca_numerica_conversoes_e_overflow_name_equal
 test eax,eax
 jnz .alias_forbidden
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel name_is_neg_zero]
 mov ecx,name_is_neg_zero_len
 call seguranca_numerica_conversoes_e_overflow_name_equal
 test eax,eax
 jnz .alias_forbidden

 ; Named APIs that remain outside the frozen foundation profile.
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel name_to_int]
 mov ecx,name_to_int_len
 call seguranca_numerica_conversoes_e_overflow_name_equal
 test eax,eax
 jnz .deferred_api
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel name_to_int_checked]
 mov ecx,name_to_int_checked_len
 call seguranca_numerica_conversoes_e_overflow_name_equal
 test eax,eax
 jnz .deferred_api
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel name_to_int_unchecked]
 mov ecx,name_to_int_unchecked_len
 call seguranca_numerica_conversoes_e_overflow_name_equal
 test eax,eax
 jnz .deferred_api
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel name_to_float_checked]
 mov ecx,name_to_float_checked_len
 call seguranca_numerica_conversoes_e_overflow_name_equal
 test eax,eax
 jnz .deferred_api
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel name_wrapping_add]
 mov ecx,name_wrapping_add_len
 call seguranca_numerica_conversoes_e_overflow_name_equal
 test eax,eax
 jnz .deferred_api
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel name_saturating_add]
 mov ecx,name_saturating_add_len
 call seguranca_numerica_conversoes_e_overflow_name_equal
 test eax,eax
 jnz .deferred_api
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel name_parse_int]
 mov ecx,name_parse_int_len
 call seguranca_numerica_conversoes_e_overflow_name_equal
 test eax,eax
 jnz .deferred_api
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel name_parse_float]
 mov ecx,name_parse_float_len
 call seguranca_numerica_conversoes_e_overflow_name_equal
 test eax,eax
 jnz .deferred_api
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel name_approximately_equal]
 mov ecx,name_approximately_equal_len
 call seguranca_numerica_conversoes_e_overflow_name_equal
 test eax,eax
 jnz .deferred_api
 mov r10d,NEBOC_API_DIAG_UNKNOWN_API
 jmp .error

.to_float:
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_API_METHOD_ID_OFFSET],NEBOC_API_METHOD_INT_TO_FLOAT
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_FLOAT
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_API_FLAGS_OFFSET],NEBOC_API_FLAGS_TO_FLOAT
 cmp qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_API_ARGUMENT_COUNT_OFFSET],0
 jne .arguments_not_allowed
 cmp qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_API_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_ID_INT
 jne .receiver_must_be_int
 jmp .success
.is_finite:
 mov ebx,NEBOC_API_METHOD_FLOAT_IS_FINITE
 jmp .classifier
.is_nan:
 mov ebx,NEBOC_API_METHOD_FLOAT_IS_NAN
 jmp .classifier
.is_infinite:
 mov ebx,NEBOC_API_METHOD_FLOAT_IS_INFINITE
 jmp .classifier
.is_negative_zero:
 mov ebx,NEBOC_API_METHOD_FLOAT_IS_NEGATIVE_ZERO
.classifier:
 mov [r12+neboc_seguranca_numerica_conversoes_e_overflow_API_METHOD_ID_OFFSET],rbx
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_BOOL
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_API_FLAGS_OFFSET],NEBOC_API_FLAGS_CLASSIFIER
 cmp qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_API_ARGUMENT_COUNT_OFFSET],0
 jne .arguments_not_allowed
 cmp qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_API_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_ID_FLOAT
 jne .receiver_must_be_float
 jmp .success

.implicit_coercion:
 mov rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_API_RECEIVER_TYPE_OFFSET]
 mov rbx,[r12+NEBOC_API_TARGET_TYPE_OFFSET]
 cmp rax,rbx
 je .invalid_argument
 cmp rax,NEBOC_TYPE_ID_INT
 je .implicit_left_int
 cmp rax,NEBOC_TYPE_ID_FLOAT
 jne .invalid_argument
 cmp rbx,NEBOC_TYPE_ID_INT
 jne .invalid_argument
 jmp .implicit_error
.implicit_left_int:
 cmp rbx,NEBOC_TYPE_ID_FLOAT
 jne .invalid_argument
.implicit_error:
 mov r10d,NEBOC_API_DIAG_IMPLICIT_COERCION_FORBIDDEN
 jmp .error
.cast_syntax:
 mov r10d,NEBOC_API_DIAG_CAST_SYNTAX_UNAVAILABLE
 jmp .error
.cross_type_constructor:
 mov rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_API_RECEIVER_TYPE_OFFSET]
 cmp rax,[r12+NEBOC_API_TARGET_TYPE_OFFSET]
 je .invalid_argument
 mov r10d,NEBOC_API_DIAG_CROSS_TYPE_CONSTRUCTOR_FORBIDDEN
 jmp .error
.arguments_not_allowed:
 mov r10d,neboc_seguranca_numerica_conversoes_e_overflow_API_DIAG_ARGUMENTS_NOT_ALLOWED
 jmp .error
.receiver_must_be_int:
 mov r10d,NEBOC_API_DIAG_RECEIVER_MUST_BE_INT
 jmp .error
.receiver_must_be_float:
 mov r10d,NEBOC_API_DIAG_RECEIVER_MUST_BE_FLOAT
 jmp .error
.alias_forbidden:
 mov r10d,neboc_seguranca_numerica_conversoes_e_overflow_API_DIAG_ALIAS_FORBIDDEN
 jmp .error
.deferred_api:
 mov r10d,neboc_seguranca_numerica_conversoes_e_overflow_API_DIAG_DEFERRED_API

.error:
 mov [r12+neboc_seguranca_numerica_conversoes_e_overflow_API_DIAGNOSTIC_OFFSET],r10
 mov rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_API_ABSOLUTE_START_OFFSET]
 mov [r12+neboc_seguranca_numerica_conversoes_e_overflow_API_ERROR_START_OFFSET],rax
 add rax,r14
 mov [r12+neboc_seguranca_numerica_conversoes_e_overflow_API_ERROR_END_OFFSET],rax
 mov rdi,r12
 call hash_request
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.success:
 mov rdi,r12
 call hash_request
 xor eax,eax
 jmp .done
.invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
