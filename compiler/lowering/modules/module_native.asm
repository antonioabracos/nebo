; IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-PF004 authenticated x86-64 module resolution plan
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/modules/module_native.inc"

section .text
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_module_native_lower
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    mov rax, rdi
    or rax, rsi
    test rax, neboc_imports_modulos_namespaces_e_api_publica_NATIVE_ALIGNMENT - 1
    jnz .invalid
    mov r8, rdi
    add r8, neboc_imports_modulos_namespaces_e_api_publica_IR_SIZE
    jc .invalid
    mov r9, rsi
    add r9, neboc_imports_modulos_namespaces_e_api_publica_NATIVE_SIZE
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
    mov rdi, r12
    mov ecx, neboc_imports_modulos_namespaces_e_api_publica_NATIVE_QWORDS
    xor eax, eax
    rep stosq
    mov rax, neboc_imports_modulos_namespaces_e_api_publica_IR_MAGIC
    cmp [rbx + neboc_imports_modulos_namespaces_e_api_publica_IR_MAGIC_OFFSET], rax
    jne .source_failure
    cmp qword [rbx + neboc_imports_modulos_namespaces_e_api_publica_IR_OPERATION_OFFSET], NEBOC_IR_OPERATION_RESOLVE
    jne .source_failure
    cmp qword [rbx + neboc_imports_modulos_namespaces_e_api_publica_IR_DECISION_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_SEM_DECISION_PERMIT
    jne .source_failure
    cmp qword [rbx + neboc_imports_modulos_namespaces_e_api_publica_IR_DIAGNOSTIC_OFFSET], 0
    jne .source_failure
    cmp qword [rbx + neboc_imports_modulos_namespaces_e_api_publica_IR_FLAGS_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_IR_FLAG_TARGET_NEUTRAL
    jne .source_failure
    cmp qword [rbx + neboc_imports_modulos_namespaces_e_api_publica_IR_TARGET_OFFSET], 0
    jne .source_failure
    mov rsi, rbx
    mov ecx, neboc_imports_modulos_namespaces_e_api_publica_IR_HASHED_BYTES
    call imports_modulos_namespaces_e_api_publica_native_hash
    cmp rax, [rbx + neboc_imports_modulos_namespaces_e_api_publica_IR_HASH_OFFSET]
    jne .source_failure

    mov rax, neboc_imports_modulos_namespaces_e_api_publica_NATIVE_MAGIC
    mov [r12 + neboc_imports_modulos_namespaces_e_api_publica_NATIVE_MAGIC_OFFSET], rax
    mov rax, [rbx + NEBOC_IR_MODULE_ID_OFFSET]
    mov [r12 + NEBOC_NATIVE_MODULE_ID_OFFSET], rax
    mov rax, [rbx + NEBOC_IR_PACKAGE_ID_OFFSET]
    mov [r12 + NEBOC_NATIVE_PACKAGE_ID_OFFSET], rax
    mov rax, [rbx + NEBOC_IR_IMPORT_MODULE_OFFSET]
    mov [r12 + NEBOC_NATIVE_IMPORT_MODULE_OFFSET], rax
    mov rax, [rbx + NEBOC_IR_EXPORT_PACKAGE_OFFSET]
    mov [r12 + NEBOC_NATIVE_EXPORT_PACKAGE_OFFSET], rax
    mov rax, [rbx + neboc_imports_modulos_namespaces_e_api_publica_IR_SYMBOL_ID_OFFSET]
    mov [r12 + NEBOC_NATIVE_SYMBOL_ID_OFFSET], rax
    mov [r12 + neboc_imports_modulos_namespaces_e_api_publica_NATIVE_RESULT_OFFSET], rax
    mov rax, [rbx + NEBOC_IR_VISIBILITY_OFFSET]
    mov [r12 + NEBOC_NATIVE_VISIBILITY_OFFSET], rax
    mov rax, [rbx + NEBOC_IR_GRAPH_EPOCH_OFFSET]
    mov [r12 + NEBOC_NATIVE_GRAPH_EPOCH_OFFSET], rax
    mov rax, [rbx + neboc_imports_modulos_namespaces_e_api_publica_IR_SYNTAX_HASH_OFFSET]
    mov [r12 + neboc_imports_modulos_namespaces_e_api_publica_NATIVE_SYNTAX_HASH_OFFSET], rax
    mov rax, [rbx + NEBOC_IR_TABLE_HASH_OFFSET]
    mov [r12 + NEBOC_NATIVE_TABLE_HASH_OFFSET], rax
    mov rax, [rbx + neboc_imports_modulos_namespaces_e_api_publica_IR_SEMANTIC_HASH_OFFSET]
    mov [r12 + neboc_imports_modulos_namespaces_e_api_publica_NATIVE_SEMANTIC_HASH_OFFSET], rax
    mov rax, [rbx + neboc_imports_modulos_namespaces_e_api_publica_IR_HASH_OFFSET]
    mov [r12 + neboc_imports_modulos_namespaces_e_api_publica_NATIVE_IR_HASH_OFFSET], rax
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_NATIVE_TARGET_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_NATIVE_TARGET_X86_64_SYSV_ELF
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_NATIVE_ABI_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_NATIVE_ABI_INTERNAL_V1
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_NATIVE_DECISION_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_SEM_DECISION_PERMIT
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_NATIVE_DIAGNOSTIC_OFFSET], 0
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_NATIVE_FLAGS_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_NATIVE_FLAG_AUTHENTICATED
    mov rsi, r12
    mov ecx, neboc_imports_modulos_namespaces_e_api_publica_NATIVE_HASHED_BYTES
    call imports_modulos_namespaces_e_api_publica_native_hash
    mov [r12 + neboc_imports_modulos_namespaces_e_api_publica_NATIVE_HASH_OFFSET], rax
    xor eax, eax
    pop r12
    pop rbx
    cld
    ret
.source_failure:
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_NATIVE_DECISION_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_SEM_DECISION_DENY
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_NATIVE_DIAGNOSTIC_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_DIAG_CODEGEN_codegen_modules_x86_64
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

%undef call
imports_modulos_namespaces_e_api_publica_native_hash:
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
