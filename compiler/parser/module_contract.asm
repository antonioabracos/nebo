; IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-PF002 bounded module/import source-to-syntax contract
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/module_contract.inc"

section .rodata
p_module: db 'module '
p_module_len equ $-p_module
p_package: db ' package '
p_package_len equ $-p_package
p_import: db ' import '
p_import_len equ $-p_import
p_symbol: db ' symbol '
p_symbol_len equ $-p_symbol
p_visibility: db ' visibility '
p_visibility_len equ $-p_visibility
p_public: db 'public'
p_public_len equ $-p_public
p_internal: db 'internal'
p_internal_len equ $-p_internal
p_private: db 'private'
p_private_len equ $-p_private

section .text
NEBOC_ABI_FUNCTION neboc_imports_modulos_namespaces_e_api_publica_module_parse
    test rdi, rdi
    jz .invalid
    test rdi, neboc_imports_modulos_namespaces_e_api_publica_PARSE_ALIGNMENT - 1
    jnz .invalid
    mov r8, rdi
    add r8, neboc_imports_modulos_namespaces_e_api_publica_PARSE_REQUEST_SIZE
    jc .invalid
    cmp qword [rdi + neboc_imports_modulos_namespaces_e_api_publica_PARSE_SOURCE_OFFSET], 0
    je .invalid
    cmp qword [rdi + neboc_imports_modulos_namespaces_e_api_publica_PARSE_OUTPUT_OFFSET], 0
    je .invalid
    mov rax, [rdi + neboc_imports_modulos_namespaces_e_api_publica_PARSE_OUTPUT_OFFSET]
    test rax, neboc_imports_modulos_namespaces_e_api_publica_SYNTAX_ALIGNMENT - 1
    jnz .invalid
    mov rax, [rdi + neboc_imports_modulos_namespaces_e_api_publica_PARSE_SOURCE_LENGTH_OFFSET]
    test rax, rax
    jz .invalid
    cmp rax, neboc_imports_modulos_namespaces_e_api_publica_PARSE_MAX_SOURCE_BYTES
    ja .limit

    mov r9, [rdi + neboc_imports_modulos_namespaces_e_api_publica_PARSE_SOURCE_OFFSET]
    mov r10, r9
    add r10, rax
    jc .invalid
    mov r11, [rdi + neboc_imports_modulos_namespaces_e_api_publica_PARSE_OUTPUT_OFFSET]
    mov rdx, r11
    add rdx, neboc_imports_modulos_namespaces_e_api_publica_SYNTAX_SIZE
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
    mov r13, [r12 + neboc_imports_modulos_namespaces_e_api_publica_PARSE_SOURCE_OFFSET]
    lea r14, [r13 + rax]
    mov r15, r13
    mov rbx, [r12 + neboc_imports_modulos_namespaces_e_api_publica_PARSE_OUTPUT_OFFSET]
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_PARSE_ERROR_OFFSET_OFFSET], 0
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_PARSE_DIAGNOSTIC_OFFSET], 0
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_PARSE_CONSUMED_OFFSET], 0
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_PARSE_CANONICAL_HASH_OFFSET], 0
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_PARSE_FEATURE_MASK_OFFSET], 0
    mov rdi, rbx
    mov ecx, neboc_imports_modulos_namespaces_e_api_publica_SYNTAX_QWORDS
    xor eax, eax
    rep stosq
    mov qword [rbx + neboc_imports_modulos_namespaces_e_api_publica_SYNTAX_FLAGS_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_SYNTAX_FLAG_CANONICAL

    lea rsi, [rel p_module]
    mov ecx, p_module_len
    call imports_modulos_namespaces_e_api_publica_match
    jc .lex
    call imports_modulos_namespaces_e_api_publica_identity
    jc .type
    mov [rbx + NEBOC_SYNTAX_MODULE_ID_OFFSET], rax
    or qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_PARSE_FEATURE_MASK_OFFSET], NEBOC_FEATURE_MODULE

    lea rsi, [rel p_package]
    mov ecx, p_package_len
    call imports_modulos_namespaces_e_api_publica_match
    jc .lex
    call imports_modulos_namespaces_e_api_publica_identity
    jc .type
    mov [rbx + neboc_imports_modulos_namespaces_e_api_publica_SYNTAX_PACKAGE_ID_OFFSET], rax
    or qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_PARSE_FEATURE_MASK_OFFSET], neboc_imports_modulos_namespaces_e_api_publica_FEATURE_PACKAGE

    lea rsi, [rel p_import]
    mov ecx, p_import_len
    call imports_modulos_namespaces_e_api_publica_match
    jc .lex
    call imports_modulos_namespaces_e_api_publica_identity
    jc .type
    mov [rbx + NEBOC_SYNTAX_IMPORT_MODULE_OFFSET], rax
    or qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_PARSE_FEATURE_MASK_OFFSET], NEBOC_FEATURE_IMPORT
    cmp rax, [rbx + NEBOC_SYNTAX_MODULE_ID_OFFSET]
    je .security

    lea rsi, [rel p_symbol]
    mov ecx, p_symbol_len
    call imports_modulos_namespaces_e_api_publica_match
    jc .lex
    call imports_modulos_namespaces_e_api_publica_identity
    jc .type
    mov [rbx + NEBOC_SYNTAX_SYMBOL_ID_OFFSET], rax
    or qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_PARSE_FEATURE_MASK_OFFSET], NEBOC_FEATURE_SYMBOL

    lea rsi, [rel p_visibility]
    mov ecx, p_visibility_len
    call imports_modulos_namespaces_e_api_publica_match
    jc .lex
    mov rax, r15
    sub rax, r13
    mov [rbx + NEBOC_SYNTAX_VISIBILITY_SPAN_OFFSET], rax
    cmp r15, r14
    jae .parse
    cmp byte [r15], 'p'
    jne .visibility_internal
    mov rax, r14
    sub rax, r15
    cmp rax, 2
    jb .lex
    cmp byte [r15 + 1], 'u'
    jne .visibility_private
    lea rsi, [rel p_public]
    mov ecx, p_public_len
    call imports_modulos_namespaces_e_api_publica_match
    jc .lex
    mov qword [rbx + NEBOC_SYNTAX_VISIBILITY_OFFSET], NEBOC_VISIBILITY_PUBLIC
    jmp .visibility_done
