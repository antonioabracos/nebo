; PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-PF004 authenticated x86_64 package lock plan
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/package/package_native.inc"
section .text
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_package_native_lower
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
    mov rdi,r12
    mov ecx,neboc_packages_registry_lockfile_e_supply_chain_NATIVE_QWORDS
    xor eax,eax
    rep stosq
    mov rax,neboc_packages_registry_lockfile_e_supply_chain_IR_MAGIC
    cmp [rbx+neboc_packages_registry_lockfile_e_supply_chain_IR_MAGIC_OFFSET],rax
    jne .fail
    cmp qword [rbx+neboc_packages_registry_lockfile_e_supply_chain_IR_OPERATION_OFFSET],NEBOC_IR_OPERATION_RESOLVE_LOCK
    jne .fail
    cmp qword [rbx+neboc_packages_registry_lockfile_e_supply_chain_IR_TARGET_OFFSET],0
    jne .fail
    mov rsi,rbx
    mov ecx,neboc_packages_registry_lockfile_e_supply_chain_IR_HASHED_BYTES
    call packages_registry_lockfile_e_supply_chain_native_hash
    cmp rax,[rbx+neboc_packages_registry_lockfile_e_supply_chain_IR_HASH_OFFSET]
    jne .fail
    mov rax,neboc_packages_registry_lockfile_e_supply_chain_NATIVE_MAGIC
    mov [r12+neboc_packages_registry_lockfile_e_supply_chain_NATIVE_MAGIC_OFFSET],rax
%macro COPY 2
    mov rax,[rbx+%1]
    mov [r12+%2],rax
%endmacro
    COPY NEBOC_IR_PACKAGE_OFFSET,NEBOC_NATIVE_PACKAGE_OFFSET
    COPY NEBOC_IR_DEPENDENCY_OFFSET,NEBOC_NATIVE_DEPENDENCY_OFFSET
    COPY NEBOC_IR_VERSION_OFFSET,NEBOC_NATIVE_VERSION_OFFSET
    COPY NEBOC_IR_DIGEST_OFFSET,NEBOC_NATIVE_DIGEST_OFFSET
    COPY neboc_packages_registry_lockfile_e_supply_chain_IR_POLICY_OFFSET,NEBOC_NATIVE_POLICY_OFFSET
    COPY NEBOC_IR_EPOCH_OFFSET,NEBOC_NATIVE_EPOCH_OFFSET
    COPY neboc_packages_registry_lockfile_e_supply_chain_IR_SYNTAX_HASH_OFFSET,neboc_packages_registry_lockfile_e_supply_chain_NATIVE_SYNTAX_HASH_OFFSET
    COPY NEBOC_IR_LOCK_HASH_OFFSET,NEBOC_NATIVE_LOCK_HASH_OFFSET
    COPY neboc_packages_registry_lockfile_e_supply_chain_IR_SEMANTIC_HASH_OFFSET,neboc_packages_registry_lockfile_e_supply_chain_NATIVE_SEMANTIC_HASH_OFFSET
    COPY neboc_packages_registry_lockfile_e_supply_chain_IR_HASH_OFFSET,neboc_packages_registry_lockfile_e_supply_chain_NATIVE_IR_HASH_OFFSET
    mov qword [r12+neboc_packages_registry_lockfile_e_supply_chain_NATIVE_TARGET_OFFSET],neboc_packages_registry_lockfile_e_supply_chain_NATIVE_TARGET_X86_64_SYSV_ELF
    mov qword [r12+neboc_packages_registry_lockfile_e_supply_chain_NATIVE_ABI_OFFSET],neboc_packages_registry_lockfile_e_supply_chain_NATIVE_ABI_INTERNAL_V1
    mov rax,[rbx+NEBOC_IR_DIGEST_OFFSET]
    mov [r12+neboc_packages_registry_lockfile_e_supply_chain_NATIVE_RESULT_OFFSET],rax
    mov qword [r12+neboc_packages_registry_lockfile_e_supply_chain_NATIVE_DECISION_OFFSET],neboc_packages_registry_lockfile_e_supply_chain_SEM_DECISION_PERMIT
    mov qword [r12+neboc_packages_registry_lockfile_e_supply_chain_NATIVE_FLAGS_OFFSET],neboc_packages_registry_lockfile_e_supply_chain_NATIVE_FLAG_AUTHENTICATED
    mov rsi,r12
    mov ecx,neboc_packages_registry_lockfile_e_supply_chain_NATIVE_HASHED_BYTES
    call packages_registry_lockfile_e_supply_chain_native_hash
    mov [r12+neboc_packages_registry_lockfile_e_supply_chain_NATIVE_HASH_OFFSET],rax
    xor eax,eax
    pop r12
    pop rbx
    cld
    ret
.fail:
    mov qword [r12+neboc_packages_registry_lockfile_e_supply_chain_NATIVE_DIAGNOSTIC_OFFSET],neboc_packages_registry_lockfile_e_supply_chain_DIAG_CODEGEN_codegen_package_x86_64
    mov eax,NEBOC_STATUS_INVALID_SOURCE
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
%undef call
packages_registry_lockfile_e_supply_chain_native_hash:
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
