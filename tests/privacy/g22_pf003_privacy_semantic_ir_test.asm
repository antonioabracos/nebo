; PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-PF003 native semantic-envelope and target-neutral IR tests
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/privacy/privacy_semantic.inc"
%include "compiler/lowering/privacy/privacy_ir.inc"

%if neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_REQUEST_QWORDS != 51
    %error "privacidade_dados_sensiveis_e_zero_trust semantic envelope must remain 51 qwords"
%endif
%if neboc_privacidade_dados_sensiveis_e_zero_trust_IR_REQUEST_QWORDS != 65
    %error "privacidade_dados_sensiveis_e_zero_trust IR envelope must remain 65 qwords"
%endif
%if neboc_privacidade_dados_sensiveis_e_zero_trust_IR_OUTPUT_OFFSET != neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_REQUEST_SIZE
    %error "privacidade_dados_sensiveis_e_zero_trust IR must embed the complete semantic envelope"
%endif

extern neboc_privacy_semantic_analyze
extern neboc_privacy_ir_lower
extern neboc_host_process_exit

section .bss align=16
envelope: resb neboc_privacidade_dados_sensiveis_e_zero_trust_IR_REQUEST_SIZE
saved_semantic_hash: resq 1
saved_ir_hash: resq 1

section .text

clear_envelope:
    cld
    lea rdi, [rel envelope]
    mov ecx, neboc_privacidade_dados_sensiveis_e_zero_trust_IR_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    ret

semantic_hash_oracle:
    lea rsi, [rel envelope]
    mov ecx, neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_HASHED_BYTES
    jmp fnv_oracle

ir_hash_oracle:
    lea rsi, [rel envelope]
    mov ecx, neboc_privacidade_dados_sensiveis_e_zero_trust_IR_HASHED_BYTES
fnv_oracle:
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor edx, edx
.loop:
    cmp rdx, rcx
    jae .done
    movzx r9d, byte [rsi + rdx]
    xor rax, r9
    imul rax, r8
    inc rdx
    jmp .loop
.done:
    ret

refresh_semantic_hash:
    call semantic_hash_oracle
    mov [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_HASH_OFFSET], rax
    ret

; Canonical P01: start(){Secret<Text>.redact(secret);}\n
prepare_secret_text_redact:
    call clear_envelope
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_WRAPPER_KIND_OFFSET], NEBOC_PRIVACY_WRAPPER_SECRET
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_PAYLOAD_TYPE_ID_OFFSET], NEBOC_PRIVACY_PAYLOAD_TYPE_TEXT
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_DIRECT_LABEL_OFFSET], NEBOC_LABEL_SECRET
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_REDACTION_MASK_OFFSET], NEBOC_LABEL_SECRET
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_FLAGS_OFFSET], NEBOC_PRIVACY_FLAG_CANONICAL | NEBOC_PRIVACY_FLAG_HAS_REDACT
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_WRAPPER_SPAN_OFFSET], 8
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_WRAPPER_SPAN_LENGTH_OFFSET], 6
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_TYPE_SPAN_OFFSET], 15
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_TYPE_SPAN_LENGTH_OFFSET], 4
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_REDACT_SPAN_OFFSET], 20
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_REDACT_SPAN_LENGTH_OFFSET], 15
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_STATEMENT_SPAN_LENGTH_OFFSET], 28
    mov rax, 0xa714ba6065bf2f03
    mov [rel envelope + NEBOC_PRIVACY_RESULT_SHAPE_HASH_OFFSET], rax

    ; Valid observable context. Syntax-owned fields are deliberately forged;
    ; the semantic front must overwrite them from the descriptor.
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_POLICY_DIRECT_EFFECTS_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_POLICY_DECLARED_EFFECTS_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_POLICY_CAPABILITIES_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_POLICY_ALLOW_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_POLICY_BUDGET_OFFSET], 1
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_POLICY_TRUST_OFFSET], NEBOC_TRUST_PUBLIC
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_POLICY_AUDIT_ID_OFFSET], 2201
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_POLICY_PERMIT_OFFSET], 22
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_DIRECT_LABELS_OFFSET], NEBOC_LABEL_PERSONAL
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_REDACTION_MASK_OFFSET], 0
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_TRANSITION_OFFSET], NEBOC_TRANSITION_PRESERVE
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_SOURCE_TRUST_OFFSET], NEBOC_TRUST_SECRET
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_TARGET_TRUST_OFFSET], NEBOC_TRUST_PUBLIC
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_RETENTION_ELAPSED_OFFSET], 1
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_RETENTION_LIMIT_OFFSET], 10
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_PURPOSE_ID_OFFSET], 2202
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_SINK_EFFECT_MASK_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    ret

