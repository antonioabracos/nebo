; IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-PF005 authenticated bounded module result emitter
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "runtime/modules/module_runtime.inc"
%include "compiler/codegen/modules/x86_64/module_codegen.inc"

extern neboc_assembly_writer_append_bytes

section .rodata
imports_modulos_namespaces_e_api_publica_template:
    db 10, 'section .text', 10
    db 'global nebo_fn_1', 10
    db 'nebo_fn_1:', 10
    db '    mov eax, 0x'
imports_modulos_namespaces_e_api_publica_hex_offset equ $-imports_modulos_namespaces_e_api_publica_template
    db '00000000',10
    db '    ret',10
imports_modulos_namespaces_e_api_publica_template_len equ $-imports_modulos_namespaces_e_api_publica_template
imports_modulos_namespaces_e_api_publica_hex: db '0123456789abcdef'

section .text
NEBOC_ABI_FUNCTION neboc_imports_modulos_namespaces_e_api_publica_module_codegen_emit_start
    test rdi, rdi
    jz .invalid_direct
    test rdi, neboc_imports_modulos_namespaces_e_api_publica_CODEGEN_ALIGNMENT - 1
    jnz .invalid_direct
    push r12
    push r13
    push r14
    sub rsp, 96
    mov r12, rdi
    lea rdi, [r12 + neboc_imports_modulos_namespaces_e_api_publica_CODEGEN_EMITTED_OFFSET]
    mov ecx, 3
    xor eax, eax
    rep stosq
    mov r13, [r12 + neboc_imports_modulos_namespaces_e_api_publica_CODEGEN_RUNTIME_OFFSET]
    mov r14, [r12 + neboc_imports_modulos_namespaces_e_api_publica_CODEGEN_WRITER_OFFSET]
    test r13, r13
    jz .invalid
    test r14, r14
    jz .invalid
    mov rax, r13
    or rax, r14
    test rax, 7
    jnz .invalid
    mov rax, neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_MAGIC
    cmp [r13 + neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_MAGIC_OFFSET], rax
    jne .authentication_failure
    cmp qword [r13 + neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_GENERATION_OFFSET], 1
    jne .authentication_failure
    cmp qword [r13 + neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_CONSUMED_OFFSET], 1
    jne .authentication_failure
    cmp qword [r13 + neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_DIAGNOSTIC_OFFSET], 0
    jne .authentication_failure
    mov rsi, r13
    mov ecx, neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_HASHED_BYTES
    call imports_modulos_namespaces_e_api_publica_codegen_hash
    cmp rax, [r13 + neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_HASH_OFFSET]
    jne .authentication_failure

    lea rsi, [rel imports_modulos_namespaces_e_api_publica_template]
    mov rdi, rsp
    mov ecx, imports_modulos_namespaces_e_api_publica_template_len
    rep movsb
    mov rax, [r13 + neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_RESULT_OFFSET]
    lea rdi, [rsp + imports_modulos_namespaces_e_api_publica_hex_offset + 8]
    lea rsi, [rel imports_modulos_namespaces_e_api_publica_hex]
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
    mov edx, imports_modulos_namespaces_e_api_publica_template_len
    call neboc_assembly_writer_append_bytes
    test eax, eax
    jnz .writer_failure
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_CODEGEN_EMITTED_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_CODEGEN_EMITTED_START
    mov rax, [r13 + neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_HASH_OFFSET]
    mov [r12 + neboc_imports_modulos_namespaces_e_api_publica_CODEGEN_HASH_OFFSET], rax
    xor eax, eax
    jmp .done
.writer_failure:
    mov edx, neboc_imports_modulos_namespaces_e_api_publica_DIAG_CODEGEN_codegen_modules_x86_64
    jmp .failure_status
.authentication_failure:
    mov edx, neboc_imports_modulos_namespaces_e_api_publica_DIAG_SECURITY_codegen_modules_x86_64
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    jmp .failure
.failure_status:
.failure:
    mov [r12 + neboc_imports_modulos_namespaces_e_api_publica_CODEGEN_DIAGNOSTIC_OFFSET], rdx
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

imports_modulos_namespaces_e_api_publica_codegen_hash:
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
