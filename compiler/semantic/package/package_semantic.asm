; PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-PF003 authenticated package-lock semantic model
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/package/package_semantic.inc"
section .text
; semantic_build(syntax*, lock*, out*)
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_package_semantic_build
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    mov rax,rdi
    or rax,rsi
    or rax,rdx
    test rax,7
    jnz .invalid
    push rbx
    push r12
    push r13
    push r14
    mov rbx,rdi
    mov r12,rsi
    mov r13,rdx
    mov rdi,r13
    mov ecx,neboc_packages_registry_lockfile_e_supply_chain_SEM_QWORDS
    xor eax,eax
    rep stosq
    cmp qword [rbx+neboc_packages_registry_lockfile_e_supply_chain_SYNTAX_FLAGS_OFFSET],neboc_packages_registry_lockfile_e_supply_chain_SYNTAX_FLAG_CANONICAL
    jne .type
    cmp qword [rbx+NEBOC_SYNTAX_POLICY_OFFSET],NEBOC_POLICY_STRICT
    jne .type
    mov rsi,rbx
    mov ecx,neboc_packages_registry_lockfile_e_supply_chain_SYNTAX_HASHED_BYTES
    call packages_registry_lockfile_e_supply_chain_sem_hash
    cmp rax,[rbx+neboc_packages_registry_lockfile_e_supply_chain_SYNTAX_SHAPE_HASH_OFFSET]
    jne .security
    mov rax,neboc_packages_registry_lockfile_e_supply_chain_MAGIC
    cmp [r12+neboc_packages_registry_lockfile_e_supply_chain_MAGIC_OFFSET],rax
    jne .type
    cmp qword [r12+neboc_packages_registry_lockfile_e_supply_chain_INITIALIZED_OFFSET],1
    jne .type
    mov rsi,r12
    mov ecx,neboc_packages_registry_lockfile_e_supply_chain_HASHED_BYTES
    call packages_registry_lockfile_e_supply_chain_sem_hash
    cmp rax,[r12+neboc_packages_registry_lockfile_e_supply_chain_STATE_HASH_OFFSET]
    jne .security
    mov rax,[rbx+neboc_packages_registry_lockfile_e_supply_chain_SYNTAX_PACKAGE_ID_OFFSET]
    cmp rax,[r12+neboc_packages_registry_lockfile_e_supply_chain_PACKAGE_ID_OFFSET]
    jne .type
    mov [r13+NEBOC_SEM_PACKAGE_OFFSET],rax
    mov rax,[rbx+NEBOC_SYNTAX_DEPENDENCY_ID_OFFSET]
    cmp rax,[r12+NEBOC_DEPENDENCY_ID_OFFSET]
    jne .type
    mov [r13+NEBOC_SEM_DEPENDENCY_OFFSET],rax
    mov rax,[rbx+NEBOC_SYNTAX_VERSION_OFFSET]
    cmp rax,[r12+NEBOC_VERSION_OFFSET]
    jne .type
    mov [r13+NEBOC_SEM_VERSION_OFFSET],rax
    mov rax,[rbx+NEBOC_SYNTAX_DIGEST_OFFSET]
    cmp rax,[r12+NEBOC_DIGEST_OFFSET]
    jne .security
    mov [r13+NEBOC_SEM_DIGEST_OFFSET],rax
    cmp qword [r12+neboc_packages_registry_lockfile_e_supply_chain_FLAGS_OFFSET],neboc_packages_registry_lockfile_e_supply_chain_REQUIRED_FLAGS
    jne .security
    mov rax,neboc_packages_registry_lockfile_e_supply_chain_SEM_MAGIC
    mov [r13+neboc_packages_registry_lockfile_e_supply_chain_SEM_MAGIC_OFFSET],rax
    mov qword [r13+neboc_packages_registry_lockfile_e_supply_chain_SEM_POLICY_OFFSET],NEBOC_POLICY_STRICT
    mov qword [r13+neboc_packages_registry_lockfile_e_supply_chain_SEM_DECISION_OFFSET],neboc_packages_registry_lockfile_e_supply_chain_SEM_DECISION_PERMIT
    mov rax,[rbx+neboc_packages_registry_lockfile_e_supply_chain_SYNTAX_SHAPE_HASH_OFFSET]
    mov [r13+neboc_packages_registry_lockfile_e_supply_chain_SEM_SYNTAX_HASH_OFFSET],rax
    mov rax,[r12+neboc_packages_registry_lockfile_e_supply_chain_STATE_HASH_OFFSET]
    mov [r13+NEBOC_SEM_LOCK_HASH_OFFSET],rax
    mov rax,[r12+NEBOC_RESOLUTION_EPOCH_OFFSET]
    mov [r13+NEBOC_SEM_EPOCH_OFFSET],rax
    mov qword [r13+neboc_packages_registry_lockfile_e_supply_chain_SEM_FLAGS_OFFSET],neboc_packages_registry_lockfile_e_supply_chain_SEM_FLAG_AUTHENTICATED
    mov rsi,r13
    mov ecx,neboc_packages_registry_lockfile_e_supply_chain_SEM_HASHED_BYTES
    call packages_registry_lockfile_e_supply_chain_sem_hash
    mov [r13+neboc_packages_registry_lockfile_e_supply_chain_SEM_HASH_OFFSET],rax
    xor eax,eax
    jmp .done
.type:
    mov r14d,neboc_packages_registry_lockfile_e_supply_chain_DIAG_TYPE_driver_cli_linux_x86_64
    jmp .fail
.security:
    mov r14d,neboc_packages_registry_lockfile_e_supply_chain_DIAG_SECURITY_codegen_package_x86_64
.fail:
    mov rdi,r13
    mov ecx,neboc_packages_registry_lockfile_e_supply_chain_SEM_QWORDS
    xor eax,eax
    rep stosq
    mov [r13+neboc_packages_registry_lockfile_e_supply_chain_SEM_DIAGNOSTIC_OFFSET],r14
    mov eax,NEBOC_STATUS_INVALID_SOURCE
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
packages_registry_lockfile_e_supply_chain_sem_hash:
    mov rax,14695981039346656037
    mov r8,1099511628211
    xor edx,edx
.loop:
    cmp edx,ecx
    jae .hash_done
    movzx r9d,byte [rsi+rdx]
    xor rax,r9
    imul rax,r8
    inc edx
    jmp .loop
.hash_done:
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
