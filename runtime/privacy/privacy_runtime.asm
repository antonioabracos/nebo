; Nebo Assembly — PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-PF004 authenticated payload-free privacy runtime gate
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "runtime/privacy/privacy_runtime.inc"

extern neboc_privacy_evaluate

section .text

NEBOC_ABI_FUNCTION neboc_privacy_runtime_check
    test rdi, rdi
    jz .invalid_argument
    test rdi, neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_ALIGNMENT - 1
    jnz .invalid_argument
    mov r8, rdi
    add r8, neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_REQUEST_SIZE
    jc .invalid_argument
    mov rsi, [rdi + NEBOC_RUNTIME_PRIVACY_RECORD_OFFSET]
    test rsi, rsi
    jz .invalid_argument
    test rsi, NEBOC_PRIVACY_ALIGNMENT - 1
    jnz .invalid_argument
    mov r9, rsi
    add r9, NEBOC_PRIVACY_REQUEST_SIZE
    jc .invalid_argument
    cmp r9, rdi
    jbe .disjoint
    cmp rsi, r8
    jb .invalid_argument
.disjoint:
    cld
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r15, [r12 + NEBOC_RUNTIME_REQUESTED_LABELS_OFFSET]
    sub rsp, NEBOC_PRIVACY_REQUEST_SIZE
    mov rdi, rsp
    mov rsi, r13
    mov ecx, NEBOC_PRIVACY_REQUEST_QWORDS
    rep movsq
    mov rdi, rsp
    call neboc_privacy_evaluate
    mov r14d, eax
    mov rdi, r13
    mov rsi, rsp
    mov ecx, NEBOC_PRIVACY_REQUEST_QWORDS
    repe cmpsq
    jne .record_mismatch
    test r14d, r14d
    jnz .record_not_green
    cmp qword [rsp + NEBOC_PRIVACY_DIAGNOSTIC_OFFSET], 0
    jne .record_not_green
    cmp qword [rsp + NEBOC_PRIVACY_DECISION_OFFSET], NEBOC_PRIVACY_DECISION_PERMIT
    jne .record_not_green
    mov rax, r15
    and rax, ~NEBOC_LABEL_MASK_KNOWN
    jnz .type_failure
    mov rax, [rsp + NEBOC_PRIVACY_EFFECTIVE_LABELS_OFFSET]
    mov rdx, rax
    not rdx
    test r15, rdx
    jnz .security_failure
    mov r8d, NEBOC_PRIVACY_DECISION_PERMIT
    mov r10, rax
    xor r9d, r9d
    mov r14d, NEBOC_STATUS_OK
    jmp .finalize
.record_mismatch:
    xor r8d, r8d
    xor r10d, r10d
    mov r9d, neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_TYPE_codegen_privacy_x86_64
    mov r14d, NEBOC_STATUS_INVALID_SOURCE
    jmp .finalize
.record_not_green:
    xor r8d, r8d
    xor r10d, r10d
    mov r9, [rsp + NEBOC_PRIVACY_DIAGNOSTIC_OFFSET]
    test r9, r9
    jnz .record_diag_ready
    mov r9d, neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_TYPE_codegen_privacy_x86_64
.record_diag_ready:
    mov r14d, NEBOC_STATUS_INVALID_SOURCE
    jmp .finalize
.type_failure:
    xor r8d, r8d
    xor r10d, r10d
    mov r9d, neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_TYPE_codegen_privacy_x86_64
    mov r14d, NEBOC_STATUS_INVALID_SOURCE
    jmp .finalize
.security_failure:
    xor r8d, r8d
    xor r10d, r10d
    mov r9d, neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_SECURITY_driver_cli_linux_x86_64
    mov r14d, NEBOC_STATUS_INVALID_SOURCE
.finalize:
    mov rax, [rsp + NEBOC_PRIVACY_METADATA_HASH_OFFSET]
    mov [rsp], rax
    mov [rsp + 8], r15
    mov [rsp + 16], r10
    mov [rsp + 24], r8
    mov [rsp + 32], r9
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r11, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.event_hash_loop:
    cmp rcx, neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_EVENT_HASHED_BYTES
    jae .event_hash_done
    movzx edx, byte [rsp + rcx]
    xor rax, rdx
    imul rax, r11
    inc rcx
    jmp .event_hash_loop
.event_hash_done:
    mov [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_DECISION_OFFSET], r8
    mov [r12 + NEBOC_RUNTIME_EFFECTIVE_LABELS_OFFSET], r10
    mov [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_DIAGNOSTIC_OFFSET], r9
    mov [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_EVENT_HASH_OFFSET], rax
    mov qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_ALLOCATIONS_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_ALLOCATION_NONE
    mov eax, r14d
    add rsp, NEBOC_PRIVACY_REQUEST_SIZE
    pop r15
    pop r14
    pop r13
    pop r12
    cld
    ret
.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
