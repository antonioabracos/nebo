; Nebo Assembly — BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-PF003 isolated binding semantic model
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/binding_definite_assignment_contract.inc"
%include "compiler/semantic/bindings/binding_semantic.inc"

section .text
NEBOC_ABI_FUNCTION neboc_binding_semantic_analyze
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 test r12,r12
 jz .invalid_argument
 mov r13,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SYNTAX_REQUEST_OFFSET]
 test r13,r13
 jz .invalid_argument
 lea rdi,[r12+NEBOC_SEM_RESULT_OPERATION_OFFSET]
 mov ecx,(neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_REQUEST_SIZE-NEBOC_SEM_RESULT_OPERATION_OFFSET)/8
 xor eax,eax
 rep stosq

 ; Syntax diagnostics are first-class and propagated before success-only invariants.
 mov rax,[r13+NEBOC_BIND_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .propagate_diagnostic

 cmp qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SYMBOL_ID_OFFSET],0
 je .symbol_invariant
 mov rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_INPUT_FLAGS_OFFSET]
 test rax,NEBOC_SEM_INPUT_VALID_SYMBOL
 jz .flag_invariant
 test rax,~neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_INPUT_ALLOWED_MASK
 jnz .flag_invariant
 test rax,NEBOC_SEM_INPUT_IMMUTABLE
 jz .flag_invariant
 test rax,NEBOC_SEM_INPUT_SAME_SCOPE
 jz .scope_invariant
 mov rax,[r12+NEBOC_SEM_SCOPE_ID_OFFSET]
 cmp rax,[r12+NEBOC_SEM_DECL_SCOPE_ID_OFFSET]
 jne .scope_invariant
 mov r14,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_NODE_START_OFFSET]
 mov r15,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_NODE_END_OFFSET]
 cmp r15,r14
 jbe .span_invariant
 mov rbx,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SUBJECT_START_OFFSET]
 cmp rbx,r14
 jb .span_invariant
 mov rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SUBJECT_END_OFFSET]
 cmp rax,rbx
 jbe .span_invariant
 cmp rax,r15
 ja .span_invariant
 mov rax,[r12+NEBOC_SEM_DECL_END_OFFSET]
 cmp rax,[r12+NEBOC_SEM_DECL_START_OFFSET]
 jbe .span_invariant

 mov rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_OPERATION_OFFSET]
 cmp rax,NEBOC_SEM_OPERATION_DIRECT_BINDING
 je .direct
 cmp rax,NEBOC_SEM_OPERATION_TYPED_DECLARATION
 je .typed
 cmp rax,NEBOC_SEM_OPERATION_ONE_SHOT_INITIALIZATION
 je .initialize
 cmp rax,NEBOC_SEM_OPERATION_READ
 je .read
 cmp rax,NEBOC_SEM_OPERATION_DEFINITE_READ
 je .definite_read
 cmp rax,NEBOC_SEM_OPERATION_FLOW_MERGE
 je .flow_merge
 jmp .contract_invariant

.direct:
 cmp qword [r13+NEBOC_BIND_OPERATION_OFFSET],NEBOC_BIND_OP_DIRECT_BINDING
 jne .contract_invariant
 cmp qword [r13+NEBOC_BIND_AST_FORM_OFFSET],NEBOC_BIND_AST_BINDING_TERMINAL
 jne .contract_invariant
 cmp qword [r12+NEBOC_SEM_CURRENT_STATE_OFFSET],NEBOC_BIND_STATE_ABSENT
 jne .state_invariant
 mov rax,[r13+NEBOC_BIND_VALUE_TYPE_OFFSET]
 test rax,rax
 jz .type_invariant
 cmp rax,NEBOC_BIND_TYPE_VOID
 je .type_invariant
 cmp rax,[r12+NEBOC_SEM_SYMBOL_TYPE_OFFSET]
 jne .type_invariant
 mov qword [r12+NEBOC_SEM_RESULT_OPERATION_OFFSET],NEBOC_SEM_OPERATION_DIRECT_BINDING
 mov qword [r12+NEBOC_SEM_RESULT_STATE_OFFSET],NEBOC_BIND_STATE_INITIALIZED
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_RESULT_TYPE_OFFSET],rax
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEMANTIC_KIND_OFFSET],NEBOC_SEM_KIND_BIND
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_EFFECT_FLAGS_OFFSET],NEBOC_SEM_EFFECTS_DEFINITE
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_DIRECT_BINDING
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_SYMBOL_BIND_VALUE
 mov qword [r12+NEBOC_SEM_SYMBOL_FLAGS_OFFSET],NEBOC_SEM_SYMBOL_IMMUTABLE|NEBOC_SEM_SYMBOL_DECLARED|NEBOC_SEM_SYMBOL_INITIALIZED|NEBOC_SEM_SYMBOL_DIRECT|NEBOC_SEM_SYMBOL_DEFINITE
 jmp .success

