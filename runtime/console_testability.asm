; G108 deterministic Console capture, snapshot and inert replay runtime.
bits 64
default rel
%define NEBO_G108_CONSOLE_TESTABILITY_IMPLEMENTATION 1
%include "runtime/console_testability.inc"

section .note.GNU-stack noalloc noexec nowrite progbits

section .rodata
g108_path_marker: db 10,'path=<path>'
g108_path_marker_len equ $-g108_path_marker
g108_time_marker: db 10,'time=<time>'
g108_time_marker_len equ $-g108_time_marker
g108_secret_marker: db 10,'secret=<redacted>'
g108_secret_marker_len equ $-g108_secret_marker

section .text
global nebo_g108_session_init
global nebo_g108_normalize_output
global nebo_g108_capture
global nebo_g108_snapshot
global nebo_g108_record_validate
global nebo_g108_golden_compare
global nebo_g108_replay
global nebo_g108_assert_equals
global nebo_g108_assert_contains
global nebo_g108_target_classify
global nebo_g108_session_close
global nebo_g108_status_diagnostic

; RDI bytes, RSI length -> FNV-1a digest. Empty data is invalid here.
g108_hash:
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    mov rax,0xcbf29ce484222325
    mov rcx,rsi
.loop:
    movzx edx,byte [rdi]
    xor rax,rdx
    mov rdx,0x100000001b3
    imul rax,rdx
    inc rdi
    dec rcx
    jnz .loop
    ret
.invalid:
    xor eax,eax
    ret

; RDI session -> 0 or negative typed status.
g108_session_validate:
    test rdi,rdi
    jz .invalid
    mov rax,NEBO_G108_SESSION_MAGIC_VALUE
    cmp [rdi+NEBO_G108_SESSION_MAGIC],rax
    jne .invalid
    cmp qword [rdi+NEBO_G108_SESSION_TARGET],NEBO_G108_TARGET_MOCK
    jb .invalid
    cmp qword [rdi+NEBO_G108_SESSION_TARGET],NEBO_G108_TARGET_MAX
    ja .invalid
    cmp qword [rdi+NEBO_G108_SESSION_STATE],NEBO_G108_STATE_READY
    jb .state
    cmp qword [rdi+NEBO_G108_SESSION_STATE],NEBO_G108_STATE_CLOSED
    ja .state
    mov rax,[rdi+NEBO_G108_SESSION_CAPABILITIES]
    test rax,~NEBO_G108_CAP_ALL
    jnz .invalid
    mov rax,[rdi+NEBO_G108_SESSION_FLAGS]
    test rax,~NEBO_G108_FLAG_ALL
    jnz .invalid
    mov rax,[rdi+NEBO_G108_SESSION_SEED]
    test rax,rax
    jz .invalid
    mov rcx,0xffffffff
    cmp rax,rcx
    ja .invalid
    mov rax,[rdi+NEBO_G108_SESSION_TIME]
    test rax,rax
    jz .invalid
    cmp rax,rcx
    ja .invalid
    mov rax,[rdi+NEBO_G108_SESSION_STATE]
    cmp rax,NEBO_G108_STATE_READY
    je .empty
    cmp rax,NEBO_G108_STATE_CLOSED
    je .empty
    mov rax,[rdi+NEBO_G108_SESSION_LENGTH]
    test rax,rax
    jz .invalid
    cmp rax,NEBO_G108_CAPTURE_MAX
    ja .invalid
    cmp qword [rdi+NEBO_G108_SESSION_DIGEST],0
    je .invalid
    xor eax,eax
    ret
.empty:
    cmp qword [rdi+NEBO_G108_SESSION_LENGTH],0
    jne .invalid
    cmp qword [rdi+NEBO_G108_SESSION_DIGEST],0
    jne .invalid
    xor eax,eax
    ret
.state:
    mov eax,-NEBO_G108_ERROR_STATE
    ret
