; Nebo Assembly — MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-PF005 authenticated bounded ownership emitter
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "runtime/memory/ownership_runtime.inc"
%include "compiler/codegen/memory/x86_64/ownership_codegen.inc"

extern neboc_assembly_writer_append_bytes

section .rodata
memoria_ownership_lifetimes_e_recursos_template:
    db 10, 'section .text', 10
    db 'global nebo_fn_1', 10
    db 'nebo_fn_1:', 10
    db '    mov eax, 0x'
memoria_ownership_lifetimes_e_recursos_hex_offset equ $-memoria_ownership_lifetimes_e_recursos_template
    db '00000000',10
    db '    ret',10
memoria_ownership_lifetimes_e_recursos_template_len equ $-memoria_ownership_lifetimes_e_recursos_template
memoria_ownership_lifetimes_e_recursos_hex: db '0123456789abcdef'

section .text
NEBOC_ABI_FUNCTION neboc_ownership_codegen_emit_start
    test rdi, rdi
    jz .invalid_direct
    test rdi, neboc_memoria_ownership_lifetimes_e_recursos_CODEGEN_ALIGNMENT - 1
    jnz .invalid_direct
    cld
    push r12
    push r13
    push r14
    sub rsp, 96
    mov r12, rdi
    lea rdi, [r12 + neboc_memoria_ownership_lifetimes_e_recursos_CODEGEN_EMITTED_OFFSET]
    mov ecx, 3
    xor eax, eax
    rep stosq
    mov r13, [r12 + neboc_memoria_ownership_lifetimes_e_recursos_CODEGEN_RUNTIME_OFFSET]
    mov r14, [r12 + neboc_memoria_ownership_lifetimes_e_recursos_CODEGEN_WRITER_OFFSET]
    test r13, r13
    jz .invalid
    test r13, 7
    jnz .invalid
    test r14, r14
    jz .invalid
    test r14, 7
    jnz .invalid

    ; Independently authenticate immutable native plan and final runtime event.
    mov rsi, r13
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_HASHED_BYTES
    call hash
    cmp rax, [r13 + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_HASH_OFFSET]
    jne .authentication_failure
    mov rsi, r13
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_HASHED_BYTES
    call hash
    cmp rax, [r13 + neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_EVENT_HASH_OFFSET]
    jne .runtime_failure
    lea rsi, [r13 + NEBOC_RUNTIME_STATE_OFFSET]
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_HASHED_BYTES
    call hash
    cmp rax, [r13 + NEBOC_RUNTIME_FINAL_STATE_HASH_OFFSET]
    jne .runtime_failure
    cmp rax, [r13 + NEBOC_RUNTIME_STATE_OFFSET + neboc_memoria_ownership_lifetimes_e_recursos_STATE_HASH_OFFSET]
    jne .runtime_failure
    cmp qword [r13 + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_DIAGNOSTIC_OFFSET], 0
    jne .authentication_failure
    cmp qword [r13 + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_DECISION_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DECISION_PERMIT
    jne .authentication_failure
    cmp qword [r13 + neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_ALLOCATIONS_OFFSET], 0
    jne .authentication_failure
    cmp qword [r13 + NEBOC_RUNTIME_EXECUTED_OFFSET], 1
    jne .runtime_failure
    cmp qword [r13 + NEBOC_RUNTIME_STATUS_OFFSET], NEBOC_STATUS_OK
    jne .runtime_failure
    cmp qword [r13 + neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_DIAGNOSTIC_OFFSET], 0
    jne .runtime_failure
    cmp qword [r13 + neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_DECISION_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_DECISION_PERMIT
    jne .runtime_failure
    mov rax, [r13 + NEBOC_RUNTIME_OBSERVED_STATE_OFFSET]
    cmp rax, [r13 + NEBOC_NATIVE_EXPECTED_RESULT_STATE_OFFSET]
    jne .runtime_failure
    mov rax, [r13 + NEBOC_RUNTIME_CLEANUP_DELTA_OFFSET]
    cmp rax, [r13 + NEBOC_NATIVE_EXPECTED_CLEANUP_DELTA_OFFSET]
    jne .runtime_failure
    mov rax, [r13 + NEBOC_RUNTIME_GENERATION_DELTA_OFFSET]
    cmp rax, [r13 + NEBOC_NATIVE_EXPECTED_GENERATION_DELTA_OFFSET]
    jne .runtime_failure
    mov rax, [r13 + NEBOC_IR_RESOURCE_ID_OFFSET]
    cmp rax, [r13 + NEBOC_SYNTAX_RESOURCE_ID_OFFSET]
    jne .authentication_failure

    lea rsi, [rel memoria_ownership_lifetimes_e_recursos_template]
    mov rdi, rsp
    mov ecx, memoria_ownership_lifetimes_e_recursos_template_len
    rep movsb
    mov rax, [r13 + NEBOC_SYNTAX_RESOURCE_ID_OFFSET]
    lea rdi, [rsp + memoria_ownership_lifetimes_e_recursos_hex_offset + 8]
    lea rsi, [rel memoria_ownership_lifetimes_e_recursos_hex]
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
    mov rdi, r14
    mov rsi, rsp
    mov edx, memoria_ownership_lifetimes_e_recursos_template_len
    call neboc_assembly_writer_append_bytes
    test eax, eax
    jnz .writer_failure
    mov qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_CODEGEN_EMITTED_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_CODEGEN_EMITTED_START
    mov rax, [r13 + neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_EVENT_HASH_OFFSET]
    mov [r12 + neboc_memoria_ownership_lifetimes_e_recursos_CODEGEN_HASH_OFFSET], rax
    xor eax, eax
    jmp .done
.writer_failure:
    mov edx, neboc_memoria_ownership_lifetimes_e_recursos_DIAG_CODEGEN_codegen_memory_x86_64
    jmp .failure_status
.runtime_failure:
    mov edx, neboc_memoria_ownership_lifetimes_e_recursos_DIAG_SECURITY_codegen_memory_x86_64
    jmp .failure_source
.authentication_failure:
    mov edx, neboc_memoria_ownership_lifetimes_e_recursos_DIAG_TYPE_codegen_memory_x86_64
.failure_source:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    jmp .failure
.failure_status:
.failure:
    mov [r12 + neboc_memoria_ownership_lifetimes_e_recursos_CODEGEN_DIAGNOSTIC_OFFSET], rdx
    jmp .done
.invalid:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
.done:
    add rsp, 96
    pop r14
    pop r13
    pop r12
    cld
    ret
.invalid_direct:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

hash:
    mov rax, 14695981039346656037
    mov r8, 1099511628211
    xor edx, edx
.loop:
    cmp edx, ecx
    jae .done
    movzx r9d, byte [rsi + rdx]
    xor rax, r9
    imul rax, r8
    inc edx
    jmp .loop
.done:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
