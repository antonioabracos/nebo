; IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-PF003 authenticated module visibility semantic model
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/modules/module_semantic.inc"

section .text
; semantic_build(syntax*, export_table*, semantic_out*)
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_module_semantic_build
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    test rdx, rdx
    jz .invalid
    mov rax, rdi
    or rax, rsi
    or rax, rdx
    test rax, neboc_imports_modulos_namespaces_e_api_publica_SEM_ALIGNMENT - 1
    jnz .invalid
    mov r8, rdi
    add r8, neboc_imports_modulos_namespaces_e_api_publica_SYNTAX_SIZE
    jc .invalid
    mov r9, rsi
    add r9, neboc_imports_modulos_namespaces_e_api_publica_RECORD_SIZE
    jc .invalid
    mov r10, rdx
    add r10, neboc_imports_modulos_namespaces_e_api_publica_SEM_SIZE
    jc .invalid
    cmp r8, rsi
    jbe .syntax_table_ok
    cmp r9, rdi
    ja .invalid
.syntax_table_ok:
    cmp r8, rdx
    jbe .syntax_out_ok
    cmp r10, rdi
    ja .invalid
.syntax_out_ok:
    cmp r9, rdx
    jbe .ranges_ok
    cmp r10, rsi
    ja .invalid
.ranges_ok:
    push rbx
    push r12
    push r13
    push r14
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov rdi, r13
    mov ecx, neboc_imports_modulos_namespaces_e_api_publica_SEM_QWORDS
    xor eax, eax
    rep stosq

    cmp qword [rbx + neboc_imports_modulos_namespaces_e_api_publica_SYNTAX_FLAGS_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_SYNTAX_FLAG_CANONICAL
    jne .type_failure
    cmp qword [rbx + NEBOC_SYNTAX_MODULE_ID_OFFSET], 0
    je .type_failure
    cmp qword [rbx + neboc_imports_modulos_namespaces_e_api_publica_SYNTAX_PACKAGE_ID_OFFSET], 0
    je .type_failure
    cmp qword [rbx + NEBOC_SYNTAX_IMPORT_MODULE_OFFSET], 0
    je .type_failure
    cmp qword [rbx + NEBOC_SYNTAX_SYMBOL_ID_OFFSET], 0
    je .type_failure
    mov rsi, rbx
    mov ecx, neboc_imports_modulos_namespaces_e_api_publica_SYNTAX_HASHED_BYTES
    call imports_modulos_namespaces_e_api_publica_sem_hash
    cmp rax, [rbx + neboc_imports_modulos_namespaces_e_api_publica_SYNTAX_SHAPE_HASH_OFFSET]
    jne .security_failure

    mov rax, neboc_imports_modulos_namespaces_e_api_publica_MAGIC
    cmp [r12 + neboc_imports_modulos_namespaces_e_api_publica_MAGIC_OFFSET], rax
    jne .type_failure
    cmp qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_INITIALIZED_OFFSET], 1
    jne .type_failure
    mov rsi, r12
    mov ecx, neboc_imports_modulos_namespaces_e_api_publica_HASHED_BYTES
    call imports_modulos_namespaces_e_api_publica_sem_hash
    cmp rax, [r12 + neboc_imports_modulos_namespaces_e_api_publica_STATE_HASH_OFFSET]
    jne .security_failure
    mov rax, [rbx + NEBOC_SYNTAX_IMPORT_MODULE_OFFSET]
    cmp rax, [r12 + NEBOC_MODULE_ID_OFFSET]
    jne .type_failure

    mov r14, [rbx + NEBOC_SYNTAX_VISIBILITY_OFFSET]
    cmp r14, NEBOC_VISIBILITY_PUBLIC
    je .public
    cmp r14, NEBOC_VISIBILITY_INTERNAL
    je .internal
    cmp r14, NEBOC_VISIBILITY_PRIVATE
    je .private
    jmp .type_failure
.public:
    mov rax, [r12 + NEBOC_PUBLIC_SYMBOL_OFFSET]
    jmp .check_symbol
.internal:
    mov rax, [rbx + neboc_imports_modulos_namespaces_e_api_publica_SYNTAX_PACKAGE_ID_OFFSET]
    cmp rax, [r12 + neboc_imports_modulos_namespaces_e_api_publica_PACKAGE_ID_OFFSET]
    jne .security_failure
    mov rax, [r12 + NEBOC_INTERNAL_SYMBOL_OFFSET]
    jmp .check_symbol