.invalid:
    mov eax,-NEBO_G108_ERROR_INVALID
    ret

; RDI target, RSI capabilities -> factual target class or negative error.
; This classifies live but never opens a window or treats headless as live.
nebo_g108_target_classify:
    cmp rdi,NEBO_G108_TARGET_MOCK
    jb .invalid
    cmp rdi,NEBO_G108_TARGET_MAX
    ja .invalid
    test rsi,~NEBO_G108_CAP_ALL
    jnz .invalid
    cmp rdi,NEBO_G108_TARGET_LIVE
    jne .ok
    test rsi,NEBO_G108_CAP_LIVE
    jz .target
.ok:
    mov rax,rdi
    ret
.target:
    mov eax,-NEBO_G108_ERROR_TARGET
    ret
.invalid:
    mov eax,-NEBO_G108_ERROR_INVALID
    ret

; RDI session, RSI target, RDX seed, RCX logical time, R8 caps, R9 flags.
; Logical time and seed are explicit inputs; no ambient clock/random is read.
nebo_g108_session_init:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov rbx,rdi
    mov r12,rsi
    mov r13,rdx
    mov r14,rcx
    mov r15,r8
    test rbx,rbx
    jz .invalid
    test r13,r13
    jz .invalid
    mov eax,0xffffffff
    cmp r13,rax
    ja .limit
    test r14,r14
    jz .invalid
    mov rax,0xffffffff
    cmp r14,rax
    ja .limit
    test r15,~NEBO_G108_CAP_ALL
    jnz .invalid
    mov rax,r15
    and rax,NEBO_G108_CAP_REQUIRED
    cmp rax,NEBO_G108_CAP_REQUIRED
    jne .capability
    test r9,~NEBO_G108_FLAG_ALL
    jnz .invalid
    mov rdi,r12
    mov rsi,r15
    call nebo_g108_target_classify
    test eax,eax
    js .done
    mov r10,r9
    mov rdi,rbx
    xor eax,eax
    mov ecx,NEBO_G108_SESSION_SIZE/8
    rep stosq
    mov rax,NEBO_G108_SESSION_MAGIC_VALUE
    mov [rbx+NEBO_G108_SESSION_MAGIC],rax
    mov [rbx+NEBO_G108_SESSION_TARGET],r12
    mov [rbx+NEBO_G108_SESSION_SEED],r13
    mov [rbx+NEBO_G108_SESSION_TIME],r14
    mov [rbx+NEBO_G108_SESSION_CAPABILITIES],r15
    mov [rbx+NEBO_G108_SESSION_FLAGS],r10
    mov qword [rbx+NEBO_G108_SESSION_STATE],NEBO_G108_STATE_READY
    mov qword [rbx+NEBO_G108_SESSION_RECEIVER_EVALS],1
    xor eax,eax
    jmp .done
.capability:
    mov eax,-NEBO_G108_ERROR_CAPABILITY
    jmp .done
.limit:
    mov eax,-NEBO_G108_ERROR_LIMIT
    jmp .done
.invalid:
    mov eax,-NEBO_G108_ERROR_INVALID
.done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; RDI input, RSI length, RDX output, RCX capacity -> normalized length/error.
; CRLF and CR become LF. A measuring pass makes capacity failure atomic.
nebo_g108_normalize_output:
    test rdi,rdi
    jz .invalid
    test rdx,rdx
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp rsi,NEBO_G108_CAPTURE_MAX
    ja .limit
    mov r8,rdi
    mov r9,rsi
    xor r10d,r10d
    xor r11d,r11d
.measure:
    cmp r10,r9
    jae .measured
    mov al,[r8+r10]
    test al,al
    jz .invalid
    inc r10
    cmp al,13
    jne .measured_one
    cmp r10,r9
    jae .measured_one
    cmp byte [r8+r10],10
    jne .measured_one
    inc r10
.measured_one:
    inc r11
    jmp .measure
