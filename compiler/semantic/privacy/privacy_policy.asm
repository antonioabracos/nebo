; Nebo Assembly — PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-PF001 deterministic privacy/zero-trust metadata core
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/privacy/privacy_policy.inc"

extern neboc_policy_evaluate

section .text

; rdi = aligned pointer to a 35-qword request/result
; eax = NEBOC_STATUS_*
;
; No field is a payload or a pointer.  q0..q16 are re-evaluated by the effects_capabilities_e_politicas
; policy owner; a caller-provided decision/hash is never trusted.  Null and
; misaligned pointers are rejected without writes.  All other failures are
; fail-closed and leave deterministic metadata plus a privacidade_dados_sensiveis_e_zero_trust diagnostic.
NEBOC_ABI_FUNCTION neboc_privacy_evaluate
    test rdi, rdi
    jz .invalid_argument
    test rdi, NEBOC_PRIVACY_ALIGNMENT - 1
    jnz .invalid_argument

    push r12
    mov r12, rdi

    ; Clear both embedded effects_capabilities_e_politicas outputs and all privacidade_dados_sensiveis_e_zero_trust outputs before validating
    ; caller inputs.  This makes stale caller state unobservable on failure.
    mov qword [r12 + NEBOC_POLICY_INFERRED_EFFECTS_OFFSET], 0
    mov qword [r12 + NEBOC_POLICY_MISSING_EFFECTS_OFFSET], 0
    mov qword [r12 + NEBOC_POLICY_REJECTED_EFFECTS_OFFSET], 0
    mov qword [r12 + NEBOC_POLICY_COST_OFFSET], 0
    mov qword [r12 + NEBOC_POLICY_DIAGNOSTIC_OFFSET], 0
    mov qword [r12 + NEBOC_POLICY_AUDIT_HASH_OFFSET], 0
    mov qword [r12 + NEBOC_POLICY_DECISION_OFFSET], 0
    mov qword [r12 + NEBOC_PRIVACY_INFERRED_LABELS_OFFSET], 0
    mov qword [r12 + NEBOC_PRIVACY_EFFECTIVE_LABELS_OFFSET], 0
    mov qword [r12 + NEBOC_PRIVACY_REJECTED_LABELS_OFFSET], 0
    mov qword [r12 + NEBOC_PRIVACY_PROVENANCE_FLAGS_OFFSET], 0
    mov qword [r12 + NEBOC_PRIVACY_DIAGNOSTIC_OFFSET], 0
    mov qword [r12 + NEBOC_PRIVACY_METADATA_HASH_OFFSET], 0
    mov qword [r12 + NEBOC_PRIVACY_DECISION_OFFSET], 0

    ; Validate every bounded privacidade_dados_sensiveis_e_zero_trust input before policy evaluation or publication
    ; of derived privacy state.
    mov rax, [r12 + NEBOC_PRIVACY_DIRECT_LABELS_OFFSET]
    or rax, [r12 + NEBOC_PRIVACY_CALLEE_LABELS_OFFSET]
    or rax, [r12 + NEBOC_PRIVACY_REDACTION_MASK_OFFSET]
    or rax, [r12 + NEBOC_PRIVACY_SINK_CLEARANCE_OFFSET]
    and rax, ~NEBOC_LABEL_MASK_KNOWN
    jnz .type_failure
    cmp qword [r12 + NEBOC_PRIVACY_TRANSITION_OFFSET], NEBOC_TRANSITION_MAX
    ja .type_failure
    cmp qword [r12 + NEBOC_PRIVACY_SOURCE_TRUST_OFFSET], NEBOC_TRUST_SECRET
    ja .type_failure
    cmp qword [r12 + NEBOC_PRIVACY_TARGET_TRUST_OFFSET], NEBOC_TRUST_SECRET
    ja .type_failure
    cmp qword [r12 + NEBOC_PRIVACY_RETENTION_ELAPSED_OFFSET], NEBOC_RETENTION_MAX
    ja .type_failure
    cmp qword [r12 + NEBOC_PRIVACY_RETENTION_LIMIT_OFFSET], NEBOC_RETENTION_MAX
    ja .type_failure
    mov rax, [r12 + NEBOC_PRIVACY_SINK_EFFECT_MASK_OFFSET]
    and rax, ~NEBOC_EFFECT_MASK_KNOWN
    jnz .type_failure

    ; Transition shape is a type invariant.  Removal is never implicit, and a
    ; redaction can remove only labels that are actually inferred.
    mov rax, [r12 + NEBOC_PRIVACY_DIRECT_LABELS_OFFSET]
    or rax, [r12 + NEBOC_PRIVACY_CALLEE_LABELS_OFFSET]
    cmp qword [r12 + NEBOC_PRIVACY_TRANSITION_OFFSET], NEBOC_TRANSITION_PRESERVE
    jne .validate_redaction
    cmp qword [r12 + NEBOC_PRIVACY_REDACTION_MASK_OFFSET], 0
    jne .type_failure
    jmp .authenticate_policy
