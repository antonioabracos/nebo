; Nebo Assembly — MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-PF001 bounded ownership/lifetime resource machine
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/memory/ownership_state.inc"

section .text

; ownership_transition(record*, operation, actor_token, region_id, aux_token)
;
; INIT interprets actor as owner, region as the finite owner region and aux as
; the non-zero resource identity. Shared/mutable borrow uses aux as borrower
; token. Releases and accesses use actor as borrower token. No raw resource
; address, payload, allocator, callback or ambient authority crosses this ABI.
NEBOC_ABI_FUNCTION neboc_ownership_transition
    test rdi, rdi
    jz .invalid_argument
    test rdi, neboc_memoria_ownership_lifetimes_e_recursos_ALIGNMENT - 1
    jnz .invalid_argument
    cmp rsi, NEBOC_OP_INIT
    jb .invalid_argument
    cmp rsi, NEBOC_OP_COUNT
    ja .invalid_argument

    push r12
    mov r12, rdi
    cmp rsi, NEBOC_OP_INIT
    je .initialize

    ; Validate the complete canonical state before dispatch. Corrupt records
    ; fail without publishing another transition or changing the state hash.
    mov rax, neboc_memoria_ownership_lifetimes_e_recursos_MAGIC
    cmp [r12 + neboc_memoria_ownership_lifetimes_e_recursos_MAGIC_OFFSET], rax
    jne .type_failure
    cmp qword [r12 + NEBOC_GENERATION_OFFSET], 0
    je .type_failure
    cmp qword [r12 + NEBOC_RESOURCE_ID_OFFSET], 0
    je .type_failure
    cmp qword [r12 + NEBOC_OWNER_TOKEN_OFFSET], 0
    je .type_failure
    cmp qword [r12 + NEBOC_OWNER_REGION_OFFSET], 0
    je .type_failure
    mov rax, [r12 + NEBOC_STATE_OFFSET]
    cmp rax, NEBOC_STATE_OWNED
    jb .type_failure
    cmp rax, neboc_memoria_ownership_lifetimes_e_recursos_STATE_DROPPED
    ja .type_failure
    cmp rax, NEBOC_STATE_BORROWED
    je .validate_borrowed
    cmp qword [r12 + NEBOC_BORROW_MODE_OFFSET], 0
    jne .type_failure
    cmp qword [r12 + NEBOC_BORROW_COUNT_OFFSET], 0
    jne .type_failure
    cmp qword [r12 + NEBOC_BORROW_TOKEN_OFFSET], 0
    jne .type_failure
    cmp qword [r12 + NEBOC_BORROW_REGION_OFFSET], 0
    jne .type_failure
    cmp rax, neboc_memoria_ownership_lifetimes_e_recursos_STATE_DROPPED
    je .validate_dropped
    cmp qword [r12 + NEBOC_CLEANUP_COUNT_OFFSET], 0
    jne .type_failure
    jmp .validated
.validate_dropped:
    cmp qword [r12 + NEBOC_CLEANUP_COUNT_OFFSET], 1
    jne .type_failure
    jmp .validated
.validate_borrowed:
    mov rax, [r12 + NEBOC_BORROW_MODE_OFFSET]
    cmp rax, NEBOC_BORROW_SHARED
    jb .type_failure
    cmp rax, NEBOC_BORROW_MUTABLE
    ja .type_failure
    cmp qword [r12 + NEBOC_BORROW_COUNT_OFFSET], 0
    je .type_failure
    cmp qword [r12 + NEBOC_BORROW_TOKEN_OFFSET], 0
    je .type_failure
    cmp qword [r12 + NEBOC_BORROW_REGION_OFFSET], 0
    je .type_failure
    cmp qword [r12 + NEBOC_CLEANUP_COUNT_OFFSET], 0
    jne .type_failure
    cmp rax, NEBOC_BORROW_MUTABLE
    jne .validated
    cmp qword [r12 + NEBOC_BORROW_COUNT_OFFSET], 1
    jne .type_failure

.validated:
    cmp rsi, NEBOC_OP_ACCESS_OWNER
    jae .dispatch
    cmp qword [r12 + NEBOC_GENERATION_OFFSET], -1
    je .runtime_failure
    cmp qword [r12 + NEBOC_TRANSITION_COUNT_OFFSET], -1
    je .runtime_failure
.dispatch:
    cmp rsi, NEBOC_OP_BORROW_SHARED
    je .borrow_shared
    cmp rsi, NEBOC_OP_RELEASE_SHARED
    je .release_shared
    cmp rsi, NEBOC_OP_BORROW_MUTABLE
    je .borrow_mutable
    cmp rsi, NEBOC_OP_RELEASE_MUTABLE
    je .release_mutable
    cmp rsi, NEBOC_OP_MOVE_OUT
    je .move_out
    cmp rsi, NEBOC_OP_DROP
    je .drop
    cmp rsi, NEBOC_OP_END_LIFETIME
    je .end_lifetime
    cmp rsi, NEBOC_OP_ACCESS_OWNER
    je .access_owner
    jmp .access_borrow