.measured:
    cmp rcx,r11
    jb .capacity
    xor r10d,r10d
    xor eax,eax
.copy:
    cmp r10,r9
    jae .done
    mov sil,[r8+r10]
    inc r10
    cmp sil,13
    jne .store
    mov sil,10
    cmp r10,r9
    jae .store
    cmp byte [r8+r10],10
    jne .store
    inc r10
.store:
    mov [rdx+rax],sil
    inc rax
    jmp .copy
.capacity:
    mov eax,-NEBO_G108_ERROR_CAPACITY
    ret
.limit:
    mov eax,-NEBO_G108_ERROR_LIMIT
    ret
.invalid:
    mov eax,-NEBO_G108_ERROR_INVALID
.done:
    ret

; RDI session, RSI structured input -> normalized capture length/error.
; Volatile values are validated then replaced with fixed public markers.
nebo_g108_capture:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,520
    mov rbx,rdi
    mov r12,rsi
    call g108_session_validate
    test eax,eax
    jnz .done
    cmp qword [rbx+NEBO_G108_SESSION_STATE],NEBO_G108_STATE_READY
    jne .state
    test qword [rbx+NEBO_G108_SESSION_CAPABILITIES],NEBO_G108_CAP_CAPTURE
    jz .capability
    test r12,r12
    jz .invalid
    mov rdi,[r12+NEBO_G108_INPUT_STABLE_PTR]
    mov rsi,[r12+NEBO_G108_INPUT_STABLE_LEN]
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp rsi,NEBO_G108_CAPTURE_MAX
    ja .limit
    mov rdx,rsp
    mov ecx,NEBO_G108_CAPTURE_MAX
    call nebo_g108_normalize_output
    test eax,eax
    js .done
    mov r13,rax

%macro G108_APPEND_VOLATILE 5
    mov r14,[r12+%1]
    test r14,r14
    jz %%next
    cmp r14,64
    ja .limit
    cmp qword [r12+%2],0
    je .invalid
    test qword [rbx+NEBO_G108_SESSION_FLAGS],%3
    jz .capability
    lea rax,[r13+%5]
    cmp rax,NEBO_G108_CAPTURE_MAX
    ja .limit
    lea rdi,[rsp+r13]
    lea rsi,[rel %4]
    mov ecx,%5
    rep movsb
    add r13,%5
%%next:
%endmacro
    G108_APPEND_VOLATILE NEBO_G108_INPUT_PATH_LEN,NEBO_G108_INPUT_PATH_PTR,NEBO_G108_FLAG_REDACT_PATH,g108_path_marker,g108_path_marker_len
    G108_APPEND_VOLATILE NEBO_G108_INPUT_TIME_LEN,NEBO_G108_INPUT_TIME_PTR,NEBO_G108_FLAG_REDACT_TIME,g108_time_marker,g108_time_marker_len
    G108_APPEND_VOLATILE NEBO_G108_INPUT_SECRET_LEN,NEBO_G108_INPUT_SECRET_PTR,NEBO_G108_FLAG_REDACT_SECRET,g108_secret_marker,g108_secret_marker_len
%undef G108_APPEND_VOLATILE

    mov rdi,rsp
    mov rsi,r13
    call g108_hash
    test rax,rax
    jz .invalid
    mov r15,rax
    lea rdi,[rbx+NEBO_G108_SESSION_BUFFER]
    mov rsi,rsp
    mov rcx,r13
    rep movsb
    mov [rbx+NEBO_G108_SESSION_LENGTH],r13
    mov [rbx+NEBO_G108_SESSION_DIGEST],r15
    mov qword [rbx+NEBO_G108_SESSION_ASSERTIONS],0
    mov qword [rbx+NEBO_G108_SESSION_STATE],NEBO_G108_STATE_CAPTURED
    mov rax,r13
    jmp .done
.state:
    mov eax,-NEBO_G108_ERROR_STATE
    jmp .done
