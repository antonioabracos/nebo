; G107 token-owned `fallback:` routing schema. The string profile selects a
; bounded sink policy; the source seed remains an independently observed value.
%define G107_FAMILY_KEY 0x4731303753524331
%define NEBO_G107_SOURCE_MIN_SEED 2700

section .rodata
%macro G107_NAME 2
g107_n_%1: db %2
g107_n_%1_len equ $-g107_n_%1
%endmacro
G107_NAME sink_route,'SinkRoute'
G107_NAME render_plan,'RenderPlan'
G107_NAME route,'route'
G107_NAME fallback,'fallback'
G107_NAME stdout,'"stdout"'
G107_NAME stderr,'"stderr"'
G107_NAME ansi,'"ansi"'
G107_NAME file_overwrite,'"file-overwrite"'
G107_NAME file_append,'"file-append"'
G107_NAME file_atomic,'"file-atomic"'
G107_NAME router,'"router"'
G107_NAME mirror_console,'"mirror-console"'
G107_NAME mirror_panel,'"mirror-panel"'
G107_NAME text,'"text"'
G107_NAME table,'"table"'
G107_NAME summary,'"summary"'
G107_NAME detect_target,'"detect-target"'
G107_NAME atomic,'"atomic"'
G107_NAME multi_target,'"multi-target"'
G107_NAME cleanup,'"cleanup"'
G107_NAME closeout,'"closeout"'
%undef G107_NAME

section .text
g107_is_program:
    lea rsi,[rel g107_n_sink_route]
    mov edx,g107_n_sink_route_len
    call ls_contains_atom
    test eax,eax
    jz .no
    lea rsi,[rel g107_n_render_plan]
    mov edx,g107_n_render_plan_len
    call ls_contains_atom
    test eax,eax
    jz .no
    lea rsi,[rel g107_n_fallback]
    mov edx,g107_n_fallback_len
    call ls_contains_atom
    test eax,eax
    jz .no
    mov eax,1
    ret
.no:
    xor eax,eax
    ret

; Current token is Text. EAX mode, EDX variant; zero mode is unknown.
g107_profile:
%macro G107_PROFILE 3
    mov rdi,[rel ls_cursor]
    lea rsi,[rel g107_n_%1]
    mov edx,g107_n_%1_len
    call ls_token_match
    test eax,eax
    jz %%next
    mov eax,%2
    mov edx,%3
    ret
%%next:
%endmacro
    G107_PROFILE stdout,1,0
    G107_PROFILE stderr,1,1
    G107_PROFILE ansi,1,2
    G107_PROFILE file_overwrite,2,0
    G107_PROFILE file_append,2,1
    G107_PROFILE file_atomic,2,2
    G107_PROFILE router,3,0
    G107_PROFILE mirror_console,4,0
    G107_PROFILE mirror_panel,4,1
    G107_PROFILE text,5,0
    G107_PROFILE table,5,1
    G107_PROFILE summary,5,2
    G107_PROFILE detect_target,5,3
    G107_PROFILE atomic,6,0
    G107_PROFILE multi_target,7,0
    G107_PROFILE cleanup,8,0
    G107_PROFILE closeout,9,0
    xor eax,eax
    xor edx,edx
    ret
%undef G107_PROFILE

neboc_g107_source_parse:
    push rbx
    push r12
    push r13
    mov qword [rel ls_cursor],0
    call ls_start_header
    test eax,eax
    jz .syntax
    lea rsi,[rel g107_n_sink_route]
    mov edx,g107_n_sink_route_len
    call ls_expect_atom
    test eax,eax
    jz .syntax
    mov edi,NEBOC_TOKEN_SEMICOLON
    call ls_expect_kind
    test eax,eax
    jz .syntax
    lea rsi,[rel g107_n_render_plan]
    mov edx,g107_n_render_plan_len
    call ls_expect_atom
    test eax,eax
    jz .syntax
    mov edi,NEBOC_TOKEN_SEMICOLON
    call ls_expect_kind
    test eax,eax
    jz .syntax
    mov rdi,[rel ls_cursor]
    call ls_kind_at
    cmp eax,NEBOC_TOKEN_INTEGER
    jne .type
    mov rdi,[rel ls_cursor]
    call ls_token_ptr
    mov r12,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
    cmp r12,NEBO_G107_SOURCE_MIN_SEED
    jb .range
    mov rax,0xffffffff
    cmp r12,rax
    ja .range
    inc qword [rel ls_cursor]
    mov edi,NEBOC_TOKEN_SEMICOLON
    call ls_expect_kind
    test eax,eax
    jz .syntax
    lea rsi,[rel g107_n_route]
    mov edx,g107_n_route_len
    call ls_expect_atom
    test eax,eax
    jz .unsupported
    mov edi,NEBOC_TOKEN_LBRACE
    call ls_expect_kind
    test eax,eax
    jz .syntax
    lea rsi,[rel g107_n_fallback]
    mov edx,g107_n_fallback_len
    call ls_expect_atom
    test eax,eax
    jz .unsupported
    mov edi,NEBOC_TOKEN_RESERVED_COLON
    call ls_expect_kind
    test eax,eax
    jz .syntax
    mov rdi,[rel ls_cursor]
    call ls_kind_at
    cmp eax,NEBOC_TOKEN_TEXT
    jne .type
    call g107_profile
    test eax,eax
    jz .unsupported
    mov ebx,eax
    mov r13d,edx
    inc qword [rel ls_cursor]
    mov edi,NEBOC_TOKEN_RBRACE
    call ls_expect_kind
    test eax,eax
    jz .syntax
    call ls_finish_program
    test eax,eax
    jz .syntax
    mov rax,rbx
    shl rax,40
    mov rcx,r13
    shl rcx,32
    or rax,rcx
    mov edi,r12d
    or rdi,rax
    mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
    mov rdx,G107_FAMILY_KEY
    call ls_success
    jmp .done
.type:
    mov edi,21
    call ls_error
    jmp .done
.range:
    mov edi,22
    call ls_error
    jmp .done
.unsupported:
    mov edi,24
    call ls_error
    jmp .done
.syntax:
    mov edi,20
    call ls_error
.done:
    pop r13
    pop r12
    pop rbx
    ret
