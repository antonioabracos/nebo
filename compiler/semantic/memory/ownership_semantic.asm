; Nebo Assembly — MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-PF003 authenticated ownership/lifetime semantic envelope
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/memory/ownership_semantic.inc"

section .text

; neboc_ownership_semantic_analyze(envelope*) -> StatusCode
; Authenticates the complete PF002 descriptor and PF001 state, binds their
; identities, and derives one transition request without mutating the state.
NEBOC_ABI_FUNCTION neboc_ownership_semantic_analyze
    test rdi, rdi
    jz .invalid_argument
    test rdi, neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_ALIGNMENT - 1
    jnz .invalid_argument
    cld
    push r12
    push r13
    mov r12, rdi
    lea rdi, [r12 + NEBOC_SEMANTIC_OPERATION_OFFSET]
    mov ecx, NEBOC_SEMANTIC_OUTPUT_QWORDS
    xor eax, eax
    rep stosq

    ; PF002 structural and shape authentication.
    cmp qword [r12 + NEBOC_SYNTAX_RESOURCE_ID_OFFSET], 0
    je .type_failure
    cmp qword [r12 + NEBOC_SYNTAX_OWNER_TOKEN_OFFSET], 0
    je .type_failure
    cmp qword [r12 + NEBOC_SYNTAX_OWNER_REGION_OFFSET], 0
    je .type_failure
    cmp qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_SYNTAX_FLAGS_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_SYNTAX_FLAG_CANONICAL
    jne .type_failure
    mov rax, [r12 + neboc_memoria_ownership_lifetimes_e_recursos_SYNTAX_STATEMENT_LENGTH_OFFSET]
    test rax, rax
    jz .type_failure
    cmp rax, neboc_memoria_ownership_lifetimes_e_recursos_PARSE_MAX_SOURCE_BYTES
    ja .type_failure
    cmp qword [r12 + NEBOC_SYNTAX_RESERVED_OFFSET], 0
    jne .type_failure
    mov rax, 14695981039346656037
    mov r8, 1099511628211
    xor ecx, ecx
.syntax_hash_loop:
    cmp ecx, neboc_memoria_ownership_lifetimes_e_recursos_SYNTAX_HASHED_BYTES
    jae .syntax_hash_done
    movzx edx, byte [r12 + rcx]
    xor rax, rdx
    imul rax, r8
    inc ecx
    jmp .syntax_hash_loop
.syntax_hash_done:
    cmp rax, [r12 + neboc_memoria_ownership_lifetimes_e_recursos_SYNTAX_SHAPE_HASH_OFFSET]
    jne .type_failure

    ; PF001 structural and state-hash authentication.
    mov rax, neboc_memoria_ownership_lifetimes_e_recursos_MAGIC
    cmp [r12 + NEBOC_SEMANTIC_STATE_OFFSET + neboc_memoria_ownership_lifetimes_e_recursos_MAGIC_OFFSET], rax
    jne .security_failure
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_GENERATION_OFFSET], 0
    je .security_failure
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_RESOURCE_ID_OFFSET], 0
    je .security_failure
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_OWNER_TOKEN_OFFSET], 0
    je .security_failure
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_OWNER_REGION_OFFSET], 0
    je .security_failure
    mov rax, [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_STATE_OFFSET]
    cmp rax, NEBOC_STATE_OWNED
    jb .security_failure
    cmp rax, neboc_memoria_ownership_lifetimes_e_recursos_STATE_DROPPED
    ja .security_failure
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + neboc_memoria_ownership_lifetimes_e_recursos_DIAGNOSTIC_OFFSET], 0
    jne .security_failure
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + neboc_memoria_ownership_lifetimes_e_recursos_DECISION_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DECISION_PERMIT
    jne .security_failure
    cmp rax, NEBOC_STATE_BORROWED
    je .validate_borrowed
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_BORROW_MODE_OFFSET], 0
    jne .security_failure
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_BORROW_COUNT_OFFSET], 0
    jne .security_failure
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_BORROW_TOKEN_OFFSET], 0
    jne .security_failure
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_BORROW_REGION_OFFSET], 0
    jne .security_failure
    cmp rax, neboc_memoria_ownership_lifetimes_e_recursos_STATE_DROPPED
    je .validate_dropped
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_CLEANUP_COUNT_OFFSET], 0
    jne .security_failure
    jmp .state_valid