.capability:
    mov eax,-NEBO_G108_ERROR_CAPABILITY
    jmp .done
.limit:
    mov eax,-NEBO_G108_ERROR_LIMIT
    jmp .done
.invalid:
    mov eax,-NEBO_G108_ERROR_INVALID
.done:
    add rsp,520
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

; RDI session, RSI output record, RDX capacity -> total record bytes/error.
nebo_g108_snapshot:
    push rbx
    push r12
    push r13
    mov rbx,rdi
    mov r12,rsi
    mov r13,rdx
    call g108_session_validate
    test eax,eax
    jnz .done
    cmp qword [rbx+NEBO_G108_SESSION_STATE],NEBO_G108_STATE_CAPTURED
    je .state_ok
    cmp qword [rbx+NEBO_G108_SESSION_STATE],NEBO_G108_STATE_REPLAYED
    jne .state
.state_ok:
    test qword [rbx+NEBO_G108_SESSION_CAPABILITIES],NEBO_G108_CAP_SNAPSHOT
    jz .capability
    test r12,r12
    jz .invalid
    mov rax,[rbx+NEBO_G108_SESSION_LENGTH]
    test rax,rax
    jz .state
    add rax,NEBO_G108_RECORD_HEADER_SIZE
    cmp r13,rax
    jb .capacity
    mov r13,rax
    mov rax,NEBO_G108_RECORD_MAGIC_VALUE
    mov [r12+NEBO_G108_RECORD_MAGIC],rax
    mov rax,NEBO_G108_RECORD_SCHEMA_VALUE
    mov [r12+NEBO_G108_RECORD_SCHEMA],rax
    mov qword [r12+NEBO_G108_RECORD_VERSION],NEBO_G108_RECORD_VERSION_VALUE
    mov rax,[rbx+NEBO_G108_SESSION_TARGET]
    mov [r12+NEBO_G108_RECORD_TARGET],rax
    mov rax,[rbx+NEBO_G108_SESSION_SEED]
    mov [r12+NEBO_G108_RECORD_SEED],rax
    mov rax,[rbx+NEBO_G108_SESSION_TIME]
    mov [r12+NEBO_G108_RECORD_TIME],rax
    mov rax,[rbx+NEBO_G108_SESSION_LENGTH]
    mov [r12+NEBO_G108_RECORD_PAYLOAD_LEN],rax
    mov rax,[rbx+NEBO_G108_SESSION_DIGEST]
    mov [r12+NEBO_G108_RECORD_DIGEST],rax
    mov rax,[rbx+NEBO_G108_SESSION_FLAGS]
    mov [r12+NEBO_G108_RECORD_FLAGS],rax
    lea rdi,[r12+NEBO_G108_RECORD_HEADER_SIZE]
    lea rsi,[rbx+NEBO_G108_SESSION_BUFFER]
    mov rcx,[rbx+NEBO_G108_SESSION_LENGTH]
    rep movsb
    mov rax,r13
    jmp .done
.capacity:
    mov eax,-NEBO_G108_ERROR_CAPACITY
    jmp .done
.capability:
    mov eax,-NEBO_G108_ERROR_CAPABILITY
    jmp .done
.state:
    mov eax,-NEBO_G108_ERROR_STATE
    jmp .done
.invalid:
    mov eax,-NEBO_G108_ERROR_INVALID
.done:
    pop r13
    pop r12
    pop rbx
    ret

