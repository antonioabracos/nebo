; Nebo Assembly — PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-PF001 bounded offline package-lock authority
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/package/package_lock.inc"

section .text

; package_lock_init(record*, package, dependency, packed_version, digest, flags)
NEBOC_ABI_FUNCTION neboc_package_lock_init
    test rdi, rdi
    jz .bad_transport
    test rdi, neboc_packages_registry_lockfile_e_supply_chain_ALIGNMENT - 1
    jnz .bad_transport
    test rsi, rsi
    jz .bad_source
    test rdx, rdx
    jz .bad_source
    cmp rsi, rdx
    je .bad_source
    test rcx, rcx
    jz .bad_source
    test r8, r8
    jz .bad_source
    cmp r9, neboc_packages_registry_lockfile_e_supply_chain_REQUIRED_FLAGS
    jne .bad_source
    cmp qword [rdi + neboc_packages_registry_lockfile_e_supply_chain_MAGIC_OFFSET], 0
    jne .bad_source

    push r12
    mov r12, rdi
    mov rax, neboc_packages_registry_lockfile_e_supply_chain_MAGIC
    mov [r12 + neboc_packages_registry_lockfile_e_supply_chain_MAGIC_OFFSET], rax
    mov [r12 + neboc_packages_registry_lockfile_e_supply_chain_PACKAGE_ID_OFFSET], rsi
    mov [r12 + NEBOC_DEPENDENCY_ID_OFFSET], rdx
    mov [r12 + NEBOC_VERSION_OFFSET], rcx
    mov [r12 + NEBOC_DIGEST_OFFSET], r8
    mov [r12 + neboc_packages_registry_lockfile_e_supply_chain_FLAGS_OFFSET], r9
    mov qword [r12 + NEBOC_RESOLUTION_EPOCH_OFFSET], 1
    mov qword [r12 + neboc_packages_registry_lockfile_e_supply_chain_INITIALIZED_OFFSET], 1
    mov qword [r12 + NEBOC_LAST_DEPENDENCY_OFFSET], 0
    mov qword [r12 + NEBOC_LAST_VERSION_OFFSET], 0
    mov qword [r12 + NEBOC_LAST_DIGEST_OFFSET], 0
    mov qword [r12 + neboc_packages_registry_lockfile_e_supply_chain_DECISION_OFFSET], neboc_packages_registry_lockfile_e_supply_chain_DECISION_PERMIT
    mov qword [r12 + neboc_packages_registry_lockfile_e_supply_chain_DIAGNOSTIC_OFFSET], 0
    mov qword [r12 + NEBOC_VERIFY_COUNT_OFFSET], 0
    mov qword [r12 + NEBOC_RESERVED_OFFSET], 0
    call hash_lock_identity
    mov [r12 + neboc_packages_registry_lockfile_e_supply_chain_STATE_HASH_OFFSET], rax
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

; package_lock_verify(record*, dependency, packed_version, digest, flags)
NEBOC_ABI_FUNCTION neboc_package_lock_verify
    test rdi, rdi
    jz .verify_bad_transport
    test rdi, neboc_packages_registry_lockfile_e_supply_chain_ALIGNMENT - 1
    jnz .verify_bad_transport
    push r12
    mov r12, rdi
    mov rax, neboc_packages_registry_lockfile_e_supply_chain_MAGIC
    cmp [r12 + neboc_packages_registry_lockfile_e_supply_chain_MAGIC_OFFSET], rax
    jne .verify_type_early
    cmp qword [r12 + neboc_packages_registry_lockfile_e_supply_chain_INITIALIZED_OFFSET], 1
    jne .verify_type_early
    push rsi
    push rdx
    push rcx
    push r8
    call hash_lock_identity
    pop r8
    pop rcx
    pop rdx
    pop rsi
    cmp rax, [r12 + neboc_packages_registry_lockfile_e_supply_chain_STATE_HASH_OFFSET]
    jne .verify_security
    test rsi, rsi
    jz .verify_type
    test rdx, rdx
    jz .verify_type
    test rcx, rcx
    jz .verify_type
    mov [r12 + NEBOC_LAST_DEPENDENCY_OFFSET], rsi
    mov [r12 + NEBOC_LAST_VERSION_OFFSET], rdx
    mov [r12 + NEBOC_LAST_DIGEST_OFFSET], rcx
    inc qword [r12 + NEBOC_VERIFY_COUNT_OFFSET]
    cmp rsi, [r12 + NEBOC_DEPENDENCY_ID_OFFSET]
    jne .verify_type
    cmp rdx, [r12 + NEBOC_VERSION_OFFSET]
    jne .verify_type
    cmp rcx, [r12 + NEBOC_DIGEST_OFFSET]
    jne .verify_security
    cmp r8, neboc_packages_registry_lockfile_e_supply_chain_REQUIRED_FLAGS
    jne .verify_security
    cmp r8, [r12 + neboc_packages_registry_lockfile_e_supply_chain_FLAGS_OFFSET]
    jne .verify_security
    mov qword [r12 + neboc_packages_registry_lockfile_e_supply_chain_DECISION_OFFSET], neboc_packages_registry_lockfile_e_supply_chain_DECISION_PERMIT
    mov qword [r12 + neboc_packages_registry_lockfile_e_supply_chain_DIAGNOSTIC_OFFSET], 0
    xor eax, eax
    pop r12
    cld
    ret
.verify_type_early:
    mov eax, neboc_packages_registry_lockfile_e_supply_chain_DIAG_TYPE_driver_cli_linux_x86_64
    jmp .deny
.verify_type:
    mov eax, neboc_packages_registry_lockfile_e_supply_chain_DIAG_TYPE_driver_cli_linux_x86_64
    jmp .deny
.verify_security:
    mov eax, neboc_packages_registry_lockfile_e_supply_chain_DIAG_SECURITY_codegen_package_x86_64
.deny:
    mov qword [r12 + neboc_packages_registry_lockfile_e_supply_chain_DECISION_OFFSET], neboc_packages_registry_lockfile_e_supply_chain_DECISION_DENY
    mov [r12 + neboc_packages_registry_lockfile_e_supply_chain_DIAGNOSTIC_OFFSET], rax
    mov eax, NEBOC_STATUS_INVALID_SOURCE
    pop r12
    cld
    ret
.verify_bad_transport:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

hash_lock_identity:
    mov rax, 14695981039346656037
    mov r8, 1099511628211
    xor ecx, ecx
.hash_loop:
    cmp rcx, neboc_packages_registry_lockfile_e_supply_chain_HASHED_BYTES
    jae .hash_done
    movzx edx, byte [r12 + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .hash_loop
.hash_done:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
