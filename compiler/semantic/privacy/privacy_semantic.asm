; Nebo Assembly — PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-PF003 contextual privacy semantic envelope
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/privacy/privacy_semantic.inc"

extern neboc_privacy_evaluate

section .text

; neboc_privacy_semantic_analyze(envelope*) -> StatusCode
; The function derives direct labels, redaction and transition only from the
; authenticated PF002 descriptor, then delegates all authority to PF001.
NEBOC_ABI_FUNCTION neboc_privacy_semantic_analyze
    test rdi, rdi
    jz .invalid_argument
    test rdi, neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_ALIGNMENT - 1
    jnz .invalid_argument

    cld
    push r12
    mov r12, rdi
    mov qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_RESULT_TYPE_OFFSET], 0
    mov qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_HASH_OFFSET], 0
    mov qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_ALLOCATIONS_OFFSET], 0

    ; Closed descriptor identity and canonical FNV over q0..q4.
    mov rax, [r12 + NEBOC_PRIVACY_RESULT_WRAPPER_KIND_OFFSET]
    cmp rax, NEBOC_PRIVACY_WRAPPER_SECRET
    je .wrapper_secret
    cmp rax, NEBOC_PRIVACY_WRAPPER_PERSONAL_DATA
    jne .descriptor_failure
    cmp qword [r12 + NEBOC_PRIVACY_RESULT_DIRECT_LABEL_OFFSET], NEBOC_LABEL_PERSONAL
    jne .descriptor_failure
    cmp qword [r12 + NEBOC_PRIVACY_RESULT_WRAPPER_SPAN_LENGTH_OFFSET], 12
    jne .descriptor_failure
    jmp .wrapper_ready
.wrapper_secret:
    cmp qword [r12 + NEBOC_PRIVACY_RESULT_DIRECT_LABEL_OFFSET], NEBOC_LABEL_SECRET
    jne .descriptor_failure
    cmp qword [r12 + NEBOC_PRIVACY_RESULT_WRAPPER_SPAN_LENGTH_OFFSET], 6
    jne .descriptor_failure
.wrapper_ready:
    mov rax, [r12 + NEBOC_PRIVACY_RESULT_PAYLOAD_TYPE_ID_OFFSET]
    cmp rax, NEBOC_PRIVACY_PAYLOAD_TYPE_INT
    je .type_int
    cmp rax, NEBOC_PRIVACY_PAYLOAD_TYPE_TEXT
    jne .descriptor_failure
    cmp qword [r12 + NEBOC_PRIVACY_RESULT_TYPE_SPAN_LENGTH_OFFSET], 4
    jne .descriptor_failure
    jmp .type_ready
.type_int:
    cmp qword [r12 + NEBOC_PRIVACY_RESULT_TYPE_SPAN_LENGTH_OFFSET], 3
    jne .descriptor_failure
.type_ready:
    mov rax, [r12 + NEBOC_PRIVACY_RESULT_REDACTION_MASK_OFFSET]
    test rax, ~NEBOC_LABEL_MASK_KNOWN
    jnz .descriptor_failure
    mov rdx, [r12 + NEBOC_PRIVACY_RESULT_FLAGS_OFFSET]
    cmp rdx, NEBOC_PRIVACY_FLAG_CANONICAL
    je .preserve_shape
    cmp rdx, NEBOC_PRIVACY_FLAG_CANONICAL | NEBOC_PRIVACY_FLAG_HAS_REDACT
    jne .descriptor_failure
    test rax, rax
    jz .descriptor_failure
    cmp qword [r12 + NEBOC_PRIVACY_RESULT_REDACT_SPAN_LENGTH_OFFSET], 0
    je .descriptor_failure
    jmp .span_shape
.preserve_shape:
    test rax, rax
    jnz .descriptor_failure
    cmp qword [r12 + NEBOC_PRIVACY_RESULT_REDACT_SPAN_OFFSET], 0
    jne .descriptor_failure
    cmp qword [r12 + NEBOC_PRIVACY_RESULT_REDACT_SPAN_LENGTH_OFFSET], 0
    jne .descriptor_failure
