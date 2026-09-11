; GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-PF002 isolated generic syntax/API/diagnostic contract tests
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/generic_api_contract.inc"
extern neboc_generic_api_contract
extern neboc_host_process_exit

%macro CASE 10
 dq %1,%2,%3,%4,%5,%6,%7,%8,%9,%10
%endmacro

section .rodata
subject: db "generic<T: Scalar> identity"
subject_len equ $-subject

section .data align=8
cases:
 ; op,paramc,bound,receiver,return,positional,flags,candidates,status,diag
 CASE NEBOC_OP_GENERIC_DECL,1,NEBOC_BOUND_SCALAR,NEBOC_TYPE_PARAMETER_T,NEBOC_TYPE_PARAMETER_T,0,neboc_generics_constraints_overload_e_dispatch_INPUT_REQUIRED_FLAGS,0,NEBOC_STATUS_OK,0
 CASE NEBOC_OP_GENERIC_CALL,0,0,neboc_generics_constraints_overload_e_dispatch_TYPE_BOOL,0,0,0,1,NEBOC_STATUS_OK,0
 CASE NEBOC_OP_GENERIC_CALL,0,0,neboc_generics_constraints_overload_e_dispatch_TYPE_INT,0,0,0,1,NEBOC_STATUS_OK,0
 CASE NEBOC_OP_GENERIC_CALL,0,0,neboc_generics_constraints_overload_e_dispatch_TYPE_FLOAT,0,0,0,1,NEBOC_STATUS_OK,0
 CASE NEBOC_OP_GENERIC_CALL,0,0,neboc_generics_constraints_overload_e_dispatch_TYPE_CHAR,0,0,0,1,NEBOC_STATUS_OK,0
 CASE NEBOC_OP_GENERIC_DECL,0,NEBOC_BOUND_SCALAR,NEBOC_TYPE_PARAMETER_T,NEBOC_TYPE_PARAMETER_T,0,neboc_generics_constraints_overload_e_dispatch_INPUT_REQUIRED_FLAGS,0,NEBOC_STATUS_INVALID_SOURCE,NEBOC_DIAG_EXPECTED_TYPE_PARAMETER
 CASE NEBOC_OP_GENERIC_DECL,2,NEBOC_BOUND_SCALAR,NEBOC_TYPE_PARAMETER_T,NEBOC_TYPE_PARAMETER_T,0,neboc_generics_constraints_overload_e_dispatch_INPUT_REQUIRED_FLAGS,0,NEBOC_STATUS_INVALID_SOURCE,NEBOC_DIAG_TYPE_PARAMETER_ARITY
 CASE NEBOC_OP_GENERIC_DECL,1,NEBOC_BOUND_SCALAR,NEBOC_TYPE_PARAMETER_T,NEBOC_TYPE_PARAMETER_T,0,neboc_generics_constraints_overload_e_dispatch_INPUT_REQUIRED_FLAGS|NEBOC_INPUT_DUPLICATE_PARAMETER,0,NEBOC_STATUS_INVALID_SOURCE,NEBOC_DIAG_DUPLICATE_TYPE_PARAMETER
 CASE NEBOC_OP_GENERIC_DECL,1,NEBOC_BOUND_NONE,NEBOC_TYPE_PARAMETER_T,NEBOC_TYPE_PARAMETER_T,0,neboc_generics_constraints_overload_e_dispatch_INPUT_REQUIRED_FLAGS,0,NEBOC_STATUS_INVALID_SOURCE,NEBOC_DIAG_BOUND_EXPECTED
 CASE NEBOC_OP_GENERIC_DECL,1,99,NEBOC_TYPE_PARAMETER_T,NEBOC_TYPE_PARAMETER_T,0,neboc_generics_constraints_overload_e_dispatch_INPUT_REQUIRED_FLAGS,0,NEBOC_STATUS_INVALID_SOURCE,NEBOC_DIAG_BOUND_UNKNOWN
 CASE NEBOC_OP_GENERIC_DECL,1,NEBOC_BOUND_SCALAR,neboc_generics_constraints_overload_e_dispatch_TYPE_INT,NEBOC_TYPE_PARAMETER_T,0,neboc_generics_constraints_overload_e_dispatch_INPUT_REQUIRED_FLAGS,0,NEBOC_STATUS_INVALID_SOURCE,NEBOC_DIAG_RECEIVER_TYPE_PARAMETER_REQUIRED
 CASE NEBOC_OP_GENERIC_DECL,1,NEBOC_BOUND_SCALAR,NEBOC_TYPE_PARAMETER_T,neboc_generics_constraints_overload_e_dispatch_TYPE_INT,0,neboc_generics_constraints_overload_e_dispatch_INPUT_REQUIRED_FLAGS,0,NEBOC_STATUS_INVALID_SOURCE,NEBOC_DIAG_RETURN_TYPE_PARAMETER_REQUIRED
 CASE NEBOC_OP_GENERIC_DECL,1,NEBOC_BOUND_SCALAR,NEBOC_TYPE_PARAMETER_T,NEBOC_TYPE_PARAMETER_T,1,neboc_generics_constraints_overload_e_dispatch_INPUT_REQUIRED_FLAGS,0,NEBOC_STATUS_INVALID_SOURCE,NEBOC_DIAG_POSITIONAL_PARAMETERS_DEFERRED
 CASE NEBOC_OP_EXPLICIT_TYPE_ARGUMENTS,0,0,0,0,0,0,0,NEBOC_STATUS_INVALID_SOURCE,NEBOC_DIAG_EXPLICIT_TYPE_ARGUMENTS_DEFERRED
 CASE NEBOC_OP_GENERIC_TYPE,0,0,0,0,0,0,0,NEBOC_STATUS_INVALID_SOURCE,NEBOC_DIAG_GENERIC_TYPE_DEFERRED
 CASE neboc_generics_constraints_overload_e_dispatch_OP_ALIAS,0,0,0,0,0,0,0,NEBOC_STATUS_INVALID_SOURCE,neboc_generics_constraints_overload_e_dispatch_DIAG_ALIAS_FORBIDDEN
 CASE NEBOC_OP_GENERIC_CALL,0,0,neboc_generics_constraints_overload_e_dispatch_TYPE_INT,0,0,0,0,NEBOC_STATUS_INVALID_SOURCE,NEBOC_DIAG_OVERLOAD_NO_MATCH
 CASE NEBOC_OP_GENERIC_CALL,0,0,neboc_generics_constraints_overload_e_dispatch_TYPE_INT,0,0,0,2,NEBOC_STATUS_INVALID_SOURCE,NEBOC_DIAG_OVERLOAD_AMBIGUOUS
 CASE NEBOC_OP_CODE_SHARING,0,0,0,0,0,0,0,NEBOC_STATUS_INVALID_SOURCE,NEBOC_DIAG_CODE_SHARING_DEFERRED
 CASE NEBOC_OP_GENERIC_CALL,0,0,neboc_generics_constraints_overload_e_dispatch_TYPE_TEXT,0,0,0,1,NEBOC_STATUS_INVALID_SOURCE,NEBOC_DIAG_BOUND_NOT_SATISFIED
