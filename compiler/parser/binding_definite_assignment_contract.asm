; Nebo Assembly — BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-PF002 isolated binding syntax/API/diagnostic contract
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/binding_definite_assignment_contract.inc"

section .text

binding_hash:
 mov r8,[rdi+NEBOC_BIND_NAME_PTR_OFFSET]
 mov r9,[rdi+NEBOC_BIND_NAME_LENGTH_OFFSET]
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
 xor rax,[rdi+NEBOC_BIND_OPERATION_OFFSET]
 imul rax,r10
 xor rax,[rdi+NEBOC_BIND_DECLARED_TYPE_OFFSET]
 imul rax,r10
 xor rax,[rdi+NEBOC_BIND_VALUE_TYPE_OFFSET]
 imul rax,r10
 xor rax,[rdi+NEBOC_BIND_SYMBOL_STATE_OFFSET]
 imul rax,r10
 xor rax,[rdi+NEBOC_BIND_SCOPE_RELATION_OFFSET]
 imul rax,r10
 xor rax,[rdi+NEBOC_BIND_AST_FORM_OFFSET]
 imul rax,r10
 xor rax,[rdi+NEBOC_BIND_RESULT_STATE_OFFSET]
 imul rax,r10
 xor rax,[rdi+NEBOC_BIND_RESULT_FLAGS_OFFSET]
 imul rax,r10
 xor rax,[rdi+NEBOC_BIND_DIAGNOSTIC_OFFSET]
 imul rax,r10
 mov [rdi+NEBOC_BIND_HASH_OFFSET],rax
 ret

NEBOC_ABI_FUNCTION neboc_binding_contract
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 test r12,r12
 jz .invalid_argument
 mov r13,[r12+NEBOC_BIND_NAME_PTR_OFFSET]
 mov r14,[r12+NEBOC_BIND_NAME_LENGTH_OFFSET]
 lea rdi,[r12+NEBOC_BIND_AST_FORM_OFFSET]
 mov ecx,(NEBOC_BIND_REQUEST_SIZE-NEBOC_BIND_AST_FORM_OFFSET)/8
 xor eax,eax
 rep stosq
 test r13,r13
 jz .invalid_argument
 test r14,r14
 jz .invalid_name
 mov rax,[r12+NEBOC_BIND_INPUT_FLAGS_OFFSET]
 test rax,NEBOC_BIND_INPUT_VALID_NAME
 jz .invalid_name
 test rax,NEBOC_BIND_INPUT_RESERVED_NAME
 jnz .reserved_name
 mov rax,[r12+NEBOC_BIND_OPERATION_OFFSET]
 cmp rax,NEBOC_BIND_OP_DIRECT_BINDING
 je .direct
 cmp rax,NEBOC_BIND_OP_TYPED_DECLARATION
 je .typed
 cmp rax,NEBOC_BIND_OP_ONE_SHOT_INITIALIZATION
 je .initialize
 cmp rax,NEBOC_BIND_OP_READ
 je .read
 cmp rax,NEBOC_BIND_OP_DEFINITE_READ
 je .definite_read
 cmp rax,NEBOC_BIND_OP_ASSIGNMENT_SYNTAX
 je .assignment
 cmp rax,NEBOC_BIND_OP_CONST_DECLARATION
 je .const
 cmp rax,NEBOC_BIND_OP_MUTABLE_DECLARATION
 je .mutable
 cmp rax,NEBOC_BIND_OP_NAMED_ARGUMENT
 je .named_argument
 jmp .invalid_argument

.direct:
 cmp qword [r12+NEBOC_BIND_SCOPE_RELATION_OFFSET],NEBOC_BIND_SCOPE_PARENT
 je .shadowing
 cmp qword [r12+NEBOC_BIND_SYMBOL_STATE_OFFSET],NEBOC_BIND_STATE_ABSENT
 jne .duplicate
 cmp qword [r12+NEBOC_BIND_VALUE_TYPE_OFFSET],NEBOC_BIND_TYPE_VOID
 je .void_forbidden
 mov qword [r12+NEBOC_BIND_AST_FORM_OFFSET],NEBOC_BIND_AST_BINDING_TERMINAL
 mov qword [r12+NEBOC_BIND_RESULT_STATE_OFFSET],NEBOC_BIND_STATE_INITIALIZED
 mov qword [r12+NEBOC_BIND_RESULT_FLAGS_OFFSET],NEBOC_BIND_FLAG_SYNTAX_ONLY|NEBOC_BIND_FLAG_IMMUTABLE|NEBOC_BIND_FLAG_DIRECT|NEBOC_BIND_FLAG_DEFINITE
 jmp .success
.typed:
 cmp qword [r12+NEBOC_BIND_SCOPE_RELATION_OFFSET],NEBOC_BIND_SCOPE_PARENT
 je .shadowing
 cmp qword [r12+NEBOC_BIND_SYMBOL_STATE_OFFSET],NEBOC_BIND_STATE_ABSENT
 jne .duplicate
 cmp qword [r12+NEBOC_BIND_DECLARED_TYPE_OFFSET],NEBOC_BIND_TYPE_VOID
 je .void_forbidden
 mov qword [r12+NEBOC_BIND_AST_FORM_OFFSET],NEBOC_BIND_AST_TYPED_DECLARATION
 mov qword [r12+NEBOC_BIND_RESULT_STATE_OFFSET],NEBOC_BIND_STATE_DECLARED_UNINITIALIZED
 mov qword [r12+NEBOC_BIND_RESULT_FLAGS_OFFSET],NEBOC_BIND_FLAG_SYNTAX_ONLY|NEBOC_BIND_FLAG_IMMUTABLE|NEBOC_BIND_FLAG_EXPLICIT_TYPE
 jmp .success
