; Nebo Assembly — EFFECTS-CAPABILITIES-E-POLITICAS-PF001 deterministic effects/capabilities policy core
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/effect/effect_classifier.inc"
%include "compiler/semantic/effect/effect_policy.inc"

section .text

; rdi = aligned pointer to a 17-qword request/result
; eax = NEBOC_STATUS_*
;
; This helper is deliberately allocation-free and does not consult ambient
; process state.  All derived fields are cleared before a valid request is
; evaluated.  Null/misaligned pointers are rejected without being touched.
NEBOC_ABI_FUNCTION neboc_policy_evaluate
    test rdi, rdi
    jz .invalid_argument
    test rdi, NEBOC_POLICY_ALIGNMENT - 1
    jnz .invalid_argument
    mov r10, rdi

    mov qword [r10 + NEBOC_POLICY_INFERRED_EFFECTS_OFFSET], 0
    mov qword [r10 + NEBOC_POLICY_MISSING_EFFECTS_OFFSET], 0
    mov qword [r10 + NEBOC_POLICY_REJECTED_EFFECTS_OFFSET], 0
    mov qword [r10 + NEBOC_POLICY_COST_OFFSET], 0
    mov qword [r10 + NEBOC_POLICY_DIAGNOSTIC_OFFSET], 0
    mov qword [r10 + NEBOC_POLICY_AUDIT_HASH_OFFSET], 0
    mov qword [r10 + NEBOC_POLICY_DECISION_OFFSET], 0

    ; Reject unknown effect bits before deriving any policy state.
    mov rax, [r10 + NEBOC_POLICY_DIRECT_EFFECTS_OFFSET]
    or rax, [r10 + NEBOC_POLICY_CALLEE_EFFECTS_OFFSET]
    or rax, [r10 + NEBOC_POLICY_DECLARED_EFFECTS_OFFSET]
    or rax, [r10 + NEBOC_POLICY_CAPABILITIES_OFFSET]
    or rax, [r10 + NEBOC_POLICY_ALLOW_OFFSET]
    or rax, [r10 + NEBOC_POLICY_DENY_OFFSET]
    mov rcx, rax
    and rcx, ~NEBOC_EFFECT_MASK_KNOWN
    jnz .type_failure
    cmp qword [r10 + NEBOC_POLICY_BUDGET_OFFSET], NEBOC_POLICY_MAX_BUDGET
    ja .type_failure
    cmp qword [r10 + NEBOC_POLICY_TRUST_OFFSET], NEBOC_TRUST_SECRET
    ja .type_failure
    cmp qword [r10 + NEBOC_POLICY_PERMIT_OFFSET], NEBOC_POLICY_MAX_PERMIT
    ja .type_failure

    ; Inference is set union over direct and transitive callee effects.
    mov rax, [r10 + NEBOC_POLICY_DIRECT_EFFECTS_OFFSET]
    or rax, [r10 + NEBOC_POLICY_CALLEE_EFFECTS_OFFSET]
    mov [r10 + NEBOC_POLICY_INFERRED_EFFECTS_OFFSET], rax

    ; Portable popcount: no optional POPCNT target feature is required.
    mov rdx, rax
    xor ecx, ecx
.cost_loop:
    test rdx, rdx
    jz .cost_done
    lea rax, [rdx - 1]
    and rdx, rax
    inc rcx
    jmp .cost_loop
.cost_done:
    mov [r10 + NEBOC_POLICY_COST_OFFSET], rcx

    ; q11 combines missing annotations and missing authority.  The diagnostic
    ; still follows first-cause precedence below.
    mov r8, [r10 + NEBOC_POLICY_DECLARED_EFFECTS_OFFSET]
    mov rax, r8
    not rax
    mov rdx, [r10 + NEBOC_POLICY_INFERRED_EFFECTS_OFFSET]
    and rdx, rax                         ; inferred but not declared
    mov r9, [r10 + NEBOC_POLICY_CAPABILITIES_OFFSET]
    not r9
    mov rax, r8
    and rax, r9                          ; declared but not capable
    mov r9, rax
    or rax, rdx
    mov [r10 + NEBOC_POLICY_MISSING_EFFECTS_OFFSET], rax

    ; q12 combines allow, deny and trust rejection metadata.
    mov r11, [r10 + NEBOC_POLICY_ALLOW_OFFSET]
    not r11
    and r11, r8                          ; declared but not allowed
    mov rsi, [r10 + NEBOC_POLICY_DENY_OFFSET]
    and rsi, r8                          ; explicitly denied
    mov rax, r11
    or rax, rsi

    xor edi, edi                         ; trust-rejected effects
    mov rcx, [r10 + NEBOC_POLICY_TRUST_OFFSET]
    cmp rcx, NEBOC_TRUST_SECRET
    je .trust_ready
    cmp rcx, NEBOC_TRUST_RESTRICTED
    je .trust_restricted
    cmp rcx, NEBOC_TRUST_INTERNAL
    je .trust_internal
    mov edi, 0x79c                       ; internal + restricted + secret
    jmp .trust_mask
