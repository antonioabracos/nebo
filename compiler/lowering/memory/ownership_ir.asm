; Nebo Assembly — MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-PF003 target-neutral ownership HIR/LIR contract
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/memory/ownership_ir.inc"

section .text

NEBOC_ABI_FUNCTION neboc_ownership_ir_lower
    test rdi, rdi
    jz .invalid_argument
    test rdi, neboc_memoria_ownership_lifetimes_e_recursos_IR_ALIGNMENT - 1
    jnz .invalid_argument
    cld
    mov r10, rdi
    lea rdi, [r10 + neboc_memoria_ownership_lifetimes_e_recursos_IR_OUTPUT_OFFSET]
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_IR_OUTPUT_QWORDS
    xor eax, eax
    rep stosq

    ; Reauthenticate semantic, syntax and PF001 state independently.
    mov rax, 14695981039346656037
    mov r8, 1099511628211
    xor ecx, ecx
.semantic_hash_loop:
    cmp ecx, neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_HASHED_BYTES
    jae .semantic_hash_done
    movzx edx, byte [r10 + rcx]
    xor rax, rdx
    imul rax, r8
    inc ecx
    jmp .semantic_hash_loop
.semantic_hash_done:
    cmp rax, [r10 + neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_HASH_OFFSET]
    jne .invalid_source
    cmp qword [r10 + neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_ALLOCATIONS_OFFSET], 0
    jne .invalid_source

    mov rax, 14695981039346656037
    mov r8, 1099511628211
    xor ecx, ecx
.syntax_hash_loop:
    cmp ecx, neboc_memoria_ownership_lifetimes_e_recursos_SYNTAX_HASHED_BYTES
    jae .syntax_hash_done
    movzx edx, byte [r10 + rcx]
    xor rax, rdx
    imul rax, r8
    inc ecx
    jmp .syntax_hash_loop
.syntax_hash_done:
    cmp rax, [r10 + neboc_memoria_ownership_lifetimes_e_recursos_SYNTAX_SHAPE_HASH_OFFSET]
    jne .invalid_source

    mov rax, 14695981039346656037
    mov r8, 1099511628211
    xor ecx, ecx
.state_hash_loop:
    cmp ecx, neboc_memoria_ownership_lifetimes_e_recursos_HASHED_BYTES
    jae .state_hash_done
    movzx edx, byte [r10 + NEBOC_SEMANTIC_STATE_OFFSET + rcx]
    xor rax, rdx
    imul rax, r8
    inc ecx
    jmp .state_hash_loop
