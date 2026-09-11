; QUALITY-CONFIDENCE-E-LINEAGE-PF004 native-plan and runtime-gate contract tests
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "runtime/quality/quality_runtime.inc"

extern neboc_quality_semantic_analyze
extern neboc_quality_ir_lower
extern neboc_quality_native_lower
extern neboc_quality_runtime_gate
extern neboc_host_process_exit

section .bss align=16
plan: resb neboc_quality_confidence_e_lineage_NATIVE_REQUEST_SIZE
gate: resb neboc_quality_confidence_e_lineage_RUNTIME_REQUEST_SIZE
saved_hash: resq 1

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
.done: ret

prepare_pipeline:
    lea rdi, [rel plan]
    mov ecx, neboc_quality_confidence_e_lineage_NATIVE_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    mov qword [rel plan + NEBOC_RESULT_DIRECT_QUALITY_OFFSET], 900000
    mov qword [rel plan + NEBOC_RESULT_INHERITED_QUALITY_OFFSET], 800000
    mov qword [rel plan + NEBOC_RESULT_DIRECT_CONFIDENCE_OFFSET], 950000
    mov qword [rel plan + NEBOC_RESULT_INHERITED_CONFIDENCE_OFFSET], 700000
    mov qword [rel plan + NEBOC_RESULT_MIN_QUALITY_OFFSET], 750000
    mov qword [rel plan + NEBOC_RESULT_MIN_CONFIDENCE_OFFSET], 650000
    mov qword [rel plan + NEBOC_RESULT_SOURCE_ID_OFFSET], 2301
    mov qword [rel plan + NEBOC_RESULT_TRANSFORM_ID_OFFSET], 2302
    mov rax, 0x1122334455667788
    mov [rel plan + NEBOC_RESULT_PARENT_HASH_OFFSET], rax
    mov qword [rel plan + neboc_quality_confidence_e_lineage_RESULT_FLAGS_OFFSET], NEBOC_RESULT_FLAG_CANONICAL
    mov qword [rel plan + NEBOC_RESULT_STATEMENT_LENGTH_OFFSET], 93
    lea rdi, [rel plan]
    mov ecx, NEBOC_RESULT_HASHED_BYTES
    call hash_memory
    mov [rel plan + NEBOC_RESULT_SHAPE_HASH_OFFSET], rax
    mov qword [rel plan + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_POLICY_PERMIT_OFFSET], 23
    mov qword [rel plan + NEBOC_SEMANTIC_QUALITY_OFFSET + NEBOC_PRIVACY_RETENTION_LIMIT_OFFSET], 1
    lea rdi, [rel plan]
    call neboc_quality_semantic_analyze
    test eax, eax
    jnz fail
    lea rdi, [rel plan]
    call neboc_quality_ir_lower
    test eax, eax
    jnz fail
    ret

lower_native:
    lea rdi, [rel plan]
    jmp neboc_quality_native_lower

prepare_gate:
    lea rdi, [rel gate]
    mov ecx, neboc_quality_confidence_e_lineage_RUNTIME_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    mov rax, [rel plan + neboc_quality_confidence_e_lineage_NATIVE_HASH_OFFSET]
    mov [rel gate + neboc_quality_confidence_e_lineage_RUNTIME_PLAN_HASH_OFFSET], rax
    mov rax, [rel plan + NEBOC_NATIVE_EFFECTIVE_QUALITY_OFFSET]
    mov [rel gate + NEBOC_RUNTIME_REQUIRED_QUALITY_OFFSET], rax
    mov [rel gate + NEBOC_RUNTIME_OBSERVED_QUALITY_OFFSET], rax
    mov rax, [rel plan + NEBOC_NATIVE_EFFECTIVE_CONFIDENCE_OFFSET]
    mov [rel gate + NEBOC_RUNTIME_REQUIRED_CONFIDENCE_OFFSET], rax
    mov [rel gate + NEBOC_RUNTIME_OBSERVED_CONFIDENCE_OFFSET], rax
    mov rax, [rel plan + NEBOC_NATIVE_LINEAGE_HASH_OFFSET]
    mov [rel gate + NEBOC_RUNTIME_EXPECTED_LINEAGE_OFFSET], rax
    mov [rel gate + NEBOC_RUNTIME_OBSERVED_LINEAGE_OFFSET], rax
    ret

run_gate:
    lea rdi, [rel gate]
    jmp neboc_quality_runtime_gate