case_count equ ($-cases)/(10*8)

section .bss align=16
request: resb neboc_generics_constraints_overload_e_dispatch_API_REQUEST_SIZE
first_hash: resq 1

section .text
global _start
_start:
 lea r14,[rel cases]
 mov r15d,case_count
 mov r13d,1
.loop:
 lea rdi,[rel request]
 mov ecx,neboc_generics_constraints_overload_e_dispatch_API_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 %assign i 0
 %rep 8
 mov rax,[r14+i*8]
 mov [rel request+i*8],rax
 %assign i i+1
 %endrep
 lea rax,[rel subject]
 mov [rel request+neboc_generics_constraints_overload_e_dispatch_API_SUBJECT_PTR_OFFSET],rax
 mov qword [rel request+neboc_generics_constraints_overload_e_dispatch_API_SUBJECT_LENGTH_OFFSET],subject_len
 mov qword [rel request+neboc_generics_constraints_overload_e_dispatch_API_ABSOLUTE_START_OFFSET],700
 lea rdi,[rel request]
 call neboc_generic_api_contract
 cmp rax,[r14+8*8]
 jne .fail
 mov rax,[rel request+neboc_generics_constraints_overload_e_dispatch_API_DIAGNOSTIC_OFFSET]
 cmp rax,[r14+9*8]
 jne .fail
 cmp qword [r14+8*8],NEBOC_STATUS_OK
 je .success_span
 cmp qword [rel request+neboc_generics_constraints_overload_e_dispatch_API_ERROR_START_OFFSET],700
 jne .fail
 cmp qword [rel request+neboc_generics_constraints_overload_e_dispatch_API_ERROR_END_OFFSET],700+subject_len
 jne .fail
 jmp .next
.success_span:
 cmp qword [rel request+neboc_generics_constraints_overload_e_dispatch_API_ERROR_START_OFFSET],0
 jne .fail
 cmp qword [rel request+neboc_generics_constraints_overload_e_dispatch_API_ERROR_END_OFFSET],0
 jne .fail
.next:
 add r14,10*8
 inc r13d
 dec r15d
 jnz .loop
 ; identical valid request produces an identical stable hash.
 lea rdi,[rel request]
 mov ecx,neboc_generics_constraints_overload_e_dispatch_API_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov qword [rel request+neboc_generics_constraints_overload_e_dispatch_API_OPERATION_OFFSET],NEBOC_OP_GENERIC_DECL
 mov qword [rel request+NEBOC_API_TYPE_PARAMETER_COUNT_OFFSET],1
 mov qword [rel request+NEBOC_API_BOUND_OFFSET],NEBOC_BOUND_SCALAR
 mov qword [rel request+neboc_generics_constraints_overload_e_dispatch_API_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_PARAMETER_T
 mov qword [rel request+NEBOC_API_RETURN_TYPE_OFFSET],NEBOC_TYPE_PARAMETER_T
 mov qword [rel request+neboc_generics_constraints_overload_e_dispatch_API_INPUT_FLAGS_OFFSET],neboc_generics_constraints_overload_e_dispatch_INPUT_REQUIRED_FLAGS
 lea rax,[rel subject]
 mov [rel request+neboc_generics_constraints_overload_e_dispatch_API_SUBJECT_PTR_OFFSET],rax
 mov qword [rel request+neboc_generics_constraints_overload_e_dispatch_API_SUBJECT_LENGTH_OFFSET],subject_len
 lea rdi,[rel request]
 call neboc_generic_api_contract
 test eax,eax
 jnz .fail
 mov rax,[rel request+neboc_generics_constraints_overload_e_dispatch_API_HASH_OFFSET]
 mov [rel first_hash],rax
 lea rdi,[rel request]
 call neboc_generic_api_contract
 test eax,eax
 jnz .fail
 mov rax,[rel first_hash]
 cmp rax,[rel request+neboc_generics_constraints_overload_e_dispatch_API_HASH_OFFSET]
 jne .fail
 xor edi,edi
 call neboc_generic_api_contract
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 jmp neboc_host_process_exit
.fail:
 mov edi,r13d
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
