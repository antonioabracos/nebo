; Nebo Assembly — GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-PF005 bounded public scalar-generic vertical recognizer
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/parser/generic_api_contract.inc"
%include "compiler/semantic/generics/generic_semantic.inc"
%include "compiler/lowering/generics/generic_ir_contract.inc"
%include "compiler/lowering/generics/generic_native_contract.inc"
%include "compiler/lowering/scalars/foundation_float_lowering.inc"
%include "compiler/semantic/generics/generic_vertical.inc"
extern neboc_generic_api_contract
extern neboc_generic_semantic_analyze
extern neboc_generic_ir_lower
extern neboc_generic_native_plan
extern neboc_foundation_float_materialize_literal

section .rodata
n_template: db 'template'
n_template_len equ $-n_template
generic_vertical_n_t: db 'T'
n_t_len equ $-generic_vertical_n_t
generics_constraints_overload_e_dispatch_n_scalar: db 'Scalar'
generics_constraints_overload_e_dispatch_n_scalar_len equ $-generics_constraints_overload_e_dispatch_n_scalar
n_shared: db 'shared'
n_shared_len equ $-n_shared
generics_constraints_overload_e_dispatch_n_value: db 'value'
generics_constraints_overload_e_dispatch_n_value_len equ $-generics_constraints_overload_e_dispatch_n_value
n_identity: db 'identity'
n_identity_len equ $-n_identity

section .bss align=16
g07v_api: resb neboc_generics_constraints_overload_e_dispatch_API_REQUEST_SIZE
g07v_sem: resb neboc_generics_constraints_overload_e_dispatch_SEM_REQUEST_SIZE
g07v_ir: resb neboc_generics_constraints_overload_e_dispatch_IR_REQUEST_SIZE
g07v_native: resb neboc_generics_constraints_overload_e_dispatch_NATIVE_REQUEST_SIZE
g07v_float: resb NEBOC_FLOAT_LOWERING_REQUEST_SIZE
g07v_float_bits: resq 1

section .text
; request*, token index -> token* or zero
g07v_token_ptr:
 mov rax,rsi
 cmp rax,[rdi+neboc_generics_constraints_overload_e_dispatch_VERTICAL_TOKEN_COUNT_OFFSET]
 jae .bad
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[rdi+neboc_generics_constraints_overload_e_dispatch_VERTICAL_TOKENS_OFFSET]
 ret
.bad: xor eax,eax
 ret