.typed:
 cmp qword [r13+NEBOC_BIND_OPERATION_OFFSET],NEBOC_BIND_OP_TYPED_DECLARATION
 jne .contract_invariant
 cmp qword [r13+NEBOC_BIND_AST_FORM_OFFSET],NEBOC_BIND_AST_TYPED_DECLARATION
 jne .contract_invariant
 cmp qword [r12+NEBOC_SEM_CURRENT_STATE_OFFSET],NEBOC_BIND_STATE_ABSENT
 jne .state_invariant
 mov rax,[r13+NEBOC_BIND_DECLARED_TYPE_OFFSET]
 test rax,rax
 jz .type_invariant
 cmp rax,NEBOC_BIND_TYPE_VOID
 je .type_invariant
 cmp rax,[r12+NEBOC_SEM_SYMBOL_TYPE_OFFSET]
 jne .type_invariant
 cmp qword [r13+NEBOC_BIND_VALUE_TYPE_OFFSET],0
 jne .type_invariant
 mov qword [r12+NEBOC_SEM_RESULT_OPERATION_OFFSET],NEBOC_SEM_OPERATION_TYPED_DECLARATION
 mov qword [r12+NEBOC_SEM_RESULT_STATE_OFFSET],NEBOC_BIND_STATE_DECLARED_UNINITIALIZED
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_RESULT_TYPE_OFFSET],rax
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEMANTIC_KIND_OFFSET],NEBOC_SEM_KIND_DECLARE
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_EFFECT_FLAGS_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_EFFECTS_BASE
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_TYPED_DECLARATION
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_SYMBOL_DECLARE
 mov qword [r12+NEBOC_SEM_SYMBOL_FLAGS_OFFSET],NEBOC_SEM_SYMBOL_IMMUTABLE|NEBOC_SEM_SYMBOL_DECLARED|NEBOC_SEM_SYMBOL_EXPLICIT_TYPE
 jmp .success

.initialize:
 cmp qword [r13+NEBOC_BIND_OPERATION_OFFSET],NEBOC_BIND_OP_ONE_SHOT_INITIALIZATION
 jne .contract_invariant
 cmp qword [r13+NEBOC_BIND_AST_FORM_OFFSET],NEBOC_BIND_AST_ONE_SHOT_INITIALIZATION
 jne .contract_invariant
 cmp qword [r12+NEBOC_SEM_CURRENT_STATE_OFFSET],NEBOC_BIND_STATE_DECLARED_UNINITIALIZED
 jne .state_invariant
 mov rax,[r13+NEBOC_BIND_DECLARED_TYPE_OFFSET]
 cmp rax,[r13+NEBOC_BIND_VALUE_TYPE_OFFSET]
 jne .type_invariant
 cmp rax,[r12+NEBOC_SEM_SYMBOL_TYPE_OFFSET]
 jne .type_invariant
 test qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_INPUT_FLAGS_OFFSET],NEBOC_SEM_INPUT_TYPE_COMPATIBLE
 jz .type_invariant
 mov rdx,[r12+NEBOC_SEM_INIT_END_OFFSET]
 cmp rdx,[r12+NEBOC_SEM_INIT_START_OFFSET]
 jbe .span_invariant
 mov qword [r12+NEBOC_SEM_RESULT_OPERATION_OFFSET],NEBOC_SEM_OPERATION_ONE_SHOT_INITIALIZATION
 mov qword [r12+NEBOC_SEM_RESULT_STATE_OFFSET],NEBOC_BIND_STATE_INITIALIZED
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_RESULT_TYPE_OFFSET],rax
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEMANTIC_KIND_OFFSET],NEBOC_SEM_KIND_INITIALIZE
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_EFFECT_FLAGS_OFFSET],NEBOC_SEM_EFFECTS_DEFINITE
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_ONE_SHOT_INITIALIZATION
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_SYMBOL_INITIALIZE_ONCE
 mov qword [r12+NEBOC_SEM_SYMBOL_FLAGS_OFFSET],NEBOC_SEM_SYMBOL_IMMUTABLE|NEBOC_SEM_SYMBOL_DECLARED|NEBOC_SEM_SYMBOL_INITIALIZED|NEBOC_SEM_SYMBOL_EXPLICIT_TYPE|NEBOC_SEM_SYMBOL_ONE_SHOT|NEBOC_SEM_SYMBOL_DEFINITE
 jmp .success

