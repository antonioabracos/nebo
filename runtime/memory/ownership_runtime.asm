; Nebo Assembly — MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-PF004 single-use ownership runtime gate
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "runtime/memory/ownership_runtime.inc"

extern neboc_ownership_transition

section .text

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_ownership_runtime_execute
    test rdi, rdi
    jz .invalid_argument
    test rdi, neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_ALIGNMENT - 1
    jnz .invalid_argument
    cld
    cmp qword [rdi + NEBOC_RUNTIME_EXECUTED_OFFSET], 0
    jne .already_executed
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi

    ; Reauthenticate immutable native plan and pre-state before copying.
    mov rsi, r12
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_HASHED_BYTES
    call hash
    cmp rax, [r12 + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_HASH_OFFSET]
    jne .pre_failure
    cmp qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_DIAGNOSTIC_OFFSET], 0
    jne .pre_failure
    cmp qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_DECISION_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DECISION_PERMIT
    jne .pre_failure
    cmp qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_ALLOCATIONS_OFFSET], 0
    jne .pre_failure
    lea rsi, [r12 + NEBOC_NATIVE_STATE_OFFSET]
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_HASHED_BYTES
    call hash
    cmp rax, [r12 + NEBOC_NATIVE_EXPECTED_PRE_HASH_OFFSET]
    jne .pre_failure
    cmp rax, [r12 + NEBOC_NATIVE_STATE_OFFSET + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET]
    jne .pre_failure
    mov rax, [r12 + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_OPERATION_OFFSET]
    cmp rax, [r12 + neboc_memoria_ownership_lifetimes_e_recursos_IR_OPERATION_OFFSET]
    jne .pre_failure
    mov rax, [r12 + NEBOC_NATIVE_ACTOR_OFFSET]
    cmp rax, [r12 + NEBOC_IR_ACTOR_OFFSET]
    jne .pre_failure
    mov rax, [r12 + NEBOC_NATIVE_REGION_OFFSET]
    cmp rax, [r12 + NEBOC_IR_REGION_OFFSET]
    jne .pre_failure
    mov rax, [r12 + NEBOC_NATIVE_AUX_TOKEN_OFFSET]
    cmp rax, [r12 + NEBOC_IR_AUX_TOKEN_OFFSET]
    jne .pre_failure

    lea rsi, [r12 + NEBOC_NATIVE_STATE_OFFSET]
    lea rdi, [r12 + NEBOC_RUNTIME_STATE_OFFSET]
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_RECORD_QWORDS
    rep movsq
    mov r13, [r12 + NEBOC_RUNTIME_STATE_OFFSET + NEBOC_GENERATION_OFFSET]
    mov r14, [r12 + NEBOC_RUNTIME_STATE_OFFSET + NEBOC_CLEANUP_COUNT_OFFSET]
    lea rdi, [r12 + NEBOC_RUNTIME_STATE_OFFSET]
    mov rsi, [r12 + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_OPERATION_OFFSET]
    mov rdx, [r12 + NEBOC_NATIVE_ACTOR_OFFSET]
    mov rcx, [r12 + NEBOC_NATIVE_REGION_OFFSET]
    mov r8, [r12 + NEBOC_NATIVE_AUX_TOKEN_OFFSET]
    call neboc_ownership_transition
    mov r15d, eax
    test eax, eax
    jnz .transition_failure

    mov rax, [r12 + NEBOC_RUNTIME_STATE_OFFSET + NEBOC_STATE_OFFSET]
    cmp rax, [r12 + NEBOC_NATIVE_EXPECTED_RESULT_STATE_OFFSET]
    jne .post_failure
    mov [r12 + NEBOC_RUNTIME_OBSERVED_STATE_OFFSET], rax
    mov rax, [r12 + NEBOC_RUNTIME_STATE_OFFSET + NEBOC_CLEANUP_COUNT_OFFSET]
    sub rax, r14
    cmp rax, [r12 + NEBOC_NATIVE_EXPECTED_CLEANUP_DELTA_OFFSET]
    jne .post_failure
    mov [r12 + NEBOC_RUNTIME_CLEANUP_DELTA_OFFSET], rax
    mov rax, [r12 + NEBOC_RUNTIME_STATE_OFFSET + NEBOC_GENERATION_OFFSET]
    sub rax, r13
    cmp rax, [r12 + NEBOC_NATIVE_EXPECTED_GENERATION_DELTA_OFFSET]
    jne .post_failure
    mov [r12 + NEBOC_RUNTIME_GENERATION_DELTA_OFFSET], rax
    mov rax, [r12 + NEBOC_RUNTIME_STATE_OFFSET + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET]
    mov [r12 + NEBOC_RUNTIME_FINAL_STATE_HASH_OFFSET], rax
    mov qword [r12 + NEBOC_RUNTIME_EXECUTED_OFFSET], 1
    mov qword [r12 + NEBOC_RUNTIME_STATUS_OFFSET], NEBOC_STATUS_OK
    mov qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_DECISION_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DECISION_PERMIT
    xor r15d, r15d
    jmp .event_hash
.transition_failure:
    mov r11, [r12 + NEBOC_RUNTIME_STATE_OFFSET + neboc_memoria_ownership_lifetimes_e_recursos_DIAGNOSTIC_OFFSET]
    jmp .publish_failure
.post_failure:
    mov r11, neboc_memoria_ownership_lifetimes_e_recursos_DIAG_RUNTIME_driver_cli_linux_x86_64
.publish_failure:
    lea rdi, [r12 + NEBOC_RUNTIME_STATE_OFFSET]
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_OUTPUT_QWORDS
    xor eax, eax
    rep stosq
    mov qword [r12 + NEBOC_RUNTIME_EXECUTED_OFFSET], 1
    mov [r12 + NEBOC_RUNTIME_STATUS_OFFSET], r15
    mov [r12 + neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_DIAGNOSTIC_OFFSET], r11
    mov qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_DECISION_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DECISION_DENY
    mov r15d, NEBOC_STATUS_INVALID_SOURCE
.event_hash:
    mov rsi, r12
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_HASHED_BYTES
    call hash
    mov [r12 + neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_EVENT_HASH_OFFSET], rax
    mov eax, r15d
    pop r15
    pop r14
    pop r13
    pop r12
    cld
    ret
.pre_failure:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    pop r15
    pop r14
    pop r13
    pop r12
    cld
    ret
.already_executed:
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
