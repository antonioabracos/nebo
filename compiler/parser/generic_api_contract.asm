; Nebo Assembly — GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-PF002 isolated generic syntax/API/diagnostic contract
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/generic_api_contract.inc"

section .text

api_scalar_allowed:
 cmp rax,neboc_generics_constraints_overload_e_dispatch_TYPE_BOOL
 je .yes
 cmp rax,neboc_generics_constraints_overload_e_dispatch_TYPE_INT
 je .yes
 cmp rax,neboc_generics_constraints_overload_e_dispatch_TYPE_FLOAT
 je .yes
 cmp rax,neboc_generics_constraints_overload_e_dispatch_TYPE_CHAR
 je .yes
 xor eax,eax
 ret
.yes:
 mov eax,1
 ret

generics_constraints_overload_e_dispatch_api_hash:
 mov r8,[rdi+neboc_generics_constraints_overload_e_dispatch_API_SUBJECT_PTR_OFFSET]
 mov r9,[rdi+neboc_generics_constraints_overload_e_dispatch_API_SUBJECT_LENGTH_OFFSET]
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
 %assign off 0
 %rep 16
 xor rax,[rdi+off]
 imul rax,r10
 %assign off off+8
 %endrep
 mov [rdi+neboc_generics_constraints_overload_e_dispatch_API_HASH_OFFSET],rax
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
generics_constraints_overload_e_dispatch_api_error:
 mov [rdi+neboc_generics_constraints_overload_e_dispatch_API_DIAGNOSTIC_OFFSET],rsi
 mov rax,[rdi+neboc_generics_constraints_overload_e_dispatch_API_ABSOLUTE_START_OFFSET]
 mov [rdi+neboc_generics_constraints_overload_e_dispatch_API_ERROR_START_OFFSET],rax
 add rax,[rdi+neboc_generics_constraints_overload_e_dispatch_API_SUBJECT_LENGTH_OFFSET]
 mov [rdi+neboc_generics_constraints_overload_e_dispatch_API_ERROR_END_OFFSET],rax
 call generics_constraints_overload_e_dispatch_api_hash
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
generics_constraints_overload_e_dispatch_api_success:
 call generics_constraints_overload_e_dispatch_api_hash
 xor eax,eax
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_generic_api_contract
 push rbx
 push r12
 mov r12,rdi
 test r12,r12
 jz .invalid
 cmp qword [r12+neboc_generics_constraints_overload_e_dispatch_API_SUBJECT_PTR_OFFSET],0
 je .invalid
 cmp qword [r12+neboc_generics_constraints_overload_e_dispatch_API_SUBJECT_LENGTH_OFFSET],0
 je .invalid
 lea rdi,[r12+NEBOC_API_AST_FORM_OFFSET]
 mov ecx,6
 xor eax,eax
 rep stosq
 mov rax,[r12+neboc_generics_constraints_overload_e_dispatch_API_OPERATION_OFFSET]
 cmp rax,NEBOC_OP_GENERIC_DECL
 je .declaration
 cmp rax,NEBOC_OP_GENERIC_CALL
 je .call
 cmp rax,NEBOC_OP_GENERIC_TYPE
 je .generic_type
 cmp rax,NEBOC_OP_EXPLICIT_TYPE_ARGUMENTS
 je .explicit
 cmp rax,neboc_generics_constraints_overload_e_dispatch_OP_ALIAS
 je .alias
 cmp rax,NEBOC_OP_CODE_SHARING
 je .sharing
 jmp .invalid

