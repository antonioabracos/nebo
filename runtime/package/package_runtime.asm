; PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-PF004 bounded single-use package lock runtime
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "runtime/package/package_runtime.inc"
section .text
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_package_runtime_execute
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    mov rax,rdi
    or rax,rsi
    test rax,7
    jnz .invalid
    push rbx
    push r12
    mov rbx,rdi
    mov r12,rsi
    cmp qword [r12+neboc_packages_registry_lockfile_e_supply_chain_RUNTIME_MAGIC_OFFSET],0
    jne .replay
    mov rax,neboc_packages_registry_lockfile_e_supply_chain_NATIVE_MAGIC
    cmp [rbx+neboc_packages_registry_lockfile_e_supply_chain_NATIVE_MAGIC_OFFSET],rax
    jne .security
    cmp qword [rbx+neboc_packages_registry_lockfile_e_supply_chain_NATIVE_TARGET_OFFSET],neboc_packages_registry_lockfile_e_supply_chain_NATIVE_TARGET_X86_64_SYSV_ELF
    jne .security
    mov rsi,rbx
    mov ecx,neboc_packages_registry_lockfile_e_supply_chain_NATIVE_HASHED_BYTES
    call packages_registry_lockfile_e_supply_chain_runtime_hash
    cmp rax,[rbx+neboc_packages_registry_lockfile_e_supply_chain_NATIVE_HASH_OFFSET]
    jne .security
    mov rax,neboc_packages_registry_lockfile_e_supply_chain_RUNTIME_MAGIC
    mov [r12+neboc_packages_registry_lockfile_e_supply_chain_RUNTIME_MAGIC_OFFSET],rax
    mov rax,[rbx+neboc_packages_registry_lockfile_e_supply_chain_NATIVE_HASH_OFFSET]
    mov [r12+neboc_packages_registry_lockfile_e_supply_chain_RUNTIME_PLAN_HASH_OFFSET],rax
    mov rax,[rbx+neboc_packages_registry_lockfile_e_supply_chain_NATIVE_RESULT_OFFSET]
    mov [r12+neboc_packages_registry_lockfile_e_supply_chain_RUNTIME_RESULT_OFFSET],rax
    mov rax,[rbx+NEBOC_NATIVE_POLICY_OFFSET]
    mov [r12+NEBOC_RUNTIME_POLICY_OFFSET],rax
    mov qword [r12+neboc_packages_registry_lockfile_e_supply_chain_RUNTIME_GENERATION_OFFSET],1
    mov qword [r12+neboc_packages_registry_lockfile_e_supply_chain_RUNTIME_CONSUMED_OFFSET],1
    mov rsi,r12
    mov ecx,neboc_packages_registry_lockfile_e_supply_chain_RUNTIME_HASHED_BYTES
    call packages_registry_lockfile_e_supply_chain_runtime_hash
    mov [r12+neboc_packages_registry_lockfile_e_supply_chain_RUNTIME_HASH_OFFSET],rax
    xor eax,eax
    jmp .done
.replay:
    mov qword [r12+neboc_packages_registry_lockfile_e_supply_chain_RUNTIME_DIAGNOSTIC_OFFSET],neboc_packages_registry_lockfile_e_supply_chain_DIAG_RUNTIME_driver_cli_linux_x86_64
    mov eax,NEBOC_STATUS_INVALID_SOURCE
    jmp .done
.security:
    mov qword [r12+neboc_packages_registry_lockfile_e_supply_chain_RUNTIME_DIAGNOSTIC_OFFSET],neboc_packages_registry_lockfile_e_supply_chain_DIAG_SECURITY_codegen_package_x86_64
    mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
%undef call
packages_registry_lockfile_e_supply_chain_runtime_hash:
    mov rax,14695981039346656037
    mov r8,1099511628211
    xor edx,edx
.loop:
    cmp edx,ecx
    jae .done
    movzx r9d,byte [rsi+rdx]
    xor rax,r9
    imul rax,r8
    inc edx
    jmp .loop
.done:
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
