; IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-PF004 bounded single-use module resolution runtime
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "runtime/modules/module_runtime.inc"

section .text
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_module_runtime_execute
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    mov rax, rdi
    or rax, rsi
    test rax, neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_ALIGNMENT - 1
    jnz .invalid
    mov r8, rdi
    add r8, neboc_imports_modulos_namespaces_e_api_publica_NATIVE_SIZE
    jc .invalid
    mov r9, rsi
    add r9, neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_SIZE
    jc .invalid
    cmp r8, rsi
    jbe .ranges_ok
    cmp r9, rdi
    ja .invalid
.ranges_ok:
    push rbx
    push r12
    mov rbx, rdi
    mov r12, rsi
    cmp qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_MAGIC_OFFSET], 0
    jne .already_consumed
    mov rax, neboc_imports_modulos_namespaces_e_api_publica_NATIVE_MAGIC
    cmp [rbx + neboc_imports_modulos_namespaces_e_api_publica_NATIVE_MAGIC_OFFSET], rax
    jne .security_failure
    cmp qword [rbx + neboc_imports_modulos_namespaces_e_api_publica_NATIVE_TARGET_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_NATIVE_TARGET_X86_64_SYSV_ELF
    jne .security_failure
    cmp qword [rbx + neboc_imports_modulos_namespaces_e_api_publica_NATIVE_ABI_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_NATIVE_ABI_INTERNAL_V1
    jne .security_failure
    cmp qword [rbx + neboc_imports_modulos_namespaces_e_api_publica_NATIVE_DECISION_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_SEM_DECISION_PERMIT
    jne .security_failure
    cmp qword [rbx + neboc_imports_modulos_namespaces_e_api_publica_NATIVE_FLAGS_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_NATIVE_FLAG_AUTHENTICATED
    jne .security_failure
    mov rsi, rbx
    mov ecx, neboc_imports_modulos_namespaces_e_api_publica_NATIVE_HASHED_BYTES
    call imports_modulos_namespaces_e_api_publica_runtime_hash
    cmp rax, [rbx + neboc_imports_modulos_namespaces_e_api_publica_NATIVE_HASH_OFFSET]
    jne .security_failure

    mov rax, neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_MAGIC
    mov [r12 + neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_MAGIC_OFFSET], rax
    mov rax, [rbx + neboc_imports_modulos_namespaces_e_api_publica_NATIVE_HASH_OFFSET]
    mov [r12 + neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_PLAN_HASH_OFFSET], rax
    mov rax, [rbx + neboc_imports_modulos_namespaces_e_api_publica_NATIVE_RESULT_OFFSET]
    mov [r12 + neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_RESULT_OFFSET], rax
    mov rax, [rbx + NEBOC_NATIVE_VISIBILITY_OFFSET]
    mov [r12 + NEBOC_RUNTIME_VISIBILITY_OFFSET], rax
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_GENERATION_OFFSET], 1
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_CONSUMED_OFFSET], 1
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_DIAGNOSTIC_OFFSET], 0
    mov rsi, r12
    mov ecx, neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_HASHED_BYTES
    call imports_modulos_namespaces_e_api_publica_runtime_hash
    mov [r12 + neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_HASH_OFFSET], rax
    xor eax, eax
    jmp .done
.already_consumed:
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_DIAGNOSTIC_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_DIAG_RUNTIME_driver_cli_linux_x86_64
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    jmp .done
.security_failure:
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_DIAGNOSTIC_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_DIAG_SECURITY_codegen_modules_x86_64
    mov eax, NEBOC_STATUS_INVALID_SOURCE
.done:
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

%undef call
imports_modulos_namespaces_e_api_publica_runtime_hash:
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
