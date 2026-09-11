; Source-to-effect bridge for G108 deterministic Console testability profiles.
bits 64
default rel
%define NEBO_G108_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/console_testability_source_probe.inc"

section .note.GNU-stack noalloc noexec nowrite progbits

section .rodata
g108_private_path: db '/tmp/user/session-42'
g108_private_path_len equ $-g108_private_path
g108_wall_time: db '2026-09-04T14:00:00Z'
g108_wall_time_len equ $-g108_wall_time
g108_secret: db 'token-do-not-persist'
g108_secret_len equ $-g108_secret
g108_redacted_needle: db '<redacted>'
g108_redacted_needle_len equ $-g108_redacted_needle

section .bss align=16
g108_session: resb NEBO_G108_SESSION_SIZE
g108_replayed: resb NEBO_G108_SESSION_SIZE
g108_bad_session: resb NEBO_G108_SESSION_SIZE
g108_input: resb NEBO_G108_INPUT_SIZE
g108_payload: resb 16
g108_record: resb NEBO_G108_RECORD_MAX
g108_bad_record: resb NEBO_G108_RECORD_MAX
g108_last_mode: resq 1
g108_last_variant: resq 1
g108_last_record_len: resq 1

section .text
global nebo_g108_source_probe
global nebo_g108_surface_probe
global nebo_g108_negative_probe

g108_clear_probe:
    lea rdi,[rel g108_session]
    mov ecx,(NEBO_G108_SESSION_SIZE*3+NEBO_G108_INPUT_SIZE+16+NEBO_G108_RECORD_MAX*2)/8
    xor eax,eax
    rep stosq
    ret

; Construct a structured capture whose volatile values must never survive.
g108_prepare_input:
    mov dword [rel g108_payload],'G108'
    mov eax,edi
    add al,'0'
    mov [rel g108_payload+4],al
    mov eax,esi
    and al,15
    add al,'A'
    mov [rel g108_payload+5],al
    mov eax,edx
    add al,'0'
    mov [rel g108_payload+6],al
    mov dword [rel g108_payload+7],'TEST'
    mov byte [rel g108_payload+11],'!'
    mov byte [rel g108_payload+12],'X'
    mov byte [rel g108_payload+13],13
    mov byte [rel g108_payload+14],10
    mov byte [rel g108_payload+15],'Y'
    lea rax,[rel g108_payload]
    mov [rel g108_input+NEBO_G108_INPUT_STABLE_PTR],rax
    mov qword [rel g108_input+NEBO_G108_INPUT_STABLE_LEN],16
    lea rax,[rel g108_private_path]
    mov [rel g108_input+NEBO_G108_INPUT_PATH_PTR],rax
    mov qword [rel g108_input+NEBO_G108_INPUT_PATH_LEN],g108_private_path_len
    lea rax,[rel g108_wall_time]
    mov [rel g108_input+NEBO_G108_INPUT_TIME_PTR],rax
    mov qword [rel g108_input+NEBO_G108_INPUT_TIME_LEN],g108_wall_time_len
    lea rax,[rel g108_secret]
    mov [rel g108_input+NEBO_G108_INPUT_SECRET_PTR],rax
    mov qword [rel g108_input+NEBO_G108_INPUT_SECRET_LEN],g108_secret_len
    ret

; EDI mode 1..9, ESI source seed, EDX variant. Success returns the seed.
nebo_g108_source_probe:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov ebx,edi
    mov ebp,esi
    mov r12d,edx
    cmp ebx,1
    jb .invalid
    cmp ebx,NEBO_G108_SOURCE_MAX_MODE
    ja .invalid
    cmp ebp,NEBO_G108_SOURCE_MIN_SEED
    jb .invalid
    cmp r12d,NEBO_G108_SOURCE_MAX_VARIANT
    ja .invalid
    call g108_clear_probe
    mov [rel g108_last_mode],rbx
    mov [rel g108_last_variant],r12
    mov edi,ebx
    mov esi,ebp
    mov edx,r12d
    call g108_prepare_input

    mov r13d,NEBO_G108_TARGET_HEADLESS
    mov r14d,NEBO_G108_CAP_REQUIRED
    mov r15d,NEBO_G108_FLAG_CANONICAL
    cmp ebx,2
    jne .mode7
    mov r13d,NEBO_G108_TARGET_MOCK
    test r12d,r12d
    jz .init
    or r15d,NEBO_G108_FLAG_SILENT
    jmp .init
.mode7:
    cmp ebx,7
    jne .init
    lea r13d,[r12+NEBO_G108_TARGET_MOCK]
    cmp r13d,NEBO_G108_TARGET_LIVE
    jne .init
    or r14d,NEBO_G108_CAP_LIVE
