; Nebo Assembly — IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-PF001 bounded module identity and visibility authority
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/modules/module_visibility.inc"

section .text

; module_visibility_init(record*, module, package, public, internal, private)
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_module_visibility_init
    test rdi, rdi
    jz .bad_transport
    test rdi, neboc_imports_modulos_namespaces_e_api_publica_ALIGNMENT - 1
    jnz .bad_transport
    test rsi, rsi
    jz .bad_source
    test rdx, rdx
    jz .bad_source
    test rcx, rcx
    jz .bad_source
    test r8, r8
    jz .bad_source
    test r9, r9
    jz .bad_source
    cmp rcx, r8
    je .bad_source
    cmp rcx, r9
    je .bad_source
    cmp r8, r9
    je .bad_source
    cmp qword [rdi + neboc_imports_modulos_namespaces_e_api_publica_MAGIC_OFFSET], 0
    jne .bad_source

    push r12
    mov r12, rdi
    mov rax, neboc_imports_modulos_namespaces_e_api_publica_MAGIC
    mov [r12 + neboc_imports_modulos_namespaces_e_api_publica_MAGIC_OFFSET], rax
    mov [r12 + NEBOC_MODULE_ID_OFFSET], rsi
    mov [r12 + neboc_imports_modulos_namespaces_e_api_publica_PACKAGE_ID_OFFSET], rdx
    mov [r12 + NEBOC_PUBLIC_SYMBOL_OFFSET], rcx
    mov [r12 + NEBOC_INTERNAL_SYMBOL_OFFSET], r8
    mov [r12 + NEBOC_PRIVATE_SYMBOL_OFFSET], r9
    mov qword [r12 + NEBOC_GRAPH_EPOCH_OFFSET], 1
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_INITIALIZED_OFFSET], 1
    mov qword [r12 + NEBOC_LAST_IMPORTER_MODULE_OFFSET], 0
    mov qword [r12 + NEBOC_LAST_IMPORTER_PACKAGE_OFFSET], 0
    mov qword [r12 + NEBOC_LAST_SYMBOL_OFFSET], 0
    mov qword [r12 + NEBOC_LAST_VISIBILITY_OFFSET], 0
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_DECISION_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_DECISION_PERMIT
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_DIAGNOSTIC_OFFSET], 0
    mov qword [r12 + NEBOC_RESOLVE_COUNT_OFFSET], 0
    push rsi
    push rdx
    push rcx
    call hash_identity
    pop rcx
    pop rdx
    pop rsi
    mov [r12 + neboc_imports_modulos_namespaces_e_api_publica_STATE_HASH_OFFSET], rax
    xor eax, eax
    pop r12
    cld
    ret
.bad_source:
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    cld
    ret
.bad_transport:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; module_visibility_resolve(record*, importer_module, importer_package, symbol)
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_module_visibility_resolve
    test rdi, rdi
    jz .resolve_bad_transport
    test rdi, neboc_imports_modulos_namespaces_e_api_publica_ALIGNMENT - 1
    jnz .resolve_bad_transport
    push r12
    mov r12, rdi
    mov rax, neboc_imports_modulos_namespaces_e_api_publica_MAGIC
    cmp [r12 + neboc_imports_modulos_namespaces_e_api_publica_MAGIC_OFFSET], rax
    jne .resolve_type
    cmp qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_INITIALIZED_OFFSET], 1
    jne .resolve_type
    push rsi
    push rdx
    push rcx
    call hash_identity
    pop rcx
    pop rdx
    pop rsi
    cmp rax, [r12 + neboc_imports_modulos_namespaces_e_api_publica_STATE_HASH_OFFSET]
    jne .resolve_security
    test rsi, rsi
    jz .resolve_type
    test rdx, rdx
    jz .resolve_type
    test rcx, rcx
    jz .resolve_type

    mov [r12 + NEBOC_LAST_IMPORTER_MODULE_OFFSET], rsi
    mov [r12 + NEBOC_LAST_IMPORTER_PACKAGE_OFFSET], rdx
    mov [r12 + NEBOC_LAST_SYMBOL_OFFSET], rcx
    inc qword [r12 + NEBOC_RESOLVE_COUNT_OFFSET]
    cmp rcx, [r12 + NEBOC_PUBLIC_SYMBOL_OFFSET]
    je .permit_public
    cmp rcx, [r12 + NEBOC_INTERNAL_SYMBOL_OFFSET]
    je .check_internal
    cmp rcx, [r12 + NEBOC_PRIVATE_SYMBOL_OFFSET]
    je .check_private
    jmp .resolve_type
.check_internal:
    cmp rdx, [r12 + neboc_imports_modulos_namespaces_e_api_publica_PACKAGE_ID_OFFSET]
    jne .resolve_security
    mov eax, NEBOC_VISIBILITY_INTERNAL
    jmp .permit
.check_private:
    cmp rsi, [r12 + NEBOC_MODULE_ID_OFFSET]
    jne .resolve_security
    mov eax, NEBOC_VISIBILITY_PRIVATE
    jmp .permit
.permit_public:
    mov eax, NEBOC_VISIBILITY_PUBLIC
.permit:
    mov [r12 + NEBOC_LAST_VISIBILITY_OFFSET], rax
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_DECISION_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_DECISION_PERMIT
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_DIAGNOSTIC_OFFSET], 0
    xor eax, eax
    pop r12
    cld
    ret
.resolve_type:
    mov eax, neboc_imports_modulos_namespaces_e_api_publica_DIAG_TYPE_driver_cli_linux_x86_64
    jmp .deny
.resolve_security:
    mov eax, neboc_imports_modulos_namespaces_e_api_publica_DIAG_SECURITY_codegen_modules_x86_64
.deny:
    mov qword [r12 + NEBOC_LAST_VISIBILITY_OFFSET], NEBOC_VISIBILITY_NONE
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_DECISION_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_DECISION_DENY
    mov [r12 + neboc_imports_modulos_namespaces_e_api_publica_DIAGNOSTIC_OFFSET], rax
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    pop r12
    cld
    ret
.resolve_bad_transport:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

%undef call
hash_identity:
    mov rax, 14695981039346656037
    mov r8, 1099511628211
    xor ecx, ecx
.hash_loop:
    cmp rcx, neboc_imports_modulos_namespaces_e_api_publica_HASHED_BYTES
    jae .hash_done
    movzx edx, byte [r12 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .hash_loop
.hash_done:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