; Canonical P03: start(){PersonalData<Int>;}\n
prepare_personal_int_preserve:
    call clear_envelope
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_WRAPPER_KIND_OFFSET], NEBOC_PRIVACY_WRAPPER_PERSONAL_DATA
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_PAYLOAD_TYPE_ID_OFFSET], NEBOC_PRIVACY_PAYLOAD_TYPE_INT
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_DIRECT_LABEL_OFFSET], NEBOC_LABEL_PERSONAL
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_REDACTION_MASK_OFFSET], 0
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_FLAGS_OFFSET], NEBOC_PRIVACY_FLAG_CANONICAL
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_WRAPPER_SPAN_OFFSET], 8
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_WRAPPER_SPAN_LENGTH_OFFSET], 12
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_TYPE_SPAN_OFFSET], 21
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_TYPE_SPAN_LENGTH_OFFSET], 3
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_REDACT_SPAN_OFFSET], 0
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_REDACT_SPAN_LENGTH_OFFSET], 0
    mov qword [rel envelope + NEBOC_PRIVACY_RESULT_STATEMENT_SPAN_LENGTH_OFFSET], 18
    mov rax, 0xda4eb06e737beee7
    mov [rel envelope + NEBOC_PRIVACY_RESULT_SHAPE_HASH_OFFSET], rax
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_POLICY_PERMIT_OFFSET], 22
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_DIRECT_LABELS_OFFSET], NEBOC_LABEL_SECRET
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_REDACTION_MASK_OFFSET], NEBOC_LABEL_SECRET
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_SINK_CLEARANCE_OFFSET], NEBOC_LABEL_PERSONAL
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_TRANSITION_OFFSET], NEBOC_TRANSITION_REDACT
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_SOURCE_TRUST_OFFSET], NEBOC_TRUST_RESTRICTED
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_TARGET_TRUST_OFFSET], NEBOC_TRUST_RESTRICTED
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_RETENTION_LIMIT_OFFSET], 10
    ret

analyze:
    lea rdi, [rel envelope]
    jmp neboc_privacy_semantic_analyze

lower_ir:
    lea rdi, [rel envelope]
    jmp neboc_privacy_ir_lower

assert_semantic_success:
    test eax, eax
    jnz fail
    cmp qword [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_ALLOCATIONS_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_ALLOCATION_NONE
    jne fail
    cmp qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_DIAGNOSTIC_OFFSET], 0
    jne fail
    cmp qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_DECISION_OFFSET], NEBOC_PRIVACY_DECISION_PERMIT
    jne fail
    mov r10, [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_HASH_OFFSET]
    test r10, r10
    jz fail
    call semantic_hash_oracle
    cmp rax, r10
    jne fail
    ret

assert_semantic_failure:
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_RESULT_TYPE_OFFSET], 0
    jne fail
    cmp qword [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_ALLOCATIONS_OFFSET], 0
    jne fail
    mov r10, [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_HASH_OFFSET]
    test r10, r10
    jz fail
    call semantic_hash_oracle
    cmp rax, r10
    jne fail
    ret

