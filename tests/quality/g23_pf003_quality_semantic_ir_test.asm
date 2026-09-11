; QUALITY-CONFIDENCE-E-LINEAGE-PF003 semantic and target-neutral IR contract tests
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/quality/quality_ir.inc"

extern neboc_quality_semantic_analyze
extern neboc_quality_ir_lower
extern neboc_host_process_exit

section .bss align=16
envelope: resb neboc_quality_confidence_e_lineage_IR_REQUEST_SIZE
saved_semantic_hash: resq 1
saved_ir_hash: resq 1

section .text
hash_memory:
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor edx, edx
.loop:
    cmp edx, ecx
    jae .done
    movzx r9d, byte [rdi + rdx]
    xor rax, r9
    imul rax, r8
    inc edx
    jmp .loop
.done:
    ret

clear_envelope:
    lea rdi, [rel envelope]
    mov ecx, neboc_quality_confidence_e_lineage_IR_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    ret

refresh_shape_hash:
    lea rdi, [rel envelope]
    mov ecx, NEBOC_RESULT_HASHED_BYTES
    call hash_memory
    mov [rel envelope + NEBOC_RESULT_SHAPE_HASH_OFFSET], rax
    ret

refresh_semantic_hash:
    lea rdi, [rel envelope]
    mov ecx, neboc_quality_confidence_e_lineage_SEMANTIC_HASHED_BYTES
    call hash_memory
    mov [rel envelope + neboc_quality_confidence_e_lineage_SEMANTIC_HASH_OFFSET], rax
    ret

prepare_valid:
    call clear_envelope
    mov qword [rel envelope + NEBOC_RESULT_DIRECT_QUALITY_OFFSET], 900000
    mov qword [rel envelope + NEBOC_RESULT_INHERITED_QUALITY_OFFSET], 800000
    mov qword [rel envelope + NEBOC_RESULT_DIRECT_CONFIDENCE_OFFSET], 950000
    mov qword [rel envelope + NEBOC_RESULT_INHERITED_CONFIDENCE_OFFSET], 700000
    mov qword [rel envelope + NEBOC_RESULT_MIN_QUALITY_OFFSET], 750000
    mov qword [rel envelope + NEBOC_RESULT_MIN_CONFIDENCE_OFFSET], 650000
    mov qword [rel envelope + NEBOC_RESULT_SOURCE_ID_OFFSET], 2301
    mov qword [rel envelope + NEBOC_RESULT_TRANSFORM_ID_OFFSET], 2302
    mov rax, 0x1122334455667788
    mov [rel envelope + NEBOC_RESULT_PARENT_HASH_OFFSET], rax
    mov qword [rel envelope + neboc_quality_confidence_e_lineage_RESULT_FLAGS_OFFSET], NEBOC_RESULT_FLAG_CANONICAL
    mov qword [rel envelope + NEBOC_RESULT_STATEMENT_LENGTH_OFFSET], 93
    ; Empty/public privacidade_dados_sensiveis_e_zero_trust predecessor with bounded retention.
    mov qword [rel envelope + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_POLICY_PERMIT_OFFSET], 23
    mov qword [rel envelope + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_PRIVACY_RETENTION_LIMIT_OFFSET], 1
    call refresh_shape_hash
    ret

analyze:
    lea rdi, [rel envelope]
    jmp neboc_quality_semantic_analyze

lower_ir:
    lea rdi, [rel envelope]
    jmp neboc_quality_ir_lower

assert_semantic_success:
    test eax, eax
    jnz fail
    cmp qword [rel envelope + neboc_quality_confidence_e_lineage_SEMANTIC_RESULT_TYPE_OFFSET], NEBOC_SEMANTIC_TYPE_INT
    jne fail
    cmp qword [rel envelope + NEBOC_SEMANTIC_EFFECTIVE_QUALITY_OFFSET], 800000
    jne fail
    cmp qword [rel envelope + NEBOC_SEMANTIC_EFFECTIVE_CONFIDENCE_OFFSET], 700000
    jne fail
    cmp qword [rel envelope + neboc_quality_confidence_e_lineage_SEMANTIC_ALLOCATIONS_OFFSET], 0
    jne fail
    cmp qword [rel envelope + NEBOC_SEMANTIC_QUALITY_OFFSET + neboc_quality_confidence_e_lineage_DIAGNOSTIC_OFFSET], 0
    jne fail
    cmp qword [rel envelope + NEBOC_SEMANTIC_QUALITY_OFFSET + neboc_quality_confidence_e_lineage_DECISION_OFFSET], neboc_quality_confidence_e_lineage_DECISION_PERMIT
    jne fail
    mov r10, [rel envelope + neboc_quality_confidence_e_lineage_SEMANTIC_HASH_OFFSET]
    test r10, r10
    jz fail
    lea rdi, [rel envelope]
    mov ecx, neboc_quality_confidence_e_lineage_SEMANTIC_HASHED_BYTES
    call hash_memory
    cmp rax, r10
    jne fail
    ret

