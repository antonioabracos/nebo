; Nebo Assembly — PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-PF005 authenticated bounded privacy program emitter
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/lowering/privacy/privacy_native.inc"
%include "runtime/privacy/privacy_runtime.inc"
%include "compiler/codegen/privacy/x86_64/privacy_codegen.inc"

extern neboc_assembly_writer_append_bytes
extern neboc_privacy_runtime_check

section .rodata
privacidade_dados_sensiveis_e_zero_trust_template:
    db 10, 'section .text', 10
    db 'global nebo_fn_1', 10
    db 'nebo_fn_1:', 10
    db '    mov eax, 0x'
privacidade_dados_sensiveis_e_zero_trust_hex_offset equ $ - privacidade_dados_sensiveis_e_zero_trust_template
    db '00000000', 10
    db '    ret', 10
privacidade_dados_sensiveis_e_zero_trust_template_length equ $ - privacidade_dados_sensiveis_e_zero_trust_template
privacidade_dados_sensiveis_e_zero_trust_hex: db '0123456789abcdef'

section .text

NEBOC_ABI_FUNCTION neboc_privacy_codegen_emit_start
    test rdi, rdi
    jz .invalid_argument_direct
    test rdi, neboc_privacidade_dados_sensiveis_e_zero_trust_CODEGEN_ALIGNMENT - 1
    jnz .invalid_argument_direct
    cld
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 160
    mov r12, rdi
    lea rdi, [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_CODEGEN_EMITTED_OFFSET]
    mov ecx, 3
    xor eax, eax
    rep stosq
    mov r13, [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_CODEGEN_NATIVE_OFFSET]
    mov r14, [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_CODEGEN_RUNTIME_OFFSET]
    mov r15, [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_CODEGEN_WRITER_OFFSET]
    test r13, r13
    jz .invalid_argument
    test r13, 7
    jnz .invalid_argument
    test r14, r14
    jz .invalid_argument
    test r14, 7
    jnz .invalid_argument
    test r15, r15
    jz .invalid_argument
    test r15, 7
    jnz .invalid_argument

    mov rax, NEBOC_FNV1A64_OFFSET_BASIS
    mov r8, NEBOC_FNV1A64_PRIME
    xor ecx, ecx
.native_hash_loop:
    cmp rcx, neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_HASHED_BYTES
    jae .native_hash_done
    movzx edx, byte [r13 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_HASH_START_OFFSET + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .native_hash_loop
.native_hash_done:
    cmp rax, [r13 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_HASH_OFFSET]
    jne .authentication_failure
    cmp qword [r13 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_TARGET_ID_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_TARGET_X86_64_SYSV_ELF_LINUX
    jne .codegen_failure
    cmp qword [r13 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_ABI_VERSION_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_ABI_VERSION
    jne .codegen_failure
    cmp qword [r13 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_FLAGS_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_FLAGS_REQUIRED
    jne .authentication_failure
    cmp qword [r13 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_DIAGNOSTIC_OFFSET], 0
    jne .authentication_failure
    cmp qword [r13 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_ALLOCATIONS_OFFSET], 0
    jne .authentication_failure
    lea rax, [r13 + NEBOC_NATIVE_PRIVACY_RECORD_OFFSET]
    cmp rax, [r14 + NEBOC_RUNTIME_PRIVACY_RECORD_OFFSET]
    jne .authentication_failure

    ; Reexecute the runtime owner in private storage and compare q1..q6.
    lea rdi, [rsp + 96]
    mov ecx, neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_REQUEST_QWORDS
    xor eax, eax
    rep stosq
    lea rax, [r13 + NEBOC_NATIVE_PRIVACY_RECORD_OFFSET]
    mov [rsp + 96 + NEBOC_RUNTIME_PRIVACY_RECORD_OFFSET], rax
    mov rax, [r14 + NEBOC_RUNTIME_REQUESTED_LABELS_OFFSET]
    mov [rsp + 96 + NEBOC_RUNTIME_REQUESTED_LABELS_OFFSET], rax
    lea rdi, [rsp + 96]
    call neboc_privacy_runtime_check
    test eax, eax
    jnz .authentication_failure
    lea rdi, [rsp + 104]
    lea rsi, [r14 + 8]
    mov ecx, neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_REQUEST_QWORDS - 1
    repe cmpsq
    jne .authentication_failure
    cmp qword [r14 + neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_DECISION_OFFSET], NEBOC_PRIVACY_DECISION_PERMIT
    jne .authentication_failure
    cmp qword [r14 + neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_DIAGNOSTIC_OFFSET], 0
    jne .authentication_failure

    lea rsi, [rel privacidade_dados_sensiveis_e_zero_trust_template]
    mov rdi, rsp
    mov ecx, privacidade_dados_sensiveis_e_zero_trust_template_length
    rep movsb
    mov rax, [r13 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_RESULT_TYPE_OFFSET]
    lea rdi, [rsp + privacidade_dados_sensiveis_e_zero_trust_hex_offset + 8]
    lea rsi, [rel privacidade_dados_sensiveis_e_zero_trust_hex]
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
    mov edx, privacidade_dados_sensiveis_e_zero_trust_template_length
    call neboc_assembly_writer_append_bytes
    test eax, eax
    jnz .writer_failure
    mov qword [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_CODEGEN_EMITTED_OFFSET], neboc_privacidade_dados_sensiveis_e_zero_trust_CODEGEN_EMITTED_START
    mov rax, [r13 + neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_HASH_OFFSET]
    mov [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_CODEGEN_HASH_OFFSET], rax
    xor eax, eax
    jmp .done
.writer_failure:
    mov edx, neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_CODEGEN_codegen_privacy_x86_64
    jmp .failure_status
.codegen_failure:
    mov edx, neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_CODEGEN_codegen_privacy_x86_64
    jmp .failure_source
.authentication_failure:
    mov edx, neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_TYPE_codegen_privacy_x86_64
.failure_source:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    jmp .failure
.failure_status:
    ; Preserve the writer status while publishing the stable diagnostic.
.failure:
    mov [r12 + neboc_privacidade_dados_sensiveis_e_zero_trust_CODEGEN_DIAGNOSTIC_OFFSET], rdx
    jmp .done
.invalid_argument:
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
.invalid_argument_direct:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