; request*, token index, bytes*, length -> EAX 1/0
g07v_token_match:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call g07v_token_ptr
 test rax,rax
 jz .no
 mov rbx,rax
 mov rax,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rax,[rbx+NEBOC_TOKEN_START_OFFSET]
 cmp rax,r15
 jne .no
 mov rax,[r12+neboc_generics_constraints_overload_e_dispatch_VERTICAL_SOURCE_OFFSET]
 add rax,[rbx+NEBOC_TOKEN_START_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,r15
 jae .yes
 mov dl,[rax+rcx]
 cmp dl,[r14+rcx]
 jne .no
 inc rcx
 jmp .loop
.yes: mov eax,1
 jmp .done
.no: xor eax,eax
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, diagnostic, token index -> INVALID_SOURCE
g07v_error:
 push rbx
 mov rbx,rdi
 mov qword [rbx+neboc_generics_constraints_overload_e_dispatch_VERTICAL_FOUND_OFFSET],1
 mov [rbx+neboc_generics_constraints_overload_e_dispatch_VERTICAL_DIAGNOSTIC_OFFSET],rsi
 mov [rbx+neboc_generics_constraints_overload_e_dispatch_VERTICAL_ERROR_TOKEN_OFFSET],rdx
 mov rsi,rdx
 call g07v_token_ptr
 test rax,rax
 jz .done_span
 mov rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov [rbx+neboc_generics_constraints_overload_e_dispatch_VERTICAL_ERROR_START_OFFSET],rcx
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 mov [rbx+neboc_generics_constraints_overload_e_dispatch_VERTICAL_ERROR_END_OFFSET],rcx
.done_span:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 pop rbx
 ret

; request*, token index, expected kind -> EAX 1/0
g07v_kind_is:
 push rdx
 call g07v_token_ptr
 pop rdx
 test rax,rax
 jz .no
 cmp [rax+NEBOC_TOKEN_KIND_OFFSET],rdx
 sete al
 movzx eax,al
 ret
.no: xor eax,eax
 ret

; Validate PF002/PF003/PF004 contracts after bounded syntax recognition.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
g07v_contract_chain:
 push rbx
 push r12
 mov r12,rdi
 lea rdi,[rel g07v_api]
 mov ecx,neboc_generics_constraints_overload_e_dispatch_API_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov qword [rel g07v_api+neboc_generics_constraints_overload_e_dispatch_API_OPERATION_OFFSET],NEBOC_OP_GENERIC_DECL
 mov qword [rel g07v_api+NEBOC_API_TYPE_PARAMETER_COUNT_OFFSET],1
 mov qword [rel g07v_api+NEBOC_API_BOUND_OFFSET],NEBOC_BOUND_SCALAR
 mov qword [rel g07v_api+neboc_generics_constraints_overload_e_dispatch_API_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_PARAMETER_T
 mov qword [rel g07v_api+NEBOC_API_RETURN_TYPE_OFFSET],NEBOC_TYPE_PARAMETER_T
 mov qword [rel g07v_api+neboc_generics_constraints_overload_e_dispatch_API_INPUT_FLAGS_OFFSET],neboc_generics_constraints_overload_e_dispatch_INPUT_REQUIRED_FLAGS
 mov rax,[r12+neboc_generics_constraints_overload_e_dispatch_VERTICAL_SOURCE_OFFSET]
 mov [rel g07v_api+neboc_generics_constraints_overload_e_dispatch_API_SUBJECT_PTR_OFFSET],rax
 mov rax,[r12+neboc_generics_constraints_overload_e_dispatch_VERTICAL_SOURCE_LENGTH_OFFSET]
 mov [rel g07v_api+neboc_generics_constraints_overload_e_dispatch_API_SUBJECT_LENGTH_OFFSET],rax
 lea rdi,[rel g07v_api]
 call neboc_generic_api_contract
 test eax,eax
 jnz .internal
 lea rdi,[rel g07v_sem]
 mov ecx,neboc_generics_constraints_overload_e_dispatch_SEM_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov qword [rel g07v_sem+neboc_generics_constraints_overload_e_dispatch_SEM_KIND_OFFSET],NEBOC_SEM_KIND_DECLARATION
 mov qword [rel g07v_sem+NEBOC_SEM_DECLARATION_ID_OFFSET],7
 mov qword [rel g07v_sem+neboc_generics_constraints_overload_e_dispatch_SEM_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_PARAMETER_T
 mov qword [rel g07v_sem+NEBOC_SEM_BODY_RETURN_TYPE_OFFSET],NEBOC_TYPE_PARAMETER_T
 mov rax,[r12+neboc_generics_constraints_overload_e_dispatch_VERTICAL_SOURCE_LENGTH_OFFSET]
 mov [rel g07v_sem+neboc_generics_constraints_overload_e_dispatch_SEM_SOURCE_END_OFFSET],rax
 lea rdi,[rel g07v_sem]
 call neboc_generic_semantic_analyze
 test eax,eax
 jnz .internal
 test qword [r12+neboc_generics_constraints_overload_e_dispatch_VERTICAL_FLAGS_OFFSET],NEBOC_VERTICAL_FLAG_CALL_PRESENT
 jz .declaration_only
 lea rdi,[rel g07v_api]
 mov ecx,neboc_generics_constraints_overload_e_dispatch_API_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov qword [rel g07v_api+neboc_generics_constraints_overload_e_dispatch_API_OPERATION_OFFSET],NEBOC_OP_GENERIC_CALL
 mov rax,[r12+NEBOC_VERTICAL_RECEIVER_TYPE_OFFSET]
 mov [rel g07v_api+neboc_generics_constraints_overload_e_dispatch_API_RECEIVER_TYPE_OFFSET],rax
 mov qword [rel g07v_api+NEBOC_API_CANDIDATE_COUNT_OFFSET],1
 mov rax,[r12+neboc_generics_constraints_overload_e_dispatch_VERTICAL_SOURCE_OFFSET]
 mov [rel g07v_api+neboc_generics_constraints_overload_e_dispatch_API_SUBJECT_PTR_OFFSET],rax
 mov rax,[r12+neboc_generics_constraints_overload_e_dispatch_VERTICAL_SOURCE_LENGTH_OFFSET]
 mov [rel g07v_api+neboc_generics_constraints_overload_e_dispatch_API_SUBJECT_LENGTH_OFFSET],rax
 lea rdi,[rel g07v_api]
 call neboc_generic_api_contract
 test eax,eax
 jnz .internal
 lea rdi,[rel g07v_sem]
 mov ecx,neboc_generics_constraints_overload_e_dispatch_SEM_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov qword [rel g07v_sem+neboc_generics_constraints_overload_e_dispatch_SEM_KIND_OFFSET],NEBOC_SEM_KIND_CALL
 mov qword [rel g07v_sem+NEBOC_SEM_DECLARATION_ID_OFFSET],7
 mov rax,[r12+NEBOC_VERTICAL_RECEIVER_TYPE_OFFSET]
 mov [rel g07v_sem+neboc_generics_constraints_overload_e_dispatch_SEM_RECEIVER_TYPE_OFFSET],rax
 mov [rel g07v_sem+NEBOC_SEM_BODY_RETURN_TYPE_OFFSET],rax
 mov rax,[r12+NEBOC_VERTICAL_CONCRETE_CANDIDATES_OFFSET]
 mov [rel g07v_sem+NEBOC_SEM_CONCRETE_CANDIDATES_OFFSET],rax
 mov rax,[r12+NEBOC_VERTICAL_GENERIC_CANDIDATES_OFFSET]
 mov [rel g07v_sem+NEBOC_SEM_GENERIC_CANDIDATES_OFFSET],rax
 mov qword [rel g07v_sem+NEBOC_SEM_INSTANCE_LIMIT_OFFSET],32
 mov rax,[r12+neboc_generics_constraints_overload_e_dispatch_VERTICAL_SOURCE_LENGTH_OFFSET]
 mov [rel g07v_sem+neboc_generics_constraints_overload_e_dispatch_SEM_SOURCE_END_OFFSET],rax
 lea rdi,[rel g07v_sem]
 call neboc_generic_semantic_analyze
 test eax,eax
 jnz .semantic_error
 mov rax,[rel g07v_sem+NEBOC_SEM_SELECTED_KIND_OFFSET]
 mov [r12+NEBOC_VERTICAL_SELECTED_OFFSET],rax
 mov rax,[rel g07v_sem+NEBOC_SEM_INSTANCE_KEY_OFFSET]
 mov [r12+NEBOC_VERTICAL_SEMANTIC_KEY_OFFSET],rax
 lea rdi,[rel g07v_ir]
 mov ecx,neboc_generics_constraints_overload_e_dispatch_IR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov qword [rel g07v_ir+NEBOC_IR_DECLARATION_ID_OFFSET],7
 mov rax,[r12+NEBOC_VERTICAL_RECEIVER_TYPE_OFFSET]
 mov [rel g07v_ir+NEBOC_IR_TYPE_ID_OFFSET],rax
 mov [rel g07v_ir+NEBOC_IR_RECEIVER_TYPE_OFFSET],rax
 mov [rel g07v_ir+NEBOC_IR_RETURN_TYPE_OFFSET],rax
 mov rax,[r12+NEBOC_VERTICAL_SEMANTIC_KEY_OFFSET]
 mov [rel g07v_ir+NEBOC_IR_SEMANTIC_KEY_OFFSET],rax
 mov qword [rel g07v_ir+NEBOC_IR_TARGET_ID_OFFSET],NEBOC_TARGET_X86_64_SYSV
 lea rdi,[rel g07v_ir]
 call neboc_generic_ir_lower
 test eax,eax
 jnz .ir_error
 mov rax,[rel g07v_ir+NEBOC_IR_SYMBOL_HASH_OFFSET]
 mov [r12+NEBOC_VERTICAL_SYMBOL_HASH_OFFSET],rax
 lea rdi,[rel g07v_native]
 mov ecx,neboc_generics_constraints_overload_e_dispatch_NATIVE_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,[r12+NEBOC_VERTICAL_RECEIVER_TYPE_OFFSET]
 mov [rel g07v_native+neboc_generics_constraints_overload_e_dispatch_NATIVE_TYPE_ID_OFFSET],rax
 mov qword [rel g07v_native+neboc_generics_constraints_overload_e_dispatch_NATIVE_TARGET_ID_OFFSET],NEBOC_TARGET_X86_64_SYSV
 mov rax,[rel g07v_ir+neboc_generics_constraints_overload_e_dispatch_IR_FLAGS_OFFSET]
 mov [rel g07v_native+NEBOC_NATIVE_IR_FLAGS_OFFSET],rax
 mov rax,[rel g07v_ir+neboc_generics_constraints_overload_e_dispatch_IR_ABI_CLASS_OFFSET]
 mov [rel g07v_native+NEBOC_NATIVE_IR_ABI_CLASS_OFFSET],rax
 lea rdi,[rel g07v_native]
 call neboc_generic_native_plan
 test eax,eax
 jnz .native_error
 mov rax,[rel g07v_native+NEBOC_NATIVE_HELPER_ID_OFFSET]
 mov [r12+NEBOC_VERTICAL_NATIVE_HELPER_OFFSET],rax
.declaration_only:
 or qword [r12+neboc_generics_constraints_overload_e_dispatch_VERTICAL_FLAGS_OFFSET],NEBOC_VERTICAL_REQUIRED_FLAGS
 xor eax,eax
 jmp .done
.semantic_error:
 mov rsi,[rel g07v_sem+neboc_generics_constraints_overload_e_dispatch_SEM_DIAGNOSTIC_OFFSET]
 jmp .contract_error
.ir_error:
 mov rsi,[rel g07v_ir+neboc_generics_constraints_overload_e_dispatch_IR_DIAGNOSTIC_OFFSET]
 jmp .contract_error
.native_error:
 mov rsi,[rel g07v_native+neboc_generics_constraints_overload_e_dispatch_NATIVE_DIAGNOSTIC_OFFSET]
.contract_error:
 mov rdi,r12
 mov rdx,[r12+NEBOC_VERTICAL_RECEIVER_TOKEN_OFFSET]
 call g07v_error
 jmp .done
.internal:
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 pop r12
 pop rbx
 ret

%undef call
NEBOC_ABI_FUNCTION neboc_generic_vertical_recognize
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 test r12,r12
 jz .invalid
 lea rdi,[r12+neboc_generics_constraints_overload_e_dispatch_VERTICAL_FOUND_OFFSET]
 mov ecx,15
 xor eax,eax
 rep stosq
 cmp qword [r12+neboc_generics_constraints_overload_e_dispatch_VERTICAL_TOKEN_COUNT_OFFSET],1
 jbe .not_owned
 mov rdi,r12
 xor esi,esi
 mov edx,NEBOC_TOKEN_KW_GENERIC
 call g07v_kind_is
 test eax,eax
 jnz .owned
 mov rdi,r12
 xor esi,esi
 lea rdx,[rel n_template]
 mov ecx,n_template_len
 call g07v_token_match
 test eax,eax
 jz .not_owned
 mov rdi,r12
 mov esi,neboc_generics_constraints_overload_e_dispatch_DIAG_ALIAS_FORBIDDEN
 xor edx,edx
 call g07v_error
 jmp .done
.owned:
 mov qword [r12+neboc_generics_constraints_overload_e_dispatch_VERTICAL_FOUND_OFFSET],1
 ; Count generic declarations and locate start.
 xor r13d,r13d
 xor r14d,r14d
 mov qword [rsp],-1
.scan:
 cmp r14,[r12+neboc_generics_constraints_overload_e_dispatch_VERTICAL_TOKEN_COUNT_OFFSET]
 jae .scan_done
 mov rdi,r12
 mov rsi,r14
 call g07v_token_ptr
 test rax,rax
 jz .scan_done
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_GENERIC
 jne .scan_start
 inc r13
.scan_start:
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_START
 jne .scan_next
 mov [rsp],r14
.scan_next:
 inc r14
 jmp .scan
.scan_done:
 mov [r12+NEBOC_VERTICAL_GENERIC_CANDIDATES_OFFSET],r13
 cmp r13,1
 jne .ambiguous
 ; generic < T : Scalar >
 mov rdi,r12
 mov esi,1
 mov edx,NEBOC_TOKEN_LESS
 call g07v_kind_is
 test eax,eax
 jz .expected
 mov rdi,r12
 mov esi,2
 mov edx,NEBOC_TOKEN_GREATER
 call g07v_kind_is
 test eax,eax
 jnz .expected
 mov rdi,r12
 mov esi,2
 lea rdx,[rel generic_vertical_n_t]
 mov ecx,n_t_len
 call g07v_token_match
 test eax,eax
 jz .alias
 mov rdi,r12
 mov esi,3
 mov edx,NEBOC_TOKEN_GREATER
 call g07v_kind_is
 test eax,eax
 jnz .bound_expected
 mov rdi,r12
 mov esi,3
 mov edx,NEBOC_TOKEN_RESERVED_COLON
 call g07v_kind_is
 test eax,eax
 jz .bound_expected
 mov rdi,r12
 mov esi,4
 lea rdx,[rel generics_constraints_overload_e_dispatch_n_scalar]
 mov ecx,generics_constraints_overload_e_dispatch_n_scalar_len
 call g07v_token_match
 test eax,eax
 jz .bound_unknown
 mov rdi,r12
 mov esi,5
 mov edx,NEBOC_TOKEN_COMMA
 call g07v_kind_is
 test eax,eax
 jnz .extra_parameter
 mov rdi,r12
 mov esi,5
 mov edx,NEBOC_TOKEN_GREATER
 call g07v_kind_is
 test eax,eax
 jz .arity
 mov rdi,r12
 mov esi,6
 mov edx,NEBOC_TOKEN_KW_STRUCT
 call g07v_kind_is
 test eax,eax
 jnz .generic_type
 mov rdi,r12
 mov esi,6
 mov edx,NEBOC_TOKEN_LPAREN
 call g07v_kind_is
 test eax,eax
 jz .generic_type
 mov rdi,r12
 mov esi,7
 lea rdx,[rel generic_vertical_n_t]
 mov ecx,n_t_len
 call g07v_token_match
 test eax,eax
 jz .receiver
 mov rdi,r12
 mov esi,9
 lea rdx,[rel generics_constraints_overload_e_dispatch_n_value]
 mov ecx,generics_constraints_overload_e_dispatch_n_value_len
 call g07v_token_match
 test eax,eax
 jz .receiver
 mov rdi,r12
 mov esi,11
 lea rdx,[rel n_identity]
 mov ecx,n_identity_len
 call g07v_token_match
 test eax,eax
 jz .alias
 mov rdi,r12
 mov esi,13
 mov edx,NEBOC_TOKEN_RPAREN
 call g07v_kind_is
 test eax,eax
 jz .positionals
 mov rdi,r12
 mov esi,15
 lea rdx,[rel generics_constraints_overload_e_dispatch_n_value]
 mov ecx,generics_constraints_overload_e_dispatch_n_value_len
 call g07v_token_match
 test eax,eax
 jz .return_type
 mov r15,[rsp]
 cmp r15,-1
 je .no_match
 ; A top-level concrete identity between the generic declaration and start wins.
 cmp r15,20
 jbe .call
 mov rdi,r12
 mov esi,20
 mov edx,NEBOC_TOKEN_LPAREN
 call g07v_kind_is
 test eax,eax
 jz .call
 mov qword [r12+NEBOC_VERTICAL_CONCRETE_CANDIDATES_OFFSET],1
 or qword [r12+neboc_generics_constraints_overload_e_dispatch_VERTICAL_FLAGS_OFFSET],NEBOC_VERTICAL_FLAG_CONCRETE_PRESENT
.call:
 lea rbx,[r15+4]
 mov rdi,r12
 mov rsi,rbx
 mov edx,NEBOC_TOKEN_RBRACE
 call g07v_kind_is
 test eax,eax
 jnz .contracts
 or qword [r12+neboc_generics_constraints_overload_e_dispatch_VERTICAL_FLAGS_OFFSET],NEBOC_VERTICAL_FLAG_CALL_PRESENT
 mov [r12+NEBOC_VERTICAL_RECEIVER_TOKEN_OFFSET],rbx
 mov rdi,r12
 mov rsi,rbx
 call g07v_token_ptr
 test rax,rax
 jz .no_match
 mov rcx,[rax+NEBOC_TOKEN_KIND_OFFSET]
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov [r12+NEBOC_VERTICAL_RECEIVER_DATA_OFFSET],rdx
 cmp rcx,NEBOC_TOKEN_INTEGER
 je .type_int
 cmp rcx,NEBOC_TOKEN_FLOAT
 je .type_float
 cmp rcx,NEBOC_TOKEN_CHAR
 je .type_char
 cmp rcx,NEBOC_TOKEN_KW_TRUE
 je .type_true
 cmp rcx,NEBOC_TOKEN_KW_FALSE
 je .type_false
 cmp rcx,NEBOC_TOKEN_TEXT
 je .bound
 jmp .no_match
.type_int: mov qword [r12+NEBOC_VERTICAL_RECEIVER_TYPE_OFFSET],neboc_generics_constraints_overload_e_dispatch_TYPE_INT
 jmp .method
.type_char: mov qword [r12+NEBOC_VERTICAL_RECEIVER_TYPE_OFFSET],neboc_generics_constraints_overload_e_dispatch_TYPE_CHAR
 jmp .method
.type_true:
 mov qword [r12+NEBOC_VERTICAL_RECEIVER_TYPE_OFFSET],neboc_generics_constraints_overload_e_dispatch_TYPE_BOOL
 mov qword [r12+NEBOC_VERTICAL_RECEIVER_DATA_OFFSET],1
 jmp .method
.type_false:
 mov qword [r12+NEBOC_VERTICAL_RECEIVER_TYPE_OFFSET],neboc_generics_constraints_overload_e_dispatch_TYPE_BOOL
 mov qword [r12+NEBOC_VERTICAL_RECEIVER_DATA_OFFSET],0
 jmp .method
.type_float:
 mov qword [r12+NEBOC_VERTICAL_RECEIVER_TYPE_OFFSET],neboc_generics_constraints_overload_e_dispatch_TYPE_FLOAT
 or qword [r12+neboc_generics_constraints_overload_e_dispatch_VERTICAL_FLAGS_OFFSET],NEBOC_VERTICAL_FLAG_FLOAT_RECEIVER
 lea rdi,[rel g07v_float]
 mov ecx,NEBOC_FLOAT_LOWERING_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov rdi,r12
 mov rsi,rbx
 call g07v_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 mov rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 sub rdx,rcx
 add rcx,[r12+neboc_generics_constraints_overload_e_dispatch_VERTICAL_SOURCE_OFFSET]
 mov [rel g07v_float+NEBOC_FLOAT_LOWERING_REQUEST_SOURCE_OFFSET],rcx
 mov [rel g07v_float+NEBOC_FLOAT_LOWERING_REQUEST_LENGTH_OFFSET],rdx
 lea rax,[rel g07v_float_bits]
 mov [rel g07v_float+NEBOC_FLOAT_LOWERING_REQUEST_OUT_BITS_OFFSET],rax
 lea rdi,[rel g07v_float]
 call neboc_foundation_float_materialize_literal
 test eax,eax
 jnz .internal
 mov rax,[rel g07v_float_bits]
 mov [r12+NEBOC_VERTICAL_RECEIVER_DATA_OFFSET],rax
.method:
 lea r13,[rbx+2]
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_identity]
 mov ecx,n_identity_len
 call g07v_token_match
 test eax,eax
 jz .no_match
 lea r13,[rbx+3]
 mov rdi,r12
 mov rsi,r13
 mov edx,NEBOC_TOKEN_LESS
 call g07v_kind_is
 test eax,eax
 jnz .explicit
.contracts:
 mov rdi,r12
 call g07v_contract_chain
 jmp .done
.extra_parameter:
 mov rdi,r12
 mov esi,6
 lea rdx,[rel n_shared]
 mov ecx,n_shared_len
 call g07v_token_match
 test eax,eax
 jnz .sharing
 mov rdi,r12
 mov esi,6
 lea rdx,[rel generic_vertical_n_t]
 mov ecx,n_t_len
 call g07v_token_match
 test eax,eax
 jnz .duplicate
 jmp .arity
.expected: mov esi,NEBOC_DIAG_EXPECTED_TYPE_PARAMETER
 mov edx,2
 jmp .error
.arity: mov esi,NEBOC_DIAG_TYPE_PARAMETER_ARITY
 mov edx,5
 jmp .error
.duplicate: mov esi,NEBOC_DIAG_DUPLICATE_TYPE_PARAMETER
 mov edx,6
 jmp .error
.bound_expected: mov esi,NEBOC_DIAG_BOUND_EXPECTED
 mov edx,3
 jmp .error
.bound_unknown: mov esi,NEBOC_DIAG_BOUND_UNKNOWN
 mov edx,4
 jmp .error
.bound: mov esi,NEBOC_DIAG_BOUND_NOT_SATISFIED
 mov rdx,rbx
 jmp .error
.receiver: mov esi,NEBOC_DIAG_RECEIVER_TYPE_PARAMETER_REQUIRED
 mov edx,7
 jmp .error
.return_type: mov esi,NEBOC_DIAG_RETURN_TYPE_PARAMETER_REQUIRED
 mov edx,15
 jmp .error
.positionals: mov esi,NEBOC_DIAG_POSITIONAL_PARAMETERS_DEFERRED
 mov edx,13
 jmp .error
.explicit: mov esi,NEBOC_DIAG_EXPLICIT_TYPE_ARGUMENTS_DEFERRED
 mov rdx,r13
 jmp .error
.generic_type: mov esi,NEBOC_DIAG_GENERIC_TYPE_DEFERRED
 mov edx,6
 jmp .error
.alias: mov esi,neboc_generics_constraints_overload_e_dispatch_DIAG_ALIAS_FORBIDDEN
 mov edx,2
 jmp .error
.no_match: mov esi,NEBOC_DIAG_OVERLOAD_NO_MATCH
 mov rdx,rbx
 jmp .error
.ambiguous: mov esi,NEBOC_DIAG_OVERLOAD_AMBIGUOUS
 mov edx,0
 jmp .error
.sharing: mov esi,NEBOC_DIAG_CODE_SHARING_DEFERRED
 mov edx,6
.error:
 mov rdi,r12
 call g07v_error
 jmp .done
.not_owned: xor eax,eax
 jmp .done
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.internal: mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