.initialize:
 cmp qword [r12+NEBOC_BIND_SYMBOL_STATE_OFFSET],NEBOC_BIND_STATE_ABSENT
 je .undefined
 cmp qword [r12+NEBOC_BIND_SYMBOL_STATE_OFFSET],NEBOC_BIND_STATE_INITIALIZED
 je .already_initialized
 mov rax,[r12+NEBOC_BIND_DECLARED_TYPE_OFFSET]
 cmp rax,[r12+NEBOC_BIND_VALUE_TYPE_OFFSET]
 jne .type_mismatch
 mov qword [r12+NEBOC_BIND_AST_FORM_OFFSET],NEBOC_BIND_AST_ONE_SHOT_INITIALIZATION
 mov qword [r12+NEBOC_BIND_RESULT_STATE_OFFSET],NEBOC_BIND_STATE_INITIALIZED
 mov qword [r12+NEBOC_BIND_RESULT_FLAGS_OFFSET],NEBOC_BIND_FLAG_SYNTAX_ONLY|NEBOC_BIND_FLAG_IMMUTABLE|NEBOC_BIND_FLAG_ONE_SHOT|NEBOC_BIND_FLAG_DEFINITE
 jmp .success
.read:
 cmp qword [r12+NEBOC_BIND_SYMBOL_STATE_OFFSET],NEBOC_BIND_STATE_ABSENT
 je .undefined
 cmp qword [r12+NEBOC_BIND_SYMBOL_STATE_OFFSET],NEBOC_BIND_STATE_DECLARED_UNINITIALIZED
 je .use_before
 mov qword [r12+NEBOC_BIND_AST_FORM_OFFSET],NEBOC_BIND_AST_IDENTIFIER_READ
 mov qword [r12+NEBOC_BIND_RESULT_STATE_OFFSET],NEBOC_BIND_STATE_INITIALIZED
 mov qword [r12+NEBOC_BIND_RESULT_FLAGS_OFFSET],NEBOC_BIND_FLAG_SYNTAX_ONLY|NEBOC_BIND_FLAG_IMMUTABLE|NEBOC_BIND_FLAG_DEFINITE
 jmp .success
.definite_read:
 cmp qword [r12+NEBOC_BIND_SYMBOL_STATE_OFFSET],NEBOC_BIND_STATE_ABSENT
 je .undefined
 mov rax,[r12+NEBOC_BIND_INPUT_FLAGS_OFFSET]
 test rax,NEBOC_BIND_INPUT_ALL_PATHS_INITIALIZED
 jz .not_definite
 cmp qword [r12+NEBOC_BIND_SYMBOL_STATE_OFFSET],NEBOC_BIND_STATE_INITIALIZED
 jne .not_definite
 mov qword [r12+NEBOC_BIND_AST_FORM_OFFSET],NEBOC_BIND_AST_IDENTIFIER_READ
 mov qword [r12+NEBOC_BIND_RESULT_STATE_OFFSET],NEBOC_BIND_STATE_INITIALIZED
 mov qword [r12+NEBOC_BIND_RESULT_FLAGS_OFFSET],NEBOC_BIND_FLAG_SYNTAX_ONLY|NEBOC_BIND_FLAG_IMMUTABLE|NEBOC_BIND_FLAG_DEFINITE
 jmp .success
.assignment: mov eax,NEBOC_BIND_DIAG_ASSIGNMENT_SYNTAX_UNAVAILABLE
 jmp .diagnostic
.const: mov eax,NEBOC_BIND_DIAG_CONST_DECLARATION_DEFERRED
 jmp .diagnostic
.mutable: mov eax,NEBOC_BIND_DIAG_MUTABLE_DECLARATION_DEFERRED
 jmp .diagnostic
.named_argument: mov eax,NEBOC_BIND_DIAG_NAMED_ARGUMENTS_DEFERRED
 jmp .diagnostic
.undefined: mov eax,NEBOC_BIND_DIAG_UNDEFINED_NAME
 jmp .diagnostic
.use_before: mov eax,NEBOC_BIND_DIAG_USE_BEFORE_INITIALIZATION
 jmp .diagnostic
.duplicate: mov eax,NEBOC_BIND_DIAG_DUPLICATE_DECLARATION
 jmp .diagnostic
.already_initialized: mov eax,NEBOC_BIND_DIAG_ALREADY_INITIALIZED
 jmp .diagnostic
.shadowing: mov eax,NEBOC_BIND_DIAG_SHADOWING_FORBIDDEN
 jmp .diagnostic
.reserved_name: mov eax,NEBOC_BIND_DIAG_RESERVED_NAME
 jmp .diagnostic
.void_forbidden: mov eax,NEBOC_BIND_DIAG_VOID_FORBIDDEN
 jmp .diagnostic
.type_mismatch: mov eax,NEBOC_BIND_DIAG_TYPE_MISMATCH
 jmp .diagnostic
.not_definite: mov eax,NEBOC_BIND_DIAG_NOT_DEFINITELY_INITIALIZED
 jmp .diagnostic
.invalid_name: mov eax,NEBOC_BIND_DIAG_INVALID_NAME
.diagnostic:
 mov [r12+NEBOC_BIND_DIAGNOSTIC_OFFSET],rax
 mov rdx,[r12+NEBOC_BIND_ABSOLUTE_START_OFFSET]
 mov [r12+NEBOC_BIND_ERROR_START_OFFSET],rdx
 add rdx,[r12+NEBOC_BIND_NAME_LENGTH_OFFSET]
 mov [r12+NEBOC_BIND_ERROR_END_OFFSET],rdx
 mov rdi,r12
 call binding_hash
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.success:
 mov rdi,r12
 call binding_hash
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
