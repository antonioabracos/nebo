; Nebo Assembly — EFFECTS-CAPABILITIES-E-POLITICAS-PF004 authenticated native runtime policy gate
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "runtime/effects/effect_policy_runtime.inc"

section .text

extern neboc_policy_evaluate

; neboc_policy_runtime_check(request*) -> StatusCode
;
; The aligned six-qword request and its aligned 17-qword policy record must be
; non-null, non-wrapping and disjoint.  Address failures are transactional and
; leave q2..q5 untouched.  For every address-valid call the policy record is
; copied, independently evaluated, compared in full, and never mutated.
NEBOC_ABI_FUNCTION neboc_policy_runtime_check
    test rdi, rdi
    jz .invalid_argument
    test rdi, NEBOC_POLICY_RUNTIME_ALIGNMENT - 1
    jnz .invalid_argument

    ; Prove the request span itself before reading q0.  Even a synthetic
    ; aligned pointer whose 48-byte range wraps is rejected without a load.
    mov r8, rdi
    add r8, NEBOC_POLICY_RUNTIME_REQUEST_SIZE
    jc .invalid_argument

    mov rsi, [rdi + NEBOC_POLICY_RUNTIME_POLICY_RECORD_OFFSET]
    test rsi, rsi
    jz .invalid_argument
    test rsi, NEBOC_POLICY_ALIGNMENT - 1
    jnz .invalid_argument

    ; Reject wrapping spans and every partial or complete overlap before a
    ; write.  Half-open ranges touching exactly at an endpoint are disjoint.
    mov r9, rsi
    add r9, NEBOC_POLICY_REQUEST_SIZE
    jc .invalid_argument
    cmp r9, rdi
    jbe .spans_disjoint
    cmp rsi, r8
    jb .invalid_argument
.spans_disjoint:

    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r15, [r12 + NEBOC_POLICY_RUNTIME_REQUESTED_MASK_OFFSET]

    ; Four saved registers leave RSP at 8 mod 16.  The 136-byte local policy
    ; copy restores 16-byte call-site alignment and itself remains 8-aligned.
    sub rsp, NEBOC_POLICY_REQUEST_SIZE
    mov rdi, rsp
    mov rsi, r13
    mov ecx, NEBOC_POLICY_REQUEST_QWORDS
    rep movsq

    ; PF001 remains the sole policy-rule owner.  It recomputes q10..q16 in the
    ; local copy without observing or changing caller memory.
    mov rdi, rsp
    call neboc_policy_evaluate
    mov r14d, eax

    ; Authenticate all inputs and derived metadata, including audit hash and
    ; decision.  A forged/stale record is a TYPE-003 provenance failure.
    mov rdi, r13
    mov rsi, rsp
    mov ecx, NEBOC_POLICY_REQUEST_QWORDS
    repe cmpsq
    jne .record_mismatch

    ; Only an exact GREEN/PERMIT evaluator record may authorize a runtime
    ; request.  Preserve a canonical evaluator diagnostic on a denied record.
    test r14d, r14d
    jnz .record_not_green
    cmp qword [rsp + NEBOC_POLICY_DIAGNOSTIC_OFFSET], 0
    jne .record_not_green
    cmp qword [rsp + NEBOC_POLICY_DECISION_OFFSET], \
        NEBOC_POLICY_DECISION_PERMIT
    jne .record_not_green

    mov rax, r15
    and rax, ~NEBOC_EFFECT_MASK_KNOWN
    jnz .requested_type_failure

    ; Runtime use can narrow, never widen, the statically proven effect set.
    mov rax, [rsp + NEBOC_POLICY_INFERRED_EFFECTS_OFFSET]
    not rax
    test r15, rax
    jnz .requested_security_failure

    mov r8d, NEBOC_POLICY_DECISION_PERMIT
    xor r9d, r9d
    mov r14d, NEBOC_STATUS_OK
    jmp .finalize

.record_mismatch:
    xor r8d, r8d
    mov r9d, neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
    mov r14d, NEBOC_STATUS_INVALID_SOURCE
    jmp .finalize

.record_not_green:
    xor r8d, r8d
    mov r9, [rsp + NEBOC_POLICY_DIAGNOSTIC_OFFSET]
    test r9, r9
    jnz .record_diagnostic_ready
    mov r9d, neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
.record_diagnostic_ready:
    mov r14d, NEBOC_STATUS_INVALID_SOURCE
    jmp .finalize

.requested_type_failure:
    xor r8d, r8d
    mov r9d, neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
    mov r14d, NEBOC_STATUS_INVALID_SOURCE
    jmp .finalize

.requested_security_failure:
    xor r8d, r8d
    mov r9d, neboc_effects_capabilities_e_politicas_DIAG_SECURITY_driver_cli_linux_x86_64
    mov r14d, NEBOC_STATUS_INVALID_SOURCE

.finalize:
    ; Canonical, redacted event preimage:
    ; [policy audit hash, requested mask, runtime decision, diagnostic].
    mov rax, [rsp + NEBOC_POLICY_AUDIT_HASH_OFFSET]
    mov [rsp], rax
    mov [rsp + 8], r15
    mov [rsp + 16], r8
    mov [rsp + 24], r9

    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r11, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.event_hash_loop:
    cmp rcx, NEBOC_POLICY_RUNTIME_EVENT_HASHED_BYTES
    jae .event_hash_done
    movzx edx, byte [rsp + rcx]
    xor rax, rdx
    imul rax, r11
    inc rcx
    jmp .event_hash_loop
.event_hash_done:

    ; Publish a complete deterministic result only after every check and hash.
    mov [r12 + NEBOC_POLICY_RUNTIME_DECISION_OFFSET], r8
    mov [r12 + NEBOC_POLICY_RUNTIME_DIAGNOSTIC_OFFSET], r9
    mov [r12 + NEBOC_POLICY_RUNTIME_EVENT_HASH_OFFSET], rax
    mov qword [r12 + NEBOC_POLICY_RUNTIME_ALLOCATIONS_OFFSET], \
        NEBOC_POLICY_RUNTIME_ALLOCATION_NONE

    mov eax, r14d
    add rsp, NEBOC_POLICY_REQUEST_SIZE
    pop r15
    pop r14
    pop r13
    pop r12
    cld
    ret

.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
