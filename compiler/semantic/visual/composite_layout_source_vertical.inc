; G093 token-owned composite layout source vertical.
%define G93_FAMILY_KEY 0x5246323034473933

section .rodata
%macro G93_NAME 2
g93_n_%1: db %2
g93_n_%1_len equ $-g93_n_%1
%endmacro
G93_NAME grid_root,'LayoutGrid'
G93_NAME cell_root,'LayoutCell'
G93_NAME profile_root,'LayoutProfile'
G93_NAME dashboard_root,'DashboardLayout'
G93_NAME box_root,'BoxLayout'
G93_NAME responsive_root,'ResponsiveLayout'
G93_NAME composite_root,'CompositeLayout'
G93_NAME lifecycle_root,'LayoutLifecycle'
G93_NAME oracle_root,'LayoutOracle'
G93_NAME tree_root,'LayoutTree'
G93_NAME grid,'grid'
G93_NAME cell,'cell'
G93_NAME layout,'layout'
G93_NAME present,'present'
G93_NAME view,'view'
%undef G93_NAME

section .text
g93_is_program:
%macro G93_ROOT 1
    lea rsi, [rel g93_n_%1]
    mov edx, g93_n_%1_len
    call ls_contains_atom
    test eax, eax
    jnz .yes
%endmacro
    G93_ROOT grid_root
    G93_ROOT cell_root
    G93_ROOT profile_root
    G93_ROOT dashboard_root
    G93_ROOT box_root
    G93_ROOT responsive_root
    G93_ROOT composite_root
    G93_ROOT lifecycle_root
    G93_ROOT oracle_root
    G93_ROOT tree_root
    xor eax, eax
    ret
.yes:
    mov eax, 1
    ret
%undef G93_ROOT

g93_method_mode:
%macro G93_METHOD 2
    cmp ebx, %2
    jne %%next
    lea rsi, [rel g93_n_%1]
    mov edx, g93_n_%1_len
    call ls_current_atom
    test eax, eax
    jz %%next
    mov eax, %2
    ret
%%next:
%endmacro
    G93_METHOD grid,1
    G93_METHOD cell,2
    G93_METHOD view,3
    G93_METHOD grid,4
    G93_METHOD layout,5
    G93_METHOD layout,6
    G93_METHOD view,7
    G93_METHOD present,8
    G93_METHOD layout,9
    G93_METHOD layout,10
    xor eax, eax
    ret
%undef G93_METHOD

; Exact bounded form: start() { Root.catalogMethod(seed); seed.return; }
neboc_g093_source_parse:
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
%macro G93_PARSE_ROOT 2
    mov rdi, [rel ls_cursor]
    lea rsi, [rel g93_n_%1]
    mov edx, g93_n_%1_len
    call ls_token_match
    test eax, eax
    jz %%next
    mov ebx, %2
    jmp .root_ready
%%next:
%endmacro
    G93_PARSE_ROOT grid_root,1
    G93_PARSE_ROOT cell_root,2
    G93_PARSE_ROOT profile_root,3
    G93_PARSE_ROOT dashboard_root,4
    G93_PARSE_ROOT box_root,5
    G93_PARSE_ROOT responsive_root,6
    G93_PARSE_ROOT composite_root,7
    G93_PARSE_ROOT lifecycle_root,8
    G93_PARSE_ROOT oracle_root,9
    G93_PARSE_ROOT tree_root,10
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
    call g93_method_mode
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
    mov rdx, G93_FAMILY_KEY
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
%undef G93_PARSE_ROOT