.read:
 cmp qword [r13+NEBOC_BIND_OPERATION_OFFSET],NEBOC_BIND_OP_READ
 jne .contract_invariant
 cmp qword [r12+NEBOC_SEM_CURRENT_STATE_OFFSET],NEBOC_BIND_STATE_INITIALIZED
 jne .state_invariant
 jmp .read_common
.definite_read:
 cmp qword [r13+NEBOC_BIND_OPERATION_OFFSET],NEBOC_BIND_OP_DEFINITE_READ
 jne .contract_invariant
 cmp qword [r12+NEBOC_SEM_CURRENT_STATE_OFFSET],NEBOC_BIND_STATE_INITIALIZED
 jne .state_invariant
 test qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_INPUT_FLAGS_OFFSET],NEBOC_SEM_INPUT_ALL_PATHS_INITIALIZED
 jz .not_definite
.read_common:
 cmp qword [r13+NEBOC_BIND_AST_FORM_OFFSET],NEBOC_BIND_AST_IDENTIFIER_READ
 jne .contract_invariant
 mov rax,[r12+NEBOC_SEM_SYMBOL_TYPE_OFFSET]
 test rax,rax
 jz .type_invariant
 cmp rax,NEBOC_BIND_TYPE_VOID
 je .type_invariant
 mov rdx,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_OPERATION_OFFSET]
 mov [r12+NEBOC_SEM_RESULT_OPERATION_OFFSET],rdx
 mov qword [r12+NEBOC_SEM_RESULT_STATE_OFFSET],NEBOC_BIND_STATE_INITIALIZED
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_RESULT_TYPE_OFFSET],rax
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEMANTIC_KIND_OFFSET],NEBOC_SEM_KIND_READ
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_EFFECT_FLAGS_OFFSET],NEBOC_SEM_EFFECTS_DEFINITE
 cmp rdx,NEBOC_SEM_OPERATION_DEFINITE_READ
 je .def_hir
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_IDENTIFIER_READ
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_SYMBOL_READ
 jmp .read_flags
.def_hir:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_DEFINITE_READ
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_SYMBOL_DEFINITE_READ
.read_flags:
 mov qword [r12+NEBOC_SEM_SYMBOL_FLAGS_OFFSET],NEBOC_SEM_SYMBOL_IMMUTABLE|NEBOC_SEM_SYMBOL_DECLARED|NEBOC_SEM_SYMBOL_INITIALIZED|NEBOC_SEM_SYMBOL_DEFINITE
 jmp .success

