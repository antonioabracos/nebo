; G094 token-owned bounded structured-view source vertical.
%define G94_FAMILY_KEY 0x5246323034473934

section .rodata
%macro G94_NAME 2
g94_n_%1: db %2
g94_n_%1_len equ $-g94_n_%1
%endmacro
G94_NAME table_root,'StructuredTable'
G94_NAME config_root,'TableConfiguration'
G94_NAME query_root,'TableQuery'
G94_NAME hierarchy_root,'HierarchyView'
G94_NAME record_root,'RecordSchemaView'
G94_NAME inspect_root,'SafeInspection'
G94_NAME value_root,'ValueMarkerView'
G94_NAME virtual_root,'VirtualizedView'
G94_NAME oracle_root,'StructuredOracle'
G94_NAME closeout_root,'StructuredCloseout'
G94_NAME table,'table'
G94_NAME columns,'columns'
G94_NAME page_size,'pageSize'
G94_NAME freeze_header,'freezeHeader'
G94_NAME preview,'preview'
G94_NAME max_rows,'maxRows'
G94_NAME max_columns,'maxColumns'
%undef G94_NAME

section .text
g94_is_program:
%macro G94_ROOT 1
    lea rsi, [rel g94_n_%1]
    mov edx, g94_n_%1_len
    call ls_contains_atom
    test eax, eax
    jnz .yes
%endmacro
    G94_ROOT table_root
    G94_ROOT config_root
    G94_ROOT query_root
    G94_ROOT hierarchy_root
    G94_ROOT record_root
    G94_ROOT inspect_root
    G94_ROOT value_root
    G94_ROOT virtual_root
    G94_ROOT oracle_root
    G94_ROOT closeout_root
    xor eax, eax
    ret
.yes:
    mov eax, 1
    ret
%undef G94_ROOT

; Exact bounded forms use one nominal root and catalog-owned operations.  S02
; exercises the three table configuration operations; S08 additionally binds
; all three historical schema keys so they are semantically consumed.
neboc_g094_source_parse:
    push rbx
    push r12
    push r13
    push r14
    mov qword [rel ls_cursor], 0
    call ls_start_header
    test eax, eax
    jz .syntax
    mov rdi, [rel ls_cursor]
    call ls_kind_at
    cmp eax, NEBOC_TOKEN_IDENTIFIER
    jne .syntax
    mov r14, [rel ls_cursor]
    xor ebx, ebx
%macro G94_PARSE_ROOT 2
    mov rdi, [rel ls_cursor]
    lea rsi, [rel g94_n_%1]
    mov edx, g94_n_%1_len
    call ls_token_match
    test eax, eax
    jz %%next
    mov ebx, %2
    jmp .root_ready
%%next:
%endmacro
    G94_PARSE_ROOT table_root,1
    G94_PARSE_ROOT config_root,2
    G94_PARSE_ROOT query_root,3
    G94_PARSE_ROOT hierarchy_root,4
    G94_PARSE_ROOT record_root,5
    G94_PARSE_ROOT inspect_root,6
    G94_PARSE_ROOT value_root,7
    G94_PARSE_ROOT virtual_root,8
    G94_PARSE_ROOT oracle_root,9
    G94_PARSE_ROOT closeout_root,10
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
    cmp ebx, 2
    je .first_columns
    cmp ebx, 6
    je .first_preview
    cmp ebx, 7
    je .first_preview
    cmp ebx, 8
    je .first_preview
    lea rsi, [rel g94_n_table]
    mov edx, g94_n_table_len
    jmp .first_match
.first_columns:
    lea rsi, [rel g94_n_columns]
    mov edx, g94_n_columns_len
    jmp .first_match
.first_preview:
    lea rsi, [rel g94_n_preview]
    mov edx, g94_n_preview_len
.first_match:
    call ls_current_atom
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
    mov r12, [rax + NEBOC_TOKEN_PAYLOAD_OFFSET]
    test r12, r12
    jz .range
    cmp r12, 255
    ja .range
    cmp ebx, 1
    je .bounded_32
    cmp ebx, 2
    je .bounded_32
    cmp ebx, 4
    je .bounded_32
    cmp ebx, 6
    je .bounded_32
    cmp ebx, 8
    jne .seed_mode_ready
.bounded_32:
    cmp r12, 32
    ja .range
.seed_mode_ready:
    cmp ebx, 9
    jne .seed_ready
    cmp r12, 8
    jne .range
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

    cmp ebx, 2
    jne .maybe_schema
%macro G94_EXTRA_CALL 1
    mov rdi, [rel ls_cursor]
    mov rsi, r14
    call ls_name_equal
    test eax, eax
    jz .method
    inc qword [rel ls_cursor]
    mov edi, NEBOC_TOKEN_DOT
    call ls_expect_kind
    test eax, eax
    jz .arity
    lea rsi, [rel g94_n_%1]
    mov edx, g94_n_%1_len
    call ls_current_atom
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
    cmp [rax + NEBOC_TOKEN_PAYLOAD_OFFSET], r12
    jne .method
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
    G94_EXTRA_CALL page_size
    G94_EXTRA_CALL freeze_header
%undef G94_EXTRA_CALL

.maybe_schema:
    cmp ebx, 8
    jne .return_value
%macro G94_SCHEMA_KEY 2
    lea rsi, [rel g94_n_%1]
    mov edx, g94_n_%1_len
    call ls_current_atom
    test eax, eax
    jz .method
    inc qword [rel ls_cursor]
    mov edi, NEBOC_TOKEN_RESERVED_COLON
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
    cmp r13, %2
    jne .range
    inc qword [rel ls_cursor]
    mov edi, NEBOC_TOKEN_SEMICOLON
    call ls_expect_kind
    test eax, eax
    jz .arity
%endmacro
    G94_SCHEMA_KEY max_rows,r12
    G94_SCHEMA_KEY max_columns,8
    G94_SCHEMA_KEY table,r12
%undef G94_SCHEMA_KEY

.return_value:
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
    mov rdx, G94_FAMILY_KEY
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
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
%undef G94_PARSE_ROOT