assert_ir_success:
    test eax, eax
    jnz fail
    cmp qword [rel envelope + NEBOC_IR_HIR_QUALITY_OFFSET], NEBOC_HIR_QUALITY_PROPAGATE
    jne fail
    cmp qword [rel envelope + NEBOC_IR_HIR_CONFIDENCE_OFFSET], NEBOC_HIR_CONFIDENCE_PROPAGATE
    jne fail
    cmp qword [rel envelope + NEBOC_IR_HIR_LINEAGE_OFFSET], NEBOC_HIR_LINEAGE_BIND
    jne fail
    cmp qword [rel envelope + NEBOC_IR_HIR_THRESHOLD_GATE_OFFSET], NEBOC_HIR_THRESHOLD_GATE
    jne fail
    cmp qword [rel envelope + NEBOC_IR_LIR_MIN_QUALITY_OFFSET], NEBOC_LIR_MIN_QUALITY
    jne fail
    cmp qword [rel envelope + NEBOC_IR_LIR_MIN_CONFIDENCE_OFFSET], NEBOC_LIR_MIN_CONFIDENCE
    jne fail
    cmp qword [rel envelope + NEBOC_IR_LIR_LINEAGE_HASH_OFFSET], NEBOC_LIR_LINEAGE_HASH
    jne fail
    cmp qword [rel envelope + NEBOC_IR_LIR_SECURITY_ASSERT_OFFSET], NEBOC_LIR_SECURITY_ASSERT
    jne fail
    cmp qword [rel envelope + NEBOC_IR_EFFECTIVE_QUALITY_OFFSET], 800000
    jne fail
    cmp qword [rel envelope + NEBOC_IR_EFFECTIVE_CONFIDENCE_OFFSET], 700000
    jne fail
    cmp qword [rel envelope + neboc_quality_confidence_e_lineage_IR_DECISION_OFFSET], neboc_quality_confidence_e_lineage_DECISION_PERMIT
    jne fail
    cmp qword [rel envelope + neboc_quality_confidence_e_lineage_IR_DIAGNOSTIC_OFFSET], 0
    jne fail
    mov r10, [rel envelope + neboc_quality_confidence_e_lineage_IR_HASH_OFFSET]
    test r10, r10
    jz fail
    lea rdi, [rel envelope]
    mov ecx, neboc_quality_confidence_e_lineage_IR_HASHED_BYTES
    call hash_memory
    cmp rax, r10
    jne fail
    ret