.visibility_internal:
    cmp byte [r15], 'i'
    jne .lex
    lea rsi, [rel p_internal]
    mov ecx, p_internal_len
    call imports_modulos_namespaces_e_api_publica_match
    jc .lex
    mov qword [rbx + NEBOC_SYNTAX_VISIBILITY_OFFSET], NEBOC_VISIBILITY_INTERNAL
    jmp .visibility_done
.visibility_private:
    lea rsi, [rel p_private]
    mov ecx, p_private_len
    call imports_modulos_namespaces_e_api_publica_match
    jc .lex
    mov qword [rbx + NEBOC_SYNTAX_VISIBILITY_OFFSET], NEBOC_VISIBILITY_PRIVATE
.visibility_done:
    or qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_PARSE_FEATURE_MASK_OFFSET], NEBOC_FEATURE_VISIBILITY
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
    mov [rbx + neboc_imports_modulos_namespaces_e_api_publica_SYNTAX_STATEMENT_LENGTH_OFFSET], rax
    mov [r12 + neboc_imports_modulos_namespaces_e_api_publica_PARSE_CONSUMED_OFFSET], rax
    mov rsi, rbx
    mov ecx, neboc_imports_modulos_namespaces_e_api_publica_SYNTAX_HASHED_BYTES
    call imports_modulos_namespaces_e_api_publica_hash
    mov [rbx + neboc_imports_modulos_namespaces_e_api_publica_SYNTAX_SHAPE_HASH_OFFSET], rax
    mov [r12 + neboc_imports_modulos_namespaces_e_api_publica_PARSE_CANONICAL_HASH_OFFSET], rax
    xor eax, eax
    jmp .done
.lex:
    mov eax, neboc_imports_modulos_namespaces_e_api_publica_DIAG_LEX_driver_cli_linux_x86_64
    jmp .failure
.parse:
    mov eax, neboc_imports_modulos_namespaces_e_api_publica_DIAG_PARSE_driver_cli_linux_x86_64
    jmp .failure
.type:
    mov eax, neboc_imports_modulos_namespaces_e_api_publica_DIAG_TYPE_driver_cli_linux_x86_64
    jmp .failure
.security:
    mov eax, neboc_imports_modulos_namespaces_e_api_publica_DIAG_SECURITY_codegen_modules_x86_64
.failure:
    mov [r12 + neboc_imports_modulos_namespaces_e_api_publica_PARSE_DIAGNOSTIC_OFFSET], rax
    mov rdx, r15
    sub rdx, r13
    mov [r12 + neboc_imports_modulos_namespaces_e_api_publica_PARSE_ERROR_OFFSET_OFFSET], rdx
    mov [r12 + neboc_imports_modulos_namespaces_e_api_publica_PARSE_CONSUMED_OFFSET], rdx
    mov qword [r12 + neboc_imports_modulos_namespaces_e_api_publica_PARSE_CANONICAL_HASH_OFFSET], 0
    mov rdi, rbx
    mov ecx, neboc_imports_modulos_namespaces_e_api_publica_SYNTAX_QWORDS
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

imports_modulos_namespaces_e_api_publica_match:
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
imports_modulos_namespaces_e_api_publica_identity:
    call imports_modulos_namespaces_e_api_publica_uint
    jc .bad
    test rax, rax
    jz .bad
    clc
    ret
.bad:
    stc
    ret

%undef call
imports_modulos_namespaces_e_api_publica_uint:
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

imports_modulos_namespaces_e_api_publica_hash:
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
