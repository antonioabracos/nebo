; G100 token-owned logs/progress/stream/parallel/timeline source vertical.
%define G100_FAMILY_KEY 0x4731303053524331

section .rodata
%macro G100_NAME 2
g100_n_%1: db %2
g100_n_%1_len equ $-g100_n_%1
%endmacro
G100_NAME logs_root,'StructuredLogMonitor'
G100_NAME progress_root,'ProgressHandleMonitor'
G100_NAME stream_root,'StreamMonitorView'
G100_NAME parallel_root,'ParallelMonitorView'
G100_NAME timeline_root,'EventTimelineView'
G100_NAME reactive_root,'ReactiveStreamMonitor'
G100_NAME window_root,'WindowedTimelineView'
G100_NAME metrics_root,'MetricStatusMonitor'
G100_NAME recovery_root,'RecoveryStreamMonitor'
G100_NAME closeout_root,'ObservabilityCloseout'
G100_NAME last,'last'
G100_NAME metric,'metric'
G100_NAME source,'source'
G100_NAME stream,'stream'
G100_NAME time,'time'
G100_NAME timeline,'timeline'
G100_NAME window,'window'
%undef G100_NAME

; Bit order follows the corrected catalogue surface order.
g100_expected_masks: dq 0x1e,0x16,0x4d,0x2c,0x34,0x4c,0x51,0x16,0x2c,0x7f

section .text
g100_is_program:
%macro G100_ROOT 1
    lea rsi,[rel g100_n_%1]
    mov edx,g100_n_%1_len
    call ls_contains_atom
    test eax,eax
    jnz .yes
%endmacro
    G100_ROOT logs_root
    G100_ROOT progress_root
    G100_ROOT stream_root
    G100_ROOT parallel_root
    G100_ROOT timeline_root
    G100_ROOT reactive_root
    G100_ROOT window_root
    G100_ROOT metrics_root
    G100_ROOT recovery_root
    G100_ROOT closeout_root
    xor eax,eax
    ret
.yes:
    mov eax,1
    ret
%undef G100_ROOT

; Parse one nominal receiver, its exact public option set and one shared
; source-derived generation. The semantic result owns lowering and codegen.
neboc_g100_source_parse:
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
%macro G100_PARSE_ROOT 2
    mov rdi,[rel ls_cursor]
    lea rsi,[rel g100_n_%1]
    mov edx,g100_n_%1_len
    call ls_token_match
    test eax,eax
    jz %%next
    mov ebx,%2
    jmp .root_ready
%%next:
%endmacro
    G100_PARSE_ROOT logs_root,1
    G100_PARSE_ROOT progress_root,2
    G100_PARSE_ROOT stream_root,3
    G100_PARSE_ROOT parallel_root,4
    G100_PARSE_ROOT timeline_root,5
    G100_PARSE_ROOT reactive_root,6
    G100_PARSE_ROOT window_root,7
    G100_PARSE_ROOT metrics_root,8
    G100_PARSE_ROOT recovery_root,9
    G100_PARSE_ROOT closeout_root,10
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
%macro G100_METHOD 2
    lea rsi,[rel g100_n_%1]
    mov edx,g100_n_%1_len
    call ls_current_atom
    test eax,eax
    jz %%next
    bt r13,%2
    jc .method
    bts r13,%2
    jmp .argument
%%next:
%endmacro
    G100_METHOD last,0
    G100_METHOD metric,1
    G100_METHOD source,2
    G100_METHOD stream,3
    G100_METHOD time,4
    G100_METHOD timeline,5
    G100_METHOD window,6
    jmp .method
.argument:
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
    jnz .compare_generation
    mov r12,rax
    jmp .range_generation
.compare_generation:
    cmp rax,r12
    jne .method
.range_generation:
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
    jmp .method_loop

.return_value:
    test r12,r12
    jz .method
    mov eax,ebx
    dec eax
    lea rdx,[rel g100_expected_masks]
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
    mov rdx,G100_FAMILY_KEY
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
%undef G100_METHOD
%undef G100_PARSE_ROOT
