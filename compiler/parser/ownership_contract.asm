; MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-PF002 bounded ownership/lifetime source-to-syntax contract
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/ownership_contract.inc"

section .rodata
p_resource: db 'resource '
p_resource_len equ $-p_resource
p_owner: db ' owner '
p_owner_len equ $-p_owner
p_lifetime: db ' lifetime '
p_lifetime_len equ $-p_lifetime
p_action: db ' action '
p_action_len equ $-p_action
p_access: db 'access'
p_access_len equ $-p_access
p_move: db 'move'
p_move_len equ $-p_move
p_drop: db 'drop'
p_drop_len equ $-p_drop
p_borrow: db 'borrow '
p_borrow_len equ $-p_borrow
p_shared: db 'shared '
p_shared_len equ $-p_shared
p_mutable: db 'mutable '
p_mutable_len equ $-p_mutable
p_region: db ' region '
p_region_len equ $-p_region

section .text
NEBOC_ABI_FUNCTION neboc_ownership_parse
    test rdi, rdi
    jz .invalid
    test rdi, neboc_memoria_ownership_lifetimes_e_recursos_PARSE_ALIGNMENT - 1
    jnz .invalid
    mov r8, rdi
    add r8, neboc_memoria_ownership_lifetimes_e_recursos_PARSE_REQUEST_SIZE
    jc .invalid
    cmp qword [rdi + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_SOURCE_OFFSET], 0
    je .invalid
    cmp qword [rdi + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_OUTPUT_OFFSET], 0
    je .invalid
    mov rax, [rdi + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_OUTPUT_OFFSET]
    test rax, neboc_memoria_ownership_lifetimes_e_recursos_SYNTAX_ALIGNMENT - 1
    jnz .invalid
    mov rax, [rdi + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_SOURCE_LENGTH_OFFSET]
    test rax, rax
    jz .invalid
    cmp rax, neboc_memoria_ownership_lifetimes_e_recursos_PARSE_MAX_SOURCE_BYTES
    ja .limit

    ; Validate wrap and pairwise disjoint transport before any publication.
    mov r9, [rdi + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_SOURCE_OFFSET]
    mov r10, r9
    add r10, rax
    jc .invalid
    mov r11, [rdi + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_OUTPUT_OFFSET]
    mov rdx, r11
    add rdx, neboc_memoria_ownership_lifetimes_e_recursos_SYNTAX_SIZE
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
    mov r13, [r12 + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_SOURCE_OFFSET]
    lea r14, [r13 + rax]
    mov r15, r13
    mov rbx, [r12 + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_OUTPUT_OFFSET]
    mov qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_ERROR_OFFSET_OFFSET], 0
    mov qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_DIAGNOSTIC_OFFSET], 0
    mov qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_CONSUMED_OFFSET], 0
    mov qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_CANONICAL_HASH_OFFSET], 0
    mov qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_FEATURE_MASK_OFFSET], 0
    mov rdi, rbx
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_SYNTAX_QWORDS
    xor eax, eax
    rep stosq
    mov qword [rbx + neboc_memoria_ownership_lifetimes_e_recursos_SYNTAX_FLAGS_OFFSET], neboc_memoria_ownership_lifetimes_e_recursos_SYNTAX_FLAG_CANONICAL

    lea rsi, [rel p_resource]
    mov ecx, p_resource_len
    call match
    jc .lex
    call identity
    jc .type
    mov [rbx + NEBOC_SYNTAX_RESOURCE_ID_OFFSET], rax
    or qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_FEATURE_MASK_OFFSET], NEBOC_FEATURE_RESOURCE

    lea rsi, [rel p_owner]
    mov ecx, p_owner_len
    call match
    jc .lex
    call identity
    jc .type
    mov [rbx + NEBOC_SYNTAX_OWNER_TOKEN_OFFSET], rax
    or qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_FEATURE_MASK_OFFSET], NEBOC_FEATURE_OWNER

    lea rsi, [rel p_lifetime]
    mov ecx, p_lifetime_len
    call match
    jc .lex
    call identity
    jc .type
    mov [rbx + NEBOC_SYNTAX_OWNER_REGION_OFFSET], rax
    or qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_FEATURE_MASK_OFFSET], NEBOC_FEATURE_LIFETIME

    lea rsi, [rel p_action]
    mov ecx, p_action_len
    call match
    jc .lex
    cmp r15, r14
    jae .parse
    mov al, [r15]
    cmp al, 'a'
    je .action_access
    cmp al, 'm'
    je .action_move
    cmp al, 'd'
    je .action_drop
    cmp al, 'b'
    je .action_borrow
    jmp .lex