.initialize:
    test rdx, rdx
    jz .type_failure
    test rcx, rcx
    jz .type_failure
    test r8, r8
    jz .type_failure
    cmp qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_MAGIC_OFFSET], 0
    jne .runtime_failure
    cmp qword [r12 + NEBOC_STATE_OFFSET], NEBOC_STATE_UNINITIALIZED
    jne .runtime_failure
    mov rax, neboc_memoria_ownership_lifetimes_e_recursos_MAGIC
    mov [r12 + neboc_memoria_ownership_lifetimes_e_recursos_MAGIC_OFFSET], rax
    mov qword [r12 + NEBOC_GENERATION_OFFSET], 1
    mov [r12 + NEBOC_RESOURCE_ID_OFFSET], r8
    mov [r12 + NEBOC_OWNER_TOKEN_OFFSET], rdx
    mov [r12 + NEBOC_OWNER_REGION_OFFSET], rcx
    mov qword [r12 + NEBOC_STATE_OFFSET], NEBOC_STATE_OWNED
    mov qword [r12 + NEBOC_BORROW_MODE_OFFSET], 0
    mov qword [r12 + NEBOC_BORROW_COUNT_OFFSET], 0
    mov qword [r12 + NEBOC_BORROW_TOKEN_OFFSET], 0
    mov qword [r12 + NEBOC_BORROW_REGION_OFFSET], 0
    mov qword [r12 + NEBOC_CLEANUP_COUNT_OFFSET], 0
    mov qword [r12 + NEBOC_TRANSITION_COUNT_OFFSET], 1
    mov qword [r12 + NEBOC_LAST_OPERATION_OFFSET], NEBOC_OP_INIT
    mov qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_DIAGNOSTIC_OFFSET], 0
    mov qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_DECISION_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DECISION_PERMIT
    jmp .rehash_success

.borrow_shared:
    cmp rdx, [r12 + NEBOC_OWNER_TOKEN_OFFSET]
    jne .security_failure
    test rcx, rcx
    jz .type_failure
    test r8, r8
    jz .type_failure
    cmp r8, rdx
    je .security_failure
    cmp qword [r12 + NEBOC_STATE_OFFSET], NEBOC_STATE_OWNED
    je .first_shared
    cmp qword [r12 + NEBOC_STATE_OFFSET], NEBOC_STATE_BORROWED
    jne .security_failure
    cmp qword [r12 + NEBOC_BORROW_MODE_OFFSET], NEBOC_BORROW_SHARED
    jne .security_failure
    cmp [r12 + NEBOC_BORROW_TOKEN_OFFSET], r8
    jne .security_failure
    cmp [r12 + NEBOC_BORROW_REGION_OFFSET], rcx
    jne .security_failure
    cmp qword [r12 + NEBOC_BORROW_COUNT_OFFSET], -1
    je .runtime_failure
    inc qword [r12 + NEBOC_BORROW_COUNT_OFFSET]
    jmp .publish_transition
.first_shared:
    mov qword [r12 + NEBOC_STATE_OFFSET], NEBOC_STATE_BORROWED
    mov qword [r12 + NEBOC_BORROW_MODE_OFFSET], NEBOC_BORROW_SHARED
    mov qword [r12 + NEBOC_BORROW_COUNT_OFFSET], 1
    mov [r12 + NEBOC_BORROW_TOKEN_OFFSET], r8
    mov [r12 + NEBOC_BORROW_REGION_OFFSET], rcx
    jmp .publish_transition

.release_shared:
    cmp qword [r12 + NEBOC_STATE_OFFSET], NEBOC_STATE_BORROWED
    jne .security_failure
    cmp qword [r12 + NEBOC_BORROW_MODE_OFFSET], NEBOC_BORROW_SHARED
    jne .security_failure
    cmp rdx, [r12 + NEBOC_BORROW_TOKEN_OFFSET]
    jne .security_failure
    cmp rcx, [r12 + NEBOC_BORROW_REGION_OFFSET]
    jne .security_failure
    dec qword [r12 + NEBOC_BORROW_COUNT_OFFSET]
    jnz .publish_transition
    call .restore_owned
    jmp .publish_transition