; RDI record, RSI total length -> 0 or negative schema/digest status.
nebo_g108_record_validate:
    push rbx
    push r12
    mov rbx,rdi
    mov r12,rsi
    test rbx,rbx
    jz .invalid
    cmp r12,NEBO_G108_RECORD_HEADER_SIZE+1
    jb .schema
    cmp r12,NEBO_G108_RECORD_MAX
    ja .limit
    mov rax,NEBO_G108_RECORD_MAGIC_VALUE
    cmp [rbx+NEBO_G108_RECORD_MAGIC],rax
    jne .schema
    mov rax,NEBO_G108_RECORD_SCHEMA_VALUE
    cmp [rbx+NEBO_G108_RECORD_SCHEMA],rax
    jne .schema
    cmp qword [rbx+NEBO_G108_RECORD_VERSION],NEBO_G108_RECORD_VERSION_VALUE
    jne .schema
    cmp qword [rbx+NEBO_G108_RECORD_TARGET],NEBO_G108_TARGET_MOCK
    jb .schema
    cmp qword [rbx+NEBO_G108_RECORD_TARGET],NEBO_G108_TARGET_MAX
    ja .schema
    mov rsi,[rbx+NEBO_G108_RECORD_PAYLOAD_LEN]
    test rsi,rsi
    jz .schema
    cmp rsi,NEBO_G108_CAPTURE_MAX
    ja .limit
    lea rax,[rsi+NEBO_G108_RECORD_HEADER_SIZE]
    cmp rax,r12
    jne .schema
    mov rax,[rbx+NEBO_G108_RECORD_FLAGS]
    test rax,~NEBO_G108_FLAG_ALL
    jnz .schema
    mov rax,[rbx+NEBO_G108_RECORD_SEED]
    test rax,rax
    jz .schema
    mov rcx,0xffffffff
    cmp rax,rcx
    ja .schema
    mov rax,[rbx+NEBO_G108_RECORD_TIME]
    test rax,rax
    jz .schema
    cmp rax,rcx
    ja .schema
    lea rdi,[rbx+NEBO_G108_RECORD_HEADER_SIZE]
    call g108_hash
    cmp rax,[rbx+NEBO_G108_RECORD_DIGEST]
    jne .digest
    xor eax,eax
    jmp .done
.digest:
    mov eax,-NEBO_G108_ERROR_DIGEST
    jmp .done
.schema:
    mov eax,-NEBO_G108_ERROR_SCHEMA
    jmp .done
.limit:
    mov eax,-NEBO_G108_ERROR_LIMIT
    jmp .done
.invalid:
    mov eax,-NEBO_G108_ERROR_INVALID
.done:
    pop r12
    pop rbx
    ret

; RDI snapshot, RSI length, RDX golden, RCX golden length -> 1/0/error.
nebo_g108_golden_compare:
    push rbx
    push r12
    push r13
    push r14
    sub rsp,8
    mov rbx,rdi
    mov r12,rsi
    mov r13,rdx
    mov r14,rcx
    call nebo_g108_record_validate
    test eax,eax
    jnz .done
    mov rdi,r13
    mov rsi,r14
    call nebo_g108_record_validate
    test eax,eax
    jnz .done
    cmp r12,r14
    jne .different
    mov rdi,rbx
    mov rsi,r13
    mov rcx,r12
    repe cmpsb
    jne .different
    mov eax,1
    jmp .done
.different:
    xor eax,eax
