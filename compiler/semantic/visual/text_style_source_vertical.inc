; G092 token-owned text style, semantic status, font, and fallback vertical.
%define G92_FAMILY_KEY 0x5246323034473932

section .rodata
%macro G92_NAME 2
g92_n_%1: db %2
g92_n_%1_len equ $-g92_n_%1
%endmacro
G92_NAME decoration,'TextDecoration'
G92_NAME optional,'OptionalStyle'
G92_NAME token,'StyleToken'
G92_NAME status,'SemanticStatus'
G92_NAME color,'StyleColor'
G92_NAME typography,'Typography'
G92_NAME fallback,'FallbackProfile'
G92_NAME accessible,'AccessibleText'
G92_NAME plan,'StylePlan'
G92_NAME bold,'bold'
G92_NAME italic,'italic'
G92_NAME underline,'underline'
G92_NAME style,'style'
G92_NAME font,'font'
G92_NAME font_size,'fontSize'
G92_NAME title,'title'
G92_NAME suffix,'suffix'
%undef G92_NAME

section .text
g92_is_program:
%macro G92_ROOT 1
    lea rsi, [rel g92_n_%1]
    mov edx, g92_n_%1_len
    call ls_contains_atom
    test eax, eax
    jnz .yes
%endmacro
    G92_ROOT decoration
    G92_ROOT optional
    G92_ROOT token
    G92_ROOT status
    G92_ROOT color
    G92_ROOT typography
    G92_ROOT fallback
    G92_ROOT accessible
    G92_ROOT plan
    xor eax, eax
    ret
.yes:
    mov eax, 1
    ret
%undef G92_ROOT

; Exact bounded public forms contain one operation, except S01 and S06 which
; consume all three decoration methods and both typography methods.
neboc_g092_source_parse:
    push rbx
    push r12
    push r13
    mov qword [rel ls_cursor], 0
    call ls_start_header
    test eax, eax
    jz .syntax
    mov rdi, [rel ls_cursor]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_IDENTIFIER
    jne .syntax
    xor ebx, ebx
%macro G92_PARSE_ROOT 2
    mov rdi, [rel ls_cursor]
    lea rsi, [rel g92_n_%1]
    mov edx, g92_n_%1_len
    call ls_token_match
    test eax, eax
    jz %%next
    mov ebx, %2
    jmp .root_ready
%%next:
%endmacro
    G92_PARSE_ROOT decoration,1
    G92_PARSE_ROOT optional,2
    G92_PARSE_ROOT token,3
    G92_PARSE_ROOT status,4
    G92_PARSE_ROOT color,5
    G92_PARSE_ROOT typography,6
    G92_PARSE_ROOT fallback,7
    G92_PARSE_ROOT accessible,8
    G92_PARSE_ROOT plan,9
    jmp .syntax
.root_ready:
    inc qword [rel ls_cursor]
    xor r12d, r12d
    cmp ebx, 1
    je .decoration_calls
    cmp ebx, 2
    je .optional_calls
    cmp ebx, 3
    je .token_calls
    cmp ebx, 4
    je .status_calls
    cmp ebx, 5
    je .color_calls
    cmp ebx, 6
    je .typography_calls
    cmp ebx, 7
    je .fallback_calls
    cmp ebx, 8
    je .accessible_calls
    jmp .plan_calls

%macro G92_CALL 1
    mov edi, NEBOC_TOKEN_DOT
    call ls_expect_kind
    test eax, eax
    jz .arity
    mov rdi, [rel ls_cursor]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_IDENTIFIER
    jne .method
    mov rdi, [rel ls_cursor]
    lea rsi, [rel g92_n_%1]
    mov edx, g92_n_%1_len
    call ls_token_match
    test eax, eax
    jz .method
    inc qword [rel ls_cursor]
    mov edi, NEBOC_TOKEN_LPAREN
    call ls_expect_kind
    test eax, eax
    jz .arity
    mov rdi, [rel ls_cursor]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_INTEGER
    jne .type
    mov rdi, [rel ls_cursor]
    call ls_token_ptr
    mov r13, [rax + NEBOC_TOKEN_PAYLOAD_OFFSET]
    test r13, r13
    jz .range
    cmp r13, 255
    ja .range
    test r12, r12
    jz %%first_seed
    cmp r12, r13
    jne .method
    jmp %%seed_ready
%%first_seed:
    mov r12, r13
%%seed_ready:
    inc qword [rel ls_cursor]
    mov edi, NEBOC_TOKEN_RPAREN
    call ls_expect_kind
    test eax, eax
    jz .arity
    mov edi, NEBOC_TOKEN_SEMICOLON
    call ls_expect_kind
    test eax, eax
    jz .arity
%endmacro

%macro G92_ROOT_AGAIN 1
    mov rdi, [rel ls_cursor]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_IDENTIFIER
    jne .method
    mov rdi, [rel ls_cursor]
    lea rsi, [rel g92_n_%1]
    mov edx, g92_n_%1_len
    call ls_token_match
    test eax, eax
    jz .method
    inc qword [rel ls_cursor]
%endmacro

.decoration_calls:
    G92_CALL bold
    G92_ROOT_AGAIN decoration
    G92_CALL italic
    G92_ROOT_AGAIN decoration
    G92_CALL underline
    jmp .finish
.optional_calls:
    G92_CALL style
    jmp .finish
.token_calls:
    G92_CALL style
    jmp .finish
.status_calls:
    G92_CALL style
    jmp .finish
.color_calls:
    G92_CALL style
    jmp .finish
.typography_calls:
    G92_CALL font
    G92_ROOT_AGAIN typography
    G92_CALL font_size
    jmp .finish
.fallback_calls:
    G92_CALL style
    jmp .finish
.accessible_calls:
    G92_CALL title
    jmp .finish
.plan_calls:
    G92_CALL suffix
.finish:
    mov rdi, [rel ls_cursor]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_INTEGER
    jne .syntax
    mov rdi, [rel ls_cursor]
    call ls_token_ptr
    cmp [rax + NEBOC_TOKEN_PAYLOAD_OFFSET], r12
    jne .method
    inc qword [rel ls_cursor]
    mov edi, NEBOC_TOKEN_DOT
    call ls_expect_kind
    test eax, eax
    jz .syntax
    mov rdi, [rel ls_cursor]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_KW_RETURN
    jne .syntax
    inc qword [rel ls_cursor]
    call ls_finish_program
    test eax, eax
    jz .syntax
    mov rax, rbx
    shl rax, 32
    mov edi, r12d
    or rdi, rax
    mov esi, NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
    mov rdx, G92_FAMILY_KEY
    call ls_success
    jmp .done
.method:
    mov edi, 20
    call ls_error
    jmp .done
.type:
    mov edi, 21
    call ls_error
    jmp .done
.range:
    mov edi, 22
    call ls_error
    jmp .done
.arity:
    mov edi, 25
    call ls_error
    jmp .done
.syntax:
    mov edi, 20
    call ls_error
.done:
    pop r13
    pop r12
    pop rbx
    ret
%undef G92_CALL
%undef G92_ROOT_AGAIN
%undef G92_PARSE_ROOT