.validate_redaction:
    mov rdx, [r12 + NEBOC_PRIVACY_REDACTION_MASK_OFFSET]
    test rdx, rdx
    jz .type_failure
    mov rcx, rax
    not rcx
    test rdx, rcx
    jnz .type_failure

.authenticate_policy:
    ; push r12 establishes the required 16-byte alignment at this nested call.
    mov rdi, r12
    call neboc_policy_evaluate
    test eax, eax
    jnz .map_failure
    cmp qword [r12 + NEBOC_POLICY_DIAGNOSTIC_OFFSET], 0
    jne .map_failure
    cmp qword [r12 + NEBOC_POLICY_DECISION_OFFSET], NEBOC_POLICY_DECISION_PERMIT
    jne .security_failure

    ; Label propagation is set union.  Effective/declassified metadata is not
    ; published until the source-trust and explicit redaction authority gates
    ; have passed.
    mov rax, [r12 + NEBOC_PRIVACY_DIRECT_LABELS_OFFSET]
    or rax, [r12 + NEBOC_PRIVACY_CALLEE_LABELS_OFFSET]
    mov [r12 + NEBOC_PRIVACY_INFERRED_LABELS_OFFSET], rax
    mov qword [r12 + NEBOC_PRIVACY_PROVENANCE_FLAGS_OFFSET], NEBOC_PROVENANCE_PROPAGATED
    or qword [r12 + NEBOC_PRIVACY_PROVENANCE_FLAGS_OFFSET], NEBOC_PROVENANCE_POLICY_AUTHENTICATED

    ; Original labels require sufficient source trust: INTERNAL=>internal,
    ; PERSONAL/SENSITIVE=>restricted, SECRET=>secret.
    mov rdx, [r12 + NEBOC_PRIVACY_INFERRED_LABELS_OFFSET]
    xor ecx, ecx
    test rdx, NEBOC_LABEL_SECRET
    jnz .source_requires_secret
    test rdx, NEBOC_LABEL_PERSONAL | NEBOC_LABEL_SENSITIVE
    jnz .source_requires_restricted
    test rdx, NEBOC_LABEL_INTERNAL
    jz .source_trust_ready
    mov ecx, NEBOC_TRUST_INTERNAL
    jmp .source_trust_ready
.source_requires_restricted:
    mov ecx, NEBOC_TRUST_RESTRICTED
    jmp .source_trust_ready
.source_requires_secret:
    mov ecx, NEBOC_TRUST_SECRET
.source_trust_ready:
    cmp [r12 + NEBOC_PRIVACY_SOURCE_TRUST_OFFSET], rcx
    jb .security_failure

    ; REDACT requires explicit purpose and audit identity before publishing
    ; any effective/declassified label metadata.  PRESERVE cannot downgrade
    ; trust even when its labels happen to fit the target.
    cmp qword [r12 + NEBOC_PRIVACY_TRANSITION_OFFSET], NEBOC_TRANSITION_REDACT
    jne .validate_preserve_trust
    cmp qword [r12 + NEBOC_PRIVACY_PURPOSE_ID_OFFSET], 0
    je .security_failure
    cmp qword [r12 + NEBOC_POLICY_AUDIT_ID_OFFSET], 0
    je .security_failure
    mov rax, [r12 + NEBOC_PRIVACY_INFERRED_LABELS_OFFSET]
    mov rdx, [r12 + NEBOC_PRIVACY_REDACTION_MASK_OFFSET]
    not rdx
    and rax, rdx
    mov [r12 + NEBOC_PRIVACY_EFFECTIVE_LABELS_OFFSET], rax
    or qword [r12 + NEBOC_PRIVACY_PROVENANCE_FLAGS_OFFSET], NEBOC_PROVENANCE_REDACTED
    jmp .validate_target_labels
.validate_preserve_trust:
    mov rax, [r12 + NEBOC_PRIVACY_TARGET_TRUST_OFFSET]
    cmp rax, [r12 + NEBOC_PRIVACY_SOURCE_TRUST_OFFSET]
    jb .security_failure
    mov rax, [r12 + NEBOC_PRIVACY_INFERRED_LABELS_OFFSET]
    mov [r12 + NEBOC_PRIVACY_EFFECTIVE_LABELS_OFFSET], rax

.validate_target_labels:
    ; The effective labels, after any authenticated redaction, must fit the
    ; destination trust.  A REDACT transition may therefore downgrade only as
    ; far as the remaining labels allow.
    mov rdx, [r12 + NEBOC_PRIVACY_EFFECTIVE_LABELS_OFFSET]
    xor ecx, ecx
    test rdx, NEBOC_LABEL_SECRET
    jnz .target_requires_secret
    test rdx, NEBOC_LABEL_PERSONAL | NEBOC_LABEL_SENSITIVE
    jnz .target_requires_restricted
    test rdx, NEBOC_LABEL_INTERNAL
    jz .target_trust_ready
    mov ecx, NEBOC_TRUST_INTERNAL
    jmp .target_trust_ready