.validate_dropped:
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_CLEANUP_COUNT_OFFSET], 1
    jne .security_failure
    jmp .state_valid
.validate_borrowed:
    mov rax, [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_BORROW_MODE_OFFSET]
    cmp rax, NEBOC_BORROW_SHARED
    jb .security_failure
    cmp rax, NEBOC_BORROW_MUTABLE
    ja .security_failure
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_BORROW_COUNT_OFFSET], 0
    je .security_failure
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_BORROW_TOKEN_OFFSET], 0
    je .security_failure
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_BORROW_REGION_OFFSET], 0
    je .security_failure
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_CLEANUP_COUNT_OFFSET], 0
    jne .security_failure
    cmp rax, NEBOC_BORROW_MUTABLE
    jne .state_valid
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_BORROW_COUNT_OFFSET], 1
    jne .security_failure
.state_valid:
    mov rax, 14695981039346656037
    mov r8, 1099511628211
    xor ecx, ecx
.state_hash_loop:
    cmp ecx, neboc_memoria_ownership_lifetimes_e_recursos_HASHED_BYTES
    jae .state_hash_done
    movzx edx, byte [r12 + NEBOC_SEMANTIC_STATE_OFFSET + rcx]
    xor rax, rdx
    imul rax, r8
    inc ecx
    jmp .state_hash_loop
.state_hash_done:
    cmp rax, [r12 + NEBOC_SEMANTIC_STATE_OFFSET + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET]
    jne .security_failure

    ; Exact identity/lifetime binding prevents descriptor substitution.
    mov rax, [r12 + NEBOC_SYNTAX_RESOURCE_ID_OFFSET]
    cmp rax, [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_RESOURCE_ID_OFFSET]
    jne .security_failure
    mov rax, [r12 + NEBOC_SYNTAX_OWNER_TOKEN_OFFSET]
    cmp rax, [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_OWNER_TOKEN_OFFSET]
    jne .security_failure
    mov rax, [r12 + NEBOC_SYNTAX_OWNER_REGION_OFFSET]
    cmp rax, [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_OWNER_REGION_OFFSET]
    jne .security_failure

    mov rax, [r12 + NEBOC_SYNTAX_ACTION_OFFSET]
    cmp rax, NEBOC_OP_ACCESS_OWNER
    je .access
    cmp rax, NEBOC_OP_MOVE_OUT
    je .move
    cmp rax, NEBOC_OP_DROP
    je .drop
    cmp rax, NEBOC_OP_BORROW_SHARED
    je .shared
    cmp rax, NEBOC_OP_BORROW_MUTABLE
    je .mutable
    jmp .type_failure
.access:
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_STATE_OFFSET], NEBOC_STATE_OWNED
    jne .security_failure
    mov r10, NEBOC_STATE_OWNED
    mov r11, NEBOC_EFFECT_READ
    jmp .owner_action
.move:
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_STATE_OFFSET], NEBOC_STATE_OWNED
    jne .security_failure
    mov r10, neboc_memoria_ownership_lifetimes_e_recursos_STATE_MOVED
    mov r11, NEBOC_EFFECT_CONSUME
    jmp .owner_action
.drop:
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_STATE_OFFSET], NEBOC_STATE_OWNED
    jne .security_failure
    mov r10, neboc_memoria_ownership_lifetimes_e_recursos_STATE_DROPPED
    mov r11, NEBOC_EFFECT_CLEANUP
.owner_action:
    mov [r12 + NEBOC_SEMANTIC_OPERATION_OFFSET], rax
    mov rdx, [r12 + NEBOC_SYNTAX_OWNER_TOKEN_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_ACTOR_OFFSET], rdx
    mov rdx, [r12 + NEBOC_SYNTAX_OWNER_REGION_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_REGION_OFFSET], rdx
    mov qword [r12 + NEBOC_SEMANTIC_REQUIRED_STATE_OFFSET], NEBOC_STATE_OWNED
    mov [r12 + NEBOC_SEMANTIC_RESULT_STATE_OFFSET], r10
    mov [r12 + NEBOC_SEMANTIC_EFFECTS_OFFSET], r11
    jmp .success
