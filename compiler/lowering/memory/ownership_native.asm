; Nebo Assembly — MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-PF004 authenticated native ownership plan
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "runtime/memory/ownership_runtime.inc"

section .text

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_ownership_native_lower
    test rdi, rdi
    jz .invalid_argument
    test rdi, neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_ALIGNMENT - 1
    jnz .invalid_argument
    cld
    mov r10, rdi
    lea rdi, [r10 + NEBOC_NATIVE_STATE_OFFSET]
    mov ecx, NEBOC_NATIVE_OWNED_QWORDS + neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_OUTPUT_QWORDS
    xor eax, eax
    rep stosq

    ; Authenticate all predecessor layers independently.
    mov rsi, r10
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_IR_HASHED_BYTES
    call hash
    cmp rax, [r10 + neboc_memoria_ownership_lifetimes_e_recursos_IR_HASH_OFFSET]
    jne .failure
    mov rsi, r10
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_HASHED_BYTES
    call hash
    cmp rax, [r10 + neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_HASH_OFFSET]
    jne .failure
    mov rsi, r10
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_SYNTAX_HASHED_BYTES
    call hash
    cmp rax, [r10 + neboc_memoria_ownership_lifetimes_e_recursos_SYNTAX_SHAPE_HASH_OFFSET]
    jne .failure
    lea rsi, [r10 + NEBOC_SEMANTIC_STATE_OFFSET]
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_HASHED_BYTES
    call hash
    cmp rax, [r10 + NEBOC_SEMANTIC_STATE_OFFSET + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET]
    jne .failure
    cmp qword [r10 + neboc_memoria_ownership_lifetimes_e_recursos_IR_DIAGNOSTIC_OFFSET], 0
    jne .failure
    cmp qword [r10 + neboc_memoria_ownership_lifetimes_e_recursos_IR_DECISION_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DECISION_PERMIT
    jne .failure
    cmp qword [r10 + neboc_memoria_ownership_lifetimes_e_recursos_IR_ALLOCATIONS_OFFSET], 0
    jne .failure
    mov rax, [r10 + neboc_memoria_ownership_lifetimes_e_recursos_IR_OPERATION_OFFSET]
    cmp rax, [r10 + NEBOC_SEMANTIC_OPERATION_OFFSET]
    jne .failure
    mov rax, [r10 + NEBOC_IR_ACTOR_OFFSET]
    cmp rax, [r10 + NEBOC_SEMANTIC_ACTOR_OFFSET]
    jne .failure
    mov rax, [r10 + NEBOC_IR_REGION_OFFSET]
    cmp rax, [r10 + NEBOC_SEMANTIC_REGION_OFFSET]
    jne .failure
    mov rax, [r10 + NEBOC_IR_AUX_TOKEN_OFFSET]
    cmp rax, [r10 + NEBOC_SEMANTIC_AUX_TOKEN_OFFSET]
    jne .failure

    ; Copy immutable pre-state into the plan; runtime executes on another copy.
    lea rsi, [r10 + NEBOC_SEMANTIC_STATE_OFFSET]
    lea rdi, [r10 + NEBOC_NATIVE_STATE_OFFSET]
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_RECORD_QWORDS
    rep movsq
    mov rax, [r10 + NEBOC_NATIVE_STATE_OFFSET + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET]
    mov [r10 + NEBOC_NATIVE_EXPECTED_PRE_HASH_OFFSET], rax
    mov rax, [r10 + NEBOC_SEMANTIC_RESULT_STATE_OFFSET]
    mov [r10 + NEBOC_NATIVE_EXPECTED_RESULT_STATE_OFFSET], rax
    xor eax, eax
    cmp qword [r10 + NEBOC_SEMANTIC_EFFECTS_OFFSET], NEBOC_EFFECT_CLEANUP
    setz al
    mov [r10 + NEBOC_NATIVE_EXPECTED_CLEANUP_DELTA_OFFSET], rax
    mov eax, 1
    cmp qword [r10 + NEBOC_SEMANTIC_OPERATION_OFFSET], NEBOC_OP_ACCESS_OWNER
    jne .generation_ready
    xor eax, eax
.generation_ready:
    mov [r10 + NEBOC_NATIVE_EXPECTED_GENERATION_DELTA_OFFSET], rax
    mov rax, [r10 + neboc_memoria_ownership_lifetimes_e_recursos_IR_OPERATION_OFFSET]
    mov [r10 + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_OPERATION_OFFSET], rax
    mov rax, [r10 + NEBOC_IR_ACTOR_OFFSET]
    mov [r10 + NEBOC_NATIVE_ACTOR_OFFSET], rax
    mov rax, [r10 + NEBOC_IR_REGION_OFFSET]
    mov [r10 + NEBOC_NATIVE_REGION_OFFSET], rax
    mov rax, [r10 + NEBOC_IR_AUX_TOKEN_OFFSET]
    mov [r10 + NEBOC_NATIVE_AUX_TOKEN_OFFSET], rax
    mov qword [r10 + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_DECISION_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DECISION_PERMIT
    mov rsi, r10
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_HASHED_BYTES
    call hash
    mov [r10 + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_HASH_OFFSET], rax
    xor eax, eax
    cld
    ret
.failure:
    lea rdi, [r10 + NEBOC_NATIVE_STATE_OFFSET]
    mov ecx, NEBOC_NATIVE_OWNED_QWORDS + neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_OUTPUT_QWORDS
    xor eax, eax
    rep stosq
    mov qword [r10 + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_DIAGNOSTIC_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DIAG_TYPE_codegen_memory_x86_64
    mov rsi, r10
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_HASHED_BYTES
    call hash
    mov [r10 + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_HASH_OFFSET], rax
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    cld
    ret
.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

%undef call
hash:
    mov rax, 14695981039346656037
    mov r8, 1099511628211
    xor edx, edx
.loop:
    cmp edx, ecx
    jae .done
    movzx r9d, byte [rsi + rdx]
    xor rax, r9
    imul rax, r8
    inc edx
    jmp .loop
.done:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
