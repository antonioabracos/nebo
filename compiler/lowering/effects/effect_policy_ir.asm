; Nebo Assembly — EFFECTS-CAPABILITIES-E-POLITICAS-PF003 deterministic effect-policy HIR/LIR contract
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/semantic/effect/effect_policy.inc"
%include "compiler/lowering/effects/effect_policy_ir.inc"

section .text

; neboc_policy_ir_lower(envelope*) -> StatusCode
; The 37-qword envelope is pointerless. q0..q24 remain caller-owned and
; q25..q36 are cleared transactionally before any semantic validation.
NEBOC_ABI_FUNCTION neboc_policy_ir_lower
    test rdi, rdi
    jz .invalid_argument
    test rdi, NEBOC_POLICY_IR_ALIGNMENT - 1
    jnz .invalid_argument
    mov r10, rdi

    lea rdi, [r10 + NEBOC_POLICY_IR_OUTPUT_OFFSET]
    mov ecx, NEBOC_POLICY_IR_OUTPUT_QWORDS
    xor eax, eax
    rep stosq

    ; The semantic envelope is authenticated byte-for-byte over q0..q22.
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.semantic_hash_loop:
    cmp rcx, NEBOC_POLICY_IR_SEMANTIC_HASHED_BYTES
    jae .semantic_hash_done
    movzx edx, byte [r10 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .semantic_hash_loop
.semantic_hash_done:
    cmp rax, [r10 + NEBOC_POLICY_IR_SEMANTIC_HASH_OFFSET]
    jne .invalid_source

    ; Revalidate the PF002 canonical parser hash. The source parser hashes
    ; [declared, 0, declared, capabilities, allow, deny, budget, trust,
    ;  audit, permit] as ten little-endian qwords.
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
%macro IR_PARSER_HASH_QWORD 1
    xor ecx, ecx
%%byte_loop:
    cmp ecx, 8
    jae %%done
    movzx edx, byte [r10 + %1 + rcx]
    xor rax, rdx
    imul rax, r8
    inc ecx
    jmp %%byte_loop
%%done:
%endmacro
%macro IR_PARSER_HASH_ZERO_QWORD 0
    mov ecx, 8
%%byte_loop:
    imul rax, r8
    dec ecx
    jnz %%byte_loop
%endmacro
    IR_PARSER_HASH_QWORD NEBOC_POLICY_IR_DECLARED_EFFECTS_OFFSET
    IR_PARSER_HASH_ZERO_QWORD
    IR_PARSER_HASH_QWORD NEBOC_POLICY_IR_DECLARED_EFFECTS_OFFSET
    IR_PARSER_HASH_QWORD NEBOC_POLICY_IR_CAPABILITIES_OFFSET
    IR_PARSER_HASH_QWORD NEBOC_POLICY_IR_ALLOW_OFFSET
    IR_PARSER_HASH_QWORD NEBOC_POLICY_IR_DENY_OFFSET
    IR_PARSER_HASH_QWORD NEBOC_POLICY_IR_BUDGET_OFFSET
    IR_PARSER_HASH_QWORD NEBOC_POLICY_IR_TRUST_OFFSET
    IR_PARSER_HASH_QWORD NEBOC_POLICY_IR_AUDIT_ID_OFFSET
    IR_PARSER_HASH_QWORD NEBOC_POLICY_IR_PERMIT_OFFSET
    cmp rax, [r10 + NEBOC_POLICY_IR_PARSER_HASH_OFFSET]
    jne .invalid_source

    ; Parser and semantic provenance must represent the complete frozen proof.
    cmp qword [r10 + NEBOC_POLICY_IR_CLAUSE_MASK_OFFSET], NEBOC_POLICY_IR_REQUIRED_CLAUSE_MASK
    jne .invalid_source
    cmp qword [r10 + NEBOC_POLICY_IR_SEMANTIC_FLAGS_OFFSET], NEBOC_POLICY_IR_REQUIRED_SEMANTIC_FLAGS
    jne .invalid_source
    mov rax, [r10 + NEBOC_POLICY_IR_SOURCE_START_OFFSET]
    cmp rax, [r10 + NEBOC_POLICY_IR_SOURCE_END_OFFSET]
    jae .invalid_source
    mov rdx, [r10 + NEBOC_POLICY_IR_SOURCE_END_OFFSET]
    sub rdx, rax
    cmp rdx, NEBOC_IR_MAX_SOURCE_BYTES
    ja .invalid_source

    ; Only a typed, allocation-free semantic PERMIT may cross into HIR.
    cmp qword [r10 + NEBOC_POLICY_IR_MISSING_EFFECTS_OFFSET], 0
    jne .invalid_source
    cmp qword [r10 + NEBOC_POLICY_IR_REJECTED_EFFECTS_OFFSET], 0
    jne .invalid_source
    cmp qword [r10 + NEBOC_POLICY_IR_SEMANTIC_DIAGNOSTIC_OFFSET], 0
    jne .invalid_source
    cmp qword [r10 + NEBOC_POLICY_IR_DECISION_OFFSET], NEBOC_POLICY_DECISION_PERMIT
    jne .invalid_source
    cmp qword [r10 + NEBOC_POLICY_IR_SEMANTIC_RESULT_TYPE_OFFSET], NEBOC_TYPE_ID_INT
    jne .invalid_source
    cmp qword [r10 + NEBOC_POLICY_IR_SEMANTIC_ALLOCATIONS_OFFSET], NEBOC_POLICY_IR_ALLOCATION_NONE
    jne .invalid_source

    ; Every effect-bearing field is a closed eleven-bit mask.
    mov rax, [r10 + NEBOC_POLICY_IR_DECLARED_EFFECTS_OFFSET]
    or rax, [r10 + NEBOC_POLICY_IR_CAPABILITIES_OFFSET]
    or rax, [r10 + NEBOC_POLICY_IR_ALLOW_OFFSET]
    or rax, [r10 + NEBOC_POLICY_IR_DENY_OFFSET]
    or rax, [r10 + NEBOC_POLICY_IR_DIRECT_EFFECTS_OFFSET]
    or rax, [r10 + NEBOC_POLICY_IR_CALLEE_EFFECTS_OFFSET]
    or rax, [r10 + NEBOC_POLICY_IR_INFERRED_EFFECTS_OFFSET]
    or rax, [r10 + NEBOC_POLICY_IR_MISSING_EFFECTS_OFFSET]
    or rax, [r10 + NEBOC_POLICY_IR_REJECTED_EFFECTS_OFFSET]
    and rax, ~NEBOC_EFFECT_MASK_KNOWN
    jnz .invalid_source
    cmp qword [r10 + NEBOC_POLICY_IR_BUDGET_OFFSET], NEBOC_POLICY_MAX_BUDGET
    ja .invalid_source
    cmp qword [r10 + NEBOC_POLICY_IR_TRUST_OFFSET], NEBOC_TRUST_SECRET
    ja .invalid_source
    cmp qword [r10 + NEBOC_POLICY_IR_PERMIT_OFFSET], NEBOC_POLICY_MAX_PERMIT
    ja .invalid_source

    ; Recompute inference and portable popcount instead of trusting metadata.
    mov rax, [r10 + NEBOC_POLICY_IR_DIRECT_EFFECTS_OFFSET]
    or rax, [r10 + NEBOC_POLICY_IR_CALLEE_EFFECTS_OFFSET]
    cmp rax, [r10 + NEBOC_POLICY_IR_INFERRED_EFFECTS_OFFSET]
    jne .invalid_source
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
    cmp rcx, [r10 + NEBOC_POLICY_IR_COST_OFFSET]
    jne .invalid_source
    cmp rcx, [r10 + NEBOC_POLICY_IR_BUDGET_OFFSET]
    ja .invalid_source

    ; Repeat the GREEN subset, deny, trust and audit invariants at the boundary.
    mov rdx, [r10 + NEBOC_POLICY_IR_DECLARED_EFFECTS_OFFSET]
    mov rax, rdx
    not rax
    test [r10 + NEBOC_POLICY_IR_INFERRED_EFFECTS_OFFSET], rax
    jnz .invalid_source
    mov rax, [r10 + NEBOC_POLICY_IR_CAPABILITIES_OFFSET]
    not rax
    test rdx, rax
    jnz .invalid_source
    mov rax, [r10 + NEBOC_POLICY_IR_ALLOW_OFFSET]
    not rax
    test rdx, rax
    jnz .invalid_source
    test rdx, [r10 + NEBOC_POLICY_IR_DENY_OFFSET]
    jnz .invalid_source

    mov rcx, [r10 + NEBOC_POLICY_IR_TRUST_OFFSET]
    cmp rcx, NEBOC_TRUST_SECRET
    je .trust_valid
    cmp rcx, NEBOC_TRUST_RESTRICTED
    je .trust_restricted
    cmp rcx, NEBOC_TRUST_INTERNAL
    je .trust_internal
    test rdx, 0x79c
    jnz .invalid_source
    jmp .trust_valid
.trust_internal:
    test rdx, 0x688
    jnz .invalid_source
    jmp .trust_valid
.trust_restricted:
    test rdx, NEBOC_EFFECT_UNSAFE
    jnz .invalid_source
.trust_valid:
    cmp qword [r10 + NEBOC_POLICY_IR_INFERRED_EFFECTS_OFFSET], 0
    je .audit_identity_valid
    cmp qword [r10 + NEBOC_POLICY_IR_AUDIT_ID_OFFSET], 0
    je .invalid_source
.audit_identity_valid:

    ; Authenticate the evaluator audit hash in its native q0..q14 order.
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
%macro IR_AUDIT_HASH_QWORD 1
    xor ecx, ecx
%%byte_loop:
    cmp ecx, 8
    jae %%done
    movzx edx, byte [r10 + %1 + rcx]
    xor rax, rdx
    imul rax, r8
    inc ecx
    jmp %%byte_loop
%%done:
%endmacro
    IR_AUDIT_HASH_QWORD NEBOC_POLICY_IR_DIRECT_EFFECTS_OFFSET
    IR_AUDIT_HASH_QWORD NEBOC_POLICY_IR_CALLEE_EFFECTS_OFFSET
    IR_AUDIT_HASH_QWORD NEBOC_POLICY_IR_DECLARED_EFFECTS_OFFSET
    IR_AUDIT_HASH_QWORD NEBOC_POLICY_IR_CAPABILITIES_OFFSET
    IR_AUDIT_HASH_QWORD NEBOC_POLICY_IR_ALLOW_OFFSET
    IR_AUDIT_HASH_QWORD NEBOC_POLICY_IR_DENY_OFFSET
    IR_AUDIT_HASH_QWORD NEBOC_POLICY_IR_BUDGET_OFFSET
    IR_AUDIT_HASH_QWORD NEBOC_POLICY_IR_TRUST_OFFSET
    IR_AUDIT_HASH_QWORD NEBOC_POLICY_IR_AUDIT_ID_OFFSET
    IR_AUDIT_HASH_QWORD NEBOC_POLICY_IR_PERMIT_OFFSET
    IR_AUDIT_HASH_QWORD NEBOC_POLICY_IR_INFERRED_EFFECTS_OFFSET
    IR_AUDIT_HASH_QWORD NEBOC_POLICY_IR_MISSING_EFFECTS_OFFSET
    IR_AUDIT_HASH_QWORD NEBOC_POLICY_IR_REJECTED_EFFECTS_OFFSET
    IR_AUDIT_HASH_QWORD NEBOC_POLICY_IR_COST_OFFSET
    IR_AUDIT_HASH_QWORD NEBOC_POLICY_IR_SEMANTIC_DIAGNOSTIC_OFFSET
    cmp rax, [r10 + NEBOC_POLICY_IR_AUDIT_HASH_OFFSET]
    jne .invalid_source

    ; Fixed abstract IR: union, policy assertion, then constant permit result.
    mov qword [r10 + NEBOC_POLICY_IR_HIR_EFFECT_UNION_OFFSET], NEBOC_HIR_EFFECT_UNION
    mov qword [r10 + NEBOC_POLICY_IR_HIR_POLICY_GATE_OFFSET], neboc_effects_capabilities_e_politicas_HIR_POLICY_GATE
    mov qword [r10 + NEBOC_POLICY_IR_HIR_PERMIT_OFFSET], NEBOC_HIR_PERMIT
    mov qword [r10 + NEBOC_POLICY_IR_LIR_MASK_OR_OFFSET], NEBOC_LIR_MASK_OR
    mov qword [r10 + NEBOC_POLICY_IR_LIR_POLICY_ASSERT_OFFSET], NEBOC_LIR_POLICY_ASSERT
    mov qword [r10 + NEBOC_POLICY_IR_LIR_CONST_I64_OFFSET], NEBOC_LIR_CONST_I64
    mov qword [r10 + NEBOC_POLICY_IR_RESULT_TYPE_OFFSET], NEBOC_TYPE_ID_INT
    mov rax, [r10 + NEBOC_POLICY_IR_PERMIT_OFFSET]
    mov [r10 + NEBOC_POLICY_IR_PERMIT_CONSTANT_OFFSET], rax
    mov rax, [r10 + NEBOC_POLICY_IR_INFERRED_EFFECTS_OFFSET]
    mov [r10 + NEBOC_POLICY_IR_EFFECTIVE_MASK_OFFSET], rax
    mov qword [r10 + NEBOC_POLICY_IR_DIAGNOSTIC_OFFSET], 0
    mov qword [r10 + NEBOC_POLICY_IR_ALLOCATIONS_OFFSET], NEBOC_POLICY_IR_ALLOCATION_NONE

    ; Canonical IR hash covers the complete semantic envelope and q25..q35.
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.ir_hash_loop:
    cmp rcx, NEBOC_POLICY_IR_HASHED_BYTES
    jae .ir_hash_done
    movzx edx, byte [r10 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .ir_hash_loop
.ir_hash_done:
    mov [r10 + NEBOC_POLICY_IR_HASH_OFFSET], rax
    xor eax, eax
    cld
    ret

.invalid_source:
    lea rdi, [r10 + NEBOC_POLICY_IR_OUTPUT_OFFSET]
    mov ecx, NEBOC_POLICY_IR_OUTPUT_QWORDS
    xor eax, eax
    rep stosq
    mov qword [r10 + NEBOC_POLICY_IR_DIAGNOSTIC_OFFSET], neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    cld
    ret

.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
