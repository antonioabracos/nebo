; Nebo FakePlatform/FakeClock — deterministic headless adapter for MF042
bits 64
default rel

%include "runtime/console/handles/console_handle.inc"
%include "runtime/console/queues/console_queue.inc"
%include "runtime/console/domain/console_domain.inc"
%include "runtime/console/platform/fake/fake_platform.inc"

global nebo_fake_clock_init
global nebo_fake_clock_read
global nebo_fake_clock_advance
global nebo_fake_platform_init
global nebo_fake_platform_validate
global nebo_fake_platform_mount
global nebo_fake_platform_inject_event
global nebo_fake_platform_close
global nebo_fake_platform_state_hash

section .text

; fake_clock_init(clock*, initial_now, deterministic_step)
nebo_fake_clock_init:
    test rdi, rdi
    jz .clock_init_invalid
    mov r8, rdi
    xor eax, eax
    mov ecx, NEBO_FAKE_CLOCK_QWORDS
    cld
    rep stosq
    test rdx, rdx
    jz .clock_init_invalid_after_zero
    mov [r8+NEBO_FAKE_CLOCK_NOW_OFFSET], rsi
    mov [r8+NEBO_FAKE_CLOCK_STEP_OFFSET], rdx
    mov qword [r8+NEBO_FAKE_CLOCK_SEQUENCE_OFFSET], 0
    mov qword [r8+NEBO_FAKE_CLOCK_STATE_OFFSET], NEBO_FAKE_CLOCK_STATE_READY
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.clock_init_invalid_after_zero:
.clock_init_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; fake_clock_read(clock*, out_now*)
nebo_fake_clock_read:
    test rdi, rdi
    jz .clock_read_invalid
    test rsi, rsi
    jz .clock_read_invalid
    mov qword [rsi], 0
    cmp qword [rdi+NEBO_FAKE_CLOCK_STATE_OFFSET], NEBO_FAKE_CLOCK_STATE_READY
    jne .clock_read_state
    mov rax, [rdi+NEBO_FAKE_CLOCK_NOW_OFFSET]
    mov [rsi], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.clock_read_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.clock_read_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; fake_clock_advance(clock*, delta, out_now*)
