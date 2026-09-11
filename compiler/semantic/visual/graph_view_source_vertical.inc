; G098 token-owned Graph/Tree/embedding/projection source vertical.
%define G98_FAMILY_KEY 0x5246323034473938

section .rodata
%macro G98_NAME 2
g98_n_%1: db %2
g98_n_%1_len equ $-g98_n_%1
%endmacro
G98_NAME graph_root,'GraphRendererView'
G98_NAME tree_root,'TreeRendererView'
G98_NAME layout_root,'GraphLayoutView'
G98_NAME highlight_root,'GraphHighlightView'
G98_NAME embedding_root,'EmbeddingView'
G98_NAME projection_root,'ProjectionView'
G98_NAME dependency_root,'DependencyGraphView'
G98_NAME bounded_root,'BoundedGraphView'
G98_NAME closeout_root,'GraphViewCloseout'
G98_NAME dimensions,'dimensions'
G98_NAME embedding,'embedding'
G98_NAME graph,'graph'
G98_NAME highlight,'highlight'
G98_NAME highlight_path,'highlightPath'
G98_NAME project,'project'
G98_NAME projection,'projection'
%undef G98_NAME

section .text
g98_is_program:
%macro G98_ROOT 1
    lea rsi,[rel g98_n_%1]
    mov edx,g98_n_%1_len
    call ls_contains_atom
    test eax,eax
    jnz .yes
%endmacro
    G98_ROOT graph_root
    G98_ROOT tree_root
    G98_ROOT layout_root
    G98_ROOT highlight_root
    G98_ROOT embedding_root
    G98_ROOT projection_root
    G98_ROOT dependency_root
    G98_ROOT bounded_root
    G98_ROOT closeout_root
    xor eax,eax
    ret
.yes:
    mov eax,1
    ret
%undef G98_ROOT

; Each form binds one nominal visual family, an exact receiver-first operation
; sequence and one source-derived seed/generation value.
neboc_g098_source_parse:
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
%macro G98_PARSE_ROOT 2
    mov rdi,[rel ls_cursor]
    lea rsi,[rel g98_n_%1]
    mov edx,g98_n_%1_len
    call ls_token_match
    test eax,eax
    jz %%next
    mov ebx,%2
    jmp .root_ready
%%next:
%endmacro
    G98_PARSE_ROOT graph_root,1
    G98_PARSE_ROOT tree_root,2
    G98_PARSE_ROOT layout_root,3
    G98_PARSE_ROOT highlight_root,4
    G98_PARSE_ROOT embedding_root,5
    G98_PARSE_ROOT projection_root,6
    G98_PARSE_ROOT dependency_root,7
    G98_PARSE_ROOT bounded_root,8
    G98_PARSE_ROOT closeout_root,9
    jmp .method
.root_ready:
    xor r12d,r12d
%macro G98_CALL 1
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
    lea rsi,[rel g98_n_%1]
    mov edx,g98_n_%1_len
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
    cmp ebx,1
    je .graph_renderer
    cmp ebx,2
    je .tree_renderer
    cmp ebx,3
    je .layout
    cmp ebx,4
    je .highlight
    cmp ebx,5
    je .embedding
    cmp ebx,6
    je .projection
    cmp ebx,7
    je .dependency
    cmp ebx,8
    je .bounded
    jmp .closeout
.graph_renderer:
    G98_CALL graph
    jmp .return_value
.tree_renderer:
    G98_CALL graph
    jmp .return_value
.layout:
    G98_CALL graph
    jmp .return_value
.highlight:
    G98_CALL graph
    G98_CALL highlight
    G98_CALL highlight_path
    jmp .return_value
.embedding:
    G98_CALL embedding
    G98_CALL dimensions
    jmp .return_value
.projection:
    G98_CALL embedding
    G98_CALL projection
    G98_CALL project
    G98_CALL dimensions
    jmp .return_value
.dependency:
    G98_CALL graph
    jmp .return_value
.bounded:
    G98_CALL graph
    jmp .return_value
.closeout:
    G98_CALL graph
    G98_CALL highlight
    G98_CALL highlight_path

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
    mov rdx,G98_FAMILY_KEY
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
%undef G98_CALL
%undef G98_PARSE_ROOT
