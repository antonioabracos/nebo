; BIBLIOTECA-PADRAO-POR-DOMINIOS-PF002 canonical pure std.math source-to-syntax contract
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/std_math_contract.inc"

section .rodata
p_root: db 'std.math.'
p_root_len equ $-p_root
p_abs: db 'abs('
p_abs_len equ $-p_abs
p_clamp: db 'clamp('
p_clamp_len equ $-p_clamp
p_min: db 'min('
p_min_len equ $-p_min
p_max: db 'max('
p_max_len equ $-p_max
p_comma: db ', '
p_comma_len equ $-p_comma
p_end: db ');'
p_end_len equ $-p_end

section .text
NEBOC_ABI_FUNCTION neboc_std_math_parse
    test rdi, rdi
    jz .invalid
    test rdi, neboc_biblioteca_padrao_por_dominios_PARSE_ALIGNMENT - 1
    jnz .invalid
    cmp qword [rdi + neboc_biblioteca_padrao_por_dominios_PARSE_SOURCE_OFFSET], 0
    je .invalid
    cmp qword [rdi + neboc_biblioteca_padrao_por_dominios_PARSE_OUTPUT_OFFSET], 0
    je .invalid
    mov rax, [rdi + neboc_biblioteca_padrao_por_dominios_PARSE_OUTPUT_OFFSET]
    test rax, neboc_biblioteca_padrao_por_dominios_SYNTAX_ALIGNMENT - 1
    jnz .invalid
    mov rax, [rdi + neboc_biblioteca_padrao_por_dominios_PARSE_SOURCE_LENGTH_OFFSET]
    test rax, rax
    jz .invalid
    cmp rax, neboc_biblioteca_padrao_por_dominios_PARSE_MAX_SOURCE_BYTES
    ja .limit

    push rbx
    push r12
    push r13
    push r14
    push r15
    cld
    mov r12, rdi
    mov r13, [r12 + neboc_biblioteca_padrao_por_dominios_PARSE_SOURCE_OFFSET]
    mov r14, r13
    add r14, rax
    jc .invalid_pushed
    mov r15, r13
    mov rbx, [r12 + neboc_biblioteca_padrao_por_dominios_PARSE_OUTPUT_OFFSET]
    mov qword [r12 + neboc_biblioteca_padrao_por_dominios_PARSE_ERROR_OFFSET_OFFSET], 0
    mov qword [r12 + neboc_biblioteca_padrao_por_dominios_PARSE_DIAGNOSTIC_OFFSET], 0
    mov qword [r12 + neboc_biblioteca_padrao_por_dominios_PARSE_CONSUMED_OFFSET], 0
    mov qword [r12 + neboc_biblioteca_padrao_por_dominios_PARSE_CANONICAL_HASH_OFFSET], 0
    mov qword [r12 + neboc_biblioteca_padrao_por_dominios_PARSE_FEATURE_MASK_OFFSET], 0
    mov rdi, rbx
    mov ecx, neboc_biblioteca_padrao_por_dominios_SYNTAX_QWORDS
    xor eax, eax
    rep stosq
    mov qword [rbx + neboc_biblioteca_padrao_por_dominios_SYNTAX_FLAGS_OFFSET], neboc_biblioteca_padrao_por_dominios_SYNTAX_REQUIRED_FLAGS

    lea rsi, [rel p_root]
    mov ecx, p_root_len
    call biblioteca_padrao_por_dominios_match
    jc .lex
    cmp r15, r14
    jae .lex
    cmp byte [r15], 'a'
    je .operation_abs
    cmp byte [r15], 'c'
    je .operation_clamp
    cmp byte [r15], 'm'
    jne .lex
    cmp r15, r14
    jae .lex
    cmp byte [r15 + 1], 'i'
    je .operation_min
    jmp .operation_max
.operation_abs:
    lea rsi, [rel p_abs]
    mov ecx, p_abs_len
    call biblioteca_padrao_por_dominios_match
    jc .lex
    mov qword [rbx + neboc_biblioteca_padrao_por_dominios_SYNTAX_OPERATION_OFFSET], NEBOC_OP_ABS
    mov qword [rbx + neboc_biblioteca_padrao_por_dominios_SYNTAX_ARITY_OFFSET], 1
    jmp .operation_done
.operation_clamp:
    lea rsi, [rel p_clamp]
    mov ecx, p_clamp_len
    call biblioteca_padrao_por_dominios_match
    jc .lex
    mov qword [rbx + neboc_biblioteca_padrao_por_dominios_SYNTAX_OPERATION_OFFSET], NEBOC_OP_CLAMP
    mov qword [rbx + neboc_biblioteca_padrao_por_dominios_SYNTAX_ARITY_OFFSET], 3
    jmp .operation_done
.operation_min:
    lea rsi, [rel p_min]
    mov ecx, p_min_len
    call biblioteca_padrao_por_dominios_match
    jc .lex
    mov qword [rbx + neboc_biblioteca_padrao_por_dominios_SYNTAX_OPERATION_OFFSET], NEBOC_OP_MIN
    mov qword [rbx + neboc_biblioteca_padrao_por_dominios_SYNTAX_ARITY_OFFSET], 2
    jmp .operation_done
