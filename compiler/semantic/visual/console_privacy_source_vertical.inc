; G106 token-owned `privacy:` schema vertical.  The named key selects a
; bounded policy profile; its value is carried through semantic output rather
; than inferred from a fixture path or the observable seed.
%define G106_FAMILY_KEY 0x4731303653524331
%define NEBO_G106_SOURCE_MIN_SEED 2600

section .rodata
%macro G106_NAME 2
g106_n_%1: db %2
g106_n_%1_len equ $-g106_n_%1
%endmacro
G106_NAME privacy_policy,'PrivacyPolicy'
G106_NAME render_plan,'RenderPlan'
G106_NAME policy,'policy'
G106_NAME privacy,'privacy'
G106_NAME public,'"public"'
G106_NAME redact,'"redact"'
G106_NAME mask,'"mask"'
G106_NAME allow,'"allow"'
G106_NAME deny,'"deny"'
G106_NAME quality_lineage,'"quality-lineage"'
G106_NAME verified,'"verified"'
G106_NAME safe_display,'"safe-display"'
G106_NAME accessible,'"accessible"'
G106_NAME no_color,'"no-color"'
G106_NAME high_contrast,'"high-contrast"'
G106_NAME screen_reader,'"screen-reader"'
G106_NAME audit,'"audit"'
G106_NAME closeout,'"closeout"'
%undef G106_NAME

section .text
g106_is_program:
    lea rsi,[rel g106_n_privacy_policy]
    mov edx,g106_n_privacy_policy_len
    call ls_contains_atom
    test eax,eax
    jz .no
    lea rsi,[rel g106_n_render_plan]
    mov edx,g106_n_render_plan_len
    call ls_contains_atom
    test eax,eax
    jz .no
    lea rsi,[rel g106_n_privacy]
    mov edx,g106_n_privacy_len
    call ls_contains_atom
    test eax,eax
    jz .no
    mov eax,1
    ret
.no:
    xor eax,eax
    ret

; Current token is a Text literal. EAX=mode, EDX=variant; zero is unknown.
g106_profile:
%macro G106_PROFILE 3
    mov rdi,[rel ls_cursor]
    lea rsi,[rel g106_n_%1]
    mov edx,g106_n_%1_len
    call ls_token_match
    test eax,eax
    jz %%next
    mov eax,%2
    mov edx,%3
    ret
%%next:
%endmacro
    G106_PROFILE public,1,0
    G106_PROFILE redact,2,0
    G106_PROFILE mask,2,1
    G106_PROFILE allow,3,0
    G106_PROFILE deny,3,1
    G106_PROFILE quality_lineage,4,0
    G106_PROFILE verified,5,0
    G106_PROFILE safe_display,6,0
    G106_PROFILE accessible,7,0
    G106_PROFILE no_color,8,0
    G106_PROFILE high_contrast,8,1
    G106_PROFILE screen_reader,8,2
    G106_PROFILE audit,9,0
    G106_PROFILE closeout,10,0
    xor eax,eax
    xor edx,edx
    ret
%undef G106_PROFILE

neboc_g106_source_parse:
    push rbx
    push r12
    push r13
    mov qword [rel ls_cursor],0
    call ls_start_header
    test eax,eax
    jz .syntax
    lea rsi,[rel g106_n_privacy_policy]
    mov edx,g106_n_privacy_policy_len
    call ls_expect_atom
    test eax,eax
    jz .syntax
    mov edi,NEBOC_TOKEN_SEMICOLON
    call ls_expect_kind
    test eax,eax
    jz .syntax
    lea rsi,[rel g106_n_render_plan]
    mov edx,g106_n_render_plan_len
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
    cmp r12,NEBO_G106_SOURCE_MIN_SEED
    jb .range
    mov rax,0xffffffff
    cmp r12,rax
    ja .range
    inc qword [rel ls_cursor]
    mov edi,NEBOC_TOKEN_SEMICOLON
    call ls_expect_kind
    test eax,eax
    jz .syntax
    lea rsi,[rel g106_n_policy]
    mov edx,g106_n_policy_len
    call ls_expect_atom
    test eax,eax
    jz .unsupported
    mov edi,NEBOC_TOKEN_LBRACE
    call ls_expect_kind
    test eax,eax
    jz .syntax
    lea rsi,[rel g106_n_privacy]
    mov edx,g106_n_privacy_len
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
    call g106_profile
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
    mov rdx,G106_FAMILY_KEY
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