.init:
    lea rdi,[rel g108_session]
    mov rsi,r13
    mov rdx,rbp
    lea rcx,[rbp+rbp*4]
    lea rcx,[rcx*2+r12]
    mov r8,r14
    mov r9,r15
    call nebo_g108_session_init
    test eax,eax
    jnz .done
    lea rdi,[rel g108_session]
    lea rsi,[rel g108_input]
    call nebo_g108_capture
    test eax,eax
    js .done
    lea rdi,[rel g108_session]
    lea rsi,[rel g108_record]
    mov edx,NEBO_G108_RECORD_MAX
    call nebo_g108_snapshot
    test eax,eax
    js .done
    mov [rel g108_last_record_len],rax
    mov r13,rax
    lea rdi,[rel g108_record]
    mov rsi,r13
    call nebo_g108_record_validate
    test eax,eax
    jnz .done
    lea rdi,[rel g108_record]
    mov rsi,r13
    lea rdx,[rel g108_record]
    mov rcx,r13
    call nebo_g108_golden_compare
    cmp eax,1
    jne .runtime
    lea rdi,[rel g108_record]
    mov rsi,r13
    lea rdx,[rel g108_replayed]
    call nebo_g108_replay
    test eax,eax
    js .done
    lea rdi,[rel g108_replayed]
    lea rsi,[rel g108_session+NEBO_G108_SESSION_BUFFER]
    mov rdx,[rel g108_session+NEBO_G108_SESSION_LENGTH]
    call nebo_g108_assert_equals
    cmp eax,1
    jne .runtime
    lea rdi,[rel g108_replayed]
    lea rsi,[rel g108_redacted_needle]
    mov edx,g108_redacted_needle_len
    call nebo_g108_assert_contains
    cmp eax,1
    jne .runtime
    cmp ebx,9
    jne .success
    lea rdi,[rel g108_session]
    call nebo_g108_session_close
    test eax,eax
    jnz .done
    lea rdi,[rel g108_replayed]
    call nebo_g108_session_close
    test eax,eax
    jnz .done
.success:
    mov eax,ebp
    jmp .done
.runtime:
    mov eax,-NEBO_G108_ERROR_MISMATCH
    jmp .done
.invalid:
    mov eax,-NEBO_G108_ERROR_INVALID
.done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

; EDI selector 1..11 -> last source-derived observation or typed error.
nebo_g108_surface_probe:
    cmp edi,1
    jb .invalid
    cmp edi,11
    ja .invalid
    lea rdx,[rel .table]
    movsxd rax,dword [rdx+rdi*4-4]
    add rax,rdx
    jmp rax
.mode: mov rax,[rel g108_last_mode]
    ret
.target: mov rax,[rel g108_session+NEBO_G108_SESSION_TARGET]
    ret
.length: mov rax,[rel g108_session+NEBO_G108_SESSION_LENGTH]
    ret
.digest: mov rax,[rel g108_session+NEBO_G108_SESSION_DIGEST]
    ret
.record_len: mov rax,[rel g108_last_record_len]
    ret
.replay_seed: mov rax,[rel g108_replayed+NEBO_G108_SESSION_SEED]
    ret
.assertions: mov rax,[rel g108_replayed+NEBO_G108_SESSION_ASSERTIONS]
    ret
.flags: mov rax,[rel g108_session+NEBO_G108_SESSION_FLAGS]
    ret
.state: mov rax,[rel g108_replayed+NEBO_G108_SESSION_STATE]
    ret
.evals: mov rax,[rel g108_session+NEBO_G108_SESSION_RECEIVER_EVALS]
    ret
.maturity: mov eax,NEBO_G108_MATURITY_DETERMINISTIC_REPLAY_GREEN
    ret
.invalid:
    mov eax,-NEBO_G108_ERROR_INVALID
    ret
align 4
.table:
    dd .mode-.table,.target-.table,.length-.table,.digest-.table
    dd .record_len-.table,.replay_seed-.table,.assertions-.table,.flags-.table
    dd .state-.table,.evals-.table,.maturity-.table

; EDI case 1..10. Every known failure is typed and publication atomic.
nebo_g108_negative_probe:
    push rbx
    push r12
    sub rsp,8
    mov ebx,edi
    cmp ebx,1
    jb .invalid
    cmp ebx,10
    ja .invalid
    call g108_clear_probe
    mov qword [rel g108_bad_session],0x51515151
    mov qword [rel g108_bad_record],0x61616161
    cmp ebx,1
    je .bad_target
    cmp ebx,2
    je .live_cap
    cmp ebx,3
    je .missing_cap
    cmp ebx,4
    je .zero_seed
    cmp ebx,5
    je .redaction
    mov edi,1
    lea esi,[rbx+3800]
    xor edx,edx
    call nebo_g108_source_probe
    test eax,eax
    js .failed
    mov qword [rel g108_bad_session],0x51515151
    mov qword [rel g108_bad_record],0x61616161
    cmp ebx,6
    je .snapshot_capacity
    cmp ebx,7
    je .schema
    cmp ebx,8
    je .digest
    cmp ebx,9
    je .truncated
    lea rdi,[rel g108_session]
    call nebo_g108_session_close
    test eax,eax
    jnz .failed
    lea rdi,[rel g108_session]
    call nebo_g108_session_close
    cmp eax,-NEBO_G108_ERROR_STATE
    jne .failed
    xor eax,eax
    jmp .done
