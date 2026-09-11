; IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-PF001 native module identity and visibility tests
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/modules/module_visibility.inc"

extern neboc_module_visibility_init
extern neboc_module_visibility_resolve
extern neboc_host_process_exit

section .bss align=16
record: resb neboc_imports_modulos_namespaces_e_api_publica_RECORD_SIZE
saved_hash: resq 1

section .text
global _start
_start:
    lea rdi, [rel record]
    mov ecx, neboc_imports_modulos_namespaces_e_api_publica_RECORD_QWORDS
    xor eax, eax
    rep stosq

    xor edi, edi
    call neboc_module_visibility_init
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    lea rdi, [rel record + 1]
    call neboc_module_visibility_init
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    lea rdi, [rel record]
    mov esi, 2501
    mov edx, 25
    mov ecx, 251
    mov r8d, 252
    mov r9d, 251
    call neboc_module_visibility_init
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel record + neboc_imports_modulos_namespaces_e_api_publica_MAGIC_OFFSET], 0
    jne fail

    lea rdi, [rel record]
    mov esi, 2501
    mov edx, 25
    mov ecx, 251
    mov r8d, 252
    mov r9d, 253
    call neboc_module_visibility_init
    test eax, eax
    jnz fail
    mov rax, [rel record + neboc_imports_modulos_namespaces_e_api_publica_STATE_HASH_OFFSET]
    test rax, rax
    jz fail
    mov [rel saved_hash], rax

    ; Public crosses package boundaries.
    lea rdi, [rel record]
    mov esi, 2502
    mov edx, 26
    mov ecx, 251
    call neboc_module_visibility_resolve
    test eax, eax
    jnz fail
    cmp qword [rel record + NEBOC_LAST_VISIBILITY_OFFSET], NEBOC_VISIBILITY_PUBLIC
    jne fail

    ; Internal is package-bound.
    lea rdi, [rel record]
    mov esi, 2502
    mov edx, 25
    mov ecx, 252
    call neboc_module_visibility_resolve
    test eax, eax
    jnz fail
    lea rdi, [rel record]
    mov esi, 2502
    mov edx, 26
    mov ecx, 252
    call neboc_module_visibility_resolve
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel record + neboc_imports_modulos_namespaces_e_api_publica_DIAGNOSTIC_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_DIAG_SECURITY_codegen_modules_x86_64
    jne fail

    ; Private is module-bound; unknown symbols fail closed.
    lea rdi, [rel record]
    mov esi, 2501
    mov edx, 25
    mov ecx, 253
    call neboc_module_visibility_resolve
    test eax, eax
    jnz fail
    lea rdi, [rel record]
    mov esi, 2502
    mov edx, 25
    mov ecx, 253
    call neboc_module_visibility_resolve
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    lea rdi, [rel record]
    mov esi, 2502
    mov edx, 25
    mov ecx, 999
    call neboc_module_visibility_resolve
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel record + neboc_imports_modulos_namespaces_e_api_publica_DIAGNOSTIC_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_DIAG_TYPE_driver_cli_linux_x86_64
    jne fail
    mov rax, [rel saved_hash]
    cmp [rel record + neboc_imports_modulos_namespaces_e_api_publica_STATE_HASH_OFFSET], rax
    jne fail

    ; Identity-hash tampering is detected before visibility resolution.
    inc qword [rel record + neboc_imports_modulos_namespaces_e_api_publica_PACKAGE_ID_OFFSET]
    lea rdi, [rel record]
    mov esi, 2502
    mov edx, 25
    mov ecx, 251
    call neboc_module_visibility_resolve
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel record + neboc_imports_modulos_namespaces_e_api_publica_DIAGNOSTIC_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_DIAG_SECURITY_codegen_modules_x86_64
    jne fail

    xor edi, edi
    jmp neboc_host_process_exit
fail:
    mov edi, 1
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