.done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; RDI record, RSI length, RDX output session -> payload length/error.
; Replay validates the complete record and only copies inert normalized bytes.
nebo_g108_replay:
    push rbx
    push r12
    push r13
    sub rsp,8
    mov rbx,rdi
    mov r12,rsi
    mov r13,rdx
    call nebo_g108_record_validate
    test eax,eax
    jnz .done
    test r13,r13
    jz .invalid
    mov rdi,r13
    xor eax,eax
    mov ecx,NEBO_G108_SESSION_SIZE/8
    rep stosq
    mov rax,NEBO_G108_SESSION_MAGIC_VALUE
    mov [r13+NEBO_G108_SESSION_MAGIC],rax
    mov rax,[rbx+NEBO_G108_RECORD_TARGET]
    mov [r13+NEBO_G108_SESSION_TARGET],rax
    mov rax,[rbx+NEBO_G108_RECORD_SEED]
    mov [r13+NEBO_G108_SESSION_SEED],rax
    mov rax,[rbx+NEBO_G108_RECORD_TIME]
    mov [r13+NEBO_G108_SESSION_TIME],rax
    mov qword [r13+NEBO_G108_SESSION_CAPABILITIES],NEBO_G108_CAP_REQUIRED
    mov rax,[rbx+NEBO_G108_RECORD_FLAGS]
    mov [r13+NEBO_G108_SESSION_FLAGS],rax
    mov qword [r13+NEBO_G108_SESSION_STATE],NEBO_G108_STATE_REPLAYED
    mov rax,[rbx+NEBO_G108_RECORD_PAYLOAD_LEN]
    mov [r13+NEBO_G108_SESSION_LENGTH],rax
    mov rcx,rax
    mov rax,[rbx+NEBO_G108_RECORD_DIGEST]
    mov [r13+NEBO_G108_SESSION_DIGEST],rax
    mov qword [r13+NEBO_G108_SESSION_RECEIVER_EVALS],1
    lea rdi,[r13+NEBO_G108_SESSION_BUFFER]
    lea rsi,[rbx+NEBO_G108_RECORD_HEADER_SIZE]
    rep movsb
    mov rax,[r13+NEBO_G108_SESSION_LENGTH]
    jmp .done
.invalid:
    mov eax,-NEBO_G108_ERROR_INVALID
.done:
    add rsp,8
    pop r13
    pop r12
    pop rbx
    ret

; RDI session, RSI expected bytes, RDX length -> 1/0/error.
nebo_g108_assert_equals:
    push rbx
    mov rbx,rdi
    call g108_session_validate
    test eax,eax
    jnz .done
    cmp qword [rbx+NEBO_G108_SESSION_STATE],NEBO_G108_STATE_CAPTURED
    je .state_ok
    cmp qword [rbx+NEBO_G108_SESSION_STATE],NEBO_G108_STATE_REPLAYED
    jne .state
.state_ok:
    test qword [rbx+NEBO_G108_SESSION_CAPABILITIES],NEBO_G108_CAP_ASSERT
    jz .capability
    test rsi,rsi
    jz .invalid
    cmp rdx,[rbx+NEBO_G108_SESSION_LENGTH]
    jne .different
    lea rdi,[rbx+NEBO_G108_SESSION_BUFFER]
    mov rcx,rdx
    repe cmpsb
    jne .different
    inc qword [rbx+NEBO_G108_SESSION_ASSERTIONS]
    mov eax,1
    jmp .done
.different:
    inc qword [rbx+NEBO_G108_SESSION_ASSERTIONS]
    xor eax,eax
    jmp .done
.capability:
    mov eax,-NEBO_G108_ERROR_CAPABILITY
    jmp .done
.state:
    mov eax,-NEBO_G108_ERROR_STATE
    jmp .done
.invalid:
    mov eax,-NEBO_G108_ERROR_INVALID
.done:
    pop rbx
    ret

; RDI session, RSI needle, RDX length -> 1/0/error.
nebo_g108_assert_contains:
    push rbx
    push r12
    push r13
    mov rbx,rdi
    mov r12,rsi
    mov r13,rdx
    call g108_session_validate
    test eax,eax
    jnz .done
    cmp qword [rbx+NEBO_G108_SESSION_STATE],NEBO_G108_STATE_CAPTURED
    je .state_ok
    cmp qword [rbx+NEBO_G108_SESSION_STATE],NEBO_G108_STATE_REPLAYED
    jne .state
.state_ok:
    test qword [rbx+NEBO_G108_SESSION_CAPABILITIES],NEBO_G108_CAP_ASSERT
    jz .capability
    test r12,r12
    jz .invalid
    test r13,r13
    jz .invalid
    mov r8,[rbx+NEBO_G108_SESSION_LENGTH]
    cmp r13,r8
    ja .absent
    lea r9,[rbx+NEBO_G108_SESSION_BUFFER]
    xor r10d,r10d
