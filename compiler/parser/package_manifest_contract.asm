; PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-PF002 bounded package manifest source-to-syntax contract
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/package_manifest_contract.inc"

section .rodata
p_root: db 'package '
p_root_len equ $-p_root
p_dependency: db ' dependency '
p_dependency_len equ $-p_dependency
p_version: db ' version '
p_version_len equ $-p_version
p_digest: db ' digest '
p_digest_len equ $-p_digest
p_policy: db ' policy '
p_policy_len equ $-p_policy
p_strict: db 'strict'
p_strict_len equ $-p_strict
p_offline: db 'offline'
p_offline_len equ $-p_offline
p_trusted: db 'trusted'
p_trusted_len equ $-p_trusted

section .text
NEBOC_ABI_FUNCTION neboc_package_manifest_parse
    test rdi, rdi
    jz .invalid
    test rdi, neboc_packages_registry_lockfile_e_supply_chain_PARSE_ALIGNMENT - 1
    jnz .invalid
    mov r8, rdi
    add r8, neboc_packages_registry_lockfile_e_supply_chain_PARSE_REQUEST_SIZE
    jc .invalid
    cmp qword [rdi + neboc_packages_registry_lockfile_e_supply_chain_PARSE_SOURCE_OFFSET], 0
    je .invalid
    cmp qword [rdi + neboc_packages_registry_lockfile_e_supply_chain_PARSE_OUTPUT_OFFSET], 0
    je .invalid
    mov rax, [rdi + neboc_packages_registry_lockfile_e_supply_chain_PARSE_OUTPUT_OFFSET]
    test rax, neboc_packages_registry_lockfile_e_supply_chain_SYNTAX_ALIGNMENT - 1
    jnz .invalid
    mov rax, [rdi + neboc_packages_registry_lockfile_e_supply_chain_PARSE_SOURCE_LENGTH_OFFSET]
    test rax, rax
    jz .invalid
    cmp rax, neboc_packages_registry_lockfile_e_supply_chain_PARSE_MAX_SOURCE_BYTES
    ja .limit

    mov r9, [rdi + neboc_packages_registry_lockfile_e_supply_chain_PARSE_SOURCE_OFFSET]
    mov r10, r9
    add r10, rax
    jc .invalid
    mov r11, [rdi + neboc_packages_registry_lockfile_e_supply_chain_PARSE_OUTPUT_OFFSET]
    mov rdx, r11
    add rdx, neboc_packages_registry_lockfile_e_supply_chain_SYNTAX_SIZE
    jc .invalid
    cmp r10, rdi
    jbe .source_request_disjoint
    cmp r9, r8
    jb .invalid
.source_request_disjoint:
    cmp rdx, rdi
    jbe .output_request_disjoint
    cmp r11, r8
    jb .invalid
.output_request_disjoint:
    cmp r10, r11
    jbe .source_output_disjoint
    cmp r9, rdx
    jb .invalid