.target_requires_restricted:
    mov ecx, NEBOC_TRUST_RESTRICTED
    jmp .target_trust_ready
.target_requires_secret:
    mov ecx, NEBOC_TRUST_SECRET
.target_trust_ready:
    cmp [r12 + NEBOC_PRIVACY_TARGET_TRUST_OFFSET], rcx
    jb .security_failure
    mov rax, [r12 + NEBOC_PRIVACY_SOURCE_TRUST_OFFSET]
    cmp rax, [r12 + NEBOC_PRIVACY_TARGET_TRUST_OFFSET]
    je .trust_transition_ready
    or qword [r12 + NEBOC_PRIVACY_PROVENANCE_FLAGS_OFFSET], NEBOC_PROVENANCE_TRUST_TRANSITION
.trust_transition_ready:

    ; Time is supplied as bounded deterministic metadata; no clock is read.
    mov rax, [r12 + NEBOC_PRIVACY_RETENTION_ELAPSED_OFFSET]
    cmp rax, [r12 + NEBOC_PRIVACY_RETENTION_LIMIT_OFFSET]
    ja .runtime_failure
    or qword [r12 + NEBOC_PRIVACY_PROVENANCE_FLAGS_OFFSET], NEBOC_PROVENANCE_RETENTION_VALID

    ; An observable sink effect must have been inferred and authenticated by
    ; effects_capabilities_e_politicas.  This prevents a forged privacidade_dados_sensiveis_e_zero_trust permit from bypassing capability policy.
    mov rax, [r12 + NEBOC_PRIVACY_SINK_EFFECT_MASK_OFFSET]
    mov rcx, [r12 + NEBOC_POLICY_INFERRED_EFFECTS_OFFSET]
    not rcx
    test rax, rcx
    jnz .security_failure

    ; Clearance is an independent label set.  Record the exact leaking labels
    ; before denying the transition.
    mov rax, [r12 + NEBOC_PRIVACY_EFFECTIVE_LABELS_OFFSET]
    mov rcx, [r12 + NEBOC_PRIVACY_SINK_CLEARANCE_OFFSET]
    not rcx
    and rax, rcx
    mov [r12 + NEBOC_PRIVACY_REJECTED_LABELS_OFFSET], rax
    test rax, rax
    jnz .security_failure

    ; Non-public data entering an observable sink always has explicit purpose
    ; and audit metadata, even when its clearance/trust otherwise permit it.
    cmp qword [r12 + NEBOC_PRIVACY_SINK_EFFECT_MASK_OFFSET], 0
    je .sink_ready
    cmp qword [r12 + NEBOC_PRIVACY_EFFECTIVE_LABELS_OFFSET], 0
    je .sink_ready
    cmp qword [r12 + NEBOC_PRIVACY_PURPOSE_ID_OFFSET], 0
    je .security_failure
    cmp qword [r12 + NEBOC_POLICY_AUDIT_ID_OFFSET], 0
    je .security_failure
.sink_ready:
    or qword [r12 + NEBOC_PRIVACY_PROVENANCE_FLAGS_OFFSET], NEBOC_PROVENANCE_SINK_AUTHORIZED
    jmp .permit

.map_failure:
    mov rax, [r12 + NEBOC_POLICY_DIAGNOSTIC_OFFSET]
    cmp rax, neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
    je .type_failure
    cmp rax, neboc_effects_capabilities_e_politicas_DIAG_RUNTIME_driver_cli_linux_x86_64
    je .runtime_failure
    jmp .security_failure

.type_failure:
    mov qword [r12 + NEBOC_PRIVACY_DIAGNOSTIC_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_TYPE_codegen_privacy_x86_64
    mov r9d, NEBOC_STATUS_INVALID_SOURCE
    jmp .hash_metadata
.runtime_failure:
    mov qword [r12 + NEBOC_PRIVACY_DIAGNOSTIC_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_RUNTIME_driver_cli_linux_x86_64
    mov r9d, NEBOC_STATUS_INVALID_SOURCE
    jmp .hash_metadata
.security_failure:
    mov qword [r12 + NEBOC_PRIVACY_DIAGNOSTIC_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_SECURITY_driver_cli_linux_x86_64
    mov r9d, NEBOC_STATUS_INVALID_SOURCE
    jmp .hash_metadata

.permit:
    xor r9d, r9d

.hash_metadata:
    ; Bytewise FNV-1a64 over q0..q32.  q33 (this hash) and q34 (decision)
    ; are excluded, as are all payloads, addresses, clocks and ambient state.
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.hash_loop:
    cmp rcx, NEBOC_PRIVACY_HASHED_BYTES
    jae .hash_done
    movzx edx, byte [r12 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .hash_loop
.hash_done:
    mov [r12 + NEBOC_PRIVACY_METADATA_HASH_OFFSET], rax
    test r9d, r9d
    jnz .return_status
    mov qword [r12 + NEBOC_PRIVACY_DECISION_OFFSET], NEBOC_PRIVACY_DECISION_PERMIT
.return_status:
    mov eax, r9d
    pop r12
    cld
    ret

.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