.private:
    mov rax, [rbx + NEBOC_SYNTAX_MODULE_ID_OFFSET]
    cmp rax, [r12 + NEBOC_MODULE_ID_OFFSET]
    jne .security_failure
    mov rax, [r12 + NEBOC_PRIVATE_SYMBOL_OFFSET]
.check_symbol:
    cmp rax, [rbx + NEBOC_SYNTAX_SYMBOL_ID_OFFSET]
    jne .type_failure

    mov rax, neboc_imports_modulos_namespaces_e_api_publica_SEM_MAGIC
    mov [r13 + neboc_imports_modulos_namespaces_e_api_publica_SEM_MAGIC_OFFSET], rax
    mov rax, [rbx + NEBOC_SYNTAX_MODULE_ID_OFFSET]
    mov [r13 + NEBOC_SEM_MODULE_ID_OFFSET], rax
    mov rax, [rbx + neboc_imports_modulos_namespaces_e_api_publica_SYNTAX_PACKAGE_ID_OFFSET]
    mov [r13 + NEBOC_SEM_PACKAGE_ID_OFFSET], rax
    mov rax, [rbx + NEBOC_SYNTAX_IMPORT_MODULE_OFFSET]
    mov [r13 + NEBOC_SEM_IMPORT_MODULE_OFFSET], rax
    mov rax, [r12 + neboc_imports_modulos_namespaces_e_api_publica_PACKAGE_ID_OFFSET]
    mov [r13 + NEBOC_SEM_EXPORT_PACKAGE_OFFSET], rax
    mov rax, [rbx + NEBOC_SYNTAX_SYMBOL_ID_OFFSET]
    mov [r13 + neboc_imports_modulos_namespaces_e_api_publica_SEM_SYMBOL_ID_OFFSET], rax
    mov [r13 + NEBOC_SEM_REQUESTED_VISIBILITY_OFFSET], r14
    mov [r13 + NEBOC_SEM_RESOLVED_VISIBILITY_OFFSET], r14
    mov qword [r13 + neboc_imports_modulos_namespaces_e_api_publica_SEM_DECISION_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_SEM_DECISION_PERMIT
    mov qword [r13 + neboc_imports_modulos_namespaces_e_api_publica_SEM_DIAGNOSTIC_OFFSET], 0
    mov rax, [rbx + neboc_imports_modulos_namespaces_e_api_publica_SYNTAX_SHAPE_HASH_OFFSET]
    mov [r13 + neboc_imports_modulos_namespaces_e_api_publica_SEM_SYNTAX_HASH_OFFSET], rax
    mov rax, [r12 + neboc_imports_modulos_namespaces_e_api_publica_STATE_HASH_OFFSET]
    mov [r13 + NEBOC_SEM_TABLE_HASH_OFFSET], rax
    mov rax, [r12 + NEBOC_GRAPH_EPOCH_OFFSET]
    mov [r13 + NEBOC_SEM_GRAPH_EPOCH_OFFSET], rax
    mov qword [r13 + neboc_imports_modulos_namespaces_e_api_publica_SEM_FLAGS_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_SEM_FLAG_AUTHENTICATED
    mov rsi, r13
    mov ecx, neboc_imports_modulos_namespaces_e_api_publica_SEM_HASHED_BYTES
    call imports_modulos_namespaces_e_api_publica_sem_hash
    mov [r13 + neboc_imports_modulos_namespaces_e_api_publica_SEM_HASH_OFFSET], rax
    xor eax, eax
    jmp .done
.type_failure:
    mov r14d, neboc_imports_modulos_namespaces_e_api_publica_DIAG_TYPE_driver_cli_linux_x86_64
    jmp .failure
.security_failure:
    mov r14d, neboc_imports_modulos_namespaces_e_api_publica_DIAG_SECURITY_codegen_modules_x86_64
.failure:
    mov rdi, r13
    mov ecx, neboc_imports_modulos_namespaces_e_api_publica_SEM_QWORDS
    xor eax, eax
    rep stosq
    mov qword [r13 + neboc_imports_modulos_namespaces_e_api_publica_SEM_DECISION_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_SEM_DECISION_DENY
    mov [r13 + neboc_imports_modulos_namespaces_e_api_publica_SEM_DIAGNOSTIC_OFFSET], r14
    mov eax, NEBOC_STATUS_INVALID_SOURCE
.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

%undef call
imports_modulos_namespaces_e_api_publica_sem_hash:
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
