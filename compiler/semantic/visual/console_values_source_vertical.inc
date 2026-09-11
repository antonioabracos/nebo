; G090 token-owned ConsoleRenderable/ConsoleValue source vertical.
%define G90_FAMILY_KEY 0x5246323034473930

section .rodata
%macro G90_NAME 2
g90_n_%1: db %2
g90_n_%1_len equ $-g90_n_%1
%endmacro
G90_NAME renderable,'ConsoleRenderable'
G90_NAME value_type,'ConsoleValue'
G90_NAME kind,'ConsoleRenderableKind'
G90_NAME result,'ConsoleRenderResult'
G90_NAME scalar,'scalar'
G90_NAME buffer,'buffer'
G90_NAME collection,'collection'
G90_NAME tabular,'tabular'
G90_NAME numeric_shape,'numericShape'
G90_NAME dynamic,'dynamic'
G90_NAME media_metadata,'mediaMetadata'
G90_NAME value,'value'
%undef G90_NAME

section .text
g90_is_program:
%macro G90_ROOT 1
    lea rsi, [rel g90_n_%1]
    mov edx, g90_n_%1_len
    call ls_contains_atom
    test eax, eax
    jnz .yes
%endmacro
    G90_ROOT renderable
    G90_ROOT value_type
    G90_ROOT kind
    G90_ROOT result
    xor eax, eax
    ret
.yes:
    mov eax, 1
    ret
%undef G90_ROOT

; EBX=root (1 renderable, 2 value, 3 kind, 4 result) -> EAX=mode.
g90_method_mode:
%macro G90_METHOD 3
    cmp ebx, %3
    jne %%next
    lea rsi, [rel g90_n_%1]
    mov edx, g90_n_%1_len
    call ls_current_atom
    test eax, eax
    jz %%next
    mov eax, %2
    ret
%%next:
%endmacro
    G90_METHOD scalar,1,1
    G90_METHOD buffer,2,2
    G90_METHOD collection,3,1
    G90_METHOD tabular,4,2
    G90_METHOD numeric_shape,5,3
    G90_METHOD dynamic,6,1
    G90_METHOD media_metadata,7,1
    G90_METHOD value,8,4
    xor eax, eax
    ret
%undef G90_METHOD

; Exact bounded public conformance form:
;   start() { Root.adapter(seed); seed.return; }
neboc_g090_source_parse:
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
%macro G90_PARSE_ROOT 2
    mov rdi, [rel ls_cursor]
    lea rsi, [rel g90_n_%1]
    mov edx, g90_n_%1_len
    call ls_token_match
    test eax, eax
    jz %%next
    mov ebx, %2
    jmp .root_ready
%%next:
%endmacro
    G90_PARSE_ROOT renderable,1
    G90_PARSE_ROOT value_type,2
    G90_PARSE_ROOT kind,3
    G90_PARSE_ROOT result,4
    jmp .syntax
.root_ready:
    inc qword [rel ls_cursor]
    mov edi, NEBOC_TOKEN_DOT
    call ls_expect_kind
    test eax, eax
    jz .arity
    mov rdi, [rel ls_cursor]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_IDENTIFIER
    jne .method
    call g90_method_mode
    test eax, eax
    jz .method
    mov r13, rax
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
    mov r12, [rax + NEBOC_TOKEN_PAYLOAD_OFFSET]
    test r12, r12
    jz .range
    cmp r12, 255
    ja .range
    inc qword [rel ls_cursor]
    mov edi, NEBOC_TOKEN_RPAREN
    call ls_expect_kind
    test eax, eax
    jz .arity
    mov edi, NEBOC_TOKEN_SEMICOLON
    call ls_expect_kind
    test eax, eax
    jz .arity
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
    mov rax, r13
    shl rax, 32
    mov edi, r12d
    or rdi, rax
    mov esi, NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
    mov rdx, G90_FAMILY_KEY
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
%undef G90_PARSE_ROOT
