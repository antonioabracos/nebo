; G108 token-owned Console testability schema. `profile:` selects one bounded
; capture/snapshot/replay contract and the integer seed remains observable.
%define G108_FAMILY_KEY 0x4731303853524331
%define NEBO_G108_SOURCE_MIN_SEED 2800

section .rodata
%macro G108_NAME 2
g108_n_%1: db %2
g108_n_%1_len equ $-g108_n_%1
%endmacro
G108_NAME capture_session,'CaptureSession'
G108_NAME capture_record,'CaptureRecord'
G108_NAME test,'test'
G108_NAME profile,'profile'
G108_NAME capture,'"capture"'
G108_NAME capture_redacted,'"capture-redacted"'
G108_NAME capture_variant,'"capture-variant"'
G108_NAME mock,'"mock"'
G108_NAME mock_silent,'"mock-silent"'
G108_NAME snapshot_golden,'"snapshot-golden"'
G108_NAME record_replay,'"record-replay"'
G108_NAME normalize_output,'"normalize-output"'
G108_NAME assertions,'"assertions"'
G108_NAME target_matrix,'"target-matrix"'
G108_NAME headless_matrix,'"headless-matrix"'
G108_NAME live_matrix,'"live-matrix"'
G108_NAME deterministic_time_seed,'"deterministic-time-seed"'
G108_NAME closeout,'"closeout"'
%undef G108_NAME

section .text
g108_is_program:
    lea rsi,[rel g108_n_capture_session]
    mov edx,g108_n_capture_session_len
    call ls_contains_atom
    test eax,eax
    jz .no
    lea rsi,[rel g108_n_capture_record]
    mov edx,g108_n_capture_record_len
    call ls_contains_atom
    test eax,eax
    jz .no
    lea rsi,[rel g108_n_profile]
    mov edx,g108_n_profile_len
    call ls_contains_atom
    test eax,eax
    jz .no
    mov eax,1
    ret
.no:
    xor eax,eax
    ret

; Current token is Text. EAX mode, EDX variant; zero mode is unknown.
g108_profile:
%macro G108_PROFILE 3
    mov rdi,[rel ls_cursor]
    lea rsi,[rel g108_n_%1]
    mov edx,g108_n_%1_len
    call ls_token_match
    test eax,eax
    jz %%next
    mov eax,%2
    mov edx,%3
    ret
%%next:
%endmacro
    G108_PROFILE capture,1,0
    G108_PROFILE capture_redacted,1,1
    G108_PROFILE capture_variant,1,2
    G108_PROFILE mock,2,0
    G108_PROFILE mock_silent,2,1
    G108_PROFILE snapshot_golden,3,0
    G108_PROFILE record_replay,4,1
    G108_PROFILE normalize_output,5,0
    G108_PROFILE assertions,6,1
    G108_PROFILE target_matrix,7,0
    G108_PROFILE headless_matrix,7,1
    G108_PROFILE live_matrix,7,2
    G108_PROFILE deterministic_time_seed,8,1
    G108_PROFILE closeout,9,0
    xor eax,eax
    xor edx,edx
    ret
%undef G108_PROFILE

neboc_g108_source_parse:
    push rbx
    push r12
    push r13
    mov qword [rel ls_cursor],0
    call ls_start_header
    test eax,eax
    jz .syntax
    lea rsi,[rel g108_n_capture_session]
    mov edx,g108_n_capture_session_len
    call ls_expect_atom
    test eax,eax
    jz .syntax
    mov edi,NEBOC_TOKEN_SEMICOLON
    call ls_expect_kind
    test eax,eax
    jz .syntax
    lea rsi,[rel g108_n_capture_record]
    mov edx,g108_n_capture_record_len
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
    cmp r12,NEBO_G108_SOURCE_MIN_SEED
    jb .range
    mov rax,0xffffffff
    cmp r12,rax
    ja .range
    inc qword [rel ls_cursor]
    mov edi,NEBOC_TOKEN_SEMICOLON
    call ls_expect_kind
    test eax,eax
    jz .syntax
    lea rsi,[rel g108_n_test]
    mov edx,g108_n_test_len
    call ls_expect_atom
    test eax,eax
    jz .unsupported
    mov edi,NEBOC_TOKEN_LBRACE
    call ls_expect_kind
    test eax,eax
    jz .syntax
    lea rsi,[rel g108_n_profile]
    mov edx,g108_n_profile_len
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
    call g108_profile
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
    mov rdx,G108_FAMILY_KEY
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