.operation_max:
    lea rsi, [rel p_max]
    mov ecx, p_max_len
    call biblioteca_padrao_por_dominios_match
    jc .lex
    mov qword [rbx + neboc_biblioteca_padrao_por_dominios_SYNTAX_OPERATION_OFFSET], NEBOC_OP_MAX
    mov qword [rbx + neboc_biblioteca_padrao_por_dominios_SYNTAX_ARITY_OFFSET], 2
.operation_done:
    or qword [r12 + neboc_biblioteca_padrao_por_dominios_PARSE_FEATURE_MASK_OFFSET], neboc_biblioteca_padrao_por_dominios_FEATURE_NAMESPACE
    mov rax, r15
    sub rax, r13
    mov [rbx + neboc_biblioteca_padrao_por_dominios_SYNTAX_ARGUMENT_SPAN_OFFSET], rax
    call int
    jc .type
    mov [rbx + neboc_biblioteca_padrao_por_dominios_SYNTAX_VALUE_OFFSET], rax
    cmp qword [rbx + neboc_biblioteca_padrao_por_dominios_SYNTAX_ARITY_OFFSET], 1
    je .arguments_done
    lea rsi, [rel p_comma]
    mov ecx, p_comma_len
    call biblioteca_padrao_por_dominios_match
    jc .parse
    call int
    jc .type
    mov [rbx + NEBOC_SYNTAX_LOWER_OFFSET], rax
    cmp qword [rbx + neboc_biblioteca_padrao_por_dominios_SYNTAX_ARITY_OFFSET], 2
    je .arguments_done
    lea rsi, [rel p_comma]
    mov ecx, p_comma_len
    call biblioteca_padrao_por_dominios_match
    jc .parse
    call int
    jc .type
    mov [rbx + NEBOC_SYNTAX_UPPER_OFFSET], rax
    mov rdx, [rbx + NEBOC_SYNTAX_LOWER_OFFSET]
    cmp rdx, rax
    jg .type
.arguments_done:
    or qword [r12 + neboc_biblioteca_padrao_por_dominios_PARSE_FEATURE_MASK_OFFSET], NEBOC_FEATURE_ARGUMENTS
    lea rsi, [rel p_end]
    mov ecx, p_end_len
    call biblioteca_padrao_por_dominios_match
    jc .parse
    or qword [r12 + neboc_biblioteca_padrao_por_dominios_PARSE_FEATURE_MASK_OFFSET], neboc_biblioteca_padrao_por_dominios_FEATURE_TERMINATOR
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
    mov [rbx + neboc_biblioteca_padrao_por_dominios_SYNTAX_STATEMENT_LENGTH_OFFSET], rax
    mov [r12 + neboc_biblioteca_padrao_por_dominios_PARSE_CONSUMED_OFFSET], rax
    mov [rbx + neboc_biblioteca_padrao_por_dominios_SYNTAX_CALL_SPAN_OFFSET], rax
    mov rsi, rbx
    mov ecx, neboc_biblioteca_padrao_por_dominios_SYNTAX_HASHED_BYTES
    call biblioteca_padrao_por_dominios_hash
    mov [rbx + neboc_biblioteca_padrao_por_dominios_SYNTAX_SHAPE_HASH_OFFSET], rax
    mov [r12 + neboc_biblioteca_padrao_por_dominios_PARSE_CANONICAL_HASH_OFFSET], rax
    xor eax, eax
    jmp .done
.lex:
    mov eax, neboc_biblioteca_padrao_por_dominios_DIAG_LEX_driver_cli_linux_x86_64
    jmp .failure
.parse:
    mov eax, neboc_biblioteca_padrao_por_dominios_DIAG_PARSE_driver_cli_linux_x86_64
    jmp .failure
.type:
    mov eax, neboc_biblioteca_padrao_por_dominios_DIAG_TYPE_driver_cli_linux_x86_64
.failure:
    mov [r12 + neboc_biblioteca_padrao_por_dominios_PARSE_DIAGNOSTIC_OFFSET], rax
    mov rdx, r15
    sub rdx, r13
    mov [r12 + neboc_biblioteca_padrao_por_dominios_PARSE_ERROR_OFFSET_OFFSET], rdx
    mov [r12 + neboc_biblioteca_padrao_por_dominios_PARSE_CONSUMED_OFFSET], rdx
    mov rdi, rbx
    mov ecx, neboc_biblioteca_padrao_por_dominios_SYNTAX_QWORDS
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
.invalid_pushed:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.limit:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

biblioteca_padrao_por_dominios_match:
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

; Parse one canonical signed Int64; CF denotes missing/overflow.
int:
    xor esi, esi
    cmp r15, r14
    jae .bad
    cmp byte [r15], '-'
    jne .digits
    mov esi, 1
    inc r15
.digits:
    xor eax, eax
    xor ecx, ecx
.loop:
    cmp r15, r14
    jae .done
    movzx edx, byte [r15]
    sub edx, '0'
    cmp edx, 9
    ja .done
    mov r8, 922337203685477580
    cmp rax, r8
    ja .bad
    jne .accumulate
    mov r9d, 7
    test esi, esi
    jz .check_last
    mov r9d, 8
.check_last:
    cmp edx, r9d
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
    test esi, esi
    jz .ok
    neg rax
.ok:
    clc
    ret
.bad:
    stc
    ret

biblioteca_padrao_por_dominios_hash:
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