.outer:
    mov rax,r8
    sub rax,r13
    cmp r10,rax
    ja .absent
    xor r11d,r11d
.inner:
    cmp r11,r13
    je .found
    mov rcx,r10
    add rcx,r11
    mov al,[r9+rcx]
    cmp al,[r12+r11]
    jne .next
    inc r11
    jmp .inner
.next:
    inc r10
    jmp .outer
.found:
    inc qword [rbx+NEBO_G108_SESSION_ASSERTIONS]
    mov eax,1
    jmp .done
.absent:
    inc qword [rbx+NEBO_G108_SESSION_ASSERTIONS]
    xor eax,eax
    jmp .done
.capability:
    mov eax,-NEBO_G108_ERROR_CAPABILITY
    jmp .done
.state:
    mov eax,-NEBO_G108_ERROR_STATE
    jmp .done
.invalid:
    mov eax,-NEBO_G108_ERROR_INVALID
.done:
    pop r13
    pop r12
    pop rbx
    ret

; RDI session -> status. Close is exact-once and clears captured bytes.
nebo_g108_session_close:
    push rbx
    mov rbx,rdi
    call g108_session_validate
    test eax,eax
    jnz .done
    cmp qword [rbx+NEBO_G108_SESSION_STATE],NEBO_G108_STATE_CLOSED
    je .state
    lea rdi,[rbx+NEBO_G108_SESSION_BUFFER]
    xor eax,eax
    mov ecx,NEBO_G108_CAPTURE_MAX/8
    rep stosq
    mov qword [rbx+NEBO_G108_SESSION_LENGTH],0
    mov qword [rbx+NEBO_G108_SESSION_DIGEST],0
    mov qword [rbx+NEBO_G108_SESSION_STATE],NEBO_G108_STATE_CLOSED
    xor eax,eax
    jmp .done
.state:
    mov eax,-NEBO_G108_ERROR_STATE
.done:
    pop rbx
    ret

; RDI negative status -> stable diagnostic ID, zero for success.
nebo_g108_status_diagnostic:
    test edi,edi
    jz .success
    neg edi
    cmp edi,NEBO_G108_ERROR_INVALID
    jb .unknown
    cmp edi,NEBO_G108_ERROR_TARGET
    ja .unknown
    lea eax,[rdi+10800]
    ret
.success:
    xor eax,eax
    ret
.unknown:
    mov eax,10899
    ret

; Compatibility entry points retained for the pre-G108 internal fronts. They
; validate bounded capacity/length/target but are not used as conformance proof.
global nebo_capture_validate
global nebo_mock_silent_validate
global nebo_snapshot_golden_validate
global nebo_record_replay_validate
global nebo_normalize_output_validate
global nebo_assertions_validate
global nebo_headless_live_matrix_validate
global nebo_deterministic_time_seed_validate
global nebo_capture_mock_snapshot_golden_record_e_replay_closeout_contract_validate
nebo_capture_validate:
nebo_mock_silent_validate:
nebo_snapshot_golden_validate:
nebo_record_replay_validate:
nebo_normalize_output_validate:
nebo_assertions_validate:
nebo_headless_live_matrix_validate:
nebo_deterministic_time_seed_validate:
nebo_capture_mock_snapshot_golden_record_e_replay_closeout_contract_validate:
    cmp rdi,1
    jb .legacy_invalid
    cmp rdi,4096
    ja .legacy_invalid
    cmp rsi,rdi
    ja .legacy_invalid
    cmp rdx,NEBO_G108_TARGET_MOCK
    jb .legacy_invalid
    cmp rdx,NEBO_G108_TARGET_MAX
    ja .legacy_invalid
    xor eax,eax
    ret
.legacy_invalid:
    mov eax,-NEBO_G108_ERROR_INVALID
    ret
