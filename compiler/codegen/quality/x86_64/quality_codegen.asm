; Nebo Assembly — QUALITY-CONFIDENCE-E-LINEAGE-PF005 authenticated bounded quality emitter
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/lowering/quality/quality_native.inc"
%include "runtime/quality/quality_runtime.inc"
%include "compiler/codegen/quality/x86_64/quality_codegen.inc"

extern neboc_assembly_writer_append_bytes
extern neboc_quality_runtime_gate

section .rodata
quality_confidence_e_lineage_template:
    db 10, 'section .text', 10
    db 'global nebo_fn_1', 10
    db 'nebo_fn_1:', 10
    db '    mov eax, 0x'
quality_confidence_e_lineage_hex_offset equ $ - quality_confidence_e_lineage_template
    db '00000000', 10
    db '    ret', 10
quality_confidence_e_lineage_template_length equ $ - quality_confidence_e_lineage_template
quality_confidence_e_lineage_hex: db '0123456789abcdef'

section .text

NEBOC_ABI_FUNCTION neboc_quality_codegen_emit_start
    test rdi, rdi
    jz .invalid_direct
    test rdi, neboc_quality_confidence_e_lineage_CODEGEN_ALIGNMENT - 1
    jnz .invalid_direct
    cld
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 160
    mov r12, rdi
    lea rdi, [r12 + neboc_quality_confidence_e_lineage_CODEGEN_EMITTED_OFFSET]
    mov ecx, 3
    xor eax, eax
    rep stosq
    mov r13, [r12 + neboc_quality_confidence_e_lineage_CODEGEN_NATIVE_OFFSET]
    mov r14, [r12 + neboc_quality_confidence_e_lineage_CODEGEN_RUNTIME_OFFSET]
    mov r15, [r12 + neboc_quality_confidence_e_lineage_CODEGEN_WRITER_OFFSET]
    test r13, r13
    jz .invalid
    test r13, 7
    jnz .invalid
    test r14, r14
    jz .invalid
    test r14, 7
    jnz .invalid
    test r15, r15
    jz .invalid
    test r15, 7
    jnz .invalid

    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.native_hash_loop:
    cmp rcx, neboc_quality_confidence_e_lineage_NATIVE_HASHED_BYTES
    jae .native_hash_done
    movzx edx, byte [r13 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .native_hash_loop
.native_hash_done:
    cmp rax, [r13 + neboc_quality_confidence_e_lineage_NATIVE_HASH_OFFSET]
    jne .authentication_failure
    cmp qword [r13 + neboc_quality_confidence_e_lineage_NATIVE_TARGET_OFFSET], NEBOC_NATIVE_TARGET_X86_64_SYSV
    jne .codegen_failure
    cmp qword [r13 + NEBOC_NATIVE_WORD_BYTES_OFFSET], 8
    jne .codegen_failure
    cmp qword [r13 + NEBOC_NATIVE_SCORE_SCALE_OFFSET], NEBOC_SCORE_SCALE
    jne .authentication_failure
    cmp qword [r13 + NEBOC_NATIVE_RUNTIME_GATE_OFFSET], NEBOC_NATIVE_RUNTIME_GATE_ID
    jne .authentication_failure
    cmp qword [r13 + neboc_quality_confidence_e_lineage_NATIVE_DECISION_OFFSET], neboc_quality_confidence_e_lineage_DECISION_PERMIT
    jne .authentication_failure
    cmp qword [r13 + neboc_quality_confidence_e_lineage_NATIVE_DIAGNOSTIC_OFFSET], 0
    jne .authentication_failure
    cmp qword [r13 + neboc_quality_confidence_e_lineage_NATIVE_ALLOCATIONS_OFFSET], 0
    jne .authentication_failure

    ; Reexecute runtime ownership in private storage and compare q7..q9.
    lea rdi, [rsp + 80]
    mov rsi, r14
    mov ecx, 7
    rep movsq
    lea rdi, [rsp + 80]
    call neboc_quality_runtime_gate
    test eax, eax
    jnz .runtime_failure
    lea rdi, [rsp + 80 + neboc_quality_confidence_e_lineage_RUNTIME_DECISION_OFFSET]
    lea rsi, [r14 + neboc_quality_confidence_e_lineage_RUNTIME_DECISION_OFFSET]
    mov ecx, 3
    repe cmpsq
    jne .runtime_failure
    cmp qword [r14 + neboc_quality_confidence_e_lineage_RUNTIME_DECISION_OFFSET], neboc_quality_confidence_e_lineage_DECISION_PERMIT
    jne .runtime_failure
    cmp qword [r14 + neboc_quality_confidence_e_lineage_RUNTIME_DIAGNOSTIC_OFFSET], 0
    jne .runtime_failure

    lea rsi, [rel quality_confidence_e_lineage_template]
    mov rdi, rsp
    mov ecx, quality_confidence_e_lineage_template_length
    rep movsb
    mov rax, [r13 + NEBOC_NATIVE_EFFECTIVE_QUALITY_OFFSET]
    lea rdi, [rsp + quality_confidence_e_lineage_hex_offset + 8]
    lea rsi, [rel quality_confidence_e_lineage_hex]
    mov ecx, 8
.hex_loop:
    mov rdx, rax
    and edx, 15
    mov dl, [rsi + rdx]
    dec rdi
    mov [rdi], dl
    shr rax, 4
    dec ecx
    jnz .hex_loop
    mov rdi, r15
    mov rsi, rsp
    mov edx, quality_confidence_e_lineage_template_length
    call neboc_assembly_writer_append_bytes
    test eax, eax
    jnz .writer_failure
    mov qword [r12 + neboc_quality_confidence_e_lineage_CODEGEN_EMITTED_OFFSET], neboc_quality_confidence_e_lineage_CODEGEN_EMITTED_START
    mov rax, [r13 + neboc_quality_confidence_e_lineage_NATIVE_HASH_OFFSET]
    mov [r12 + neboc_quality_confidence_e_lineage_CODEGEN_HASH_OFFSET], rax
    xor eax, eax
    jmp .done
.writer_failure:
    mov edx, neboc_quality_confidence_e_lineage_DIAG_CODEGEN_codegen_quality_x86_64
    jmp .failure_status
.codegen_failure:
    mov edx, neboc_quality_confidence_e_lineage_DIAG_CODEGEN_codegen_quality_x86_64
    jmp .failure_source
.runtime_failure:
    mov edx, neboc_quality_confidence_e_lineage_DIAG_SECURITY_codegen_quality_x86_64
    jmp .failure_source
.authentication_failure:
    mov edx, neboc_quality_confidence_e_lineage_DIAG_TYPE_codegen_quality_x86_64
.failure_source:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    jmp .failure
.failure_status:
.failure:
    mov [r12 + neboc_quality_confidence_e_lineage_CODEGEN_DIAGNOSTIC_OFFSET], rdx
    jmp .done
.invalid:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
.done:
    add rsp, 160
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret
.invalid_direct:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
