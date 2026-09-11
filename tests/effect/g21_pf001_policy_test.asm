; EFFECTS-CAPABILITIES-E-POLITICAS-PF001 native policy contract, security and determinism tests
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/effect/effect_classifier.inc"
%include "compiler/semantic/effect/effect_policy.inc"

%if NEBOC_POLICY_REQUEST_QWORDS != 17
    %error "effects_capabilities_e_politicas policy request must remain 17 qwords"
%endif
%if NEBOC_POLICY_REQUEST_SIZE != 136
    %error "effects_capabilities_e_politicas policy request must remain 136 bytes"
%endif

extern neboc_policy_evaluate
extern neboc_policy_mask_from_legacy_effect_id
extern neboc_host_process_exit

section .bss align=16
request: resb NEBOC_POLICY_REQUEST_SIZE
request_copy: resb NEBOC_POLICY_REQUEST_SIZE
saved_hash: resq 1

section .text

clear_request:
    lea rdi, [rel request]
    mov ecx, NEBOC_POLICY_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    ret

clear_request_copy:
    lea rdi, [rel request_copy]
    mov ecx, NEBOC_POLICY_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    ret

prepare_console:
    call clear_request
    mov qword [rel request + NEBOC_POLICY_DIRECT_EFFECTS_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    mov qword [rel request + NEBOC_POLICY_DECLARED_EFFECTS_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    mov qword [rel request + NEBOC_POLICY_CAPABILITIES_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    mov qword [rel request + NEBOC_POLICY_ALLOW_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    mov qword [rel request + NEBOC_POLICY_BUDGET_OFFSET], 1
    mov qword [rel request + NEBOC_POLICY_TRUST_OFFSET], NEBOC_TRUST_PUBLIC
    mov qword [rel request + NEBOC_POLICY_AUDIT_ID_OFFSET], 21
    mov qword [rel request + NEBOC_POLICY_PERMIT_OFFSET], 21
    ret

prepare_console_copy:
    call clear_request_copy
    mov qword [rel request_copy + NEBOC_POLICY_DIRECT_EFFECTS_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    mov qword [rel request_copy + NEBOC_POLICY_DECLARED_EFFECTS_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    mov qword [rel request_copy + NEBOC_POLICY_CAPABILITIES_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    mov qword [rel request_copy + NEBOC_POLICY_ALLOW_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    mov qword [rel request_copy + NEBOC_POLICY_BUDGET_OFFSET], 1
    mov qword [rel request_copy + NEBOC_POLICY_TRUST_OFFSET], NEBOC_TRUST_PUBLIC
    mov qword [rel request_copy + NEBOC_POLICY_AUDIT_ID_OFFSET], 21
    mov qword [rel request_copy + NEBOC_POLICY_PERMIT_OFFSET], 21
    ret

prepare_combined:
    call clear_request
    mov qword [rel request + NEBOC_POLICY_DIRECT_EFFECTS_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    mov qword [rel request + NEBOC_POLICY_CALLEE_EFFECTS_OFFSET], NEBOC_EFFECT_CONSOLE_READ
    mov qword [rel request + NEBOC_POLICY_DECLARED_EFFECTS_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE | NEBOC_EFFECT_CONSOLE_READ
    mov qword [rel request + NEBOC_POLICY_CAPABILITIES_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE | NEBOC_EFFECT_CONSOLE_READ
    mov qword [rel request + NEBOC_POLICY_ALLOW_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE | NEBOC_EFFECT_CONSOLE_READ
    mov qword [rel request + NEBOC_POLICY_BUDGET_OFFSET], 2
    mov qword [rel request + NEBOC_POLICY_TRUST_OFFSET], NEBOC_TRUST_PUBLIC
    mov qword [rel request + NEBOC_POLICY_AUDIT_ID_OFFSET], 22
    mov qword [rel request + NEBOC_POLICY_PERMIT_OFFSET], 22
    ret

prepare_fs_write:
    call clear_request
    mov qword [rel request + NEBOC_POLICY_DIRECT_EFFECTS_OFFSET], NEBOC_EFFECT_FS_WRITE
    mov qword [rel request + NEBOC_POLICY_DECLARED_EFFECTS_OFFSET], NEBOC_EFFECT_FS_WRITE
    mov qword [rel request + NEBOC_POLICY_CAPABILITIES_OFFSET], NEBOC_EFFECT_FS_WRITE
    mov qword [rel request + NEBOC_POLICY_ALLOW_OFFSET], NEBOC_EFFECT_FS_WRITE
    mov qword [rel request + NEBOC_POLICY_BUDGET_OFFSET], 1
    mov qword [rel request + NEBOC_POLICY_TRUST_OFFSET], NEBOC_TRUST_INTERNAL
    mov qword [rel request + NEBOC_POLICY_AUDIT_ID_OFFSET], 23
    mov qword [rel request + NEBOC_POLICY_PERMIT_OFFSET], 23
    ret

evaluate_request:
    lea rdi, [rel request]
    jmp neboc_policy_evaluate

; Compute the normative FNV-1a64 oracle over q0..q14 of request.
hash_request_oracle:
    lea rsi, [rel request]
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.loop:
    cmp rcx, NEBOC_POLICY_HASHED_BYTES
    jae .done
    movzx edx, byte [rsi + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .loop
.done:
    ret

global _start
_start:
    ; 1. Null and misaligned requests are rejected without writes.
    xor edi, edi
    call neboc_policy_evaluate
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    call clear_request
    mov rax, 0x1122334455667788
    mov [rel request + NEBOC_POLICY_AUDIT_HASH_OFFSET], rax
    lea rdi, [rel request + 1]
    call neboc_policy_evaluate
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    mov rax, [rel request + NEBOC_POLICY_AUDIT_HASH_OFFSET]
    mov rdx, 0x1122334455667788
    cmp rax, rdx
    jne fail

    ; 2. The v0.1 four-state classifier maps exactly into the effects_capabilities_e_politicas set.
    mov edi, NEBOC_EFFECT_ID_PURE
    call neboc_policy_mask_from_legacy_effect_id
    test rax, rax
    jnz fail
    mov edi, NEBOC_EFFECT_ID_CONSOLE
    call neboc_policy_mask_from_legacy_effect_id
    cmp rax, NEBOC_EFFECT_CONSOLE_WRITE
    jne fail
    mov edi, NEBOC_EFFECT_ID_SCAN
    call neboc_policy_mask_from_legacy_effect_id
    cmp rax, NEBOC_EFFECT_CONSOLE_READ
    jne fail
    mov edi, NEBOC_EFFECT_ID_CONSOLE_SCAN
    call neboc_policy_mask_from_legacy_effect_id
    cmp rax, NEBOC_EFFECT_CONSOLE_WRITE | NEBOC_EFFECT_CONSOLE_READ
    jne fail
    xor edi, edi
    call neboc_policy_mask_from_legacy_effect_id
    cmp rax, -1
    jne fail
    mov edi, 5
    call neboc_policy_mask_from_legacy_effect_id
    cmp rax, -1
    jne fail

    ; 3. Pure deny-by-default proof is valid because it requests no effect.
    call clear_request
    mov qword [rel request + NEBOC_POLICY_PERMIT_OFFSET], 7
    call evaluate_request
    test eax, eax
    jnz fail
    cmp qword [rel request + NEBOC_POLICY_INFERRED_EFFECTS_OFFSET], 0
    jne fail
    cmp qword [rel request + NEBOC_POLICY_COST_OFFSET], 0
    jne fail
    cmp qword [rel request + NEBOC_POLICY_DIAGNOSTIC_OFFSET], 0
    jne fail
    cmp qword [rel request + NEBOC_POLICY_DECISION_OFFSET], NEBOC_POLICY_DECISION_PERMIT
    jne fail
    cmp qword [rel request + NEBOC_POLICY_AUDIT_HASH_OFFSET], 0
    je fail

    ; 4. Direct console proof permits with one inferred effect and one cost.
    call prepare_console
    call evaluate_request
    test eax, eax
    jnz fail
    cmp qword [rel request + NEBOC_POLICY_INFERRED_EFFECTS_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    jne fail
    cmp qword [rel request + NEBOC_POLICY_COST_OFFSET], 1
    jne fail
    cmp qword [rel request + NEBOC_POLICY_DECISION_OFFSET], NEBOC_POLICY_DECISION_PERMIT
    jne fail

    ; 5. Transitive callee union is observable and uses portable popcount.
    call prepare_combined
    call evaluate_request
    test eax, eax
    jnz fail
    cmp qword [rel request + NEBOC_POLICY_INFERRED_EFFECTS_OFFSET], 3
    jne fail
    cmp qword [rel request + NEBOC_POLICY_COST_OFFSET], 2
    jne fail

    ; 6. Inferred effect absent from the declaration is a typed failure.
    call prepare_console
    mov qword [rel request + NEBOC_POLICY_DECLARED_EFFECTS_OFFSET], 0
    mov qword [rel request + NEBOC_POLICY_CAPABILITIES_OFFSET], 0
    mov qword [rel request + NEBOC_POLICY_ALLOW_OFFSET], 0
    call evaluate_request
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel request + NEBOC_POLICY_MISSING_EFFECTS_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    jne fail
    cmp qword [rel request + NEBOC_POLICY_DIAGNOSTIC_OFFSET], neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
    jne fail
    cmp qword [rel request + NEBOC_POLICY_DECISION_OFFSET], NEBOC_POLICY_DECISION_DENY
    jne fail

    ; 7. Declaration without capability records q11 and is denied.
    call prepare_console
    mov qword [rel request + NEBOC_POLICY_CAPABILITIES_OFFSET], 0
    call evaluate_request
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel request + NEBOC_POLICY_MISSING_EFFECTS_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    jne fail
    cmp qword [rel request + NEBOC_POLICY_DIAGNOSTIC_OFFSET], neboc_effects_capabilities_e_politicas_DIAG_SECURITY_driver_cli_linux_x86_64
    jne fail

    ; 8. Empty allow is deny-by-default and records q12.
    call prepare_console
    mov qword [rel request + NEBOC_POLICY_ALLOW_OFFSET], 0
    call evaluate_request
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel request + NEBOC_POLICY_REJECTED_EFFECTS_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    jne fail
    cmp qword [rel request + NEBOC_POLICY_DIAGNOSTIC_OFFSET], neboc_effects_capabilities_e_politicas_DIAG_SECURITY_driver_cli_linux_x86_64
    jne fail

    ; 9. Explicit deny wins even when capability and allow are present.
    call prepare_console
    mov qword [rel request + NEBOC_POLICY_DENY_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    call evaluate_request
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel request + NEBOC_POLICY_REJECTED_EFFECTS_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    jne fail

    ; 10. fs_write needs restricted trust; internal rejects, restricted permits.
    call prepare_fs_write
    call evaluate_request
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel request + NEBOC_POLICY_REJECTED_EFFECTS_OFFSET], NEBOC_EFFECT_FS_WRITE
    jne fail
    call prepare_fs_write
    mov qword [rel request + NEBOC_POLICY_TRUST_OFFSET], NEBOC_TRUST_RESTRICTED
    call evaluate_request
    test eax, eax
    jnz fail

    ; 11. Compile-time budget overflow uses RUNTIME-005, not a panic.
    call prepare_combined
    mov qword [rel request + NEBOC_POLICY_BUDGET_OFFSET], 1
    call evaluate_request
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel request + NEBOC_POLICY_DIAGNOSTIC_OFFSET], neboc_effects_capabilities_e_politicas_DIAG_RUNTIME_driver_cli_linux_x86_64
    jne fail
    cmp qword [rel request + NEBOC_POLICY_COST_OFFSET], 2
    jne fail

    ; 12. Any inferred effect requires a non-zero redacted audit identity.
    call prepare_console
    mov qword [rel request + NEBOC_POLICY_AUDIT_ID_OFFSET], 0
    call evaluate_request
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel request + NEBOC_POLICY_DIAGNOSTIC_OFFSET], neboc_effects_capabilities_e_politicas_DIAG_SECURITY_driver_cli_linux_x86_64
    jne fail

    ; 13. Unknown bits and invalid scalar ranges are TYPE-003.  Derived fields
    ; are cleared before each early validation failure.
    call prepare_console
    mov rax, 0x8000000000000000
    mov [rel request + NEBOC_POLICY_DIRECT_EFFECTS_OFFSET], rax
    mov qword [rel request + NEBOC_POLICY_INFERRED_EFFECTS_OFFSET], -1
    mov qword [rel request + NEBOC_POLICY_DECISION_OFFSET], -1
    call evaluate_request
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel request + NEBOC_POLICY_INFERRED_EFFECTS_OFFSET], 0
    jne fail
    cmp qword [rel request + NEBOC_POLICY_DIAGNOSTIC_OFFSET], neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
    jne fail
    cmp qword [rel request + NEBOC_POLICY_DECISION_OFFSET], 0
    jne fail
    cmp qword [rel request + NEBOC_POLICY_AUDIT_HASH_OFFSET], 0
    je fail
    call prepare_console
    mov qword [rel request + NEBOC_POLICY_TRUST_OFFSET], 4
    call evaluate_request
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel request + NEBOC_POLICY_DIAGNOSTIC_OFFSET], neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
    jne fail
    call prepare_console
    mov qword [rel request + NEBOC_POLICY_BUDGET_OFFSET], 65536
    call evaluate_request
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    call prepare_console
    mov qword [rel request + NEBOC_POLICY_PERMIT_OFFSET], 256
    call evaluate_request
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail

    ; 14. The bytewise FNV oracle matches, identical metadata is stable, and
    ; changing an audit ID changes the hash without recording payload bytes.
    call prepare_console
    call evaluate_request
    test eax, eax
    jnz fail
    mov rax, [rel request + NEBOC_POLICY_AUDIT_HASH_OFFSET]
    mov [rel saved_hash], rax
    call hash_request_oracle
    cmp rax, [rel saved_hash]
    jne fail
    call prepare_console_copy
    lea rdi, [rel request_copy]
    call neboc_policy_evaluate
    test eax, eax
    jnz fail
    mov rax, [rel request_copy + NEBOC_POLICY_AUDIT_HASH_OFFSET]
    cmp rax, [rel saved_hash]
    jne fail
    call prepare_console
    mov qword [rel request + NEBOC_POLICY_AUDIT_ID_OFFSET], 24
    call evaluate_request
    test eax, eax
    jnz fail
    mov rax, [rel request + NEBOC_POLICY_AUDIT_HASH_OFFSET]
    cmp rax, [rel saved_hash]
    je fail

    ; 15. The evaluator preserves every SysV callee-saved register and clears
    ; DF on return, even when the caller enters with DF set.
    call prepare_console
    mov rbx, 0x11111111
    mov rbp, 0x22222222
    mov r12, 0x33333333
    mov r13, 0x44444444
    mov r14, 0x55555555
    mov r15, 0x66666666
    std
    call evaluate_request
    test eax, eax
    jnz fail
    cmp rbx, 0x11111111
    jne fail
    cmp rbp, 0x22222222
    jne fail
    cmp r12, 0x33333333
    jne fail
    cmp r13, 0x44444444
    jne fail
    cmp r14, 0x55555555
    jne fail
    cmp r15, 0x66666666
    jne fail
    pushfq
    pop rax
    test rax, 1 << 10
    jnz fail

pass:
    xor edi, edi
    jmp neboc_host_process_exit

fail:
    cld
    mov edi, 1
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