nebo_fake_clock_advance:
    test rdi, rdi
    jz .clock_advance_invalid
    test rdx, rdx
    jz .clock_advance_invalid
    mov qword [rdx], 0
    cmp qword [rdi+NEBO_FAKE_CLOCK_STATE_OFFSET], NEBO_FAKE_CLOCK_STATE_READY
    jne .clock_advance_state
    mov rax, [rdi+NEBO_FAKE_CLOCK_NOW_OFFSET]
    add rax, rsi
    jc .clock_advance_limit
    mov [rdi+NEBO_FAKE_CLOCK_NOW_OFFSET], rax
    inc qword [rdi+NEBO_FAKE_CLOCK_SEQUENCE_OFFSET]
    mov [rdx], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.clock_advance_limit:
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    ret
.clock_advance_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.clock_advance_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; fake_platform_init(platform*, clock*)
nebo_fake_platform_init:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .platform_init_invalid
    mov rdi, r12
    xor eax, eax
    mov ecx, NEBO_FAKE_PLATFORM_QWORDS
    cld
    rep stosq
    test r13, r13
    jz .platform_init_invalid
    cmp qword [r13+NEBO_FAKE_CLOCK_STATE_OFFSET], NEBO_FAKE_CLOCK_STATE_READY
    jne .platform_init_state
    mov [r12+NEBO_FAKE_PLATFORM_CLOCK_PTR_OFFSET], r13
    mov qword [r12+NEBO_FAKE_PLATFORM_STATE_OFFSET], NEBO_FAKE_PLATFORM_STATE_READY
    mov qword [r12+NEBO_FAKE_PLATFORM_FLAGS_OFFSET], NEBO_FAKE_PLATFORM_REQUIRED_FLAGS
    mov qword [r12+NEBO_FAKE_PLATFORM_NEXT_WINDOW_ID_OFFSET], 1
    mov qword [r12+NEBO_FAKE_PLATFORM_ACTIVE_WINDOWS_OFFSET], 0
    mov qword [r12+NEBO_FAKE_PLATFORM_MOUNT_COUNT_OFFSET], 0
    mov qword [r12+NEBO_FAKE_PLATFORM_CLOSE_COUNT_OFFSET], 0
    mov qword [r12+NEBO_FAKE_PLATFORM_EVENT_SEQUENCE_OFFSET], 0
    mov eax, NEBO_FAKE_PLATFORM_HASH_FNV1A32_OFFSET_BASIS
    mov [r12+NEBO_FAKE_PLATFORM_TRACE_HASH_OFFSET], rax
    mov qword [r12+NEBO_FAKE_PLATFORM_LAST_EVENT_KIND_OFFSET], 0
    mov qword [r12+NEBO_FAKE_PLATFORM_LAST_HANDLE_OFFSET], 0
    mov qword [r12+NEBO_FAKE_PLATFORM_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .platform_init_done
.platform_init_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .platform_init_done
.platform_init_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.platform_init_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; fake_platform_validate(platform*)
nebo_fake_platform_validate:
    test rdi, rdi
    jz .platform_validate_invalid
    cmp qword [rdi+NEBO_FAKE_PLATFORM_STATE_OFFSET], NEBO_FAKE_PLATFORM_STATE_READY
    jne .platform_validate_state
    mov rax, [rdi+NEBO_FAKE_PLATFORM_FLAGS_OFFSET]
    and rax, NEBO_FAKE_PLATFORM_REQUIRED_FLAGS
    cmp rax, NEBO_FAKE_PLATFORM_REQUIRED_FLAGS
    jne .platform_validate_state
    mov rax, [rdi+NEBO_FAKE_PLATFORM_CLOCK_PTR_OFFSET]
    test rax, rax
    jz .platform_validate_invalid
    cmp qword [rax+NEBO_FAKE_CLOCK_STATE_OFFSET], NEBO_FAKE_CLOCK_STATE_READY
    jne .platform_validate_state
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.platform_validate_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.platform_validate_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; fake_platform_mount(platform*, domain*) — emits WINDOW_MOUNTED only.
nebo_fake_platform_mount:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    call nebo_fake_platform_validate
    test eax, eax
    jnz .mount_done
    test r13, r13
    jz .mount_invalid
    cmp dword [r13+NEBO_CONSOLE_DOMAIN_STATE_OFFSET], NEBO_CONSOLE_DOMAIN_STATE_READY
    jne .mount_state
    cmp dword [r13+NEBO_CONSOLE_DOMAIN_LIFECYCLE_OFFSET], NEBO_CONSOLE_LIFECYCLE_MOUNT_REQUESTED
    jne .mount_state
    mov rax, [r12+NEBO_FAKE_PLATFORM_ACTIVE_WINDOWS_OFFSET]
    cmp rax, NEBO_FAKE_PLATFORM_MAX_WINDOWS
    jae .mount_limit
    mov r14, [r12+NEBO_FAKE_PLATFORM_NEXT_WINDOW_ID_OFFSET]
    test r14, r14
    jz .mount_limit
    cmp r14, -1
    je .mount_limit
    mov r15, [r12+NEBO_FAKE_PLATFORM_EVENT_SEQUENCE_OFFSET]
    inc r15
    jz .mount_limit
    mov rax, [r12+NEBO_FAKE_PLATFORM_CLOCK_PTR_OFFSET]
    mov rbx, [rax+NEBO_FAKE_CLOCK_NOW_OFFSET]
    mov rdx, rbx
    add rdx, [rax+NEBO_FAKE_CLOCK_STEP_OFFSET]
    jc .mount_limit
    mov rdi, rsp
    xor eax, eax
    mov ecx, NEBO_CONSOLE_EVENT_DESCRIPTOR_QWORDS
    cld
    rep stosq
    mov rax, [r13+NEBO_CONSOLE_DOMAIN_HANDLE_OFFSET]
    mov [rsp+NEBO_CONSOLE_EVENT_HANDLE_OFFSET], rax
    mov dword [rsp+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_MOUNTED
    mov [rsp+NEBO_CONSOLE_EVENT_TIMESTAMP_OFFSET], rbx
    mov [rsp+NEBO_CONSOLE_EVENT_SEQUENCE_OFFSET], r15
    mov [rsp+NEBO_CONSOLE_EVENT_PAYLOAD0_OFFSET], r14
    mov rdi, r13
    mov rsi, rsp
    call nebo_console_domain_event_enqueue
    test eax, eax
    jnz .mount_status
    mov [r12+NEBO_FAKE_PLATFORM_EVENT_SEQUENCE_OFFSET], r15
    inc qword [r12+NEBO_FAKE_PLATFORM_NEXT_WINDOW_ID_OFFSET]
    inc qword [r12+NEBO_FAKE_PLATFORM_ACTIVE_WINDOWS_OFFSET]
    inc qword [r12+NEBO_FAKE_PLATFORM_MOUNT_COUNT_OFFSET]
    mov qword [r12+NEBO_FAKE_PLATFORM_LAST_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_MOUNTED
    mov rax, [r13+NEBO_CONSOLE_DOMAIN_HANDLE_OFFSET]
    mov [r12+NEBO_FAKE_PLATFORM_LAST_HANDLE_OFFSET], rax
    mov qword [r12+NEBO_FAKE_PLATFORM_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov rdi, r12
    mov rsi, NEBO_CONSOLE_EVENT_WINDOW_MOUNTED
    mov rdx, r15
    call nebo_fake_platform_trace_pair_internal
    mov rax, [r12+NEBO_FAKE_PLATFORM_CLOCK_PTR_OFFSET]
    mov rdx, [rax+NEBO_FAKE_CLOCK_STEP_OFFSET]
    add [rax+NEBO_FAKE_CLOCK_NOW_OFFSET], rdx
    inc qword [rax+NEBO_FAKE_CLOCK_SEQUENCE_OFFSET]
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .mount_done
.mount_status:
    mov [r12+NEBO_FAKE_PLATFORM_LAST_STATUS_OFFSET], rax
    jmp .mount_done
.mount_limit:
    mov qword [r12+NEBO_FAKE_PLATFORM_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .mount_done
.mount_state:
    mov qword [r12+NEBO_FAKE_PLATFORM_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_BAD_STATE
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .mount_done
.mount_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.mount_done:
    add rsp, NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; fake_platform_inject_event(platform*, domain*, kind, payload0, payload1)
nebo_fake_platform_inject_event:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
    mov r12, rdi
    mov r13, rsi
    mov r14d, edx
    mov r15, rcx
    mov rbx, r8
    mov rdi, r12
    call nebo_fake_platform_validate
    test eax, eax
    jnz .inject_done
    test r13, r13
    jz .inject_invalid
    cmp r14d, NEBO_CONSOLE_EVENT_KIND_MIN
    jb .inject_invalid
    cmp r14d, NEBO_CONSOLE_EVENT_KIND_MAX
    ja .inject_invalid
    mov rax, [r12+NEBO_FAKE_PLATFORM_EVENT_SEQUENCE_OFFSET]
    inc rax
    jz .inject_limit
    ; Preserve the accepted event sequence across descriptor zeroing.  RAX is
    ; cleared by REP STOSQ preparation below, so the sequence must live in a
    ; separate caller-saved register until it is copied into the descriptor
    ; and then into callee-saved R15 before the enqueue call.
    mov r10, rax
    mov rdx, [r12+NEBO_FAKE_PLATFORM_CLOCK_PTR_OFFSET]
    mov rcx, [rdx+NEBO_FAKE_CLOCK_NOW_OFFSET]
    mov r9, rcx
    add r9, [rdx+NEBO_FAKE_CLOCK_STEP_OFFSET]
    jc .inject_limit
    mov rdi, rsp
    xor eax, eax
    mov ecx, NEBO_CONSOLE_EVENT_DESCRIPTOR_QWORDS
    cld
    rep stosq
    mov rcx, [rdx+NEBO_FAKE_CLOCK_NOW_OFFSET]
    mov rdx, [r13+NEBO_CONSOLE_DOMAIN_HANDLE_OFFSET]
    mov [rsp+NEBO_CONSOLE_EVENT_HANDLE_OFFSET], rdx
    mov [rsp+NEBO_CONSOLE_EVENT_KIND_OFFSET], r14d
    mov [rsp+NEBO_CONSOLE_EVENT_TIMESTAMP_OFFSET], rcx
    mov [rsp+NEBO_CONSOLE_EVENT_SEQUENCE_OFFSET], r10
    mov [rsp+NEBO_CONSOLE_EVENT_PAYLOAD0_OFFSET], r15
    mov [rsp+NEBO_CONSOLE_EVENT_PAYLOAD1_OFFSET], rbx
    mov r15, r10
    mov rdi, r13
    mov rsi, rsp
    call nebo_console_domain_event_enqueue
    test eax, eax
    jnz .inject_status
    mov [r12+NEBO_FAKE_PLATFORM_EVENT_SEQUENCE_OFFSET], r15
    mov [r12+NEBO_FAKE_PLATFORM_LAST_EVENT_KIND_OFFSET], r14
    mov rax, [r13+NEBO_CONSOLE_DOMAIN_HANDLE_OFFSET]
    mov [r12+NEBO_FAKE_PLATFORM_LAST_HANDLE_OFFSET], rax
    mov qword [r12+NEBO_FAKE_PLATFORM_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov rdi, r12
    mov rsi, r14
    mov rdx, r15
    call nebo_fake_platform_trace_pair_internal
    mov rax, [r12+NEBO_FAKE_PLATFORM_CLOCK_PTR_OFFSET]
    mov rdx, [rax+NEBO_FAKE_CLOCK_STEP_OFFSET]
    add [rax+NEBO_FAKE_CLOCK_NOW_OFFSET], rdx
    inc qword [rax+NEBO_FAKE_CLOCK_SEQUENCE_OFFSET]
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .inject_done
.inject_status:
    mov [r12+NEBO_FAKE_PLATFORM_LAST_STATUS_OFFSET], rax
    jmp .inject_done
.inject_limit:
    mov qword [r12+NEBO_FAKE_PLATFORM_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .inject_done
.inject_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.inject_done:
    add rsp, NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; fake_platform_close(platform*, domain*)
nebo_fake_platform_close:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    call nebo_fake_platform_validate
    test eax, eax
    jnz .close_done
    test r13, r13
    jz .close_invalid
    cmp qword [r13+NEBO_CONSOLE_DOMAIN_FAKE_WINDOW_HANDLE_OFFSET], 0
    je .close_state
    cmp qword [r12+NEBO_FAKE_PLATFORM_ACTIVE_WINDOWS_OFFSET], 0
    je .close_state
    dec qword [r12+NEBO_FAKE_PLATFORM_ACTIVE_WINDOWS_OFFSET]
    inc qword [r12+NEBO_FAKE_PLATFORM_CLOSE_COUNT_OFFSET]
    mov qword [r12+NEBO_FAKE_PLATFORM_LAST_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_CLOSE_REQUESTED
    mov rax, [r13+NEBO_CONSOLE_DOMAIN_HANDLE_OFFSET]
    mov [r12+NEBO_FAKE_PLATFORM_LAST_HANDLE_OFFSET], rax
    mov qword [r12+NEBO_FAKE_PLATFORM_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov rdi, r12
    mov esi, NEBO_CONSOLE_EVENT_WINDOW_CLOSE_REQUESTED
    mov rdx, [r12+NEBO_FAKE_PLATFORM_CLOSE_COUNT_OFFSET]
    call nebo_fake_platform_trace_pair_internal
    mov qword [r13+NEBO_CONSOLE_DOMAIN_FAKE_WINDOW_HANDLE_OFFSET], 0
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .close_done
.close_state:
    mov qword [r12+NEBO_FAKE_PLATFORM_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_BAD_STATE
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .close_done
.close_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.close_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Canonical pointer-free platform/clock state hash.
nebo_fake_platform_state_hash:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov rdi, r12
    call nebo_fake_platform_validate
    test eax, eax
    jnz .platform_hash_invalid
    mov eax, NEBO_FAKE_PLATFORM_HASH_FNV1A32_OFFSET_BASIS
    mov rdx, [r12+NEBO_FAKE_PLATFORM_STATE_OFFSET]
    call nebo_fake_platform_hash_qword_internal
    mov rdx, [r12+NEBO_FAKE_PLATFORM_FLAGS_OFFSET]
    call nebo_fake_platform_hash_qword_internal
    mov rdx, [r12+NEBO_FAKE_PLATFORM_NEXT_WINDOW_ID_OFFSET]
    call nebo_fake_platform_hash_qword_internal
    mov rdx, [r12+NEBO_FAKE_PLATFORM_ACTIVE_WINDOWS_OFFSET]
    call nebo_fake_platform_hash_qword_internal
    mov rdx, [r12+NEBO_FAKE_PLATFORM_MOUNT_COUNT_OFFSET]
    call nebo_fake_platform_hash_qword_internal
    mov rdx, [r12+NEBO_FAKE_PLATFORM_CLOSE_COUNT_OFFSET]
    call nebo_fake_platform_hash_qword_internal
    mov rdx, [r12+NEBO_FAKE_PLATFORM_EVENT_SEQUENCE_OFFSET]
    call nebo_fake_platform_hash_qword_internal
    mov rdx, [r12+NEBO_FAKE_PLATFORM_TRACE_HASH_OFFSET]
    call nebo_fake_platform_hash_qword_internal
    mov rdx, [r12+NEBO_FAKE_PLATFORM_LAST_EVENT_KIND_OFFSET]
    call nebo_fake_platform_hash_qword_internal
    mov rdx, [r12+NEBO_FAKE_PLATFORM_LAST_HANDLE_OFFSET]
    call nebo_fake_platform_hash_qword_internal
    mov r13, [r12+NEBO_FAKE_PLATFORM_CLOCK_PTR_OFFSET]
    mov rdx, [r13+NEBO_FAKE_CLOCK_NOW_OFFSET]
    call nebo_fake_platform_hash_qword_internal
    mov rdx, [r13+NEBO_FAKE_CLOCK_STEP_OFFSET]
    call nebo_fake_platform_hash_qword_internal
    mov rdx, [r13+NEBO_FAKE_CLOCK_SEQUENCE_OFFSET]
    call nebo_fake_platform_hash_qword_internal
    test eax, eax
    jnz .platform_hash_done
    mov eax, 1
    jmp .platform_hash_done
.platform_hash_invalid:
    xor eax, eax
.platform_hash_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Internal pointer-free trace update over two qwords.
; RDI=platform*, RSI=value0, RDX=value1.
nebo_fake_platform_trace_pair_internal:
    push rbx
    mov eax, [rdi+NEBO_FAKE_PLATFORM_TRACE_HASH_OFFSET]
    test eax, eax
    jnz .platform_trace_seeded
    mov eax, NEBO_FAKE_PLATFORM_HASH_FNV1A32_OFFSET_BASIS
.platform_trace_seeded:
    mov r8, rdx
    mov rdx, rsi
    call nebo_fake_platform_hash_qword_internal
    mov rdx, r8
    call nebo_fake_platform_hash_qword_internal
    mov [rdi+NEBO_FAKE_PLATFORM_TRACE_HASH_OFFSET], rax
    pop rbx
    ret
nebo_fake_platform_hash_qword_internal:
    push rcx
    mov ecx, 8
.platform_hash_byte:
    movzx esi, dl
    xor eax, esi
    imul eax, eax, NEBO_FAKE_PLATFORM_HASH_FNV1A32_PRIME
    shr rdx, 8
    dec ecx
    jnz .platform_hash_byte
    pop rcx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