.flow_merge:
 cmp qword [r13+NEBOC_BIND_OPERATION_OFFSET],NEBOC_BIND_OP_DEFINITE_READ
 jne .contract_invariant
 mov rax,[r12+NEBOC_SEM_TRUE_STATE_OFFSET]
 cmp rax,NEBOC_BIND_STATE_INITIALIZED
 jne .not_definite
 mov rax,[r12+NEBOC_SEM_FALSE_STATE_OFFSET]
 cmp rax,NEBOC_BIND_STATE_INITIALIZED
 jne .not_definite
 test qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_INPUT_FLAGS_OFFSET],NEBOC_SEM_INPUT_ALL_PATHS_INITIALIZED
 jz .not_definite
 mov rax,[r12+NEBOC_SEM_SYMBOL_TYPE_OFFSET]
 test rax,rax
 jz .type_invariant
 mov qword [r12+NEBOC_SEM_RESULT_OPERATION_OFFSET],NEBOC_SEM_OPERATION_FLOW_MERGE
 mov qword [r12+NEBOC_SEM_RESULT_STATE_OFFSET],NEBOC_BIND_STATE_INITIALIZED
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_RESULT_TYPE_OFFSET],rax
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEMANTIC_KIND_OFFSET],NEBOC_SEM_KIND_FLOW
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_EFFECT_FLAGS_OFFSET],NEBOC_SEM_EFFECTS_DEFINITE
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_FLOW_STATE_MERGE
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_FLOW_STATE_INTERSECTION
 mov qword [r12+NEBOC_SEM_SYMBOL_FLAGS_OFFSET],NEBOC_SEM_SYMBOL_IMMUTABLE|NEBOC_SEM_SYMBOL_DECLARED|NEBOC_SEM_SYMBOL_INITIALIZED|NEBOC_SEM_SYMBOL_DEFINITE
 mov qword [r12+NEBOC_SEM_MERGE_MASK_OFFSET],NEBOC_SEM_MERGE_ALL_INITIALIZED
 jmp .success

.not_definite:
 mov qword [r12+NEBOC_SEM_SOURCE_DIAGNOSTIC_OFFSET],NEBOC_BIND_DIAG_NOT_DEFINITELY_INITIALIZED
 mov rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SUBJECT_START_OFFSET]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_START_OFFSET],rax
 mov rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SUBJECT_END_OFFSET]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_END_OFFSET],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done

.success:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_RUNTIME_METADATA_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_RUNTIME_METADATA_NONE
 mov rax,neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_HASH_OFFSET_BASIS
 mov r10,neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_HASH_PRIME
 xor rax,[r12+NEBOC_SEM_RESULT_OPERATION_OFFSET]
 imul rax,r10
 xor rax,[r12+NEBOC_SEM_RESULT_STATE_OFFSET]
 imul rax,r10
 xor rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_RESULT_TYPE_OFFSET]
 imul rax,r10
 xor rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_HIR_KIND_OFFSET]
 imul rax,r10
 xor rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_LIR_KIND_OFFSET]
 imul rax,r10
 xor rax,[r12+NEBOC_SEM_SYMBOL_FLAGS_OFFSET]
 imul rax,r10
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SEMANTIC_HASH_OFFSET],rax
 xor rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SOURCE_ID_OFFSET]
 imul rax,r10
 xor rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_NODE_START_OFFSET]
 imul rax,r10
 xor rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SUBJECT_START_OFFSET]
 imul rax,r10
 xor rax,[r13+NEBOC_BIND_HASH_OFFSET]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_PROVENANCE_HASH_OFFSET],rax
 xor eax,eax
 jmp .done

.propagate_diagnostic:
 mov [r12+NEBOC_SEM_SOURCE_DIAGNOSTIC_OFFSET],rax
 mov rdx,[r13+NEBOC_BIND_ERROR_START_OFFSET]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_START_OFFSET],rdx
 mov rdx,[r13+NEBOC_BIND_ERROR_END_OFFSET]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_END_OFFSET],rdx
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.contract_invariant: mov edx,neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_CONTRACT_INVALID
 jmp .internal_error
.symbol_invariant: mov edx,NEBOC_SEM_ERROR_SYMBOL_INVARIANT
 jmp .internal_error
.state_invariant: mov edx,NEBOC_SEM_ERROR_STATE_TRANSITION
 jmp .internal_error
.type_invariant: mov edx,neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_TYPE_INVARIANT
 jmp .internal_error
.scope_invariant: mov edx,NEBOC_SEM_ERROR_SCOPE_INVARIANT
 jmp .internal_error
.flag_invariant: mov edx,neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_FLAG_INVARIANT
 jmp .internal_error
.span_invariant: mov edx,neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_SPAN_INVARIANT
 jmp .internal_error
.flow_invariant: mov edx,NEBOC_SEM_ERROR_FLOW_INVARIANT
.internal_error:
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_CODE_OFFSET],rdx
 mov rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SUBJECT_START_OFFSET]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_START_OFFSET],rax
 mov rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SUBJECT_END_OFFSET]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_END_OFFSET],rax
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
