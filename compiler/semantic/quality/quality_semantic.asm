; Nebo Assembly — QUALITY-CONFIDENCE-E-LINEAGE-PF003 quality/confidence/lineage semantic envelope
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/quality/quality_semantic.inc"

extern neboc_quality_lineage_evaluate

section .text

; neboc_quality_semantic_analyze(envelope*) -> StatusCode
; Syntax owns the score and lineage inputs. PF001 remains the sole owner of
; contextual privacy, threshold authority and monotonic composition.
NEBOC_ABI_FUNCTION neboc_quality_semantic_analyze
    test rdi, rdi
    jz .invalid_argument
    test rdi, neboc_quality_confidence_e_lineage_SEMANTIC_ALIGNMENT - 1
    jnz .invalid_argument
    cld
    push r12
    mov r12, rdi
    mov qword [r12 + neboc_quality_confidence_e_lineage_SEMANTIC_RESULT_TYPE_OFFSET], 0
    mov qword [r12 + NEBOC_SEMANTIC_EFFECTIVE_QUALITY_OFFSET], 0
    mov qword [r12 + NEBOC_SEMANTIC_EFFECTIVE_CONFIDENCE_OFFSET], 0
    mov qword [r12 + NEBOC_SEMANTIC_LINEAGE_HASH_OFFSET], 0
    mov qword [r12 + neboc_quality_confidence_e_lineage_SEMANTIC_HASH_OFFSET], 0
    mov qword [r12 + neboc_quality_confidence_e_lineage_SEMANTIC_ALLOCATIONS_OFFSET], 0

    cmp qword [r12 + NEBOC_RESULT_DIRECT_QUALITY_OFFSET], NEBOC_SCORE_SCALE
    ja .descriptor_failure
    cmp qword [r12 + NEBOC_RESULT_INHERITED_QUALITY_OFFSET], NEBOC_SCORE_SCALE
    ja .descriptor_failure
    cmp qword [r12 + NEBOC_RESULT_DIRECT_CONFIDENCE_OFFSET], NEBOC_SCORE_SCALE
    ja .descriptor_failure
    cmp qword [r12 + NEBOC_RESULT_INHERITED_CONFIDENCE_OFFSET], NEBOC_SCORE_SCALE
    ja .descriptor_failure
    cmp qword [r12 + NEBOC_RESULT_MIN_QUALITY_OFFSET], NEBOC_SCORE_SCALE
    ja .descriptor_failure
    cmp qword [r12 + NEBOC_RESULT_MIN_CONFIDENCE_OFFSET], NEBOC_SCORE_SCALE
    ja .descriptor_failure
    cmp qword [r12 + NEBOC_RESULT_SOURCE_ID_OFFSET], 0
    je .descriptor_failure
    cmp qword [r12 + NEBOC_RESULT_TRANSFORM_ID_OFFSET], 0
    je .descriptor_failure
    cmp qword [r12 + neboc_quality_confidence_e_lineage_RESULT_FLAGS_OFFSET], NEBOC_RESULT_FLAG_CANONICAL
    jne .descriptor_failure
    mov rax, [r12 + NEBOC_RESULT_STATEMENT_LENGTH_OFFSET]
    test rax, rax
    jz .descriptor_failure
    cmp rax, neboc_quality_confidence_e_lineage_PARSE_MAX_SOURCE_BYTES
    ja .descriptor_failure
    cmp qword [r12 + NEBOC_RESULT_RESERVED_OFFSET], 0
    jne .descriptor_failure

    ; Authenticate the exact PF002 q0..q10 preimage.
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.shape_hash_loop:
    cmp rcx, NEBOC_RESULT_HASHED_BYTES
    jae .shape_hash_done
    movzx edx, byte [r12 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .shape_hash_loop
.shape_hash_done:
    cmp rax, [r12 + NEBOC_RESULT_SHAPE_HASH_OFFSET]
    jne .descriptor_failure

    ; Overwrite every syntax-owned PF001 input before authority evaluation.
    mov rax, [r12 + NEBOC_RESULT_DIRECT_QUALITY_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_DIRECT_QUALITY_OFFSET], rax
    mov rax, [r12 + NEBOC_RESULT_INHERITED_QUALITY_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_INHERITED_QUALITY_OFFSET], rax
    mov rax, [r12 + NEBOC_RESULT_DIRECT_CONFIDENCE_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_DIRECT_CONFIDENCE_OFFSET], rax
    mov rax, [r12 + NEBOC_RESULT_INHERITED_CONFIDENCE_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_INHERITED_CONFIDENCE_OFFSET], rax
    mov rax, [r12 + NEBOC_RESULT_MIN_QUALITY_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_MIN_QUALITY_OFFSET], rax
    mov rax, [r12 + NEBOC_RESULT_MIN_CONFIDENCE_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_MIN_CONFIDENCE_OFFSET], rax
    mov rax, [r12 + NEBOC_RESULT_SOURCE_ID_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_SOURCE_ID_OFFSET], rax
    mov rax, [r12 + NEBOC_RESULT_TRANSFORM_ID_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_TRANSFORM_ID_OFFSET], rax
    mov rax, [r12 + NEBOC_RESULT_PARENT_HASH_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_PARENT_LINEAGE_HASH_OFFSET], rax

    lea rdi, [r12 + NEBOC_SEMANTIC_QUALITY_OFFSET]
    call neboc_quality_lineage_evaluate
    mov r9d, eax
    test eax, eax
    jnz .semantic_hash
    mov qword [r12 + neboc_quality_confidence_e_lineage_SEMANTIC_RESULT_TYPE_OFFSET], NEBOC_SEMANTIC_TYPE_INT
    mov rax, [r12 + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_EFFECTIVE_QUALITY_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_EFFECTIVE_QUALITY_OFFSET], rax
    mov rax, [r12 + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_EFFECTIVE_CONFIDENCE_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_EFFECTIVE_CONFIDENCE_OFFSET], rax
    mov rax, [r12 + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_LINEAGE_HASH_OFFSET]
    mov [r12 + NEBOC_SEMANTIC_LINEAGE_HASH_OFFSET], rax
    jmp .semantic_hash

.descriptor_failure:
    lea rdi, [r12 + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_EFFECTIVE_QUALITY_OFFSET]
    mov ecx, 6
    xor eax, eax
    rep stosq
    mov qword [r12 + NEBOC_SEMANTIC_QUALITY_OFFSET + neboc_quality_confidence_e_lineage_DIAGNOSTIC_OFFSET], neboc_quality_confidence_e_lineage_DIAG_TYPE_codegen_quality_x86_64
    mov r9d, NEBOC_STATUS_INVALID_SOURCE

.semantic_hash:
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.semantic_hash_loop:
    cmp rcx, neboc_quality_confidence_e_lineage_SEMANTIC_HASHED_BYTES
    jae .semantic_hash_done
    movzx edx, byte [r12 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .semantic_hash_loop
.semantic_hash_done:
    mov [r12 + neboc_quality_confidence_e_lineage_SEMANTIC_HASH_OFFSET], rax
    mov eax, r9d
    pop r12
    cld
    ret

.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
