; G099 token-owned dashboard/panel/cell composition source vertical.
%define G99_FAMILY_KEY 0x5246323034473939

section .rodata
%macro G99_NAME 2
g99_n_%1: db %2
g99_n_%1_len equ $-g99_n_%1
%endmacro
G99_NAME spec_root,'DashboardSpecView'
G99_NAME panel_root,'PanelCompositionView'
G99_NAME multi_root,'MultiViewDashboard'
G99_NAME log_root,'LogPanelDashboard'
G99_NAME present_root,'PresentedDashboard'
G99_NAME export_root,'ExportDashboard'
G99_NAME interaction_root,'InteractiveDashboard'
G99_NAME snapshot_root,'SnapshotDashboard'
G99_NAME closeout_root,'DashboardCloseout'
G99_NAME dashboard,'dashboard'
G99_NAME log_panel,'logPanel'
%undef G99_NAME

section .text
g99_is_program:
%macro G99_ROOT 1
    lea rsi,[rel g99_n_%1]
    mov edx,g99_n_%1_len
    call ls_contains_atom
    test eax,eax
    jnz .yes
%endmacro
    G99_ROOT spec_root
    G99_ROOT panel_root
    G99_ROOT multi_root
    G99_ROOT log_root
    G99_ROOT present_root
    G99_ROOT export_root
    G99_ROOT interaction_root
    G99_ROOT snapshot_root
    G99_ROOT closeout_root
    xor eax,eax
    ret
.yes:
    mov eax,1
    ret
%undef G99_ROOT

; Each form binds one nominal dashboard family, an exact receiver-first
; operation sequence and one source-derived generation value.
neboc_g099_source_parse:
    push rbx
    push r12
    push r13
    push r14
    mov qword [rel ls_cursor],0
    call ls_start_header
    test eax,eax
    jz .syntax
    mov rdi,[rel ls_cursor]
    call ls_kind_at
    cmp eax,NEBOC_TOKEN_IDENTIFIER
    jne .syntax
    mov r14,[rel ls_cursor]
    xor ebx,ebx
%macro G99_PARSE_ROOT 2
    mov rdi,[rel ls_cursor]
    lea rsi,[rel g99_n_%1]
    mov edx,g99_n_%1_len
    call ls_token_match
    test eax,eax
    jz %%next
    mov ebx,%2
    jmp .root_ready
%%next:
%endmacro
    G99_PARSE_ROOT spec_root,1
    G99_PARSE_ROOT panel_root,2
    G99_PARSE_ROOT multi_root,3
    G99_PARSE_ROOT log_root,4
    G99_PARSE_ROOT present_root,5
    G99_PARSE_ROOT export_root,6
    G99_PARSE_ROOT interaction_root,7
    G99_PARSE_ROOT snapshot_root,8
    G99_PARSE_ROOT closeout_root,9
    jmp .method
.root_ready:
    xor r12d,r12d
%macro G99_CALL 1
    mov rdi,[rel ls_cursor]
    mov rsi,r14
    call ls_name_equal
    test eax,eax
    jz .method
    inc qword [rel ls_cursor]
    mov edi,NEBOC_TOKEN_DOT
    call ls_expect_kind
    test eax,eax
    jz .arity
    lea rsi,[rel g99_n_%1]
    mov edx,g99_n_%1_len
    call ls_current_atom
    test eax,eax
    jz .method
    inc qword [rel ls_cursor]
    mov edi,NEBOC_TOKEN_LPAREN
    call ls_expect_kind
    test eax,eax
    jz .arity
    mov rdi,[rel ls_cursor]
    call ls_kind_at
    cmp eax,NEBOC_TOKEN_INTEGER
    jne .type
    mov rdi,[rel ls_cursor]
    call ls_token_ptr
    mov rax,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
    test r12,r12
    jnz %%compare
    mov r12,rax
    jmp %%range
%%compare:
    cmp rax,r12
    jne .method
%%range:
    test rax,rax
    jz .range_error
    cmp rax,255
    ja .range_error
    inc qword [rel ls_cursor]
    mov edi,NEBOC_TOKEN_RPAREN
    call ls_expect_kind
    test eax,eax
    jz .arity
    mov edi,NEBOC_TOKEN_SEMICOLON
    call ls_expect_kind
    test eax,eax
    jz .arity
%endmacro
    G99_CALL dashboard
    cmp ebx,4
    je .with_log_panel
    cmp ebx,9
    je .with_log_panel
    jmp .return_value
.with_log_panel:
    G99_CALL log_panel

.return_value:
    mov rdi,[rel ls_cursor]
    call ls_kind_at
    cmp eax,NEBOC_TOKEN_INTEGER
    jne .syntax
    mov rdi,[rel ls_cursor]
    call ls_token_ptr
    cmp [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],r12
    jne .method
    inc qword [rel ls_cursor]
    mov edi,NEBOC_TOKEN_DOT
    call ls_expect_kind
    test eax,eax
    jz .syntax
    mov rdi,[rel ls_cursor]
    call ls_kind_at
    cmp eax,NEBOC_TOKEN_KW_RETURN
    jne .syntax
    inc qword [rel ls_cursor]
    call ls_finish_program
    test eax,eax
    jz .syntax
    mov rax,rbx
    shl rax,32
    mov edi,r12d
    or rdi,rax
    mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
    mov rdx,G99_FAMILY_KEY
    call ls_success
    jmp .done
.method:
    mov edi,20
    call ls_error
    jmp .done
.type:
    mov edi,21
    call ls_error
    jmp .done
.range_error:
    mov edi,22
    call ls_error
    jmp .done
.arity:
    mov edi,25
    call ls_error
    jmp .done
.syntax:
    mov edi,20
    call ls_error
.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
%undef G99_CALL
%undef G99_PARSE_ROOT