.borrow_mutable:
    cmp qword [r12 + NEBOC_STATE_OFFSET], NEBOC_STATE_OWNED
    jne .security_failure
    cmp rdx, [r12 + NEBOC_OWNER_TOKEN_OFFSET]
    jne .security_failure
    test rcx, rcx
    jz .type_failure
    test r8, r8
    jz .type_failure
    cmp r8, rdx
    je .security_failure
    mov qword [r12 + NEBOC_STATE_OFFSET], NEBOC_STATE_BORROWED
    mov qword [r12 + NEBOC_BORROW_MODE_OFFSET], NEBOC_BORROW_MUTABLE
    mov qword [r12 + NEBOC_BORROW_COUNT_OFFSET], 1
    mov [r12 + NEBOC_BORROW_TOKEN_OFFSET], r8
    mov [r12 + NEBOC_BORROW_REGION_OFFSET], rcx
    jmp .publish_transition

.release_mutable:
    cmp qword [r12 + NEBOC_STATE_OFFSET], NEBOC_STATE_BORROWED
    jne .security_failure
    cmp qword [r12 + NEBOC_BORROW_MODE_OFFSET], NEBOC_BORROW_MUTABLE
    jne .security_failure
    cmp rdx, [r12 + NEBOC_BORROW_TOKEN_OFFSET]
    jne .security_failure
    cmp rcx, [r12 + NEBOC_BORROW_REGION_OFFSET]
    jne .security_failure
    call .restore_owned
    jmp .publish_transition

.move_out:
    cmp qword [r12 + NEBOC_STATE_OFFSET], NEBOC_STATE_OWNED
    jne .security_failure
    cmp rdx, [r12 + NEBOC_OWNER_TOKEN_OFFSET]
    jne .security_failure
    mov qword [r12 + NEBOC_STATE_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_STATE_MOVED
    jmp .publish_transition

.drop:
    cmp qword [r12 + NEBOC_STATE_OFFSET], NEBOC_STATE_OWNED
    jne .runtime_failure
    cmp rdx, [r12 + NEBOC_OWNER_TOKEN_OFFSET]
    jne .security_failure
    cmp qword [r12 + NEBOC_CLEANUP_COUNT_OFFSET], 0
    jne .runtime_failure
    mov qword [r12 + NEBOC_CLEANUP_COUNT_OFFSET], 1
    mov qword [r12 + NEBOC_STATE_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_STATE_DROPPED
    jmp .publish_transition

.end_lifetime:
    cmp rcx, [r12 + NEBOC_OWNER_REGION_OFFSET]
    jne .security_failure
    jmp .drop

.access_owner:
    cmp qword [r12 + NEBOC_STATE_OFFSET], NEBOC_STATE_OWNED
    jne .security_failure
    cmp rdx, [r12 + NEBOC_OWNER_TOKEN_OFFSET]
    jne .security_failure
    jmp .publish_observation

.access_borrow:
    cmp qword [r12 + NEBOC_STATE_OFFSET], NEBOC_STATE_BORROWED
    jne .security_failure
    cmp rdx, [r12 + NEBOC_BORROW_TOKEN_OFFSET]
    jne .security_failure
    cmp rcx, [r12 + NEBOC_BORROW_REGION_OFFSET]
    jne .security_failure
    jmp .publish_observation

.restore_owned:
    mov qword [r12 + NEBOC_STATE_OFFSET], NEBOC_STATE_OWNED
    mov qword [r12 + NEBOC_BORROW_MODE_OFFSET], 0
    mov qword [r12 + NEBOC_BORROW_COUNT_OFFSET], 0
    mov qword [r12 + NEBOC_BORROW_TOKEN_OFFSET], 0
    mov qword [r12 + NEBOC_BORROW_REGION_OFFSET], 0
    ret

.publish_transition:
    inc qword [r12 + NEBOC_GENERATION_OFFSET]
    inc qword [r12 + NEBOC_TRANSITION_COUNT_OFFSET]
    mov [r12 + NEBOC_LAST_OPERATION_OFFSET], rsi
.publish_observation:
    mov qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_DIAGNOSTIC_OFFSET], 0
    mov qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_DECISION_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DECISION_PERMIT
.rehash_success:
    call .rehash
    xor eax, eax
    pop r12
    cld
    ret

.rehash:
    mov rax, 14695981039346656037
    mov r8, 1099511628211
    xor ecx, ecx
.hash_loop:
    cmp rcx, neboc_memoria_ownership_lifetimes_e_recursos_HASHED_BYTES
    jae .hash_done
    movzx edx, byte [r12 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .hash_loop
.hash_done:
    mov [r12 + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET], rax
    ret

.type_failure:
    mov qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_DIAGNOSTIC_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DIAG_TYPE_codegen_memory_x86_64
    jmp .invalid_source
.security_failure:
    mov qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_DIAGNOSTIC_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DIAG_SECURITY_codegen_memory_x86_64
    jmp .invalid_source
.runtime_failure:
    mov qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_DIAGNOSTIC_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DIAG_RUNTIME_driver_cli_linux_x86_64
.invalid_source:
    mov qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_DECISION_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DECISION_DENY
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    pop r12
    cld
    ret
.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
