; Nebo Assembly — QUALITY-CONFIDENCE-E-LINEAGE-PF004 fail-closed runtime observation gate
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "runtime/quality/quality_runtime.inc"

section .text

NEBOC_ABI_FUNCTION neboc_quality_runtime_gate
    test rdi, rdi
    jz .invalid_argument
    test rdi, neboc_quality_confidence_e_lineage_RUNTIME_ALIGNMENT - 1
    jnz .invalid_argument
    cld
    mov r10, rdi
    mov qword [r10 + neboc_quality_confidence_e_lineage_RUNTIME_DECISION_OFFSET], 0
    mov qword [r10 + neboc_quality_confidence_e_lineage_RUNTIME_DIAGNOSTIC_OFFSET], 0
    mov qword [r10 + neboc_quality_confidence_e_lineage_RUNTIME_EVENT_HASH_OFFSET], 0
    cmp qword [r10 + neboc_quality_confidence_e_lineage_RUNTIME_PLAN_HASH_OFFSET], 0
    je .runtime_failure
    cmp qword [r10 + NEBOC_RUNTIME_REQUIRED_QUALITY_OFFSET], NEBOC_SCORE_SCALE
    ja .runtime_failure
    cmp qword [r10 + NEBOC_RUNTIME_REQUIRED_CONFIDENCE_OFFSET], NEBOC_SCORE_SCALE
    ja .runtime_failure
    cmp qword [r10 + NEBOC_RUNTIME_OBSERVED_QUALITY_OFFSET], NEBOC_SCORE_SCALE
    ja .runtime_failure
    cmp qword [r10 + NEBOC_RUNTIME_OBSERVED_CONFIDENCE_OFFSET], NEBOC_SCORE_SCALE
    ja .runtime_failure
    cmp qword [r10 + NEBOC_RUNTIME_EXPECTED_LINEAGE_OFFSET], 0
    je .runtime_failure
    mov rax, [r10 + NEBOC_RUNTIME_OBSERVED_QUALITY_OFFSET]
    cmp rax, [r10 + NEBOC_RUNTIME_REQUIRED_QUALITY_OFFSET]
    jb .security_failure
    mov rax, [r10 + NEBOC_RUNTIME_OBSERVED_CONFIDENCE_OFFSET]
    cmp rax, [r10 + NEBOC_RUNTIME_REQUIRED_CONFIDENCE_OFFSET]
    jb .security_failure
    mov rax, [r10 + NEBOC_RUNTIME_OBSERVED_LINEAGE_OFFSET]
    cmp rax, [r10 + NEBOC_RUNTIME_EXPECTED_LINEAGE_OFFSET]
    jne .security_failure
    mov qword [r10 + neboc_quality_confidence_e_lineage_RUNTIME_DECISION_OFFSET], neboc_quality_confidence_e_lineage_DECISION_PERMIT
    xor r9d, r9d
    jmp .event_hash
.runtime_failure:
    mov qword [r10 + neboc_quality_confidence_e_lineage_RUNTIME_DIAGNOSTIC_OFFSET], neboc_quality_confidence_e_lineage_DIAG_RUNTIME_driver_cli_linux_x86_64
    mov r9d, NEBOC_STATUS_INVALID_SOURCE
    jmp .event_hash
.security_failure:
    mov qword [r10 + neboc_quality_confidence_e_lineage_RUNTIME_DIAGNOSTIC_OFFSET], neboc_quality_confidence_e_lineage_DIAG_SECURITY_codegen_quality_x86_64
    mov r9d, NEBOC_STATUS_INVALID_SOURCE
.event_hash:
    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.hash_loop:
    cmp rcx, neboc_quality_confidence_e_lineage_RUNTIME_HASHED_BYTES
    jae .hash_done
    movzx edx, byte [r10 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .hash_loop
.hash_done:
    mov [r10 + neboc_quality_confidence_e_lineage_RUNTIME_EVENT_HASH_OFFSET], rax
    mov eax, r9d
    cld
    ret
.invalid_argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
