; Nebo Assembly — QUALITY-CONFIDENCE-E-LINEAGE-PF001 deterministic quality/confidence/lineage core
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/quality/quality_lineage.inc"

extern neboc_privacy_evaluate

section .text

; rdi = aligned pointer to a 50-qword request/result
; eax = NEBOC_STATUS_*
;
; The evaluator owns no payload, allocation, clock, I/O or ambient authority.
; privacidade_dados_sensiveis_e_zero_trust is re-evaluated first. Quality and confidence can only stay equal or
; decrease under composition; lineage binds all authenticated metadata.
NEBOC_ABI_FUNCTION neboc_quality_lineage_evaluate
    test rdi, rdi
    jz .invalid_argument
    test rdi, neboc_quality_confidence_e_lineage_ALIGNMENT - 1
    jnz .invalid_argument

    push r12
    mov r12, rdi
    mov qword [r12 + NEBOC_EFFECTIVE_QUALITY_OFFSET], 0
    mov qword [r12 + NEBOC_EFFECTIVE_CONFIDENCE_OFFSET], 0
    mov qword [r12 + NEBOC_PROVENANCE_FLAGS_OFFSET], 0
    mov qword [r12 + NEBOC_LINEAGE_HASH_OFFSET], 0
    mov qword [r12 + neboc_quality_confidence_e_lineage_DIAGNOSTIC_OFFSET], 0
    mov qword [r12 + neboc_quality_confidence_e_lineage_DECISION_OFFSET], 0

    ; Bounds are validated before invoking the predecessor. This makes TYPE
    ; the exact first cause for malformed quality_confidence_e_lineage score domains.
    cmp qword [r12 + NEBOC_DIRECT_QUALITY_OFFSET], NEBOC_SCORE_SCALE
    ja .type_failure
    cmp qword [r12 + NEBOC_INHERITED_QUALITY_OFFSET], NEBOC_SCORE_SCALE
    ja .type_failure
    cmp qword [r12 + NEBOC_DIRECT_CONFIDENCE_OFFSET], NEBOC_SCORE_SCALE
    ja .type_failure
    cmp qword [r12 + NEBOC_INHERITED_CONFIDENCE_OFFSET], NEBOC_SCORE_SCALE
    ja .type_failure
    cmp qword [r12 + NEBOC_MIN_QUALITY_OFFSET], NEBOC_SCORE_SCALE
    ja .type_failure
    cmp qword [r12 + NEBOC_MIN_CONFIDENCE_OFFSET], NEBOC_SCORE_SCALE
    ja .type_failure
    cmp qword [r12 + NEBOC_SOURCE_ID_OFFSET], 0
    je .type_failure
    cmp qword [r12 + NEBOC_TRANSFORM_ID_OFFSET], 0
    je .type_failure

    mov rdi, r12
    call neboc_privacy_evaluate
    test eax, eax
    jnz .security_failure
    cmp qword [r12 + NEBOC_PRIVACY_DECISION_OFFSET], NEBOC_PRIVACY_DECISION_PERMIT
    jne .security_failure
    cmp qword [r12 + NEBOC_PRIVACY_DIAGNOSTIC_OFFSET], 0
    jne .security_failure
    mov qword [r12 + NEBOC_PROVENANCE_FLAGS_OFFSET], NEBOC_PROVENANCE_PRIVACY_AUTHENTICATED

    ; Monotonic composition is min(direct, inherited). No caller flag can
    ; raise either score above its least trustworthy input.
    mov rax, [r12 + NEBOC_DIRECT_QUALITY_OFFSET]
    mov rdx, [r12 + NEBOC_INHERITED_QUALITY_OFFSET]
    cmp rax, rdx
    cmova rax, rdx
    mov [r12 + NEBOC_EFFECTIVE_QUALITY_OFFSET], rax
    or qword [r12 + NEBOC_PROVENANCE_FLAGS_OFFSET], NEBOC_PROVENANCE_QUALITY_PROPAGATED

    mov rax, [r12 + NEBOC_DIRECT_CONFIDENCE_OFFSET]
    mov rdx, [r12 + NEBOC_INHERITED_CONFIDENCE_OFFSET]
    cmp rax, rdx
    cmova rax, rdx
    mov [r12 + NEBOC_EFFECTIVE_CONFIDENCE_OFFSET], rax
    or qword [r12 + NEBOC_PROVENANCE_FLAGS_OFFSET], NEBOC_PROVENANCE_CONFIDENCE_PROPAGATED

    mov rax, [r12 + NEBOC_EFFECTIVE_QUALITY_OFFSET]
    cmp rax, [r12 + NEBOC_MIN_QUALITY_OFFSET]
    jb .security_failure
    mov rax, [r12 + NEBOC_EFFECTIVE_CONFIDENCE_OFFSET]
    cmp rax, [r12 + NEBOC_MIN_CONFIDENCE_OFFSET]
    jb .security_failure
    or qword [r12 + NEBOC_PROVENANCE_FLAGS_OFFSET], NEBOC_PROVENANCE_LINEAGE_BOUND
    xor r9d, r9d
    jmp .hash_metadata

.type_failure:
    mov qword [r12 + neboc_quality_confidence_e_lineage_DIAGNOSTIC_OFFSET], neboc_quality_confidence_e_lineage_DIAG_TYPE_codegen_quality_x86_64
    mov r9d, NEBOC_STATUS_INVALID_SOURCE
    jmp .hash_metadata
.security_failure:
    mov qword [r12 + neboc_quality_confidence_e_lineage_DIAGNOSTIC_OFFSET], neboc_quality_confidence_e_lineage_DIAG_SECURITY_codegen_quality_x86_64
    mov r9d, NEBOC_STATUS_INVALID_SOURCE

.hash_metadata:
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.hash_loop:
    cmp rcx, neboc_quality_confidence_e_lineage_HASHED_BYTES
    jae .hash_done
    movzx edx, byte [r12 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .hash_loop
.hash_done:
    ; Bind an explicit parent hash after the record domain to avoid relying
    ; on addresses or mutable graph storage.
    mov rdx, [r12 + NEBOC_PARENT_LINEAGE_HASH_OFFSET]
    xor rax, rdx
    imul rax, r8
    mov [r12 + NEBOC_LINEAGE_HASH_OFFSET], rax
    test r9d, r9d
    jnz .return_status
    mov qword [r12 + neboc_quality_confidence_e_lineage_DECISION_OFFSET], neboc_quality_confidence_e_lineage_DECISION_PERMIT
.return_status:
    mov eax, r9d
    pop r12
    cld
    ret

.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
