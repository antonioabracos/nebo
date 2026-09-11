; G102 token-owned animation, capture and export vertical.
%define G102_FAMILY_KEY 0x4731303253524331

section .rodata
%macro G102_NAME 2
g102_n_%1: db %2
g102_n_%1_len equ $-g102_n_%1
%endmacro
G102_NAME animation_root,'AnimationModelView'
G102_NAME timeline_root,'TimelineFrameView'
G102_NAME playback_root,'PlaybackPlanView'
G102_NAME deterministic_root,'DeterministicAnimationView'
G102_NAME capture_root,'CaptureScreenshotView'
G102_NAME png_root,'PngExportView'
G102_NAME video_root,'VideoFramesExportView'
G102_NAME target_root,'ExportTargetView'
G102_NAME atomic_root,'AtomicExportView'
G102_NAME closeout_root,'AnimationExportCloseout'
G102_NAME animate,'animate'
G102_NAME animation,'animation'
G102_NAME capture,'capture'
G102_NAME duration,'duration'
G102_NAME export,'export'
G102_NAME fps,'fps'
G102_NAME frames,'frames'
G102_NAME loop,'loop'
G102_NAME mp4,'mp4'
G102_NAME path,'path'
G102_NAME png,'png'
G102_NAME screenshot,'screenshot'
G102_NAME seed,'seed'
G102_NAME target,'target'
G102_NAME hide_on_screen,'hideOnScreen'
%undef G102_NAME

; Bit order follows the corrected catalogue surface table. The final bit is
; the named hideOnScreen: schema key rather than a callable method.
g102_expected_masks: dq 0x0003,0x0048,0x00a8,0x1002,0x0804
                     dq 0x0610,0x2150,0x6200,0x2214,0x7fff

section .text
g102_is_program:
%macro G102_ROOT 1
    lea rsi,[rel g102_n_%1]
    mov edx,g102_n_%1_len
    call ls_contains_atom
    test eax,eax
    jnz .yes
%endmacro
    G102_ROOT animation_root
    G102_ROOT timeline_root
    G102_ROOT playback_root
    G102_ROOT deterministic_root
    G102_ROOT capture_root
    G102_ROOT png_root
    G102_ROOT video_root
    G102_ROOT target_root
    G102_ROOT atomic_root
    G102_ROOT closeout_root
    xor eax,eax
    ret
.yes:
    mov eax,1
    ret
%undef G102_ROOT

; Parse one nominal receiver, its exact public option set and one shared,
; source-derived value. No source path or fixture name participates.
neboc_g102_source_parse:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
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
%macro G102_PARSE_ROOT 2
    mov rdi,[rel ls_cursor]
    lea rsi,[rel g102_n_%1]
    mov edx,g102_n_%1_len
    call ls_token_match
    test eax,eax
    jz %%next
    mov ebx,%2
    jmp .root_ready
%%next:
%endmacro
    G102_PARSE_ROOT animation_root,1
    G102_PARSE_ROOT timeline_root,2
    G102_PARSE_ROOT playback_root,3
    G102_PARSE_ROOT deterministic_root,4
    G102_PARSE_ROOT capture_root,5
    G102_PARSE_ROOT png_root,6
    G102_PARSE_ROOT video_root,7
    G102_PARSE_ROOT target_root,8
    G102_PARSE_ROOT atomic_root,9
    G102_PARSE_ROOT closeout_root,10
    jmp .method
.root_ready:
    xor r12d,r12d
    xor r13d,r13d
.method_loop:
    mov rdi,[rel ls_cursor]
    call ls_kind_at
    cmp eax,NEBOC_TOKEN_INTEGER
    je .return_value
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
    xor r15d,r15d
%macro G102_METHOD 2
    lea rsi,[rel g102_n_%1]
    mov edx,g102_n_%1_len
    call ls_current_atom
    test eax,eax
    jz %%next
    bt r13,%2
    jc .method
    bts r13,%2
    mov r15d,%2
    jmp .argument
%%next:
%endmacro
    G102_METHOD animate,0
    G102_METHOD animation,1
    G102_METHOD capture,2
    G102_METHOD duration,3
    G102_METHOD export,4
    G102_METHOD fps,5
    G102_METHOD frames,6
    G102_METHOD loop,7
    G102_METHOD mp4,8
    G102_METHOD path,9
    G102_METHOD png,10
    G102_METHOD screenshot,11
    G102_METHOD seed,12
    G102_METHOD target,13
    G102_METHOD hide_on_screen,14
    jmp .method
.argument:
    inc qword [rel ls_cursor]
    cmp r15d,14
    je .named_argument
    mov edi,NEBOC_TOKEN_LPAREN
    call ls_expect_kind
    test eax,eax
    jz .arity
    jmp .integer_argument
.named_argument:
    mov edi,NEBOC_TOKEN_RESERVED_COLON
    call ls_expect_kind
    test eax,eax
    jz .arity
.integer_argument:
    mov rdi,[rel ls_cursor]
    call ls_kind_at
    cmp eax,NEBOC_TOKEN_INTEGER
    jne .type
    mov rdi,[rel ls_cursor]
    call ls_token_ptr
    mov rax,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
    test r12,r12
    jnz .compare_value
    mov r12,rax
    jmp .range_value
.compare_value:
    cmp rax,r12
    jne .method
.range_value:
    test rax,rax
    jz .range_error
    cmp rax,255
    ja .range_error
    inc qword [rel ls_cursor]
    cmp r15d,14
    je .argument_end
    mov edi,NEBOC_TOKEN_RPAREN
    call ls_expect_kind
    test eax,eax
    jz .arity
.argument_end:
    mov edi,NEBOC_TOKEN_SEMICOLON
    call ls_expect_kind
    test eax,eax
    jz .arity
    jmp .method_loop

.return_value:
    test r12,r12
    jz .method
    mov eax,ebx
    dec eax
    lea rdx,[rel g102_expected_masks]
    cmp r13,[rdx+rax*8]
    jne .method
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
    mov rdx,G102_FAMILY_KEY
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
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
%undef G102_METHOD
%undef G102_PARSE_ROOT