.state_hash_done:
    cmp rax, [r10 + NEBOC_SEMANTIC_STATE_OFFSET + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET]
    jne .invalid_source
    cmp qword [r10 + neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_DIAGNOSTIC_OFFSET], 0
    jne .invalid_source
    cmp qword [r10 + neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_DECISION_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DECISION_PERMIT
    jne .invalid_source

    ; Cross-check all semantic derivations before publishing IR.
    mov rax, [r10 + NEBOC_SYNTAX_ACTION_OFFSET]
    cmp rax, [r10 + NEBOC_SEMANTIC_OPERATION_OFFSET]
    jne .invalid_source
    mov rax, [r10 + NEBOC_SYNTAX_OWNER_TOKEN_OFFSET]
    cmp rax, [r10 + NEBOC_SEMANTIC_ACTOR_OFFSET]
    jne .invalid_source
    mov rax, [r10 + NEBOC_SYNTAX_RESOURCE_ID_OFFSET]
    cmp rax, [r10 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_RESOURCE_ID_OFFSET]
    jne .invalid_source
    mov rax, [r10 + NEBOC_SEMANTIC_REQUIRED_STATE_OFFSET]
    cmp rax, [r10 + NEBOC_SEMANTIC_STATE_OFFSET + NEBOC_STATE_OFFSET]
    jne .invalid_source
    cmp qword [r10 + NEBOC_SEMANTIC_RESULT_STATE_OFFSET], NEBOC_STATE_BORROWED
    je .check_borrow
    cmp qword [r10 + NEBOC_SEMANTIC_AUX_TOKEN_OFFSET], 0
    jne .invalid_source
    jmp .publish
.check_borrow:
    cmp qword [r10 + NEBOC_SEMANTIC_AUX_TOKEN_OFFSET], 0
    je .invalid_source
    cmp qword [r10 + NEBOC_SEMANTIC_REGION_OFFSET], 0
    je .invalid_source
.publish:
    mov qword [r10 + NEBOC_IR_HIR_RESOURCE_BIND_OFFSET], NEBOC_HIR_RESOURCE_BIND
    mov qword [r10 + NEBOC_IR_HIR_OWNER_BIND_OFFSET], NEBOC_HIR_OWNER_BIND
    mov qword [r10 + NEBOC_IR_HIR_LIFETIME_GUARD_OFFSET], NEBOC_HIR_LIFETIME_GUARD
    mov qword [r10 + NEBOC_IR_HIR_ACTION_OFFSET], NEBOC_HIR_ACTION
    mov qword [r10 + NEBOC_IR_LIR_STATE_HASH_ASSERT_OFFSET], NEBOC_LIR_STATE_HASH_ASSERT
    mov qword [r10 + NEBOC_IR_LIR_AUTHORITY_ASSERT_OFFSET], NEBOC_LIR_AUTHORITY_ASSERT
    mov qword [r10 + NEBOC_IR_LIR_TRANSITION_CALL_OFFSET], NEBOC_LIR_TRANSITION_CALL
    mov qword [r10 + NEBOC_IR_LIR_EXACT_CLEANUP_OFFSET], NEBOC_LIR_EXACT_CLEANUP
    mov rax, [r10 + NEBOC_SYNTAX_RESOURCE_ID_OFFSET]
    mov [r10 + NEBOC_IR_RESOURCE_ID_OFFSET], rax
    mov rax, [r10 + NEBOC_SEMANTIC_OPERATION_OFFSET]
    mov [r10 + neboc_memoria_ownership_lifetimes_e_recursos_IR_OPERATION_OFFSET], rax
    mov rax, [r10 + NEBOC_SEMANTIC_ACTOR_OFFSET]
    mov [r10 + NEBOC_IR_ACTOR_OFFSET], rax
    mov rax, [r10 + NEBOC_SEMANTIC_REGION_OFFSET]
    mov [r10 + NEBOC_IR_REGION_OFFSET], rax
    mov rax, [r10 + NEBOC_SEMANTIC_AUX_TOKEN_OFFSET]
    mov [r10 + NEBOC_IR_AUX_TOKEN_OFFSET], rax
    mov rax, [r10 + NEBOC_SEMANTIC_EFFECTS_OFFSET]
    mov [r10 + NEBOC_IR_EFFECTS_OFFSET], rax
    mov qword [r10 + neboc_memoria_ownership_lifetimes_e_recursos_IR_DECISION_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DECISION_PERMIT
    jmp .ir_hash
.invalid_source:
    lea rdi, [r10 + neboc_memoria_ownership_lifetimes_e_recursos_IR_OUTPUT_OFFSET]
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_IR_OUTPUT_QWORDS
    xor eax, eax
    rep stosq
    mov qword [r10 + neboc_memoria_ownership_lifetimes_e_recursos_IR_DIAGNOSTIC_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DIAG_TYPE_codegen_memory_x86_64
    mov r11d, NEBOC_STATUS_INVALID_SOURCE
    jmp .ir_hash_status
.ir_hash:
    xor r11d, r11d
.ir_hash_status:
    mov rax, 14695981039346656037
    mov r8, 1099511628211
    xor ecx, ecx
.ir_hash_loop:
    cmp ecx, neboc_memoria_ownership_lifetimes_e_recursos_IR_HASHED_BYTES
    jae .ir_hash_done
    movzx edx, byte [r10 + rcx]
    xor rax, rdx
    imul rax, r8
    inc ecx
    jmp .ir_hash_loop
.ir_hash_done:
    mov [r10 + neboc_memoria_ownership_lifetimes_e_recursos_IR_HASH_OFFSET], rax
    mov eax, r11d
    cld
    ret
.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
