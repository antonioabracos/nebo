; Nebo Assembly — EFFECTS-CAPABILITIES-E-POLITICAS-PF003 deterministic semantic policy envelope
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/policy_contract.inc"
%include "compiler/semantic/effect/effect_policy.inc"
%include "compiler/semantic/effect/effect_policy_semantic.inc"

section .text

extern neboc_policy_evaluate

; rdi = aligned pointer to a 25-qword semantic request/result
; eax = NEBOC_STATUS_*
;
; The PF002 parser identity is reconstructed independently before the PF001
; evaluator receives resolved direct and transitive callee effects.  Null and
; misaligned pointers are rejected transactionally without touching memory.
NEBOC_ABI_FUNCTION neboc_policy_semantic_analyze
    test rdi, rdi
    jz .invalid_argument
    test rdi, neboc_effects_capabilities_e_politicas_SEMANTIC_ALIGNMENT - 1
    jnz .invalid_argument

    push r12
    push r13
    sub rsp, NEBOC_POLICY_REQUEST_SIZE
    mov r12, rdi

    ; A valid pointer always receives deterministic outputs, including on a
    ; provenance or delegated policy failure.
    lea rdi, [r12 + NEBOC_SEMANTIC_INFERRED_EFFECTS_OFFSET]
    mov ecx, 10
    xor eax, eax
    rep stosq

    cmp qword [r12 + NEBOC_SEMANTIC_CLAUSE_MASK_OFFSET], \
        NEBOC_SEMANTIC_REQUIRED_CLAUSE_MASK
    jne .provenance_failure
    cmp qword [r12 + NEBOC_SEMANTIC_FLAGS_OFFSET], \
        NEBOC_SEMANTIC_FLAG_REQUIRED
    jne .provenance_failure

    mov rax, [r12 + NEBOC_SEMANTIC_SOURCE_END_OFFSET]
    cmp rax, [r12 + NEBOC_SEMANTIC_SOURCE_START_OFFSET]
    jbe .provenance_failure
    sub rax, [r12 + NEBOC_SEMANTIC_SOURCE_START_OFFSET]
    cmp rax, NEBOC_SEMANTIC_MAX_SOURCE_BYTES
    ja .provenance_failure

    ; Build the exact canonical PF002 output preimage in the aligned local
    ; PF001 record: [declared, 0, declared, caps, allow, deny, budget, trust,
    ; audit, permit].  Its trailing evaluator outputs start cleared.
    mov rdi, rsp
    mov ecx, NEBOC_POLICY_REQUEST_QWORDS
    xor eax, eax
    rep stosq

    mov rax, [r12 + NEBOC_SEMANTIC_DECLARED_EFFECTS_OFFSET]
    mov [rsp + NEBOC_POLICY_DIRECT_EFFECTS_OFFSET], rax
    mov [rsp + NEBOC_POLICY_DECLARED_EFFECTS_OFFSET], rax
    mov rax, [r12 + NEBOC_SEMANTIC_CAPABILITIES_OFFSET]
    mov [rsp + NEBOC_POLICY_CAPABILITIES_OFFSET], rax
    mov rax, [r12 + NEBOC_SEMANTIC_ALLOW_OFFSET]
    mov [rsp + NEBOC_POLICY_ALLOW_OFFSET], rax
    mov rax, [r12 + NEBOC_SEMANTIC_DENY_OFFSET]
    mov [rsp + NEBOC_POLICY_DENY_OFFSET], rax
    mov rax, [r12 + NEBOC_SEMANTIC_BUDGET_OFFSET]
    mov [rsp + NEBOC_POLICY_BUDGET_OFFSET], rax
    mov rax, [r12 + NEBOC_SEMANTIC_TRUST_OFFSET]
    mov [rsp + NEBOC_POLICY_TRUST_OFFSET], rax
    mov rax, [r12 + NEBOC_SEMANTIC_AUDIT_ID_OFFSET]
    mov [rsp + NEBOC_POLICY_AUDIT_ID_OFFSET], rax
    mov rax, [r12 + NEBOC_SEMANTIC_PERMIT_OFFSET]
    mov [rsp + NEBOC_POLICY_PERMIT_OFFSET], rax

    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.parser_hash_loop:
    cmp rcx, NEBOC_SEMANTIC_PARSER_HASHED_BYTES
    jae .parser_hash_done
    movzx edx, byte [rsp + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .parser_hash_loop
.parser_hash_done:
    cmp rax, [r12 + NEBOC_SEMANTIC_PARSER_HASH_OFFSET]
    jne .provenance_failure

    ; The parser preimage was authentic; replace its synthetic first two
    ; qwords with the resolver-owned direct/transitive effect masks.
    mov rax, [r12 + NEBOC_SEMANTIC_RESOLVED_DIRECT_EFFECTS_OFFSET]
    mov [rsp + NEBOC_POLICY_DIRECT_EFFECTS_OFFSET], rax
    mov rax, [r12 + NEBOC_SEMANTIC_RESOLVED_CALLEE_EFFECTS_OFFSET]
    mov [rsp + NEBOC_POLICY_CALLEE_EFFECTS_OFFSET], rax

    mov rdi, rsp
    call neboc_policy_evaluate
    mov r13d, eax

    mov rax, [rsp + NEBOC_POLICY_INFERRED_EFFECTS_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_INFERRED_EFFECTS_OFFSET], rax
    mov rax, [rsp + NEBOC_POLICY_MISSING_EFFECTS_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_MISSING_EFFECTS_OFFSET], rax
    mov rax, [rsp + NEBOC_POLICY_REJECTED_EFFECTS_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_REJECTED_EFFECTS_OFFSET], rax
    mov rax, [rsp + NEBOC_POLICY_COST_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_COST_OFFSET], rax
    mov rax, [rsp + NEBOC_POLICY_DIAGNOSTIC_OFFSET]
    mov [r12 + neboc_effects_capabilities_e_politicas_SEMANTIC_DIAGNOSTIC_OFFSET], rax
    mov rax, [rsp + NEBOC_POLICY_AUDIT_HASH_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_AUDIT_HASH_OFFSET], rax
    mov rax, [rsp + NEBOC_POLICY_DECISION_OFFSET]
    mov [r12 + neboc_effects_capabilities_e_politicas_SEMANTIC_DECISION_OFFSET], rax

    test r13d, r13d
    jnz .semantic_hash
    mov qword [r12 + neboc_effects_capabilities_e_politicas_SEMANTIC_RESULT_TYPE_OFFSET], \
        NEBOC_SEMANTIC_RESULT_TYPE_INT
    jmp .semantic_hash

.provenance_failure:
    mov qword [r12 + neboc_effects_capabilities_e_politicas_SEMANTIC_DIAGNOSTIC_OFFSET], neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
    mov r13d, NEBOC_STATUS_INVALID_SOURCE

.semantic_hash:
    ; FNV-1a64 over q0..q22 bytewise.  The semantic hash and allocation count
    ; are excluded; allocation count remains the cleared, canonical zero.
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.semantic_hash_loop:
    cmp rcx, neboc_effects_capabilities_e_politicas_SEMANTIC_HASHED_BYTES
    jae .semantic_hash_done
    movzx edx, byte [r12 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .semantic_hash_loop
.semantic_hash_done:
    mov [r12 + neboc_effects_capabilities_e_politicas_SEMANTIC_HASH_OFFSET], rax
    mov eax, r13d
    add rsp, NEBOC_POLICY_REQUEST_SIZE
    pop r13
    pop r12
    cld
    ret

.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