.trust_internal:
    mov edi, 0x688                       ; restricted + secret
    jmp .trust_mask
.trust_restricted:
    mov edi, NEBOC_EFFECT_UNSAFE
.trust_mask:
    and rdi, r8
    or rax, rdi
.trust_ready:
    mov [r10 + NEBOC_POLICY_REJECTED_EFFECTS_OFFSET], rax

    ; Deterministic first-cause ordering from the normative specification.
    test rdx, rdx
    jnz .type_failure
    test r9, r9
    jnz .security_failure
    test r11, r11
    jnz .security_failure
    test rsi, rsi
    jnz .security_failure
    test rdi, rdi
    jnz .security_failure
    mov rax, [r10 + NEBOC_POLICY_COST_OFFSET]
    cmp rax, [r10 + NEBOC_POLICY_BUDGET_OFFSET]
    ja .budget_failure
    cmp qword [r10 + NEBOC_POLICY_INFERRED_EFFECTS_OFFSET], 0
    je .permit
    cmp qword [r10 + NEBOC_POLICY_AUDIT_ID_OFFSET], 0
    je .security_failure

.permit:
    mov qword [r10 + NEBOC_POLICY_DECISION_OFFSET], NEBOC_POLICY_DECISION_PERMIT
    xor esi, esi
    jmp .hash_metadata

.type_failure:
    mov qword [r10 + NEBOC_POLICY_DIAGNOSTIC_OFFSET], neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
    mov esi, NEBOC_STATUS_INVALID_SOURCE
    jmp .hash_metadata

.security_failure:
    mov qword [r10 + NEBOC_POLICY_DIAGNOSTIC_OFFSET], neboc_effects_capabilities_e_politicas_DIAG_SECURITY_driver_cli_linux_x86_64
    mov esi, NEBOC_STATUS_INVALID_SOURCE
    jmp .hash_metadata

.budget_failure:
    mov qword [r10 + NEBOC_POLICY_DIAGNOSTIC_OFFSET], neboc_effects_capabilities_e_politicas_DIAG_RUNTIME_driver_cli_linux_x86_64
    ; The staged public proof is compile-time evaluable.  Budget rejection is
    ; therefore invalid source, while its stable diagnostic retains runtime
    ; ownership for a future dynamic-policy profile.
    mov esi, NEBOC_STATUS_INVALID_SOURCE

.hash_metadata:
    ; FNV-1a64 over q0..q14 bytewise.  The stored hash and final decision are
    ; deliberately excluded, so no address/payload/process state enters it.
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.hash_loop:
    cmp rcx, NEBOC_POLICY_HASHED_BYTES
    jae .hash_done
    movzx edx, byte [r10 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .hash_loop
.hash_done:
    mov [r10 + NEBOC_POLICY_AUDIT_HASH_OFFSET], rax
    mov eax, esi
    cld
    ret

.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; rdi = legacy NEBOC_EFFECT_ID_*
; rax = effects_capabilities_e_politicas effect mask, or UINT64_MAX for an invalid legacy ID
NEBOC_ABI_FUNCTION neboc_policy_mask_from_legacy_effect_id
    cmp rdi, NEBOC_EFFECT_ID_PURE
    je .legacy_pure
    cmp rdi, NEBOC_EFFECT_ID_CONSOLE
    je .legacy_console
    cmp rdi, NEBOC_EFFECT_ID_SCAN
    je .legacy_scan
    cmp rdi, NEBOC_EFFECT_ID_CONSOLE_SCAN
    je .legacy_both
    mov rax, -1
    cld
    ret
.legacy_pure:
    xor eax, eax
    cld
    ret
.legacy_console:
    mov eax, NEBOC_EFFECT_CONSOLE_WRITE
    cld
    ret
.legacy_scan:
    mov eax, NEBOC_EFFECT_CONSOLE_READ
    cld
    ret
.legacy_both:
    mov eax, NEBOC_EFFECT_CONSOLE_WRITE | NEBOC_EFFECT_CONSOLE_READ
    cld
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
