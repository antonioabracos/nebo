; PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-PF001 native offline package-lock tests
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/package/package_lock.inc"

extern neboc_package_lock_init
extern neboc_package_lock_verify
extern neboc_host_process_exit

section .bss align=16
record: resb neboc_packages_registry_lockfile_e_supply_chain_RECORD_SIZE
saved_hash: resq 1

section .text
global _start
_start:
    lea rdi, [rel record]
    mov ecx, neboc_packages_registry_lockfile_e_supply_chain_RECORD_QWORDS
    xor eax, eax
    rep stosq

    xor edi, edi
    call neboc_package_lock_init
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail
    lea rdi, [rel record + 1]
    call neboc_package_lock_init
    cmp eax, NEBOC_STATUS_INVALID_ARGUMENT
    jne fail

    lea rdi, [rel record]
    mov esi, 2601
    mov edx, 2601
    mov rcx, 0x000100020003
    mov r8d, 0x260026
    mov r9d, neboc_packages_registry_lockfile_e_supply_chain_REQUIRED_FLAGS
    call neboc_package_lock_init
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel record + neboc_packages_registry_lockfile_e_supply_chain_MAGIC_OFFSET], 0
    jne fail

    lea rdi, [rel record]
    mov esi, 2601
    mov edx, 2602
    mov rcx, 0x000100020003
    mov r8d, 0x260026
    mov r9d, neboc_packages_registry_lockfile_e_supply_chain_REQUIRED_FLAGS
    call neboc_package_lock_init
    test eax, eax
    jnz fail
    mov rax, [rel record + neboc_packages_registry_lockfile_e_supply_chain_STATE_HASH_OFFSET]
    test rax, rax
    jz fail
    mov [rel saved_hash], rax

    lea rdi, [rel record]
    mov esi, 2602
    mov rdx, 0x000100020003
    mov ecx, 0x260026
    mov r8d, neboc_packages_registry_lockfile_e_supply_chain_REQUIRED_FLAGS
    call neboc_package_lock_verify
    test eax, eax
    jnz fail
    cmp qword [rel record + neboc_packages_registry_lockfile_e_supply_chain_DECISION_OFFSET], neboc_packages_registry_lockfile_e_supply_chain_DECISION_PERMIT
    jne fail

    ; Version mismatch is a type failure.
    lea rdi, [rel record]
    mov esi, 2602
    mov rdx, 0x000100020004
    mov ecx, 0x260026
    mov r8d, neboc_packages_registry_lockfile_e_supply_chain_REQUIRED_FLAGS
    call neboc_package_lock_verify
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel record + neboc_packages_registry_lockfile_e_supply_chain_DIAGNOSTIC_OFFSET], neboc_packages_registry_lockfile_e_supply_chain_DIAG_TYPE_driver_cli_linux_x86_64
    jne fail

    ; Digest and policy mismatches are security failures.
    lea rdi, [rel record]
    mov esi, 2602
    mov rdx, 0x000100020003
    mov ecx, 0x260027
    mov r8d, neboc_packages_registry_lockfile_e_supply_chain_REQUIRED_FLAGS
    call neboc_package_lock_verify
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel record + neboc_packages_registry_lockfile_e_supply_chain_DIAGNOSTIC_OFFSET], neboc_packages_registry_lockfile_e_supply_chain_DIAG_SECURITY_codegen_package_x86_64
    jne fail
    lea rdi, [rel record]
    mov esi, 2602
    mov rdx, 0x000100020003
    mov ecx, 0x260026
    mov r8d, NEBOC_FLAG_LOCAL | NEBOC_FLAG_OFFLINE
    call neboc_package_lock_verify
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail

    ; Immutable lock prefix tampering is detected before matching.
    inc qword [rel record + NEBOC_DIGEST_OFFSET]
    lea rdi, [rel record]
    mov esi, 2602
    mov rdx, 0x000100020003
    mov ecx, 0x260026
    mov r8d, neboc_packages_registry_lockfile_e_supply_chain_REQUIRED_FLAGS
    call neboc_package_lock_verify
    cmp eax, NEBOC_STATUS_INVALID_SOURCE
    jne fail
    cmp qword [rel record + neboc_packages_registry_lockfile_e_supply_chain_DIAGNOSTIC_OFFSET], neboc_packages_registry_lockfile_e_supply_chain_DIAG_SECURITY_codegen_package_x86_64
    jne fail
    mov rax, [rel saved_hash]
    cmp [rel record + neboc_packages_registry_lockfile_e_supply_chain_STATE_HASH_OFFSET], rax
    jne fail

    xor edi, edi
    jmp neboc_host_process_exit
fail:
    mov edi, 1
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
