; PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-PF001 native privacy/zero-trust metadata contract tests
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/privacy/privacy_policy.inc"

%if NEBOC_PRIVACY_REQUEST_QWORDS != 35
    %error "privacidade_dados_sensiveis_e_zero_trust privacy record must remain 35 qwords"
%endif
%if NEBOC_PRIVACY_REQUEST_SIZE != 280
    %error "privacidade_dados_sensiveis_e_zero_trust privacy record must remain 280 bytes"
%endif
%if NEBOC_PRIVACY_HASHED_BYTES != 264
    %error "privacidade_dados_sensiveis_e_zero_trust privacy hash domain must remain q0..q32"
%endif

extern neboc_privacy_evaluate
extern neboc_host_process_exit

section .bss align=16
request: resb NEBOC_PRIVACY_REQUEST_SIZE
saved_hash: resq 1

section .text

clear_request:
    lea rdi, [rel request]
    mov ecx, NEBOC_PRIVACY_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    ret

; A pure authenticated effects_capabilities_e_politicas policy.  effects_capabilities_e_politicas permits the empty effect set without
; an audit id; individual privacidade_dados_sensiveis_e_zero_trust gates still require audit/purpose when needed.
prepare_public:
    call clear_request
    mov qword [rel request + NEBOC_POLICY_PERMIT_OFFSET], 22
    mov qword [rel request + NEBOC_PRIVACY_RETENTION_LIMIT_OFFSET], 10
    ret