.span_shape:
    cmp qword [r12 + NEBOC_PRIVACY_RESULT_STATEMENT_SPAN_LENGTH_OFFSET], 0
    je .descriptor_failure
    ; The pointerless spans must still form one canonical, non-overlapping
    ; statement.  This rejects authenticated shape words paired with forged
    ; locations before contextual policy evaluation is reachable.
    mov rax, [r12 + NEBOC_PRIVACY_RESULT_WRAPPER_SPAN_OFFSET]
    mov rdx, rax
    add rdx, [r12 + NEBOC_PRIVACY_RESULT_WRAPPER_SPAN_LENGTH_OFFSET]
    jc .descriptor_failure
    inc rdx                         ; canonical '<'
    jc .descriptor_failure
    cmp rdx, [r12 + NEBOC_PRIVACY_RESULT_TYPE_SPAN_OFFSET]
    jne .descriptor_failure
    add rdx, [r12 + NEBOC_PRIVACY_RESULT_TYPE_SPAN_LENGTH_OFFSET]
    jc .descriptor_failure
    inc rdx                         ; canonical '>'
    jc .descriptor_failure
    test qword [r12 + NEBOC_PRIVACY_RESULT_FLAGS_OFFSET], NEBOC_PRIVACY_FLAG_HAS_REDACT
    jz .preserve_span_end
    cmp rdx, [r12 + NEBOC_PRIVACY_RESULT_REDACT_SPAN_OFFSET]
    jne .descriptor_failure
    add rdx, [r12 + NEBOC_PRIVACY_RESULT_REDACT_SPAN_LENGTH_OFFSET]
    jc .descriptor_failure
.preserve_span_end:
    inc rdx                         ; canonical ';'
    jc .descriptor_failure
    sub rdx, rax
    cmp rdx, [r12 + NEBOC_PRIVACY_RESULT_STATEMENT_SPAN_LENGTH_OFFSET]
    jne .descriptor_failure

    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.shape_hash_loop:
    cmp rcx, NEBOC_PRIVACY_HASHED_OUTPUT_BYTES
    jae .shape_hash_done
    movzx edx, byte [r12 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .shape_hash_loop
.shape_hash_done:
    cmp rax, [r12 + NEBOC_PRIVACY_RESULT_SHAPE_HASH_OFFSET]
    jne .descriptor_failure

    ; Compose the PF001 record. Contextual fields remain caller-owned; the
    ; three syntax-owned fields are always overwritten before evaluation.
    mov rax, [r12 + NEBOC_PRIVACY_RESULT_DIRECT_LABEL_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_DIRECT_LABELS_OFFSET], rax
    mov rax, [r12 + NEBOC_PRIVACY_RESULT_REDACTION_MASK_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_REDACTION_MASK_OFFSET], rax
    xor eax, eax
    test qword [r12 + NEBOC_PRIVACY_RESULT_FLAGS_OFFSET], NEBOC_PRIVACY_FLAG_HAS_REDACT
    setnz al
    mov [r12 + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_TRANSITION_OFFSET], rax

    lea rdi, [r12 + NEBOC_SEMANTIC_PRIVACY_OFFSET]
    call neboc_privacy_evaluate
    mov r9d, eax
    test eax, eax
    jnz .semantic_hash
    mov rax, [r12 + NEBOC_PRIVACY_RESULT_PAYLOAD_TYPE_ID_OFFSET]
    mov [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_RESULT_TYPE_OFFSET], rax
    jmp .semantic_hash

.descriptor_failure:
    lea rdi, [r12 + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_INFERRED_LABELS_OFFSET]
    mov ecx, 7
    xor eax, eax
    rep stosq
    mov qword [r12 + NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_DIAGNOSTIC_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_TYPE_codegen_privacy_x86_64
    mov r9d, NEBOC_STATUS_INVALID_SOURCE

.semantic_hash:
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.semantic_hash_loop:
    cmp rcx, neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_HASHED_BYTES
    jae .semantic_hash_done
    movzx edx, byte [r12 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .semantic_hash_loop
.semantic_hash_done:
    mov [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_HASH_OFFSET], rax
    mov eax, r9d
    pop r12
    cld
    ret

.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
