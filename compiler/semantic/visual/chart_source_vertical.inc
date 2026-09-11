; G095 token-owned 2D chart adapter source vertical.
%define G95_FAMILY_KEY 0x5246323034473935

section .rodata
%macro G95_NAME 2
g95_n_%1: db %2
g95_n_%1_len equ $-g95_n_%1
%endmacro
G95_NAME registry_root,'ChartKindRegistry'
G95_NAME line_root,'LineTimeSeries'
G95_NAME bar_root,'BarChart2D'
G95_NAME histogram_root,'HistogramChart2D'
G95_NAME scatter_root,'ScatterChart2D'
G95_NAME heatmap_root,'HeatmapChart2D'
G95_NAME axes_root,'ChartAxes2D'
G95_NAME encoding_root,'ChartEncoding2D'
G95_NAME differential_root,'ChartDifferential'
G95_NAME closeout_root,'ChartCloseout'
G95_NAME chart,'chart'
G95_NAME plot,'plot'
G95_NAME bins,'bins'
G95_NAME heatmap,'heatmap'
G95_NAME x,'x'
G95_NAME y,'y'
G95_NAME x_label,'xLabel'
G95_NAME y_label,'yLabel'
G95_NAME labels,'labels'
G95_NAME color_by,'colorBy'
G95_NAME size_by,'sizeBy'
%undef G95_NAME

section .text
g95_is_program:
%macro G95_ROOT 1
    lea rsi,[rel g95_n_%1]
    mov edx,g95_n_%1_len
    call ls_contains_atom
    test eax,eax
    jnz .yes
%endmacro
    G95_ROOT registry_root
    G95_ROOT line_root
    G95_ROOT bar_root
    G95_ROOT histogram_root
    G95_ROOT scatter_root
    G95_ROOT heatmap_root
    G95_ROOT axes_root
    G95_ROOT encoding_root
    G95_ROOT differential_root
    G95_ROOT closeout_root
    xor eax,eax
    ret
.yes:
    mov eax,1
    ret
%undef G95_ROOT

; Exact bounded forms bind a nominal chart family, every public operation and
; one data extent.  The extent is propagated through lowering to the runtime
; chart adapter; it is not a fixture selector.
neboc_g095_source_parse:
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
%macro G95_PARSE_ROOT 2
    mov rdi,[rel ls_cursor]
    lea rsi,[rel g95_n_%1]
    mov edx,g95_n_%1_len
    call ls_token_match
    test eax,eax
    jz %%next
    mov ebx,%2
    jmp .root_ready
%%next:
%endmacro
    G95_PARSE_ROOT registry_root,1
    G95_PARSE_ROOT line_root,2
    G95_PARSE_ROOT bar_root,3
    G95_PARSE_ROOT histogram_root,4
    G95_PARSE_ROOT scatter_root,5
    G95_PARSE_ROOT heatmap_root,6
    G95_PARSE_ROOT axes_root,7
    G95_PARSE_ROOT encoding_root,8
    G95_PARSE_ROOT differential_root,9
    G95_PARSE_ROOT closeout_root,10
    jmp .method
.root_ready:
    inc qword [rel ls_cursor]
    mov edi,NEBOC_TOKEN_DOT
    call ls_expect_kind
    test eax,eax
    jz .arity
    cmp ebx,4
    je .first_bins
    cmp ebx,8
    je .first_bins
    cmp ebx,6
    je .first_heatmap
    cmp ebx,7
    je .first_x
    cmp ebx,1
    je .first_chart
    cmp ebx,3
    je .first_chart
    cmp ebx,10
    je .first_chart
    lea rsi,[rel g95_n_plot]
    mov edx,g95_n_plot_len
    jmp .first_match
.first_chart:
    lea rsi,[rel g95_n_chart]
    mov edx,g95_n_chart_len
    jmp .first_match
.first_bins:
    lea rsi,[rel g95_n_bins]
    mov edx,g95_n_bins_len
    jmp .first_match
.first_heatmap:
    lea rsi,[rel g95_n_heatmap]
    mov edx,g95_n_heatmap_len
    jmp .first_match
.first_x:
    lea rsi,[rel g95_n_x]
    mov edx,g95_n_x_len
.first_match:
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
    mov r12,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
    test r12,r12
    jz .range
    cmp r12,255
    ja .range
    inc qword [rel ls_cursor]
    mov edi,NEBOC_TOKEN_RPAREN
    call ls_expect_kind
    test eax,eax
    jz .arity
    mov edi,NEBOC_TOKEN_SEMICOLON
    call ls_expect_kind
    test eax,eax
    jz .arity

    cmp ebx,7
    jne .maybe_encoding
%macro G95_EXTRA_CALL 1
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
    lea rsi,[rel g95_n_%1]
    mov edx,g95_n_%1_len
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
    cmp [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],r12
    jne .method
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
    G95_EXTRA_CALL y
    G95_EXTRA_CALL x_label
    G95_EXTRA_CALL y_label
    jmp .return_value
.maybe_encoding:
    cmp ebx,8
    jne .return_value
    G95_EXTRA_CALL labels
    G95_EXTRA_CALL color_by
    G95_EXTRA_CALL size_by

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
    mov rdx,G95_FAMILY_KEY
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
.range:
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
%undef G95_EXTRA_CALL
%undef G95_PARSE_ROOT