.source_output_disjoint:
    push rbx
    push r12
    push r13
    push r14
    push r15
    cld
    mov r12, rdi
    mov r13, [r12 + neboc_packages_registry_lockfile_e_supply_chain_PARSE_SOURCE_OFFSET]
    lea r14, [r13 + rax]
    mov r15, r13
    mov rbx, [r12 + neboc_packages_registry_lockfile_e_supply_chain_PARSE_OUTPUT_OFFSET]
    mov qword [r12 + neboc_packages_registry_lockfile_e_supply_chain_PARSE_ERROR_OFFSET_OFFSET], 0
    mov qword [r12 + neboc_packages_registry_lockfile_e_supply_chain_PARSE_DIAGNOSTIC_OFFSET], 0
    mov qword [r12 + neboc_packages_registry_lockfile_e_supply_chain_PARSE_CONSUMED_OFFSET], 0
    mov qword [r12 + neboc_packages_registry_lockfile_e_supply_chain_PARSE_CANONICAL_HASH_OFFSET], 0
    mov qword [r12 + neboc_packages_registry_lockfile_e_supply_chain_PARSE_FEATURE_MASK_OFFSET], 0
    mov rdi, rbx
    mov ecx, neboc_packages_registry_lockfile_e_supply_chain_SYNTAX_QWORDS
    xor eax, eax
    rep stosq
    mov qword [rbx + neboc_packages_registry_lockfile_e_supply_chain_SYNTAX_FLAGS_OFFSET], neboc_packages_registry_lockfile_e_supply_chain_SYNTAX_FLAG_CANONICAL

    lea rsi, [rel p_root]
    mov ecx, p_root_len
    call packages_registry_lockfile_e_supply_chain_match
    jc .lex
    call packages_registry_lockfile_e_supply_chain_identity
    jc .type
    mov [rbx + neboc_packages_registry_lockfile_e_supply_chain_SYNTAX_PACKAGE_ID_OFFSET], rax
    or qword [r12 + neboc_packages_registry_lockfile_e_supply_chain_PARSE_FEATURE_MASK_OFFSET], neboc_packages_registry_lockfile_e_supply_chain_FEATURE_PACKAGE

    lea rsi, [rel p_dependency]
    mov ecx, p_dependency_len
    call packages_registry_lockfile_e_supply_chain_match
    jc .lex
    call packages_registry_lockfile_e_supply_chain_identity
    jc .type
    mov [rbx + NEBOC_SYNTAX_DEPENDENCY_ID_OFFSET], rax
    or qword [r12 + neboc_packages_registry_lockfile_e_supply_chain_PARSE_FEATURE_MASK_OFFSET], NEBOC_FEATURE_DEPENDENCY
    cmp rax, [rbx + neboc_packages_registry_lockfile_e_supply_chain_SYNTAX_PACKAGE_ID_OFFSET]
    je .security

    lea rsi, [rel p_version]
    mov ecx, p_version_len
    call packages_registry_lockfile_e_supply_chain_match
    jc .lex
    call packages_registry_lockfile_e_supply_chain_identity
    jc .type
    mov [rbx + NEBOC_SYNTAX_VERSION_OFFSET], rax
    or qword [r12 + neboc_packages_registry_lockfile_e_supply_chain_PARSE_FEATURE_MASK_OFFSET], NEBOC_FEATURE_VERSION

    lea rsi, [rel p_digest]
    mov ecx, p_digest_len
    call packages_registry_lockfile_e_supply_chain_match
    jc .lex
    call packages_registry_lockfile_e_supply_chain_identity
    jc .type
    mov [rbx + NEBOC_SYNTAX_DIGEST_OFFSET], rax
    or qword [r12 + neboc_packages_registry_lockfile_e_supply_chain_PARSE_FEATURE_MASK_OFFSET], NEBOC_FEATURE_DIGEST

    lea rsi, [rel p_policy]
    mov ecx, p_policy_len
    call packages_registry_lockfile_e_supply_chain_match
    jc .lex
    mov rax, r15
    sub rax, r13
    mov [rbx + NEBOC_SYNTAX_POLICY_SPAN_OFFSET], rax
    cmp r15, r14
    jae .parse
    cmp byte [r15], 's'
    jne .policy_offline
    lea rsi, [rel p_strict]
    mov ecx, p_strict_len
    call packages_registry_lockfile_e_supply_chain_match
    jc .lex
    mov qword [rbx + NEBOC_SYNTAX_POLICY_OFFSET], NEBOC_POLICY_STRICT
    jmp .policy_done
.policy_offline:
    cmp byte [r15], 'o'
    jne .policy_trusted
    lea rsi, [rel p_offline]
    mov ecx, p_offline_len
    call packages_registry_lockfile_e_supply_chain_match
    jc .lex
    mov qword [rbx + NEBOC_SYNTAX_POLICY_OFFSET], NEBOC_POLICY_OFFLINE
    jmp .policy_done
.policy_trusted:
    cmp byte [r15], 't'
    jne .lex
    lea rsi, [rel p_trusted]
    mov ecx, p_trusted_len
    call packages_registry_lockfile_e_supply_chain_match
    jc .lex
    mov qword [rbx + NEBOC_SYNTAX_POLICY_OFFSET], NEBOC_POLICY_TRUSTED