.action_access:
    lea rsi, [rel p_access]
    mov ecx, p_access_len
    call match
    jc .lex
    mov qword [rbx + NEBOC_SYNTAX_ACTION_OFFSET], NEBOC_OP_ACCESS_OWNER
    jmp .action_done
.action_move:
    lea rsi, [rel p_move]
    mov ecx, p_move_len
    call match
    jc .lex
    mov qword [rbx + NEBOC_SYNTAX_ACTION_OFFSET], NEBOC_OP_MOVE_OUT
    jmp .action_done
.action_drop:
    lea rsi, [rel p_drop]
    mov ecx, p_drop_len
    call match
    jc .lex
    mov qword [rbx + NEBOC_SYNTAX_ACTION_OFFSET], NEBOC_OP_DROP
    jmp .action_done
.action_borrow:
    lea rsi, [rel p_borrow]
    mov ecx, p_borrow_len
    call match
    jc .lex
    cmp r15, r14
    jae .parse
    cmp byte [r15], 's'
    je .borrow_shared
    cmp byte [r15], 'm'
    je .borrow_mutable
    jmp .lex
.borrow_shared:
    lea rsi, [rel p_shared]
    mov ecx, p_shared_len
    call match
    jc .lex
    mov qword [rbx + NEBOC_SYNTAX_ACTION_OFFSET], NEBOC_OP_BORROW_SHARED
    jmp .borrow_identity
.borrow_mutable:
    lea rsi, [rel p_mutable]
    mov ecx, p_mutable_len
    call match
    jc .lex
    mov qword [rbx + NEBOC_SYNTAX_ACTION_OFFSET], NEBOC_OP_BORROW_MUTABLE
.borrow_identity:
    call identity
    jc .type
    cmp rax, [rbx + NEBOC_SYNTAX_OWNER_TOKEN_OFFSET]
    je .type
    mov [rbx + NEBOC_SYNTAX_BORROW_TOKEN_OFFSET], rax
    lea rsi, [rel p_region]
    mov ecx, p_region_len
    call match
    jc .parse
    call identity
    jc .type
    mov [rbx + NEBOC_SYNTAX_BORROW_REGION_OFFSET], rax
    or qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_FEATURE_MASK_OFFSET], NEBOC_FEATURE_BORROW
.action_done:
    or qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_FEATURE_MASK_OFFSET], NEBOC_FEATURE_ACTION
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
    mov [rbx + neboc_memoria_ownership_lifetimes_e_recursos_SYNTAX_STATEMENT_LENGTH_OFFSET], rax
    mov [r12 + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_CONSUMED_OFFSET], rax
    mov rsi, rbx
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_SYNTAX_HASHED_BYTES
    call hash
    mov [rbx + neboc_memoria_ownership_lifetimes_e_recursos_SYNTAX_SHAPE_HASH_OFFSET], rax
    mov [r12 + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_CANONICAL_HASH_OFFSET], rax
    xor eax, eax
    jmp .done
.lex:
    mov eax, neboc_memoria_ownership_lifetimes_e_recursos_DIAG_LEX_driver_cli_linux_x86_64
    jmp .failure
.parse:
    mov eax, neboc_memoria_ownership_lifetimes_e_recursos_DIAG_PARSE_driver_cli_linux_x86_64
    jmp .failure
.type:
    mov eax, neboc_memoria_ownership_lifetimes_e_recursos_DIAG_TYPE_codegen_memory_x86_64
.failure:
    mov [r12 + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_DIAGNOSTIC_OFFSET], rax
    mov rdx, r15
    sub rdx, r13
    mov [r12 + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_ERROR_OFFSET_OFFSET], rdx
    mov [r12 + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_CONSUMED_OFFSET], rdx
    mov qword [r12 + neboc_memoria_ownership_lifetimes_e_recursos_PARSE_CANONICAL_HASH_OFFSET], 0
    mov rdi, rbx
    mov ecx, neboc_memoria_ownership_lifetimes_e_recursos_SYNTAX_QWORDS
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

match:
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
identity:
    call uint
    jc .bad
    test rax, rax
    jz .bad
    clc
    ret
.bad:
    stc
    ret

%undef call
uint:
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

hash:
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