.declaration:
 mov rax,[r12+neboc_generics_constraints_overload_e_dispatch_API_INPUT_FLAGS_OFFSET]
 test rax,NEBOC_INPUT_DUPLICATE_PARAMETER
 jnz .duplicate
 and rax,neboc_generics_constraints_overload_e_dispatch_INPUT_REQUIRED_FLAGS
 cmp rax,neboc_generics_constraints_overload_e_dispatch_INPUT_REQUIRED_FLAGS
 jne .alias
 mov rax,[r12+NEBOC_API_TYPE_PARAMETER_COUNT_OFFSET]
 test rax,rax
 jz .expected_parameter
 cmp rax,1
 jne .parameter_arity
 mov rax,[r12+NEBOC_API_BOUND_OFFSET]
 test rax,rax
 jz .bound_expected
 cmp rax,NEBOC_BOUND_SCALAR
 jne .bound_unknown
 cmp qword [r12+neboc_generics_constraints_overload_e_dispatch_API_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_PARAMETER_T
 jne .receiver_parameter
 cmp qword [r12+NEBOC_API_RETURN_TYPE_OFFSET],NEBOC_TYPE_PARAMETER_T
 jne .return_parameter
 cmp qword [r12+NEBOC_API_POSITIONAL_COUNT_OFFSET],0
 jne .positionals
 mov qword [r12+NEBOC_API_AST_FORM_OFFSET],NEBOC_AST_GENERIC_DECL
 mov qword [r12+neboc_generics_constraints_overload_e_dispatch_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_PARAMETER_T
 mov qword [r12+neboc_generics_constraints_overload_e_dispatch_API_DIAGNOSTIC_OFFSET],neboc_generics_constraints_overload_e_dispatch_DIAG_NONE
 jmp .ok

.call:
 cmp qword [r12+NEBOC_API_POSITIONAL_COUNT_OFFSET],0
 jne .positionals
 mov rax,[r12+NEBOC_API_CANDIDATE_COUNT_OFFSET]
 test rax,rax
 jz .no_match
 cmp rax,1
 jne .ambiguous
 mov rax,[r12+neboc_generics_constraints_overload_e_dispatch_API_RECEIVER_TYPE_OFFSET]
 mov rbx,rax
 call api_scalar_allowed
 test eax,eax
 jz .bound_not_satisfied
 mov qword [r12+NEBOC_API_AST_FORM_OFFSET],NEBOC_AST_GENERIC_CALL
 mov [r12+neboc_generics_constraints_overload_e_dispatch_API_RESULT_TYPE_OFFSET],rbx
 mov qword [r12+neboc_generics_constraints_overload_e_dispatch_API_DIAGNOSTIC_OFFSET],neboc_generics_constraints_overload_e_dispatch_DIAG_NONE
 jmp .ok

.generic_type: mov esi,NEBOC_DIAG_GENERIC_TYPE_DEFERRED
 jmp .diag
.explicit: mov esi,NEBOC_DIAG_EXPLICIT_TYPE_ARGUMENTS_DEFERRED
 jmp .diag
.alias: mov esi,neboc_generics_constraints_overload_e_dispatch_DIAG_ALIAS_FORBIDDEN
 jmp .diag
.sharing: mov esi,NEBOC_DIAG_CODE_SHARING_DEFERRED
 jmp .diag
.expected_parameter: mov esi,NEBOC_DIAG_EXPECTED_TYPE_PARAMETER
 jmp .diag
.parameter_arity: mov esi,NEBOC_DIAG_TYPE_PARAMETER_ARITY
 jmp .diag
.duplicate: mov esi,NEBOC_DIAG_DUPLICATE_TYPE_PARAMETER
 jmp .diag
.bound_expected: mov esi,NEBOC_DIAG_BOUND_EXPECTED
 jmp .diag
.bound_unknown: mov esi,NEBOC_DIAG_BOUND_UNKNOWN
 jmp .diag
.bound_not_satisfied: mov esi,NEBOC_DIAG_BOUND_NOT_SATISFIED
 jmp .diag
.receiver_parameter: mov esi,NEBOC_DIAG_RECEIVER_TYPE_PARAMETER_REQUIRED
 jmp .diag
.return_parameter: mov esi,NEBOC_DIAG_RETURN_TYPE_PARAMETER_REQUIRED
 jmp .diag
.positionals: mov esi,NEBOC_DIAG_POSITIONAL_PARAMETERS_DEFERRED
 jmp .diag
.no_match: mov esi,NEBOC_DIAG_OVERLOAD_NO_MATCH
 jmp .diag
.ambiguous: mov esi,NEBOC_DIAG_OVERLOAD_AMBIGUOUS
.diag:
 mov rdi,r12
 call generics_constraints_overload_e_dispatch_api_error
 jmp .done
.ok:
 or qword [r12+neboc_generics_constraints_overload_e_dispatch_API_RESULT_TYPE_OFFSET],0
 mov rdi,r12
 call generics_constraints_overload_e_dispatch_api_success
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
%undef call