.policy_done:
    or qword [r12 + neboc_packages_registry_lockfile_e_supply_chain_PARSE_FEATURE_MASK_OFFSET], NEBOC_FEATURE_POLICY
    cmp r15, r14
    jae .parse
    cmp byte [r15], ';'
    jne .parse
    inc r15
    cmp r15, r14
    je .finish
    cmp byte [r15], 10
    jne .parse
    inc r15
    cmp r15, r14
    jne .parse
.finish:
    mov rax, r15
    sub rax, r13
    mov [rbx + neboc_packages_registry_lockfile_e_supply_chain_SYNTAX_STATEMENT_LENGTH_OFFSET], rax
    mov [r12 + neboc_packages_registry_lockfile_e_supply_chain_PARSE_CONSUMED_OFFSET], rax
    mov rsi, rbx
    mov ecx, neboc_packages_registry_lockfile_e_supply_chain_SYNTAX_HASHED_BYTES
    call packages_registry_lockfile_e_supply_chain_hash
    mov [rbx + neboc_packages_registry_lockfile_e_supply_chain_SYNTAX_SHAPE_HASH_OFFSET], rax
    mov [r12 + neboc_packages_registry_lockfile_e_supply_chain_PARSE_CANONICAL_HASH_OFFSET], rax
    xor eax, eax
    jmp .done
.lex:
    mov eax, neboc_packages_registry_lockfile_e_supply_chain_DIAG_LEX_driver_cli_linux_x86_64
    jmp .failure
.parse:
    mov eax, neboc_packages_registry_lockfile_e_supply_chain_DIAG_PARSE_driver_cli_linux_x86_64
    jmp .failure
.type:
    mov eax, neboc_packages_registry_lockfile_e_supply_chain_DIAG_TYPE_driver_cli_linux_x86_64
    jmp .failure
.security:
    mov eax, neboc_packages_registry_lockfile_e_supply_chain_DIAG_SECURITY_codegen_package_x86_64
.failure:
    mov [r12 + neboc_packages_registry_lockfile_e_supply_chain_PARSE_DIAGNOSTIC_OFFSET], rax
    mov rdx, r15
    sub rdx, r13
    mov [r12 + neboc_packages_registry_lockfile_e_supply_chain_PARSE_ERROR_OFFSET_OFFSET], rdx
    mov [r12 + neboc_packages_registry_lockfile_e_supply_chain_PARSE_CONSUMED_OFFSET], rdx
    mov qword [r12 + neboc_packages_registry_lockfile_e_supply_chain_PARSE_CANONICAL_HASH_OFFSET], 0
    mov rdi, rbx
    mov ecx, neboc_packages_registry_lockfile_e_supply_chain_SYNTAX_QWORDS
    xor eax, eax
    rep stosq
    mov eax, NEBOC_STATUS_INVALID_SOURCE
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.limit:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

packages_registry_lockfile_e_supply_chain_match:
    mov rdx, r14
    sub rdx, r15
    cmp rdx, rcx
    jb .bad
.loop:
    test ecx, ecx
    jz .ok
    mov al, [r15]
    cmp al, [rsi]
    jne .bad
    inc r15
    inc rsi
    dec ecx
    jmp .loop
.ok:
    clc
    ret
.bad:
    stc
    ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
packages_registry_lockfile_e_supply_chain_identity:
    call packages_registry_lockfile_e_supply_chain_uint
    jc .bad
    test rax, rax
    jz .bad
    clc
    ret
.bad:
    stc
    ret

%undef call
packages_registry_lockfile_e_supply_chain_uint:
    xor eax, eax
    xor ecx, ecx
.loop:
    cmp r15, r14
    jae .done
    movzx edx, byte [r15]
    sub edx, '0'
    cmp edx, 9
    ja .done
    mov r8, 0x1999999999999999
    cmp rax, r8
    ja .bad
    jne .accumulate
    cmp edx, 5
    ja .bad
.accumulate:
    imul rax, rax, 10
    add rax, rdx
    inc r15
    inc ecx
    jmp .loop
.done:
    test ecx, ecx
    jz .bad
    clc
    ret
.bad:
    stc
    ret

packages_registry_lockfile_e_supply_chain_hash:
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
