; G091 token-owned ConsoleDocument geometry source vertical.
%define G91_FAMILY_KEY 0x5246323034473931

section .rodata
%macro G91_NAME 2
g91_n_%1: db %2
g91_n_%1_len equ $-g91_n_%1
%endmacro
G91_NAME position,'Position'
G91_NAME sizing,'Sizing'
G91_NAME region_type,'Region'
G91_NAME layer,'Layer'
G91_NAME update,'Update'
G91_NAME label,'PositionalLabel'
G91_NAME selection_type,'Selection'
G91_NAME window_type,'Window'
G91_NAME viewport_type,'Viewport'
G91_NAME document,'ConsoleDocument'
G91_NAME at,'at'
G91_NAME size,'size'
G91_NAME region,'region'
G91_NAME panel,'panel'
G91_NAME clear,'clear'
G91_NAME viewport,'viewport'
G91_NAME refresh,'refresh'
%undef G91_NAME

section .text
g91_is_program:
%macro G91_ROOT 1
    lea rsi, [rel g91_n_%1]
    mov edx, g91_n_%1_len
    call ls_contains_atom
    test eax, eax
    jnz .yes
%endmacro
    G91_ROOT position
    G91_ROOT sizing
    G91_ROOT region_type
    G91_ROOT layer
    G91_ROOT update
    G91_ROOT label
    G91_ROOT selection_type
    G91_ROOT viewport_type
    G91_ROOT document
    ; Window is also a canonical G018 root.  G091 owns only its Window.panel
    ; geometry profile; broad Window selection would steal the older lifecycle.
    lea rsi, [rel g91_n_window_type]
    mov edx, g91_n_window_type_len
    call ls_contains_atom
    test eax, eax
    jz .no
    lea rsi, [rel g91_n_panel]
    mov edx, g91_n_panel_len
    call ls_contains_atom
    test eax, eax
    jnz .yes
.no:
    xor eax, eax
    ret
.yes:
    mov eax, 1
    ret
%undef G91_ROOT

; EBX=root/mode. Every nominal object has one catalog-owned operation.
g91_method_mode:
%macro G91_METHOD 2
    cmp ebx, %2
    jne %%next
    lea rsi, [rel g91_n_%1]
    mov edx, g91_n_%1_len
    call ls_current_atom
    test eax, eax
    jz %%next
    mov eax, %2
    ret
%%next:
%endmacro
    G91_METHOD at,1
    G91_METHOD size,2
    G91_METHOD region,3
    G91_METHOD panel,4
    G91_METHOD clear,5
    G91_METHOD at,6
    G91_METHOD at,7
    G91_METHOD panel,8
    G91_METHOD viewport,9
    G91_METHOD refresh,10
    xor eax, eax
    ret
%undef G91_METHOD

; Exact bounded public form: start() { Root.operation(seed); seed.return; }
neboc_g091_source_parse:
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
%macro G91_PARSE_ROOT 2
    mov rdi, [rel ls_cursor]
    lea rsi, [rel g91_n_%1]
    mov edx, g91_n_%1_len
    call ls_token_match
    test eax, eax
    jz %%next
    mov ebx, %2
    jmp .root_ready
%%next:
%endmacro
    G91_PARSE_ROOT position,1
    G91_PARSE_ROOT sizing,2
    G91_PARSE_ROOT region_type,3
    G91_PARSE_ROOT layer,4
    G91_PARSE_ROOT update,5
    G91_PARSE_ROOT label,6
    G91_PARSE_ROOT selection_type,7
    G91_PARSE_ROOT window_type,8
    G91_PARSE_ROOT viewport_type,9
    G91_PARSE_ROOT document,10
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
    call g91_method_mode
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
    cmp r13, 8
    jne .seed_ready
    cmp r12, 64
    ja .range
.seed_ready:
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
    mov rdx, G91_FAMILY_KEY
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
%undef G91_PARSE_ROOT
