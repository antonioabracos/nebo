; Nebo Assembly — QUALITY-CONFIDENCE-E-LINEAGE-PF003 target-neutral quality HIR/LIR contract
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/quality/quality_ir.inc"

section .text

NEBOC_ABI_FUNCTION neboc_quality_ir_lower
    test rdi, rdi
    jz .invalid_argument
    test rdi, neboc_quality_confidence_e_lineage_IR_ALIGNMENT - 1
    jnz .invalid_argument
    cld
    mov r10, rdi
    lea rdi, [r10 + neboc_quality_confidence_e_lineage_IR_OUTPUT_OFFSET]
    mov ecx, neboc_quality_confidence_e_lineage_IR_OUTPUT_QWORDS
    xor eax, eax
    rep stosq

    ; Authenticate semantic, syntax and PF001 identities independently.
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.semantic_hash_loop:
    cmp rcx, neboc_quality_confidence_e_lineage_SEMANTIC_HASHED_BYTES
    jae .semantic_hash_done
    movzx edx, byte [r10 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .semantic_hash_loop
.semantic_hash_done:
    cmp rax, [r10 + neboc_quality_confidence_e_lineage_SEMANTIC_HASH_OFFSET]
    jne .invalid_source
    cmp qword [r10 + neboc_quality_confidence_e_lineage_SEMANTIC_ALLOCATIONS_OFFSET], 0
    jne .invalid_source

    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.shape_hash_loop:
    cmp rcx, NEBOC_RESULT_HASHED_BYTES
    jae .shape_hash_done
    movzx edx, byte [r10 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .shape_hash_loop
.shape_hash_done:
    cmp rax, [r10 + NEBOC_RESULT_SHAPE_HASH_OFFSET]
    jne .invalid_source

    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.lineage_hash_loop:
    cmp rcx, neboc_quality_confidence_e_lineage_HASHED_BYTES
    jae .lineage_hash_done
    movzx edx, byte [r10 + NEBOC_SEMANTIC_QUALITY_OFFSET + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .lineage_hash_loop
.lineage_hash_done:
    mov rdx, [r10 + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_PARENT_LINEAGE_HASH_OFFSET]
    xor rax, rdx
    imul rax, r8
    cmp rax, [r10 + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_LINEAGE_HASH_OFFSET]
    jne .invalid_source

    cmp qword [r10 + NEBOC_SEMANTIC_QUALITY_OFFSET + neboc_quality_confidence_e_lineage_DIAGNOSTIC_OFFSET], 0
    jne .invalid_source
    cmp qword [r10 + NEBOC_SEMANTIC_QUALITY_OFFSET + neboc_quality_confidence_e_lineage_DECISION_OFFSET], neboc_quality_confidence_e_lineage_DECISION_PERMIT
    jne .invalid_source
    cmp qword [r10 + neboc_quality_confidence_e_lineage_SEMANTIC_RESULT_TYPE_OFFSET], NEBOC_SEMANTIC_TYPE_INT
    jne .invalid_source
    mov rax, [r10 + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_EFFECTIVE_QUALITY_OFFSET]
    cmp rax, [r10 + NEBOC_SEMANTIC_EFFECTIVE_QUALITY_OFFSET]
    jne .invalid_source
    mov rax, [r10 + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_EFFECTIVE_CONFIDENCE_OFFSET]
    cmp rax, [r10 + NEBOC_SEMANTIC_EFFECTIVE_CONFIDENCE_OFFSET]
    jne .invalid_source
    mov rax, [r10 + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_LINEAGE_HASH_OFFSET]
    cmp rax, [r10 + NEBOC_SEMANTIC_LINEAGE_HASH_OFFSET]
    jne .invalid_source

    mov qword [r10 + NEBOC_IR_HIR_QUALITY_OFFSET], NEBOC_HIR_QUALITY_PROPAGATE
    mov qword [r10 + NEBOC_IR_HIR_CONFIDENCE_OFFSET], NEBOC_HIR_CONFIDENCE_PROPAGATE
    mov qword [r10 + NEBOC_IR_HIR_LINEAGE_OFFSET], NEBOC_HIR_LINEAGE_BIND
    mov qword [r10 + NEBOC_IR_HIR_THRESHOLD_GATE_OFFSET], NEBOC_HIR_THRESHOLD_GATE
    mov qword [r10 + NEBOC_IR_LIR_MIN_QUALITY_OFFSET], NEBOC_LIR_MIN_QUALITY
    mov qword [r10 + NEBOC_IR_LIR_MIN_CONFIDENCE_OFFSET], NEBOC_LIR_MIN_CONFIDENCE
    mov qword [r10 + NEBOC_IR_LIR_LINEAGE_HASH_OFFSET], NEBOC_LIR_LINEAGE_HASH
    mov qword [r10 + NEBOC_IR_LIR_SECURITY_ASSERT_OFFSET], NEBOC_LIR_SECURITY_ASSERT
    mov rax, [r10 + neboc_quality_confidence_e_lineage_SEMANTIC_RESULT_TYPE_OFFSET]
    mov [r10 + neboc_quality_confidence_e_lineage_IR_RESULT_TYPE_OFFSET], rax
    mov rax, [r10 + NEBOC_SEMANTIC_EFFECTIVE_QUALITY_OFFSET]
    mov [r10 + NEBOC_IR_EFFECTIVE_QUALITY_OFFSET], rax
    mov rax, [r10 + NEBOC_SEMANTIC_EFFECTIVE_CONFIDENCE_OFFSET]
    mov [r10 + NEBOC_IR_EFFECTIVE_CONFIDENCE_OFFSET], rax
    mov rax, [r10 + NEBOC_SEMANTIC_LINEAGE_HASH_OFFSET]
    mov [r10 + NEBOC_IR_LINEAGE_HASH_OFFSET], rax
    mov qword [r10 + neboc_quality_confidence_e_lineage_IR_DECISION_OFFSET], neboc_quality_confidence_e_lineage_DECISION_PERMIT

    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.ir_hash_loop:
    cmp rcx, neboc_quality_confidence_e_lineage_IR_HASHED_BYTES
    jae .ir_hash_done
    movzx edx, byte [r10 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .ir_hash_loop
.ir_hash_done:
    mov [r10 + neboc_quality_confidence_e_lineage_IR_HASH_OFFSET], rax
    xor eax, eax
    cld
    ret

.invalid_source:
    lea rdi, [r10 + neboc_quality_confidence_e_lineage_IR_OUTPUT_OFFSET]
    mov ecx, neboc_quality_confidence_e_lineage_IR_OUTPUT_QWORDS
    xor eax, eax
    rep stosq
    mov qword [r10 + neboc_quality_confidence_e_lineage_IR_DIAGNOSTIC_OFFSET], neboc_quality_confidence_e_lineage_DIAG_TYPE_codegen_quality_x86_64
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    cld
    ret

.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