global _start
_start:
    ; Transport failures cannot write caller storage.
    xor edi, edi
    call neboc_quality_semantic_analyze
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    call prepare_valid
    mov qword [rel envelope + neboc_quality_confidence_e_lineage_SEMANTIC_HASH_OFFSET], 0x1234
    lea rdi, [rel envelope + 1]
    call neboc_quality_semantic_analyze
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    cmp qword [rel envelope + neboc_quality_confidence_e_lineage_SEMANTIC_HASH_OFFSET], 0x1234
    jne fail
    xor edi, edi
    call neboc_quality_ir_lower
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail

    ; Canonical syntax composes through PF001 and remains deterministic.
    call prepare_valid
    call analyze
    call assert_semantic_success
    mov rax, [rel envelope + neboc_quality_confidence_e_lineage_SEMANTIC_HASH_OFFSET]
    mov [rel saved_semantic_hash], rax
    mov rax, [rel envelope + NEBOC_SEMANTIC_LINEAGE_HASH_OFFSET]
    test rax, rax
    jz fail
    call prepare_valid
    call analyze
    call assert_semantic_success
    mov rax, [rel saved_semantic_hash]
    cmp rax, [rel envelope + neboc_quality_confidence_e_lineage_SEMANTIC_HASH_OFFSET]
    jne fail

    ; IR is abstract, atomic and byte-stable across repeated lowering.
    lea rdi, [rel envelope + neboc_quality_confidence_e_lineage_IR_OUTPUT_OFFSET]
    mov ecx, neboc_quality_confidence_e_lineage_IR_OUTPUT_QWORDS
    mov rax, -1
    rep stosq
    call lower_ir
    call assert_ir_success
    mov rax, [rel envelope + neboc_quality_confidence_e_lineage_IR_HASH_OFFSET]
    mov [rel saved_ir_hash], rax
    call lower_ir
    call assert_ir_success
    mov rax, [rel saved_ir_hash]
    cmp rax, [rel envelope + neboc_quality_confidence_e_lineage_IR_HASH_OFFSET]
    jne fail

    ; Descriptor family failures are exact TYPE failures with no result.
    call prepare_valid
    inc qword [rel envelope + NEBOC_RESULT_SHAPE_HASH_OFFSET]
    call analyze
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel envelope + NEBOC_SEMANTIC_QUALITY_OFFSET + neboc_quality_confidence_e_lineage_DIAGNOSTIC_OFFSET], neboc_quality_confidence_e_lineage_DIAG_TYPE_codegen_quality_x86_64
    jne fail
    cmp qword [rel envelope + neboc_quality_confidence_e_lineage_SEMANTIC_RESULT_TYPE_OFFSET], 0
    jne fail
    call prepare_valid
    mov qword [rel envelope + NEBOC_RESULT_RESERVED_OFFSET], 1
    call refresh_shape_hash
    call analyze
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    call prepare_valid
    mov qword [rel envelope + NEBOC_RESULT_DIRECT_QUALITY_OFFSET], 1000001
    call refresh_shape_hash
    call analyze
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    call prepare_valid
    mov qword [rel envelope + NEBOC_RESULT_SOURCE_ID_OFFSET], 0
    call refresh_shape_hash
    call analyze
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail

    ; Threshold and privacy authority remain exact SECURITY failures.
    call prepare_valid
    mov qword [rel envelope + NEBOC_RESULT_MIN_CONFIDENCE_OFFSET], 700001
    call refresh_shape_hash
    call analyze
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel envelope + NEBOC_SEMANTIC_QUALITY_OFFSET + neboc_quality_confidence_e_lineage_DIAGNOSTIC_OFFSET], neboc_quality_confidence_e_lineage_DIAG_SECURITY_codegen_quality_x86_64
    jne fail
    call prepare_valid
    mov qword [rel envelope + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_POLICY_DIRECT_EFFECTS_OFFSET], NEBOC_EFFECT_CONSOLE_WRITE
    call analyze
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel envelope + NEBOC_SEMANTIC_QUALITY_OFFSET + neboc_quality_confidence_e_lineage_DIAGNOSTIC_OFFSET], neboc_quality_confidence_e_lineage_DIAG_SECURITY_codegen_quality_x86_64
    jne fail

    ; Independent authentication catches each forged layer.
    call prepare_valid
    call analyze
    inc qword [rel envelope + neboc_quality_confidence_e_lineage_SEMANTIC_HASH_OFFSET]
    call lower_ir
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel envelope + neboc_quality_confidence_e_lineage_IR_DIAGNOSTIC_OFFSET], neboc_quality_confidence_e_lineage_DIAG_TYPE_codegen_quality_x86_64
    jne fail
    cmp qword [rel envelope + neboc_quality_confidence_e_lineage_IR_HASH_OFFSET], 0
    jne fail
    call prepare_valid
    call analyze
    inc qword [rel envelope + NEBOC_RESULT_DIRECT_QUALITY_OFFSET]
    call refresh_semantic_hash
    call lower_ir
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    call prepare_valid
    call analyze
    inc qword [rel envelope + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_LINEAGE_HASH_OFFSET]
    call refresh_semantic_hash
    call lower_ir
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail

    ; SysV callee-saved values and DF are preserved/cleared.
    call prepare_valid
    mov rbx, 0x22334455
    mov r12, 0x33445566
    std
    lea rdi, [rel envelope]
    call neboc_quality_semantic_analyze
    cmp rbx, 0x22334455
    jne fail
    cmp r12, 0x33445566
    jne fail
    pushfq
    pop rax
    test rax, 1 << 10
    jnz fail

    xor edi, edi
    jmp neboc_host_process_exit
fail:
    cld
    mov edi, 1
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