assert_ir_success:
    test eax, eax
    jnz fail
    cmp qword [rel envelope + NEBOC_IR_HIR_CLASSIFY_OFFSET], NEBOC_HIR_PRIVACY_CLASSIFY
    jne fail
    cmp qword [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_IR_HIR_POLICY_GATE_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_HIR_POLICY_GATE
    jne fail
    cmp qword [rel envelope + NEBOC_IR_HIR_REDACT_OFFSET], NEBOC_HIR_REDACT
    jne fail
    cmp qword [rel envelope + NEBOC_IR_HIR_SINK_GATE_OFFSET], NEBOC_HIR_SINK_GATE
    jne fail
    cmp qword [rel envelope + NEBOC_IR_LIR_LABEL_UNION_OFFSET], NEBOC_LIR_LABEL_UNION
    jne fail
    cmp qword [rel envelope + NEBOC_IR_LIR_REDACT_MASK_OFFSET], NEBOC_LIR_REDACT_MASK
    jne fail
    cmp qword [rel envelope + NEBOC_IR_LIR_TRUST_ASSERT_OFFSET], NEBOC_LIR_TRUST_ASSERT
    jne fail
    cmp qword [rel envelope + NEBOC_IR_LIR_SINK_ASSERT_OFFSET], NEBOC_LIR_SINK_ASSERT
    jne fail
    cmp qword [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_IR_DECISION_OFFSET], NEBOC_PRIVACY_DECISION_PERMIT
    jne fail
    cmp qword [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_IR_DIAGNOSTIC_OFFSET], 0
    jne fail
    cmp qword [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_IR_ALLOCATIONS_OFFSET], 0
    jne fail
    mov r10, [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_IR_HASH_OFFSET]
    test r10, r10
    jz fail
    call ir_hash_oracle
    cmp rax, r10
    jne fail
    ret

assert_ir_failure:
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel envelope + NEBOC_IR_HIR_CLASSIFY_OFFSET], 0
    jne fail
    cmp qword [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_IR_DIAGNOSTIC_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_TYPE_codegen_privacy_x86_64
    jne fail
    cmp qword [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_IR_HASH_OFFSET], 0
    jne fail
    ret

global _start
_start:
    ; 1. Transport errors do not write caller storage.
    xor edi, edi
    call neboc_privacy_semantic_analyze
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    call clear_envelope
    mov qword [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_HASH_OFFSET], 0x1234
    lea rdi, [rel envelope + 1]
    call neboc_privacy_semantic_analyze
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    cmp qword [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_HASH_OFFSET], 0x1234
    jne fail
    xor edi, edi
    call neboc_privacy_ir_lower
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail

    ; 2. Secret/Text redaction succeeds and syntax owns policy composition.
    call prepare_secret_text_redact
    call analyze
    call assert_semantic_success
    cmp qword [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_RESULT_TYPE_OFFSET], NEBOC_PRIVACY_PAYLOAD_TYPE_TEXT
    jne fail
    cmp qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_DIRECT_LABELS_OFFSET], NEBOC_LABEL_SECRET
    jne fail
    cmp qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_REDACTION_MASK_OFFSET], NEBOC_LABEL_SECRET
    jne fail
    cmp qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_TRANSITION_OFFSET], NEBOC_TRANSITION_REDACT
    jne fail
    cmp qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_EFFECTIVE_LABELS_OFFSET], 0
    jne fail
    mov rax, [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_HASH_OFFSET]
    mov [rel saved_semantic_hash], rax

    ; 3. Lowering is deterministic, abstract and clears stale output words.
    lea rdi, [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_IR_OUTPUT_OFFSET]
    mov ecx, neboc_privacidade_dados_sensiveis_e_zero_trust_IR_OUTPUT_QWORDS
    mov rax, -1
    rep stosq
    call lower_ir
    call assert_ir_success
    cmp qword [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_IR_RESULT_TYPE_OFFSET], NEBOC_PRIVACY_PAYLOAD_TYPE_TEXT
    jne fail
    cmp qword [rel envelope + NEBOC_IR_EFFECTIVE_LABELS_OFFSET], 0
    jne fail
    mov rax, [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_IR_HASH_OFFSET]
    mov [rel saved_ir_hash], rax
    call lower_ir
    call assert_ir_success
    mov rax, [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_IR_HASH_OFFSET]
    cmp rax, [rel saved_ir_hash]
    jne fail

    ; 4. PersonalData/Int preserve succeeds and ignores forged caller labels.
    call prepare_personal_int_preserve
    call analyze
    call assert_semantic_success
    cmp qword [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_RESULT_TYPE_OFFSET], NEBOC_PRIVACY_PAYLOAD_TYPE_INT
    jne fail
    cmp qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_DIRECT_LABELS_OFFSET], NEBOC_LABEL_PERSONAL
    jne fail
    cmp qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_REDACTION_MASK_OFFSET], 0
    jne fail
    cmp qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_TRANSITION_OFFSET], NEBOC_TRANSITION_PRESERVE
    jne fail
    call lower_ir
    call assert_ir_success
    cmp qword [rel envelope + NEBOC_IR_EFFECTIVE_LABELS_OFFSET], NEBOC_LABEL_PERSONAL
    jne fail

    ; 5. Every authenticated descriptor family rejects a forged identity.
    call prepare_secret_text_redact
    xor qword [rel envelope + NEBOC_PRIVACY_RESULT_WRAPPER_KIND_OFFSET], 3
    call analyze
    call assert_semantic_failure
    call prepare_secret_text_redact
    inc qword [rel envelope + NEBOC_PRIVACY_RESULT_PAYLOAD_TYPE_ID_OFFSET]
    call analyze
    call assert_semantic_failure
    call prepare_secret_text_redact
    inc qword [rel envelope + NEBOC_PRIVACY_RESULT_DIRECT_LABEL_OFFSET]
    call analyze
    call assert_semantic_failure
    call prepare_secret_text_redact
    xor qword [rel envelope + NEBOC_PRIVACY_RESULT_FLAGS_OFFSET], NEBOC_PRIVACY_FLAG_HAS_REDACT
    call analyze
    call assert_semantic_failure
    call prepare_secret_text_redact
    inc qword [rel envelope + NEBOC_PRIVACY_RESULT_TYPE_SPAN_OFFSET]
    call analyze
    call assert_semantic_failure
    call prepare_secret_text_redact
    inc qword [rel envelope + NEBOC_PRIVACY_RESULT_STATEMENT_SPAN_LENGTH_OFFSET]
    call analyze
    call assert_semantic_failure
    call prepare_secret_text_redact
    xor qword [rel envelope + NEBOC_PRIVACY_RESULT_SHAPE_HASH_OFFSET], 1
    call analyze
    call assert_semantic_failure

    ; 6. Contextual zero-trust denial remains owned by PF001 authority.
    call prepare_personal_int_preserve
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_TARGET_TRUST_OFFSET], NEBOC_TRUST_PUBLIC
    call analyze
    call assert_semantic_failure
    cmp qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_DIAGNOSTIC_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_SECURITY_driver_cli_linux_x86_64
    jne fail

    ; 7. IR authenticates semantic, PF002 and PF001 identities independently.
    call prepare_personal_int_preserve
    call analyze
    call assert_semantic_success
    xor qword [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_HASH_OFFSET], 1
    call lower_ir
    call assert_ir_failure
    call prepare_personal_int_preserve
    call analyze
    call assert_semantic_success
    xor qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_METADATA_HASH_OFFSET], 1
    call refresh_semantic_hash
    call lower_ir
    call assert_ir_failure
    call prepare_personal_int_preserve
    call analyze
    call assert_semantic_success
    mov qword [rel envelope + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_DECISION_OFFSET], NEBOC_PRIVACY_DECISION_DENY
    call refresh_semantic_hash
    call lower_ir
    call assert_ir_failure
    call prepare_personal_int_preserve
    call analyze
    call assert_semantic_success
    inc qword [rel envelope + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_RESULT_TYPE_OFFSET]
    call refresh_semantic_hash
    call lower_ir
    call assert_ir_failure

    ; 8. SysV callee-saved registers survive and both functions leave DF clear.
    call prepare_secret_text_redact
    mov rbx, 0x1111222233334444
    mov rbp, 0x2222333344445555
    mov r12, 0x3333444455556666
    mov r13, 0x4444555566667777
    mov r14, 0x5555666677778888
    mov r15, 0x6666777788889999
    std
    call analyze
    call assert_semantic_success
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
    std
    call lower_ir
    call assert_ir_success
    pushfq
    pop rax
    test rax, 1 << 10
    jnz fail

success:
    xor edi, edi
    jmp neboc_host_process_exit
fail:
    cld
    mov edi, 1
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