prepare_console_policy:
    call clear_request
    mov qword [rel request + NEBOC_POLICY_DIRECT_EFFECTS_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    mov qword [rel request + NEBOC_POLICY_DECLARED_EFFECTS_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    mov qword [rel request + NEBOC_POLICY_CAPABILITIES_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    mov qword [rel request + NEBOC_POLICY_ALLOW_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    mov qword [rel request + NEBOC_POLICY_BUDGET_OFFSET], 1
    mov qword [rel request + NEBOC_POLICY_TRUST_OFFSET], NEBOC_TRUST_PUBLIC
    mov qword [rel request + NEBOC_POLICY_AUDIT_ID_OFFSET], 2201
    mov qword [rel request + NEBOC_POLICY_PERMIT_OFFSET], 22
    mov qword [rel request + NEBOC_PRIVACY_RETENTION_LIMIT_OFFSET], 10
    ret

prepare_personal_preserve:
    call prepare_public
    mov qword [rel request + NEBOC_PRIVACY_DIRECT_LABELS_OFFSET], NEBOC_LABEL_PERSONAL
    mov qword [rel request + NEBOC_PRIVACY_SINK_CLEARANCE_OFFSET], NEBOC_LABEL_PERSONAL
    mov qword [rel request + NEBOC_PRIVACY_SOURCE_TRUST_OFFSET], NEBOC_TRUST_RESTRICTED
    mov qword [rel request + NEBOC_PRIVACY_TARGET_TRUST_OFFSET], NEBOC_TRUST_RESTRICTED
    ret

prepare_secret_redact_console:
    call prepare_console_policy
    mov qword [rel request + NEBOC_PRIVACY_DIRECT_LABELS_OFFSET], NEBOC_LABEL_SECRET
    mov qword [rel request + NEBOC_PRIVACY_REDACTION_MASK_OFFSET], NEBOC_LABEL_SECRET
    mov qword [rel request + NEBOC_PRIVACY_TRANSITION_OFFSET], NEBOC_TRANSITION_REDACT
    mov qword [rel request + NEBOC_PRIVACY_SOURCE_TRUST_OFFSET], NEBOC_TRUST_SECRET
    mov qword [rel request + NEBOC_PRIVACY_TARGET_TRUST_OFFSET], NEBOC_TRUST_PUBLIC
    mov qword [rel request + NEBOC_PRIVACY_RETENTION_ELAPSED_OFFSET], 1
    mov qword [rel request + NEBOC_PRIVACY_PURPOSE_ID_OFFSET], 2202
    mov qword [rel request + NEBOC_PRIVACY_SINK_EFFECT_MASK_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    ret

evaluate_request:
    lea rdi, [rel request]
    jmp neboc_privacy_evaluate

hash_oracle:
    lea rsi, [rel request]
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.loop:
    cmp rcx, NEBOC_PRIVACY_HASHED_BYTES
    jae .done
    movzx edx, byte [rsi + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .loop
.done:
    ret

assert_type_failure:
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel request + NEBOC_PRIVACY_DIAGNOSTIC_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_TYPE_codegen_privacy_x86_64
    jne fail
    cmp qword [rel request + NEBOC_PRIVACY_DECISION_OFFSET], NEBOC_PRIVACY_DECISION_DENY
    jne fail
    cmp qword [rel request + NEBOC_PRIVACY_METADATA_HASH_OFFSET], 0
    je fail
    mov r10, [rel request + NEBOC_PRIVACY_METADATA_HASH_OFFSET]
    call hash_oracle
    cmp rax, r10
    jne fail
    ret

assert_security_failure:
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel request + NEBOC_PRIVACY_DIAGNOSTIC_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_SECURITY_driver_cli_linux_x86_64
    jne fail
    cmp qword [rel request + NEBOC_PRIVACY_DECISION_OFFSET], NEBOC_PRIVACY_DECISION_DENY
    jne fail
    cmp qword [rel request + NEBOC_PRIVACY_METADATA_HASH_OFFSET], 0
    je fail
    mov r10, [rel request + NEBOC_PRIVACY_METADATA_HASH_OFFSET]
    call hash_oracle
    cmp rax, r10
    jne fail
    ret

assert_runtime_failure:
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel request + NEBOC_PRIVACY_DIAGNOSTIC_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_RUNTIME_driver_cli_linux_x86_64
    jne fail
    cmp qword [rel request + NEBOC_PRIVACY_DECISION_OFFSET], NEBOC_PRIVACY_DECISION_DENY
    jne fail
    mov r10, [rel request + NEBOC_PRIVACY_METADATA_HASH_OFFSET]
    test r10, r10
    jz fail
    call hash_oracle
    cmp rax, r10
    jne fail
    ret

global _start
_start:
    ; 1. Null and misaligned pointers reject without touching caller memory.
    xor edi, edi
    call neboc_privacy_evaluate
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    call clear_request
    mov rax, 0x1122334455667788
    mov [rel request + NEBOC_PRIVACY_METADATA_HASH_OFFSET], rax
    lea rdi, [rel request + 1]
    call neboc_privacy_evaluate
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    mov rax, [rel request + NEBOC_PRIVACY_METADATA_HASH_OFFSET]
    mov rdx, 0x1122334455667788
    cmp rax, rdx
    jne fail

    ; 2. Empty/public metadata permits under a re-evaluated pure effects_capabilities_e_politicas policy.
    call prepare_public
    call evaluate_request
    test eax, eax
    jnz fail
    cmp qword [rel request + NEBOC_PRIVACY_INFERRED_LABELS_OFFSET], 0
    jne fail
    cmp qword [rel request + NEBOC_PRIVACY_EFFECTIVE_LABELS_OFFSET], 0
    jne fail
    cmp qword [rel request + NEBOC_PRIVACY_DIAGNOSTIC_OFFSET], 0
    jne fail
    cmp qword [rel request + NEBOC_PRIVACY_DECISION_OFFSET], NEBOC_PRIVACY_DECISION_PERMIT
    jne fail
    cmp qword [rel request + NEBOC_PRIVACY_PROVENANCE_FLAGS_OFFSET], 53
    jne fail

    ; 3. Direct and transitive labels propagate by set union.
    call prepare_public
    mov qword [rel request + NEBOC_PRIVACY_DIRECT_LABELS_OFFSET], NEBOC_LABEL_PERSONAL
    mov qword [rel request + NEBOC_PRIVACY_CALLEE_LABELS_OFFSET], NEBOC_LABEL_SENSITIVE
    mov qword [rel request + NEBOC_PRIVACY_SINK_CLEARANCE_OFFSET], NEBOC_LABEL_PERSONAL | NEBOC_LABEL_SENSITIVE
    mov qword [rel request + NEBOC_PRIVACY_SOURCE_TRUST_OFFSET], NEBOC_TRUST_RESTRICTED
    mov qword [rel request + NEBOC_PRIVACY_TARGET_TRUST_OFFSET], NEBOC_TRUST_RESTRICTED
    call evaluate_request
    test eax, eax
    jnz fail
    cmp qword [rel request + NEBOC_PRIVACY_INFERRED_LABELS_OFFSET], 6
    jne fail
    cmp qword [rel request + NEBOC_PRIVACY_EFFECTIVE_LABELS_OFFSET], 6
    jne fail

    ; 4. PRESERVE may move only to equal or greater trust.
    call prepare_public
    mov qword [rel request + NEBOC_PRIVACY_DIRECT_LABELS_OFFSET], NEBOC_LABEL_INTERNAL
    mov qword [rel request + NEBOC_PRIVACY_SINK_CLEARANCE_OFFSET], NEBOC_LABEL_INTERNAL
    mov qword [rel request + NEBOC_PRIVACY_SOURCE_TRUST_OFFSET], NEBOC_TRUST_INTERNAL
    mov qword [rel request + NEBOC_PRIVACY_TARGET_TRUST_OFFSET], NEBOC_TRUST_RESTRICTED
    call evaluate_request
    test eax, eax
    jnz fail
    test qword [rel request + NEBOC_PRIVACY_PROVENANCE_FLAGS_OFFSET], NEBOC_PROVENANCE_TRUST_TRANSITION
    jz fail

    ; 5. Full secret redaction authorizes a public observable sink.
    call prepare_secret_redact_console
    call evaluate_request
    test eax, eax
    jnz fail
    cmp qword [rel request + NEBOC_PRIVACY_INFERRED_LABELS_OFFSET], NEBOC_LABEL_SECRET
    jne fail
    cmp qword [rel request + NEBOC_PRIVACY_EFFECTIVE_LABELS_OFFSET], 0
    jne fail
    cmp qword [rel request + NEBOC_PRIVACY_PROVENANCE_FLAGS_OFFSET], 63
    jne fail

    ; 6. Selective redaction removes only the requested subset.
    call prepare_public
    mov qword [rel request + NEBOC_POLICY_AUDIT_ID_OFFSET], 2203
    mov qword [rel request + NEBOC_PRIVACY_DIRECT_LABELS_OFFSET], NEBOC_LABEL_PERSONAL | NEBOC_LABEL_SENSITIVE
    mov qword [rel request + NEBOC_PRIVACY_REDACTION_MASK_OFFSET], NEBOC_LABEL_PERSONAL
    mov qword [rel request + NEBOC_PRIVACY_SINK_CLEARANCE_OFFSET], NEBOC_LABEL_SENSITIVE
    mov qword [rel request + NEBOC_PRIVACY_TRANSITION_OFFSET], NEBOC_TRANSITION_REDACT
    mov qword [rel request + NEBOC_PRIVACY_SOURCE_TRUST_OFFSET], NEBOC_TRUST_RESTRICTED
    mov qword [rel request + NEBOC_PRIVACY_TARGET_TRUST_OFFSET], NEBOC_TRUST_RESTRICTED
    mov qword [rel request + NEBOC_PRIVACY_PURPOSE_ID_OFFSET], 2204
    call evaluate_request
    test eax, eax
    jnz fail
    cmp qword [rel request + NEBOC_PRIVACY_EFFECTIVE_LABELS_OFFSET], NEBOC_LABEL_SENSITIVE
    jne fail

    ; 7. A labelled sink permits only with effects_capabilities_e_politicas effect proof and clearance.
    call prepare_console_policy
    mov qword [rel request + NEBOC_PRIVACY_DIRECT_LABELS_OFFSET], NEBOC_LABEL_PERSONAL
    mov qword [rel request + NEBOC_PRIVACY_SINK_CLEARANCE_OFFSET], NEBOC_LABEL_PERSONAL
    mov qword [rel request + NEBOC_PRIVACY_SOURCE_TRUST_OFFSET], NEBOC_TRUST_RESTRICTED
    mov qword [rel request + NEBOC_PRIVACY_TARGET_TRUST_OFFSET], NEBOC_TRUST_RESTRICTED
    mov qword [rel request + NEBOC_PRIVACY_PURPOSE_ID_OFFSET], 2205
    mov qword [rel request + NEBOC_PRIVACY_SINK_EFFECT_MASK_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    call evaluate_request
    test eax, eax
    jnz fail

    ; 8. Unknown label and clearance bits are TYPE first causes.
    call prepare_public
    mov qword [rel request + NEBOC_PRIVACY_DIRECT_LABELS_OFFSET], 0x10
    call evaluate_request
    call assert_type_failure
    call prepare_public
    mov qword [rel request + NEBOC_PRIVACY_SINK_CLEARANCE_OFFSET], 0x20
    call evaluate_request
    call assert_type_failure

    ; 9. Transition, trust and retention domains are independently bounded.
    call prepare_public
    mov qword [rel request + NEBOC_PRIVACY_TRANSITION_OFFSET], 2
    call evaluate_request
    call assert_type_failure
    call prepare_public
    mov qword [rel request + NEBOC_PRIVACY_SOURCE_TRUST_OFFSET], 4
    call evaluate_request
    call assert_type_failure
    call prepare_public
    mov qword [rel request + NEBOC_PRIVACY_RETENTION_LIMIT_OFFSET], 65536
    call evaluate_request
    call assert_type_failure

    ; 10. Unknown effects_capabilities_e_politicas sink-effect bits are a privacidade_dados_sensiveis_e_zero_trust TYPE failure.
    call prepare_public
    mov qword [rel request + NEBOC_PRIVACY_SINK_EFFECT_MASK_OFFSET], 0x800
    call evaluate_request
    call assert_type_failure

    ; 11. PRESERVE cannot carry a hidden redaction mask.
    call prepare_personal_preserve
    mov qword [rel request + NEBOC_PRIVACY_REDACTION_MASK_OFFSET], NEBOC_LABEL_PERSONAL
    call evaluate_request
    call assert_type_failure

    ; 12. REDACT requires a non-empty subset of inferred labels.
    call prepare_personal_preserve
    mov qword [rel request + NEBOC_PRIVACY_TRANSITION_OFFSET], NEBOC_TRANSITION_REDACT
    call evaluate_request
    call assert_type_failure
    call prepare_personal_preserve
    mov qword [rel request + NEBOC_PRIVACY_TRANSITION_OFFSET], NEBOC_TRANSITION_REDACT
    mov qword [rel request + NEBOC_PRIVACY_REDACTION_MASK_OFFSET], NEBOC_LABEL_SECRET
    call evaluate_request
    call assert_type_failure

    ; 13. effects_capabilities_e_politicas TYPE failure is re-evaluated and mapped, never trusted stale data.
    call prepare_public
    mov qword [rel request + NEBOC_POLICY_DIRECT_EFFECTS_OFFSET], 0x800
    mov qword [rel request + NEBOC_POLICY_DECISION_OFFSET], NEBOC_POLICY_DECISION_PERMIT
    mov qword [rel request + NEBOC_POLICY_AUDIT_HASH_OFFSET], -1
    call evaluate_request
    call assert_type_failure
    cmp qword [rel request + NEBOC_POLICY_DECISION_OFFSET], NEBOC_POLICY_DECISION_DENY
    jne fail

    ; 14. effects_capabilities_e_politicas deny-by-default maps to privacidade_dados_sensiveis_e_zero_trust SECURITY.
    call prepare_console_policy
    mov qword [rel request + NEBOC_POLICY_ALLOW_OFFSET], 0
    mov qword [rel request + NEBOC_POLICY_DECISION_OFFSET], NEBOC_POLICY_DECISION_PERMIT
    call evaluate_request
    call assert_security_failure
    cmp qword [rel request + NEBOC_PRIVACY_EFFECTIVE_LABELS_OFFSET], 0
    jne fail
    test qword [rel request + NEBOC_PRIVACY_PROVENANCE_FLAGS_OFFSET], NEBOC_PROVENANCE_REDACTED
    jnz fail

    ; 15. Source trust must cover every inferred privacy label.
    call prepare_personal_preserve
    mov qword [rel request + NEBOC_PRIVACY_SOURCE_TRUST_OFFSET], NEBOC_TRUST_INTERNAL
    call evaluate_request
    call assert_security_failure
    cmp qword [rel request + NEBOC_PRIVACY_EFFECTIVE_LABELS_OFFSET], 0
    jne fail
    test qword [rel request + NEBOC_PRIVACY_PROVENANCE_FLAGS_OFFSET], NEBOC_PROVENANCE_REDACTED
    jnz fail

    ; 16. Redaction requires both purpose and audit identity.
    call prepare_personal_preserve
    mov qword [rel request + NEBOC_POLICY_AUDIT_ID_OFFSET], 2206
    mov qword [rel request + NEBOC_PRIVACY_REDACTION_MASK_OFFSET], NEBOC_LABEL_PERSONAL
    mov qword [rel request + NEBOC_PRIVACY_TRANSITION_OFFSET], NEBOC_TRANSITION_REDACT
    mov qword [rel request + NEBOC_PRIVACY_TARGET_TRUST_OFFSET], NEBOC_TRUST_PUBLIC
    call evaluate_request
    call assert_security_failure
    cmp qword [rel request + NEBOC_PRIVACY_EFFECTIVE_LABELS_OFFSET], 0
    jne fail
    test qword [rel request + NEBOC_PRIVACY_PROVENANCE_FLAGS_OFFSET], NEBOC_PROVENANCE_REDACTED
    jnz fail
    call prepare_personal_preserve
    mov qword [rel request + NEBOC_PRIVACY_REDACTION_MASK_OFFSET], NEBOC_LABEL_PERSONAL
    mov qword [rel request + NEBOC_PRIVACY_TRANSITION_OFFSET], NEBOC_TRANSITION_REDACT
    mov qword [rel request + NEBOC_PRIVACY_TARGET_TRUST_OFFSET], NEBOC_TRUST_PUBLIC
    mov qword [rel request + NEBOC_PRIVACY_PURPOSE_ID_OFFSET], 2207
    call evaluate_request
    call assert_security_failure
    cmp qword [rel request + NEBOC_PRIVACY_EFFECTIVE_LABELS_OFFSET], 0
    jne fail
    test qword [rel request + NEBOC_PRIVACY_PROVENANCE_FLAGS_OFFSET], NEBOC_PROVENANCE_REDACTED
    jnz fail

    ; 17. PRESERVE cannot downgrade a trust zone.
    call prepare_personal_preserve
    mov qword [rel request + NEBOC_PRIVACY_TARGET_TRUST_OFFSET], NEBOC_TRUST_PUBLIC
    call evaluate_request
    call assert_security_failure

    ; 18. Remaining labels must fit target trust after redaction.
    call prepare_public
    mov qword [rel request + NEBOC_POLICY_AUDIT_ID_OFFSET], 2208
    mov qword [rel request + NEBOC_PRIVACY_DIRECT_LABELS_OFFSET], NEBOC_LABEL_PERSONAL | NEBOC_LABEL_SENSITIVE
    mov qword [rel request + NEBOC_PRIVACY_REDACTION_MASK_OFFSET], NEBOC_LABEL_PERSONAL
    mov qword [rel request + NEBOC_PRIVACY_SINK_CLEARANCE_OFFSET], NEBOC_LABEL_SENSITIVE
    mov qword [rel request + NEBOC_PRIVACY_TRANSITION_OFFSET], NEBOC_TRANSITION_REDACT
    mov qword [rel request + NEBOC_PRIVACY_SOURCE_TRUST_OFFSET], NEBOC_TRUST_RESTRICTED
    mov qword [rel request + NEBOC_PRIVACY_TARGET_TRUST_OFFSET], NEBOC_TRUST_PUBLIC
    mov qword [rel request + NEBOC_PRIVACY_PURPOSE_ID_OFFSET], 2209
    call evaluate_request
    call assert_security_failure

    ; 19. Expired retention is a typed recoverable RUNTIME diagnostic.
    call prepare_personal_preserve
    mov qword [rel request + NEBOC_PRIVACY_RETENTION_ELAPSED_OFFSET], 11
    mov qword [rel request + NEBOC_PRIVACY_RETENTION_LIMIT_OFFSET], 10
    call evaluate_request
    call assert_runtime_failure

    ; 20. Sink effect and label clearance are independent fail-closed gates.
    call prepare_personal_preserve
    mov qword [rel request + NEBOC_PRIVACY_SINK_EFFECT_MASK_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    call evaluate_request
    call assert_security_failure
    call prepare_personal_preserve
    mov qword [rel request + NEBOC_PRIVACY_SINK_CLEARANCE_OFFSET], 0
    call evaluate_request
    call assert_security_failure
    cmp qword [rel request + NEBOC_PRIVACY_REJECTED_LABELS_OFFSET], NEBOC_LABEL_PERSONAL
    jne fail
    ; With valid effect proof and clearance, missing purpose is isolated as
    ; the final observable-labelled-sink authorization failure.
    call prepare_console_policy
    mov qword [rel request + NEBOC_PRIVACY_DIRECT_LABELS_OFFSET], NEBOC_LABEL_PERSONAL
    mov qword [rel request + NEBOC_PRIVACY_SINK_CLEARANCE_OFFSET], NEBOC_LABEL_PERSONAL
    mov qword [rel request + NEBOC_PRIVACY_SOURCE_TRUST_OFFSET], NEBOC_TRUST_RESTRICTED
    mov qword [rel request + NEBOC_PRIVACY_TARGET_TRUST_OFFSET], NEBOC_TRUST_RESTRICTED
    mov qword [rel request + NEBOC_PRIVACY_SINK_EFFECT_MASK_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    call evaluate_request
    call assert_security_failure
    cmp qword [rel request + NEBOC_PRIVACY_REJECTED_LABELS_OFFSET], 0
    jne fail

    ; 21. Compound failures lock the exact normative first-cause precedence.
    ; effects_capabilities_e_politicas runtime rejection precedes privacidade_dados_sensiveis_e_zero_trust source-trust rejection.
    call prepare_console_policy
    mov qword [rel request + NEBOC_POLICY_CALLEE_EFFECTS_OFFSET], NEBOC_EFFECT_CONSOLE_READ
    mov qword [rel request + NEBOC_POLICY_DECLARED_EFFECTS_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE | NEBOC_EFFECT_CONSOLE_READ
    mov qword [rel request + NEBOC_POLICY_CAPABILITIES_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE | NEBOC_EFFECT_CONSOLE_READ
    mov qword [rel request + NEBOC_POLICY_ALLOW_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE | NEBOC_EFFECT_CONSOLE_READ
    mov qword [rel request + NEBOC_PRIVACY_DIRECT_LABELS_OFFSET], NEBOC_LABEL_PERSONAL
    mov qword [rel request + NEBOC_PRIVACY_SOURCE_TRUST_OFFSET], NEBOC_TRUST_PUBLIC
    call evaluate_request
    call assert_runtime_failure
    ; Source trust precedes retention expiry.
    call prepare_personal_preserve
    mov qword [rel request + NEBOC_PRIVACY_SOURCE_TRUST_OFFSET], NEBOC_TRUST_INTERNAL
    mov qword [rel request + NEBOC_PRIVACY_RETENTION_ELAPSED_OFFSET], 11
    call evaluate_request
    call assert_security_failure
    ; Retention expiry precedes an unauthenticated sink effect.
    call prepare_personal_preserve
    mov qword [rel request + NEBOC_PRIVACY_RETENTION_ELAPSED_OFFSET], 11
    mov qword [rel request + NEBOC_PRIVACY_SINK_EFFECT_MASK_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    call evaluate_request
    call assert_runtime_failure
    mov rax, [rel request + NEBOC_PRIVACY_METADATA_HASH_OFFSET]
    mov [rel saved_hash], rax
    call evaluate_request
    call assert_runtime_failure
    mov rax, [rel request + NEBOC_PRIVACY_METADATA_HASH_OFFSET]
    cmp rax, [rel saved_hash]
    jne fail
    ; Clearance records the exact leaking labels before observable-auth denial.
    call prepare_console_policy
    mov qword [rel request + NEBOC_PRIVACY_DIRECT_LABELS_OFFSET], NEBOC_LABEL_PERSONAL
    mov qword [rel request + NEBOC_PRIVACY_SOURCE_TRUST_OFFSET], NEBOC_TRUST_RESTRICTED
    mov qword [rel request + NEBOC_PRIVACY_TARGET_TRUST_OFFSET], NEBOC_TRUST_RESTRICTED
    mov qword [rel request + NEBOC_PRIVACY_SINK_EFFECT_MASK_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    call evaluate_request
    call assert_security_failure
    cmp qword [rel request + NEBOC_PRIVACY_REJECTED_LABELS_OFFSET], NEBOC_LABEL_PERSONAL
    jne fail

    ; 22. Stale outputs are overwritten and the q0..q32 hash is exact/stable.
    call prepare_secret_redact_console
    mov qword [rel request + NEBOC_POLICY_INFERRED_EFFECTS_OFFSET], -1
    mov qword [rel request + NEBOC_PRIVACY_INFERRED_LABELS_OFFSET], -1
    mov qword [rel request + NEBOC_PRIVACY_DIAGNOSTIC_OFFSET], -1
    mov qword [rel request + NEBOC_PRIVACY_METADATA_HASH_OFFSET], -1
    mov qword [rel request + NEBOC_PRIVACY_DECISION_OFFSET], -1
    call evaluate_request
    test eax, eax
    jnz fail
    mov rax, [rel request + NEBOC_PRIVACY_METADATA_HASH_OFFSET]
    mov [rel saved_hash], rax
    call hash_oracle
    cmp rax, [rel saved_hash]
    jne fail
    call evaluate_request
    test eax, eax
    jnz fail
    mov rax, [rel request + NEBOC_PRIVACY_METADATA_HASH_OFFSET]
    cmp rax, [rel saved_hash]
    jne fail

    ; 23. SysV callee-saved registers and the clear direction flag survive.
    mov rbx, 0x1111222233334444
    mov rbp, 0x2222333344445555
    mov r12, 0x3333444455556666
    mov r13, 0x4444555566667777
    mov r14, 0x5555666677778888
    mov r15, 0x6666777788889999
    std
    lea rdi, [rel request]
    call neboc_privacy_evaluate
    test eax, eax
    jnz fail
    pushfq
    pop rax
    test rax, 1 << 10
    jnz fail
    mov rax, 0x1111222233334444
    cmp rbx, rax
    jne fail
    mov rax, 0x2222333344445555
    cmp rbp, rax
    jne fail
    mov rax, 0x3333444455556666
    cmp r12, rax
    jne fail
    mov rax, 0x4444555566667777
    cmp r13, rax
    jne fail
    mov rax, 0x5555666677778888
    cmp r14, rax
    jne fail
    mov rax, 0x6666777788889999
    cmp r15, rax
    jne fail

success:
    xor edi, edi
    jmp neboc_host_process_exit
fail:
    cld
    mov edi, 1
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
