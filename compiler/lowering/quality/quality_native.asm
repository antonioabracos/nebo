; Nebo Assembly — QUALITY-CONFIDENCE-E-LINEAGE-PF004 authenticated native plan
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/quality/quality_native.inc"

section .text

NEBOC_ABI_FUNCTION neboc_quality_native_lower
    test rdi, rdi
    jz .invalid_argument
    test rdi, neboc_quality_confidence_e_lineage_NATIVE_ALIGNMENT - 1
    jnz .invalid_argument
    cld
    mov r10, rdi
    lea rdi, [r10 + neboc_quality_confidence_e_lineage_NATIVE_OUTPUT_OFFSET]
    mov ecx, neboc_quality_confidence_e_lineage_NATIVE_OUTPUT_QWORDS
    xor eax, eax
    rep stosq

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
    cmp rax, [r10 + neboc_quality_confidence_e_lineage_IR_HASH_OFFSET]
    jne .invalid_source
    cmp qword [r10 + NEBOC_IR_HIR_QUALITY_OFFSET], NEBOC_HIR_QUALITY_PROPAGATE
    jne .invalid_source
    cmp qword [r10 + NEBOC_IR_HIR_CONFIDENCE_OFFSET], NEBOC_HIR_CONFIDENCE_PROPAGATE
    jne .invalid_source
    cmp qword [r10 + NEBOC_IR_HIR_LINEAGE_OFFSET], NEBOC_HIR_LINEAGE_BIND
    jne .invalid_source
    cmp qword [r10 + NEBOC_IR_HIR_THRESHOLD_GATE_OFFSET], NEBOC_HIR_THRESHOLD_GATE
    jne .invalid_source
    cmp qword [r10 + NEBOC_IR_LIR_MIN_QUALITY_OFFSET], NEBOC_LIR_MIN_QUALITY
    jne .invalid_source
    cmp qword [r10 + NEBOC_IR_LIR_MIN_CONFIDENCE_OFFSET], NEBOC_LIR_MIN_CONFIDENCE
    jne .invalid_source
    cmp qword [r10 + NEBOC_IR_LIR_LINEAGE_HASH_OFFSET], NEBOC_LIR_LINEAGE_HASH
    jne .invalid_source
    cmp qword [r10 + NEBOC_IR_LIR_SECURITY_ASSERT_OFFSET], NEBOC_LIR_SECURITY_ASSERT
    jne .invalid_source
    cmp qword [r10 + neboc_quality_confidence_e_lineage_IR_DECISION_OFFSET], neboc_quality_confidence_e_lineage_DECISION_PERMIT
    jne .invalid_source
    cmp qword [r10 + neboc_quality_confidence_e_lineage_IR_DIAGNOSTIC_OFFSET], 0
    jne .invalid_source
    cmp qword [r10 + neboc_quality_confidence_e_lineage_IR_ALLOCATIONS_OFFSET], 0
    jne .invalid_source
    cmp qword [r10 + NEBOC_IR_EFFECTIVE_QUALITY_OFFSET], NEBOC_SCORE_SCALE
    ja .invalid_source
    cmp qword [r10 + NEBOC_IR_EFFECTIVE_CONFIDENCE_OFFSET], NEBOC_SCORE_SCALE
    ja .invalid_source
    cmp qword [r10 + NEBOC_IR_LINEAGE_HASH_OFFSET], 0
    je .invalid_source

    mov qword [r10 + neboc_quality_confidence_e_lineage_NATIVE_TARGET_OFFSET], NEBOC_NATIVE_TARGET_X86_64_SYSV
    mov qword [r10 + NEBOC_NATIVE_WORD_BYTES_OFFSET], NEBOC_NATIVE_WORD_BYTES
    mov qword [r10 + NEBOC_NATIVE_SCORE_SCALE_OFFSET], NEBOC_SCORE_SCALE
    mov qword [r10 + NEBOC_NATIVE_RUNTIME_GATE_OFFSET], NEBOC_NATIVE_RUNTIME_GATE_ID
    mov rax, [r10 + neboc_quality_confidence_e_lineage_IR_RESULT_TYPE_OFFSET]
    mov [r10 + neboc_quality_confidence_e_lineage_NATIVE_RESULT_TYPE_OFFSET], rax
    mov rax, [r10 + NEBOC_IR_EFFECTIVE_QUALITY_OFFSET]
    mov [r10 + NEBOC_NATIVE_EFFECTIVE_QUALITY_OFFSET], rax
    mov rax, [r10 + NEBOC_IR_EFFECTIVE_CONFIDENCE_OFFSET]
    mov [r10 + NEBOC_NATIVE_EFFECTIVE_CONFIDENCE_OFFSET], rax
    mov rax, [r10 + NEBOC_IR_LINEAGE_HASH_OFFSET]
    mov [r10 + NEBOC_NATIVE_LINEAGE_HASH_OFFSET], rax
    mov qword [r10 + neboc_quality_confidence_e_lineage_NATIVE_DECISION_OFFSET], neboc_quality_confidence_e_lineage_DECISION_PERMIT

    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.native_hash_loop:
    cmp rcx, neboc_quality_confidence_e_lineage_NATIVE_HASHED_BYTES
    jae .native_hash_done
    movzx edx, byte [r10 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .native_hash_loop
.native_hash_done:
    mov [r10 + neboc_quality_confidence_e_lineage_NATIVE_HASH_OFFSET], rax
    xor eax, eax
    cld
    ret

.invalid_source:
    lea rdi, [r10 + neboc_quality_confidence_e_lineage_NATIVE_OUTPUT_OFFSET]
    mov ecx, neboc_quality_confidence_e_lineage_NATIVE_OUTPUT_QWORDS
    xor eax, eax
    rep stosq
    mov qword [r10 + neboc_quality_confidence_e_lineage_NATIVE_DIAGNOSTIC_OFFSET], neboc_quality_confidence_e_lineage_DIAG_CODEGEN_codegen_quality_x86_64
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    cld
    ret
.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
