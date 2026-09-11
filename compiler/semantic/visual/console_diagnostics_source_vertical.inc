; G109 token-owned structured Console diagnostic schema.  Both public options
; are parsed from canonical tokens; fixture paths and names are never read.
%define G109_FAMILY_KEY 0x4731303953524331
%define NEBO_G109_SOURCE_MIN_SEED 2900

section .rodata
%macro G109_NAME 2
g109_n_%1: db %2
g109_n_%1_len equ $-g109_n_%1
%endmacro
G109_NAME diagnostic_event,'DiagnosticEvent'
G109_NAME renderer_info,'RendererDebugInfo'
G109_NAME diagnose,'diagnose'
G109_NAME value,'value'
G109_NAME inspect,'inspect'
G109_NAME debug_renderer_info,'debugRendererInfo'
G109_NAME profile,'profile'
G109_NAME registry,'"registry"'
G109_NAME console_option,'"console-option"'
G109_NAME color,'"color"'
G109_NAME const_binding,'"const-binding"'
G109_NAME render_protocol,'"render-protocol"'
G109_NAME explain_fixit,'"explain-fixit"'
G109_NAME inspect_profiler,'"inspect-profiler"'
G109_NAME tooling,'"tooling"'
G109_NAME closeout,'"closeout"'
%undef G109_NAME

section .text
g109_is_program:
    lea rsi,[rel g109_n_diagnostic_event]
    mov edx,g109_n_diagnostic_event_len
    call ls_contains_atom
    test eax,eax
    jz .no
    lea rsi,[rel g109_n_renderer_info]
    mov edx,g109_n_renderer_info_len
    call ls_contains_atom
    test eax,eax
    jz .no
    lea rsi,[rel g109_n_diagnose]
    mov edx,g109_n_diagnose_len
    call ls_contains_atom
    test eax,eax
    jz .no
    mov eax,1
    ret
.no:
    xor eax,eax
    ret

; Current token is Text. EAX is the bounded subgroup mode.
g109_profile:
%macro G109_PROFILE 2
    mov rdi,[rel ls_cursor]
    lea rsi,[rel g109_n_%1]
    mov edx,g109_n_%1_len
    call ls_token_match
    test eax,eax
    jz %%next
    mov eax,%2
    ret
%%next:
%endmacro
    G109_PROFILE registry,1
    G109_PROFILE console_option,2
    G109_PROFILE color,3
    G109_PROFILE const_binding,4
    G109_PROFILE render_protocol,5
    G109_PROFILE explain_fixit,6
    G109_PROFILE inspect_profiler,7
    G109_PROFILE tooling,8
    G109_PROFILE closeout,9
    xor eax,eax
    ret
%undef G109_PROFILE

neboc_g109_source_parse:
    push rbx
    push r12
    push r13
    push r14
    mov qword [rel ls_cursor],0
    call ls_start_header
    test eax,eax
    jz .syntax
    lea rsi,[rel g109_n_diagnostic_event]
    mov edx,g109_n_diagnostic_event_len
    call ls_expect_atom
    test eax,eax
    jz .syntax
    mov edi,NEBOC_TOKEN_SEMICOLON
    call ls_expect_kind
    test eax,eax
    jz .syntax
    lea rsi,[rel g109_n_renderer_info]
    mov edx,g109_n_renderer_info_len
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
    cmp r12,NEBO_G109_SOURCE_MIN_SEED
    jb .range
    mov rax,0xffffffff
    cmp r12,rax
    ja .range
    inc qword [rel ls_cursor]
    mov edi,NEBOC_TOKEN_SEMICOLON
    call ls_expect_kind
    test eax,eax
    jz .syntax
    lea rsi,[rel g109_n_diagnose]
    mov edx,g109_n_diagnose_len
    call ls_expect_atom
    test eax,eax
    jz .unsupported
    mov edi,NEBOC_TOKEN_LBRACE
    call ls_expect_kind
    test eax,eax
    jz .syntax
    lea rsi,[rel g109_n_value]
    mov edx,g109_n_value_len
    call ls_expect_atom
    test eax,eax
    jz .unsupported
    mov edi,NEBOC_TOKEN_DOT
    call ls_expect_kind
    test eax,eax
    jz .syntax
    lea rsi,[rel g109_n_inspect]
    mov edx,g109_n_inspect_len
    call ls_expect_atom
    test eax,eax
    jz .unsupported
    mov edi,NEBOC_TOKEN_LPAREN
    call ls_expect_kind
    test eax,eax
    jz .syntax
    mov rdi,[rel ls_cursor]
    call ls_kind_at
    cmp eax,NEBOC_TOKEN_INTEGER
    jne .type
    mov rdi,[rel ls_cursor]
    call ls_token_ptr
    mov r13,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
    cmp r13,1
    jb .range
    cmp r13,8
    ja .range
    inc qword [rel ls_cursor]
    mov edi,NEBOC_TOKEN_RPAREN
    call ls_expect_kind
    test eax,eax
    jz .syntax
    mov edi,NEBOC_TOKEN_DOT
    call ls_expect_kind
    test eax,eax
    jz .syntax
    lea rsi,[rel g109_n_debug_renderer_info]
    mov edx,g109_n_debug_renderer_info_len
    call ls_expect_atom
    test eax,eax
    jz .unsupported
    mov edi,NEBOC_TOKEN_LPAREN
    call ls_expect_kind
    test eax,eax
    jz .syntax
    mov rdi,[rel ls_cursor]
    call ls_kind_at
    cmp eax,NEBOC_TOKEN_INTEGER
    jne .type
    mov rdi,[rel ls_cursor]
    call ls_token_ptr
    mov r14,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
    cmp r14,1
    jb .range
    cmp r14,64
    ja .range
    cmp r14,r13
    jb .range
    inc qword [rel ls_cursor]
    mov edi,NEBOC_TOKEN_RPAREN
    call ls_expect_kind
    test eax,eax
    jz .syntax
    mov edi,NEBOC_TOKEN_SEMICOLON
    call ls_expect_kind
    test eax,eax
    jz .syntax
    lea rsi,[rel g109_n_profile]
    mov edx,g109_n_profile_len
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
    call g109_profile
    test eax,eax
    jz .unsupported
    mov ebx,eax
    inc qword [rel ls_cursor]
    mov edi,NEBOC_TOKEN_RBRACE
    call ls_expect_kind
    test eax,eax
    jz .syntax
    call ls_finish_program
    test eax,eax
    jz .syntax
    mov rax,rbx
    shl rax,56
    mov rcx,r13
    shl rcx,8
    or rcx,r14
    shl rcx,32
    or rax,rcx
    mov edi,r12d
    or rdi,rax
    mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
    mov rdx,G109_FAMILY_KEY
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
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
