; Nebo Assembly — PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-PF003 target-neutral privacy HIR/LIR contract
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/privacy/privacy_ir.inc"

section .text

NEBOC_ABI_FUNCTION neboc_privacy_ir_lower
    test rdi, rdi
    jz .invalid_argument
    test rdi, neboc_privacidade_dados_sensiveis_e_zero_trust_IR_ALIGNMENT - 1
    jnz .invalid_argument
    cld
    mov r10, rdi

    lea rdi, [r10 + neboc_privacidade_dados_sensiveis_e_zero_trust_IR_OUTPUT_OFFSET]
    mov ecx, neboc_privacidade_dados_sensiveis_e_zero_trust_IR_OUTPUT_QWORDS
    xor eax, eax
    rep stosq

    ; Authenticate the complete semantic preimage q0..q48.
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.semantic_hash_loop:
    cmp rcx, neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_HASHED_BYTES
    jae .semantic_hash_done
    movzx edx, byte [r10 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .semantic_hash_loop
.semantic_hash_done:
    cmp rax, [r10 + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_HASH_OFFSET]
    jne .invalid_source
    cmp qword [r10 + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_ALLOCATIONS_OFFSET], 0
    jne .invalid_source

    ; Re-authenticate PF002 shape and PF001 metadata, not caller claims.
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.shape_hash_loop:
    cmp rcx, NEBOC_PRIVACY_HASHED_OUTPUT_BYTES
    jae .shape_hash_done
    movzx edx, byte [r10 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .shape_hash_loop
.shape_hash_done:
    cmp rax, [r10 + NEBOC_PRIVACY_RESULT_SHAPE_HASH_OFFSET]
    jne .invalid_source

    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.privacy_hash_loop:
    cmp rcx, NEBOC_PRIVACY_HASHED_BYTES
    jae .privacy_hash_done
    movzx edx, byte [r10 + NEBOC_SEMANTIC_PRIVACY_OFFSET + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .privacy_hash_loop
.privacy_hash_done:
    cmp rax, [r10 + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_METADATA_HASH_OFFSET]
    jne .invalid_source

    cmp qword [r10 + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_DIAGNOSTIC_OFFSET], 0
    jne .invalid_source
    cmp qword [r10 + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_DECISION_OFFSET], NEBOC_PRIVACY_DECISION_PERMIT
    jne .invalid_source
    cmp qword [r10 + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_REJECTED_LABELS_OFFSET], 0
    jne .invalid_source
    mov rax, [r10 + NEBOC_PRIVACY_RESULT_PAYLOAD_TYPE_ID_OFFSET]
    cmp rax, [r10 + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_RESULT_TYPE_OFFSET]
    jne .invalid_source
    mov rax, [r10 + NEBOC_PRIVACY_RESULT_DIRECT_LABEL_OFFSET]
    cmp rax, [r10 + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_DIRECT_LABELS_OFFSET]
    jne .invalid_source
    mov rax, [r10 + NEBOC_PRIVACY_RESULT_REDACTION_MASK_OFFSET]
    cmp rax, [r10 + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_REDACTION_MASK_OFFSET]
    jne .invalid_source
    xor eax, eax
    test qword [r10 + NEBOC_PRIVACY_RESULT_FLAGS_OFFSET], NEBOC_PRIVACY_FLAG_HAS_REDACT
    setnz al
    cmp rax, [r10 + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_TRANSITION_OFFSET]
    jne .invalid_source

    mov qword [r10 + NEBOC_IR_HIR_CLASSIFY_OFFSET], NEBOC_HIR_PRIVACY_CLASSIFY
    mov qword [r10 + neboc_privacidade_dados_sensiveis_e_zero_trust_IR_HIR_POLICY_GATE_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_HIR_POLICY_GATE
    mov qword [r10 + NEBOC_IR_HIR_REDACT_OFFSET], NEBOC_HIR_REDACT
    mov qword [r10 + NEBOC_IR_HIR_SINK_GATE_OFFSET], NEBOC_HIR_SINK_GATE
    mov qword [r10 + NEBOC_IR_LIR_LABEL_UNION_OFFSET], NEBOC_LIR_LABEL_UNION
    mov qword [r10 + NEBOC_IR_LIR_REDACT_MASK_OFFSET], NEBOC_LIR_REDACT_MASK
    mov qword [r10 + NEBOC_IR_LIR_TRUST_ASSERT_OFFSET], NEBOC_LIR_TRUST_ASSERT
    mov qword [r10 + NEBOC_IR_LIR_SINK_ASSERT_OFFSET], NEBOC_LIR_SINK_ASSERT
    mov rax, [r10 + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_RESULT_TYPE_OFFSET]
    mov [r10 + neboc_privacidade_dados_sensiveis_e_zero_trust_IR_RESULT_TYPE_OFFSET], rax
    mov rax, [r10 + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_EFFECTIVE_LABELS_OFFSET]
    mov [r10 + NEBOC_IR_EFFECTIVE_LABELS_OFFSET], rax
    mov qword [r10 + neboc_privacidade_dados_sensiveis_e_zero_trust_IR_DECISION_OFFSET], NEBOC_PRIVACY_DECISION_PERMIT

    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.ir_hash_loop:
    cmp rcx, neboc_privacidade_dados_sensiveis_e_zero_trust_IR_HASHED_BYTES
    jae .ir_hash_done
    movzx edx, byte [r10 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .ir_hash_loop
.ir_hash_done:
    mov [r10 + neboc_privacidade_dados_sensiveis_e_zero_trust_IR_HASH_OFFSET], rax
    xor eax, eax
    cld
    ret

.invalid_source:
    lea rdi, [r10 + neboc_privacidade_dados_sensiveis_e_zero_trust_IR_OUTPUT_OFFSET]
    mov ecx, neboc_privacidade_dados_sensiveis_e_zero_trust_IR_OUTPUT_QWORDS
    xor eax, eax
    rep stosq
    mov qword [r10 + neboc_privacidade_dados_sensiveis_e_zero_trust_IR_DIAGNOSTIC_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_TYPE_codegen_privacy_x86_64
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    cld
    ret

.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