.bad_target:
    lea rdi,[rel g108_bad_session]
    mov esi,NEBO_G108_TARGET_MAX+1
    mov edx,3801
    mov ecx,38010
    mov r8d,NEBO_G108_CAP_REQUIRED
    mov r9d,NEBO_G108_FLAG_CANONICAL
    call nebo_g108_session_init
    cmp eax,-NEBO_G108_ERROR_INVALID
    jne .failed
    jmp .session_sentinel
.live_cap:
    lea rdi,[rel g108_bad_session]
    mov esi,NEBO_G108_TARGET_LIVE
    mov edx,3802
    mov ecx,38020
    mov r8d,NEBO_G108_CAP_REQUIRED
    mov r9d,NEBO_G108_FLAG_CANONICAL
    call nebo_g108_session_init
    cmp eax,-NEBO_G108_ERROR_TARGET
    jne .failed
    jmp .session_sentinel
.missing_cap:
    lea rdi,[rel g108_bad_session]
    mov esi,NEBO_G108_TARGET_HEADLESS
    mov edx,3803
    mov ecx,38030
    mov r8d,NEBO_G108_CAP_REQUIRED-NEBO_G108_CAP_REPLAY
    mov r9d,NEBO_G108_FLAG_CANONICAL
    call nebo_g108_session_init
    cmp eax,-NEBO_G108_ERROR_CAPABILITY
    jne .failed
    jmp .session_sentinel
.zero_seed:
    lea rdi,[rel g108_bad_session]
    mov esi,NEBO_G108_TARGET_HEADLESS
    xor edx,edx
    mov ecx,38040
    mov r8d,NEBO_G108_CAP_REQUIRED
    mov r9d,NEBO_G108_FLAG_CANONICAL
    call nebo_g108_session_init
    cmp eax,-NEBO_G108_ERROR_INVALID
    jne .failed
    jmp .session_sentinel
.redaction:
    mov edi,5
    mov esi,3805
    xor edx,edx
    call g108_prepare_input
    lea rdi,[rel g108_session]
    mov esi,NEBO_G108_TARGET_HEADLESS
    mov edx,3805
    mov ecx,38050
    mov r8d,NEBO_G108_CAP_REQUIRED
    mov r9d,NEBO_G108_FLAG_NORMALIZE_NEWLINES
    call nebo_g108_session_init
    test eax,eax
    jnz .failed
    lea rdi,[rel g108_session]
    lea rsi,[rel g108_input]
    call nebo_g108_capture
    cmp eax,-NEBO_G108_ERROR_CAPABILITY
    jne .failed
    cmp qword [rel g108_session+NEBO_G108_SESSION_STATE],NEBO_G108_STATE_READY
    jne .failed
    cmp qword [rel g108_session+NEBO_G108_SESSION_LENGTH],0
    jne .failed
    xor eax,eax
    jmp .done
.snapshot_capacity:
    lea rdi,[rel g108_session]
    lea rsi,[rel g108_bad_record]
    mov edx,NEBO_G108_RECORD_HEADER_SIZE-1
    call nebo_g108_snapshot
    cmp eax,-NEBO_G108_ERROR_CAPACITY
    jne .failed
    cmp qword [rel g108_bad_record],0x61616161
    jne .failed
    xor eax,eax
    jmp .done
.schema:
    xor qword [rel g108_record+NEBO_G108_RECORD_SCHEMA],1
    lea rdi,[rel g108_record]
    mov rsi,[rel g108_last_record_len]
    call nebo_g108_record_validate
    cmp eax,-NEBO_G108_ERROR_SCHEMA
    jne .failed
    xor eax,eax
    jmp .done
.digest:
    xor byte [rel g108_record+NEBO_G108_RECORD_HEADER_SIZE],1
    lea rdi,[rel g108_record]
    mov rsi,[rel g108_last_record_len]
    lea rdx,[rel g108_bad_session]
    call nebo_g108_replay
    cmp eax,-NEBO_G108_ERROR_DIGEST
    jne .failed
    cmp qword [rel g108_bad_session],0x51515151
    jne .failed
    xor eax,eax
    jmp .done
.truncated:
    lea rdi,[rel g108_record]
    mov rsi,[rel g108_last_record_len]
    dec rsi
    call nebo_g108_record_validate
    cmp eax,-NEBO_G108_ERROR_SCHEMA
    jne .failed
    xor eax,eax
    jmp .done
.session_sentinel:
    cmp qword [rel g108_bad_session],0x51515151
    jne .failed
    xor eax,eax
    jmp .done
.invalid:
    mov eax,-NEBO_G108_ERROR_INVALID
    jmp .done
.failed:
    mov eax,-NEBO_G108_ERROR_STATE
.done:
    add rsp,8
    pop r12
    pop rbx
    ret