.shared:
    cmp qword [r12 + NEBOC_SYNTAX_BORROW_TOKEN_OFFSET], 0
    je .type_failure
    mov rdx, [r12 + NEBOC_SYNTAX_BORROW_TOKEN_OFFSET]
    cmp rdx, [r12 + NEBOC_SYNTAX_OWNER_TOKEN_OFFSET]
    je .type_failure
    cmp qword [r12 + NEBOC_SYNTAX_BORROW_REGION_OFFSET], 0
    je .type_failure
    mov rdx, [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_STATE_OFFSET]
    cmp rdx, NEBOC_STATE_OWNED
    je .borrow_publish
    cmp rdx, NEBOC_STATE_BORROWED
    jne .security_failure
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_BORROW_MODE_OFFSET], NEBOC_BORROW_SHARED
    jne .security_failure
    mov rdx, [r12 + NEBOC_SYNTAX_BORROW_TOKEN_OFFSET]
    cmp rdx, [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_BORROW_TOKEN_OFFSET]
    jne .security_failure
    mov rdx, [r12 + NEBOC_SYNTAX_BORROW_REGION_OFFSET]
    cmp rdx, [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_BORROW_REGION_OFFSET]
    jne .security_failure
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_BORROW_COUNT_OFFSET], -1
    je .runtime_failure
    jmp .borrow_publish
.mutable:
    cmp qword [r12 + NEBOC_SYNTAX_BORROW_TOKEN_OFFSET], 0
    je .type_failure
    mov rdx, [r12 + NEBOC_SYNTAX_BORROW_TOKEN_OFFSET]
    cmp rdx, [r12 + NEBOC_SYNTAX_OWNER_TOKEN_OFFSET]
    je .type_failure
    cmp qword [r12 + NEBOC_SYNTAX_BORROW_REGION_OFFSET], 0
    je .type_failure
    cmp qword [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_STATE_OFFSET], NEBOC_STATE_OWNED
    jne .security_failure
.borrow_publish:
    mov [r12 + NEBOC_SEMANTIC_OPERATION_OFFSET], rax
    mov rdx, [r12 + NEBOC_SYNTAX_OWNER_TOKEN_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_ACTOR_OFFSET], rdx
    mov rdx, [r12 + NEBOC_SYNTAX_BORROW_REGION_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_REGION_OFFSET], rdx
    mov rdx, [r12 + NEBOC_SYNTAX_BORROW_TOKEN_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_AUX_TOKEN_OFFSET], rdx
    mov rdx, [r12 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_STATE_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_REQUIRED_STATE_OFFSET], rdx
    mov qword [r12 + NEBOC_SEMANTIC_RESULT_STATE_OFFSET], NEBOC_STATE_BORROWED
    cmp rax, NEBOC_OP_BORROW_SHARED
    jne .mutable_effect
    mov qword [r12 + NEBOC_SEMANTIC_EFFECTS_OFFSET], NEBOC_EFFECT_BORROW_SHARED
    jmp .success
.mutable_effect:
    mov qword [r12 + NEBOC_SEMANTIC_EFFECTS_OFFSET], NEBOC_EFFECT_BORROW_MUTABLE
.success:
    mov qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_DECISION_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DECISION_PERMIT
    xor r13d, r13d
    jmp .semantic_hash
.type_failure:
    mov r11, neboc_memoria_ownership_lifetimes_e_recursos_DIAG_TYPE_codegen_memory_x86_64
    jmp .failure
.security_failure:
    mov r11, neboc_memoria_ownership_lifetimes_e_recursos_DIAG_SECURITY_codegen_memory_x86_64
    jmp .failure
.runtime_failure:
    mov r11, neboc_memoria_ownership_lifetimes_e_recursos_DIAG_RUNTIME_driver_cli_linux_x86_64
.failure:
    lea rdi, [r12 + NEBOC_SEMANTIC_OPERATION_OFFSET]
    mov ecx, NEBOC_SEMANTIC_OUTPUT_QWORDS
    xor eax, eax
    rep stosq
    mov [r12 + neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_DIAGNOSTIC_OFFSET], r11
    mov qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_DECISION_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DECISION_DENY
    mov r13d, NEBOC_STATUS_INVALID_SOURCE
.semantic_hash:
    mov rax, 14695981039346656037
    mov r8, 1099511628211
    xor ecx, ecx
.semantic_hash_loop:
    cmp ecx, neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_HASHED_BYTES
    jae .semantic_hash_done
    movzx edx, byte [r12 + rcx]
    xor rax, rdx
    imul rax, r8
    inc ecx
    jmp .semantic_hash_loop
.semantic_hash_done:
    mov [r12 + neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_HASH_OFFSET], rax
    mov eax, r13d
    pop r13
    pop r12
    cld
    ret
.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