global _start
_start:
    ; Transport failures are write-free.
    xor edi, edi
    call neboc_quality_native_lower
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    xor edi, edi
    call neboc_quality_runtime_gate
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail

    ; Authenticated IR lowers to one exact payload-free x86-64 plan.
    call prepare_pipeline
    call lower_native
    test eax, eax
    jnz fail
    cmp qword [rel plan + neboc_quality_confidence_e_lineage_NATIVE_TARGET_OFFSET], NEBOC_NATIVE_TARGET_X86_64_SYSV
    jne fail
    cmp qword [rel plan + NEBOC_NATIVE_WORD_BYTES_OFFSET], 8
    jne fail
    cmp qword [rel plan + NEBOC_NATIVE_SCORE_SCALE_OFFSET], NEBOC_SCORE_SCALE
    jne fail
    cmp qword [rel plan + NEBOC_NATIVE_RUNTIME_GATE_OFFSET], NEBOC_NATIVE_RUNTIME_GATE_ID
    jne fail
    cmp qword [rel plan + NEBOC_NATIVE_EFFECTIVE_QUALITY_OFFSET], 800000
    jne fail
    cmp qword [rel plan + NEBOC_NATIVE_EFFECTIVE_CONFIDENCE_OFFSET], 700000
    jne fail
    cmp qword [rel plan + neboc_quality_confidence_e_lineage_NATIVE_DECISION_OFFSET], neboc_quality_confidence_e_lineage_DECISION_PERMIT
    jne fail
    cmp qword [rel plan + neboc_quality_confidence_e_lineage_NATIVE_DIAGNOSTIC_OFFSET], 0
    jne fail
    mov r10, [rel plan + neboc_quality_confidence_e_lineage_NATIVE_HASH_OFFSET]
    test r10, r10
    jz fail
    lea rdi, [rel plan]
    mov ecx, neboc_quality_confidence_e_lineage_NATIVE_HASHED_BYTES
    call hash_memory
    cmp rax, r10
    jne fail
    mov [rel saved_hash], r10
    call lower_native
    test eax, eax
    jnz fail
    mov rax, [rel saved_hash]
    cmp rax, [rel plan + neboc_quality_confidence_e_lineage_NATIVE_HASH_OFFSET]
    jne fail

    ; IR identity and operation forgeries fail atomically as CODEGEN.
    call prepare_pipeline
    inc qword [rel plan + neboc_quality_confidence_e_lineage_IR_HASH_OFFSET]
    call lower_native
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel plan + neboc_quality_confidence_e_lineage_NATIVE_DIAGNOSTIC_OFFSET], neboc_quality_confidence_e_lineage_DIAG_CODEGEN_codegen_quality_x86_64
    jne fail
    cmp qword [rel plan + neboc_quality_confidence_e_lineage_NATIVE_HASH_OFFSET], 0
    jne fail
    call prepare_pipeline
    inc qword [rel plan + NEBOC_IR_HIR_LINEAGE_OFFSET]
    lea rdi, [rel plan]
    mov ecx, neboc_quality_confidence_e_lineage_IR_HASHED_BYTES
    call hash_memory
    mov [rel plan + neboc_quality_confidence_e_lineage_IR_HASH_OFFSET], rax
    call lower_native
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail

    ; Exact runtime observations pass and produce deterministic events.
    call prepare_pipeline
    call lower_native
    test eax, eax
    jnz fail
    call prepare_gate
    call run_gate
    test eax, eax
    jnz fail
    cmp qword [rel gate + neboc_quality_confidence_e_lineage_RUNTIME_DECISION_OFFSET], neboc_quality_confidence_e_lineage_DECISION_PERMIT
    jne fail
    cmp qword [rel gate + neboc_quality_confidence_e_lineage_RUNTIME_DIAGNOSTIC_OFFSET], 0
    jne fail
    mov rax, [rel gate + neboc_quality_confidence_e_lineage_RUNTIME_EVENT_HASH_OFFSET]
    test rax, rax
    jz fail
    mov [rel saved_hash], rax
    call prepare_gate
    call run_gate
    mov rax, [rel saved_hash]
    cmp rax, [rel gate + neboc_quality_confidence_e_lineage_RUNTIME_EVENT_HASH_OFFSET]
    jne fail

    ; Score degradation and lineage substitution are SECURITY failures.
    call prepare_gate
    dec qword [rel gate + NEBOC_RUNTIME_OBSERVED_QUALITY_OFFSET]
    call run_gate
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel gate + neboc_quality_confidence_e_lineage_RUNTIME_DIAGNOSTIC_OFFSET], neboc_quality_confidence_e_lineage_DIAG_SECURITY_codegen_quality_x86_64
    jne fail
    cmp qword [rel gate + neboc_quality_confidence_e_lineage_RUNTIME_DECISION_OFFSET], 0
    jne fail
    call prepare_gate
    dec qword [rel gate + NEBOC_RUNTIME_OBSERVED_CONFIDENCE_OFFSET]
    call run_gate
    cmp qword [rel gate + neboc_quality_confidence_e_lineage_RUNTIME_DIAGNOSTIC_OFFSET], neboc_quality_confidence_e_lineage_DIAG_SECURITY_codegen_quality_x86_64
    jne fail
    call prepare_gate
    inc qword [rel gate + NEBOC_RUNTIME_OBSERVED_LINEAGE_OFFSET]
    call run_gate
    cmp qword [rel gate + neboc_quality_confidence_e_lineage_RUNTIME_DIAGNOSTIC_OFFSET], neboc_quality_confidence_e_lineage_DIAG_SECURITY_codegen_quality_x86_64
    jne fail

    ; Malformed runtime domains retain the RUNTIME diagnostic owner.
    call prepare_gate
    mov qword [rel gate + neboc_quality_confidence_e_lineage_RUNTIME_PLAN_HASH_OFFSET], 0
    call run_gate
    cmp qword [rel gate + neboc_quality_confidence_e_lineage_RUNTIME_DIAGNOSTIC_OFFSET], neboc_quality_confidence_e_lineage_DIAG_RUNTIME_driver_cli_linux_x86_64
    jne fail
    call prepare_gate
    mov qword [rel gate + NEBOC_RUNTIME_OBSERVED_QUALITY_OFFSET], 1000001
    call run_gate
    cmp qword [rel gate + neboc_quality_confidence_e_lineage_RUNTIME_DIAGNOSTIC_OFFSET], neboc_quality_confidence_e_lineage_DIAG_RUNTIME_driver_cli_linux_x86_64
    jne fail

    ; Both functions clear DF and preserve callee-saved state.
    call prepare_pipeline
    mov rbx, 0x22334455
    mov r12, 0x33445566
    std
    call lower_native
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
