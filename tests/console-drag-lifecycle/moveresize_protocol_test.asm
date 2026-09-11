; Nebo Console moveresize lifecycle — exact direct-X11 protocol/state oracle.
bits 64
default rel

%include "runtime/console/platform/adapter_contract.inc"
%include "runtime/console/platform/linux-x11-ewmh-direct-v0/x11_adapter.inc"

extern nebo_platform_report_init
extern nebo_x11_adapter_begin_window_drag
extern nebo_x11_adapter_begin_window_resize
extern nebo_x11_adapter_normalize_event
extern nebo_x11_adapter_request_close

global _start

%define SYS_READ 0
%define SYS_CLOSE 3
%define SYS_PIPE 22
%define SYS_SOCKETPAIR 53
%define SYS_EXIT 60
%define TEST_ROOT_XID 0x10203040
%define TEST_WINDOW_XID 0x50607080
%define TEST_WINDOW2_XID 0x50607081
%define TEST_MOVERESIZE_ATOM 0x90a0b0c0

section .bss align=64
adapter: resb NEBO_X11_ADAPTER_SIZE
window: resb NEBO_X11_WINDOW_SIZE
window2: resb NEBO_X11_WINDOW_SIZE
event: resb NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
raw: resb NEBO_X11_EVENT_SIZE
scratch: resb NEBO_X11_MIN_SCRATCH_CAPACITY
wire: resb 64
socket_fds: resd 2
pipe_fds: resd 2
expected_root_x: resd 1
expected_root_y: resd 1
expected_direction: resd 1
expected_window_xid: resd 1
saved_sequence: resq 1
saved_generation: resq 1

section .text
_start:
    mov ebp, 10
    call initialize_fixture
    test eax, eax
    jnz test_fail

    ; DR-001/002: negative root coordinates remain exact signed dwords and the
    ; core ungrab is the first complete request on the stream.
    mov ebp, 11
    mov dword [rel expected_root_x], -50
    mov dword [rel expected_root_y], -25
    mov dword [rel expected_direction], NEBO_X11_NET_WM_MOVERESIZE_MOVE
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, -50
    mov ecx, -25
    mov r8d, 1
    call nebo_x11_adapter_begin_window_drag
    test eax, eax
    jnz test_fail
    call verify_start_wire
    test eax, eax
    jnz test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 1
    jne test_fail
    cmp qword [rel window+NEBO_X11_WINDOW_MOVERESIZE_GENERATION_OFFSET], 1
    jne test_fail
    cmp qword [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET], 2
    jne test_fail

    ; DR-003: an unrelated release cannot cancel the primary transaction.
    mov ebp, 12
    mov edi, NEBO_X11_EVENT_BUTTON_RELEASE
    mov esi, 2
    call inject_button
    test eax, eax
    jnz test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 1
    jne test_fail
    cmp qword [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET], 2
    jne test_fail

    ; DR-004: geometry progress followed by matching release completes without
    ; emitting a redundant CANCEL.
    mov ebp, 13
    call inject_configure
    test eax, eax
    jnz test_fail
    test dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_FLAGS_OFFSET], NEBO_X11_WINDOW_MOVERESIZE_FLAG_WM_PROGRESS
    jz test_fail
    mov edi, NEBO_X11_EVENT_BUTTON_RELEASE
    mov esi, 1
    call inject_button
    test eax, eax
    jnz test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne test_fail
    cmp qword [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET], 2
    jne test_fail

    ; DR-005: duplicate/stale release is an ordinary pointer event.
    mov ebp, 14
    mov edi, NEBO_X11_EVENT_BUTTON_RELEASE
    mov esi, 1
    call inject_button
    test eax, eax
    jnz test_fail
    cmp qword [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET], 2
    jne test_fail

    ; DR-006: no-progress matching release emits one bounded direction-11
    ; cancellation and leaves no active transaction.
    mov ebp, 15
    mov dword [rel expected_root_x], 101
    mov dword [rel expected_root_y], 202
    mov dword [rel expected_direction], NEBO_X11_NET_WM_MOVERESIZE_MOVE
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 101
    mov ecx, 202
    mov r8d, 1
    call nebo_x11_adapter_begin_window_drag
    test eax, eax
    jnz test_fail
    call verify_start_wire
    test eax, eax
    jnz test_fail
    mov edi, NEBO_X11_EVENT_BUTTON_RELEASE
    mov esi, 1
    call inject_button
    test eax, eax
    jnz test_fail
    call verify_cancel_wire
    test eax, eax
    jnz test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne test_fail

    ; DR-007..014: all eight resize directions use the same ordered lifecycle.
    mov ebp, 20
    xor r12d, r12d
.direction_loop:
    mov dword [rel expected_root_x], 303
    mov dword [rel expected_root_y], 404
    mov [rel expected_direction], r12d
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 303
    mov ecx, 404
    mov r8d, r12d
    mov r9d, 1
    call nebo_x11_adapter_begin_window_resize
    test eax, eax
    jnz test_fail
    call verify_start_wire
    test eax, eax
    jnz test_fail
    mov edi, NEBO_X11_EVENT_BUTTON_RELEASE
    mov esi, 1
    call inject_button
    test eax, eax
    jnz test_fail
    call verify_cancel_wire
    test eax, eax
    jnz test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne test_fail
    inc r12d
    inc ebp
    cmp r12d, 8
    jb .direction_loop

    ; Per-window records permit independent transactions without cross-window
    ; contamination on the shared ordered connection.
    mov ebp, 29
    mov dword [rel expected_root_x], 450
    mov dword [rel expected_root_y], 460
    mov dword [rel expected_direction], NEBO_X11_NET_WM_MOVERESIZE_MOVE
    mov dword [rel expected_window_xid], TEST_WINDOW_XID
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 450
    mov ecx, 460
    mov r8d, 1
    call nebo_x11_adapter_begin_window_drag
    test eax, eax
    jnz test_fail
    call verify_start_wire
    test eax, eax
    jnz test_fail
    mov dword [rel expected_root_x], 470
    mov dword [rel expected_root_y], 480
    mov dword [rel expected_direction], NEBO_X11_NET_WM_MOVERESIZE_SIZE_RIGHT
    mov dword [rel expected_window_xid], TEST_WINDOW2_XID
    lea rdi, [rel adapter]
    lea rsi, [rel window2]
    mov edx, 470
    mov ecx, 480
    mov r8d, NEBO_X11_NET_WM_MOVERESIZE_SIZE_RIGHT
    mov r9d, 1
    call nebo_x11_adapter_begin_window_resize
    test eax, eax
    jnz test_fail
    call verify_start_wire
    test eax, eax
    jnz test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 1
    jne test_fail
    cmp dword [rel window2+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 1
    jne test_fail
    lea rdi, [rel adapter]
    lea rsi, [rel window2]
    lea rdx, [rel event]
    call nebo_x11_adapter_request_close
    test eax, eax
    jnz test_fail
    call verify_cancel_wire
    test eax, eax
    jnz test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 1
    jne test_fail
    cmp dword [rel window2+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne test_fail
    and dword [rel window2+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], ~NEBO_X11_WINDOW_NATIVE_FLAG_CLOSE_REQUESTED
    mov dword [rel window2+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    mov dword [rel expected_root_x], 450
    mov dword [rel expected_root_y], 460
    mov dword [rel expected_window_xid], TEST_WINDOW_XID
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel event]
    call nebo_x11_adapter_request_close
    test eax, eax
    jnz test_fail
    call verify_cancel_wire
    test eax, eax
    jnz test_fail
    and dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], ~NEBO_X11_WINDOW_NATIVE_FLAG_CLOSE_REQUESTED
    mov dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE

    ; DR-015: a direct nested begin is rejected without a write or generation.
    mov ebp, 30
    mov dword [rel expected_root_x], 505
    mov dword [rel expected_root_y], 606
    mov dword [rel expected_direction], NEBO_X11_NET_WM_MOVERESIZE_MOVE
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 505
    mov ecx, 606
    mov r8d, 1
    call nebo_x11_adapter_begin_window_drag
    test eax, eax
    jnz test_fail
    call verify_start_wire
    test eax, eax
    jnz test_fail
    mov rax, [rel window+NEBO_X11_WINDOW_MOVERESIZE_GENERATION_OFFSET]
    mov [rel saved_generation], rax
    mov rax, [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    mov [rel saved_sequence], rax
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 1
    mov ecx, 2
    mov r8d, 1
    call nebo_x11_adapter_begin_window_drag
    cmp eax, NEBO_PLATFORM_STATUS_BAD_STATE
    jne test_fail
    mov rax, [rel saved_generation]
    cmp [rel window+NEBO_X11_WINDOW_MOVERESIZE_GENERATION_OFFSET], rax
    jne test_fail
    mov rax, [rel saved_sequence]
    cmp [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET], rax
    jne test_fail
    mov edi, NEBO_X11_EVENT_BUTTON_RELEASE
    mov esi, 1
    call inject_button
    test eax, eax
    jnz test_fail
    call verify_cancel_wire
    test eax, eax
    jnz test_fail

    ; DR-016: delivery of a new ButtonPress reconciles a release consumed by WM.
    mov ebp, 31
    mov dword [rel expected_root_x], 707
    mov dword [rel expected_root_y], 808
    mov dword [rel expected_direction], NEBO_X11_NET_WM_MOVERESIZE_MOVE
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 707
    mov ecx, 808
    mov r8d, 1
    call nebo_x11_adapter_begin_window_drag
    test eax, eax
    jnz test_fail
    call verify_start_wire
    test eax, eax
    jnz test_fail
    mov edi, NEBO_X11_EVENT_BUTTON_PRESS
    mov esi, 2
    call inject_button
    test eax, eax
    jnz test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 1
    jne test_fail
    mov edi, NEBO_X11_EVENT_BUTTON_PRESS
    mov esi, 1
    call inject_button
    test eax, eax
    jnz test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne test_fail

    ; Bounds reject generation wrap, non-primary buttons and resize direction 8
    ; before any protocol write.
    mov ebp, 32
    mov rax, [rel window+NEBO_X11_WINDOW_MOVERESIZE_GENERATION_OFFSET]
    mov [rel saved_generation], rax
    mov qword [rel window+NEBO_X11_WINDOW_MOVERESIZE_GENERATION_OFFSET], -1
    mov rax, [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    mov [rel saved_sequence], rax
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 1
    mov ecx, 2
    mov r8d, 1
    call nebo_x11_adapter_begin_window_drag
    cmp eax, NEBO_PLATFORM_STATUS_BAD_STATE
    jne test_fail
    mov rax, [rel saved_generation]
    mov [rel window+NEBO_X11_WINDOW_MOVERESIZE_GENERATION_OFFSET], rax
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 1
    mov ecx, 2
    mov r8d, 2
    call nebo_x11_adapter_begin_window_drag
    cmp eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
    jne test_fail
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 1
    mov ecx, 2
    mov r8d, NEBO_X11_NET_WM_MOVERESIZE_MOVE
    mov r9d, 1
    call nebo_x11_adapter_begin_window_resize
    cmp eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
    jne test_fail
    mov rax, [rel saved_sequence]
    cmp [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET], rax
    jne test_fail

    ; Ungrab write failure: no ClientMessage, no active/partial transaction.
    mov ebp, 33
    mov eax, SYS_PIPE
    lea rdi, [rel pipe_fds]
    syscall
    test eax, eax
    js test_fail
    mov rax, [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    mov [rel saved_sequence], rax
    mov eax, [rel pipe_fds]
    mov [rel adapter+NEBO_X11_ADAPTER_FD_OFFSET], rax
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 1
    mov ecx, 2
    mov r8d, 1
    call nebo_x11_adapter_begin_window_drag
    cmp eax, NEBO_PLATFORM_STATUS_IO_FAILURE
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne test_fail
    mov rax, [rel saved_sequence]
    cmp [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET], rax
    jne test_fail
    call restore_socket_and_close_pipe

    ; CANCEL write failure still clears state and produces a deterministic error.
    mov ebp, 34
    mov dword [rel expected_root_x], 909
    mov dword [rel expected_root_y], 1001
    mov dword [rel expected_direction], NEBO_X11_NET_WM_MOVERESIZE_MOVE
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 909
    mov ecx, 1001
    mov r8d, 1
    call nebo_x11_adapter_begin_window_drag
    test eax, eax
    jnz test_fail
    call verify_start_wire
    test eax, eax
    jnz test_fail
    mov eax, SYS_PIPE
    lea rdi, [rel pipe_fds]
    syscall
    test eax, eax
    js test_fail
    mov eax, [rel pipe_fds]
    mov [rel adapter+NEBO_X11_ADAPTER_FD_OFFSET], rax
    mov edi, NEBO_X11_EVENT_BUTTON_RELEASE
    mov esi, 1
    call inject_button
    cmp eax, NEBO_PLATFORM_STATUS_IO_FAILURE
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_FAILED
    jne test_fail
    call restore_socket_and_close_pipe
    mov dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED

    ; Close during an active transaction sends CANCEL before normal close event.
    mov ebp, 35
    mov dword [rel expected_root_x], 1102
    mov dword [rel expected_root_y], 1203
    mov dword [rel expected_direction], NEBO_X11_NET_WM_MOVERESIZE_MOVE
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 1102
    mov ecx, 1203
    mov r8d, 1
    call nebo_x11_adapter_begin_window_drag
    test eax, eax
    jnz test_fail
    call verify_start_wire
    test eax, eax
    jnz test_fail
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel event]
    call nebo_x11_adapter_request_close
    test eax, eax
    jnz test_fail
    call verify_cancel_wire
    test eax, eax
    jnz test_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_CLOSE_REQUESTED
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne test_fail
    mov rax, [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    mov [rel saved_sequence], rax
    mov edi, NEBO_X11_EVENT_BUTTON_RELEASE
    mov esi, 1
    call inject_button
    test eax, eax
    jnz test_fail
    mov rax, [rel saved_sequence]
    cmp [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET], rax
    jne test_fail
    and dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], ~NEBO_X11_WINDOW_NATIVE_FLAG_CLOSE_REQUESTED
    mov dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE

    ; The same close cleanup contract applies to resize transactions.
    mov ebp, 36
    mov dword [rel expected_root_x], 1250
    mov dword [rel expected_root_y], 1260
    mov dword [rel expected_direction], NEBO_X11_NET_WM_MOVERESIZE_SIZE_BOTTOMRIGHT
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 1250
    mov ecx, 1260
    mov r8d, NEBO_X11_NET_WM_MOVERESIZE_SIZE_BOTTOMRIGHT
    mov r9d, 1
    call nebo_x11_adapter_begin_window_resize
    test eax, eax
    jnz test_fail
    call verify_start_wire
    test eax, eax
    jnz test_fail
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel event]
    call nebo_x11_adapter_request_close
    test eax, eax
    jnz test_fail
    call verify_cancel_wire
    test eax, eax
    jnz test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne test_fail
    and dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], ~NEBO_X11_WINDOW_NATIVE_FLAG_CLOSE_REQUESTED
    mov dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE

    ; A raw X error preserves bounded detail, emits CANCEL if needed, and clears.
    mov ebp, 37
    mov dword [rel expected_root_x], 1304
    mov dword [rel expected_root_y], 1405
    mov dword [rel expected_direction], NEBO_X11_NET_WM_MOVERESIZE_MOVE
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 1304
    mov ecx, 1405
    mov r8d, 1
    call nebo_x11_adapter_begin_window_drag
    test eax, eax
    jnz test_fail
    call verify_start_wire
    test eax, eax
    jnz test_fail
    lea rdi, [rel raw]
    xor eax, eax
    mov ecx, (NEBO_X11_EVENT_SIZE/8)
    cld
    rep stosq
    mov byte [rel raw], NEBO_X11_EVENT_ERROR
    mov byte [rel raw+1], 3
    mov word [rel raw+2], 0x1234
    mov word [rel raw+8], 0x5678
    mov byte [rel raw+10], NEBO_X11_OP_SEND_EVENT
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    cmp eax, NEBO_PLATFORM_STATUS_PROTOCOL_FAILURE
    jne test_fail
    call verify_cancel_wire
    test eax, eax
    jnz test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_FAILED
    jne test_fail
    cmp qword [rel window+NEBO_X11_WINDOW_LAST_PROTOCOL_ERROR_DETAIL_OFFSET], 0
    je test_fail

    mov ebp, 38
    mov edi, [rel socket_fds]
    mov eax, SYS_CLOSE
    syscall
    mov edi, [rel socket_fds+4]
    mov eax, SYS_CLOSE
    syscall
    xor edi, edi
    jmp test_exit

initialize_fixture:
    sub rsp, 8
    lea rdi, [rel adapter]
    xor eax, eax
    mov ecx, NEBO_X11_ADAPTER_QWORDS
    cld
    rep stosq
    lea rdi, [rel window]
    mov ecx, NEBO_X11_WINDOW_QWORDS
    rep stosq
    lea rdi, [rel window2]
    mov ecx, NEBO_X11_WINDOW_QWORDS
    rep stosq
    mov eax, SYS_SOCKETPAIR
    mov edi, NEBO_LINUX_AF_UNIX
    mov esi, NEBO_LINUX_SOCK_STREAM
    xor edx, edx
    lea r10, [rel socket_fds]
    syscall
    test eax, eax
    js .fixture_done
    mov eax, [rel socket_fds]
    mov [rel adapter+NEBO_X11_ADAPTER_FD_OFFSET], rax
    mov dword [rel adapter+NEBO_X11_ADAPTER_STATE_OFFSET], NEBO_PLATFORM_ADAPTER_STATE_READY
    mov dword [rel adapter+NEBO_X11_ADAPTER_FLAGS_OFFSET], NEBO_X11_ADAPTER_REQUIRED_FLAGS
    mov qword [rel adapter+NEBO_X11_ADAPTER_CAPABILITIES_OFFSET], NEBO_PLATFORM_MF053_REQUIRED_CAPABILITIES
    mov qword [rel adapter+NEBO_X11_ADAPTER_REQUIRED_CAPABILITIES_OFFSET], NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
    mov dword [rel adapter+NEBO_X11_ADAPTER_ROOT_WINDOW_OFFSET], TEST_ROOT_XID
    mov qword [rel adapter+NEBO_X11_ADAPTER_SCALE_FACTOR_OFFSET], NEBO_PLATFORM_SCALE_ONE
    mov dword [rel adapter+NEBO_X11_ADAPTER_NET_WM_MOVERESIZE_ATOM_OFFSET], TEST_MOVERESIZE_ATOM
    lea rax, [rel scratch]
    mov [rel adapter+NEBO_X11_ADAPTER_SCRATCH_PTR_OFFSET], rax
    mov qword [rel adapter+NEBO_X11_ADAPTER_SCRATCH_CAPACITY_OFFSET], NEBO_X11_MIN_SCRATCH_CAPACITY
    lea rdi, [rel adapter+NEBO_X11_ADAPTER_REPORT_OFFSET]
    mov rsi, NEBO_X11_ADAPTER_ID_HASH
    mov rdx, NEBO_PLATFORM_MF053_REQUIRED_CAPABILITIES
    mov rcx, NEBO_PLATFORM_SCALE_ONE
    mov r8d, NEBO_PLATFORM_REPORT_REQUIRED_FLAGS
    call nebo_platform_report_init
    test eax, eax
    jnz .fixture_done
    mov qword [rel adapter+NEBO_X11_ADAPTER_REPORT_OFFSET+NEBO_PLATFORM_REPORT_REQUIRED_CAPABILITIES_OFFSET], NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
    lea rax, [rel adapter]
    mov [rel window+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], rax
    mov rax, 0x0000000100000001
    mov [rel window+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET], rax
    mov dword [rel window+NEBO_X11_WINDOW_XID_OFFSET], TEST_WINDOW_XID
    mov dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    mov dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAPPED
    lea rax, [rel adapter]
    mov [rel window2+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], rax
    mov rax, 0x0000000200000002
    mov [rel window2+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET], rax
    mov dword [rel window2+NEBO_X11_WINDOW_XID_OFFSET], TEST_WINDOW2_XID
    mov dword [rel window2+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    mov dword [rel window2+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAPPED
    mov dword [rel expected_window_xid], TEST_WINDOW_XID
    xor eax, eax
.fixture_done:
    add rsp, 8
    ret

; Exact 8-byte UngrabPointer followed by exact 44-byte SendEvent.
verify_start_wire:
    sub rsp, 8
    mov edi, [rel socket_fds+4]
    lea rsi, [rel wire]
    mov edx, 52
    call read_exact
    test eax, eax
    jnz .start_bad
    cmp byte [rel wire], NEBO_X11_OP_UNGRAB_POINTER
    jne .start_bad
    cmp word [rel wire+2], 2
    jne .start_bad
    cmp dword [rel wire+4], NEBO_X11_CURRENT_TIME
    jne .start_bad
    cmp byte [rel wire+8], NEBO_X11_OP_SEND_EVENT
    jne .start_bad
    cmp word [rel wire+10], 11
    jne .start_bad
    cmp dword [rel wire+12], TEST_ROOT_XID
    jne .start_bad
    cmp byte [rel wire+20], NEBO_X11_EVENT_CLIENT_MESSAGE
    jne .start_bad
    cmp byte [rel wire+21], 32
    jne .start_bad
    mov eax, [rel expected_window_xid]
    cmp [rel wire+24], eax
    jne .start_bad
    cmp dword [rel wire+28], TEST_MOVERESIZE_ATOM
    jne .start_bad
    mov eax, [rel expected_root_x]
    cmp [rel wire+32], eax
    jne .start_bad
    mov eax, [rel expected_root_y]
    cmp [rel wire+36], eax
    jne .start_bad
    mov eax, [rel expected_direction]
    cmp [rel wire+40], eax
    jne .start_bad
    cmp dword [rel wire+44], 1
    jne .start_bad
    cmp dword [rel wire+48], NEBO_X11_NET_WM_SOURCE_APPLICATION
    jne .start_bad
    xor eax, eax
    jmp .start_done
.start_bad:
    mov eax, 1
.start_done:
    add rsp, 8
    ret

verify_cancel_wire:
    sub rsp, 8
    mov edi, [rel socket_fds+4]
    lea rsi, [rel wire]
    mov edx, 44
    call read_exact
    test eax, eax
    jnz .cancel_bad
    cmp byte [rel wire], NEBO_X11_OP_SEND_EVENT
    jne .cancel_bad
    cmp word [rel wire+2], 11
    jne .cancel_bad
    cmp dword [rel wire+4], TEST_ROOT_XID
    jne .cancel_bad
    cmp byte [rel wire+12], NEBO_X11_EVENT_CLIENT_MESSAGE
    jne .cancel_bad
    mov eax, [rel expected_window_xid]
    cmp [rel wire+16], eax
    jne .cancel_bad
    cmp dword [rel wire+20], TEST_MOVERESIZE_ATOM
    jne .cancel_bad
    mov eax, [rel expected_root_x]
    cmp [rel wire+24], eax
    jne .cancel_bad
    mov eax, [rel expected_root_y]
    cmp [rel wire+28], eax
    jne .cancel_bad
    cmp dword [rel wire+32], NEBO_X11_NET_WM_MOVERESIZE_CANCEL
    jne .cancel_bad
    cmp dword [rel wire+36], 1
    jne .cancel_bad
    cmp dword [rel wire+40], NEBO_X11_NET_WM_SOURCE_APPLICATION
    jne .cancel_bad
    xor eax, eax
    jmp .cancel_done
.cancel_bad:
    mov eax, 1
.cancel_done:
    add rsp, 8
    ret

; EDI=response type, ESI=button.
inject_button:
    sub rsp, 8
    mov r8d, edi
    mov r9d, esi
    lea rdi, [rel raw]
    xor eax, eax
    mov ecx, (NEBO_X11_EVENT_SIZE/8)
    cld
    rep stosq
    mov [rel raw], r8b
    mov [rel raw+1], r9b
    mov dword [rel raw+12], TEST_WINDOW_XID
    mov word [rel raw+24], 12
    mov word [rel raw+26], 14
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    add rsp, 8
    ret

inject_configure:
    sub rsp, 8
    lea rdi, [rel raw]
    xor eax, eax
    mov ecx, (NEBO_X11_EVENT_SIZE/8)
    cld
    rep stosq
    mov byte [rel raw], NEBO_X11_EVENT_CONFIGURE_NOTIFY
    mov ax, [rel window+NEBO_X11_WINDOW_PENDING_PROTOCOL_SEQUENCE_OFFSET]
    mov [rel raw+2], ax
    mov dword [rel raw+8], TEST_WINDOW_XID
    mov word [rel raw+16], 20
    mov word [rel raw+18], 30
    mov word [rel raw+20], 640
    mov word [rel raw+22], 480
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    add rsp, 8
    ret

restore_socket_and_close_pipe:
    mov eax, [rel socket_fds]
    mov [rel adapter+NEBO_X11_ADAPTER_FD_OFFSET], rax
    mov edi, [rel pipe_fds]
    mov eax, SYS_CLOSE
    syscall
    mov edi, [rel pipe_fds+4]
    mov eax, SYS_CLOSE
    syscall
    ret

; EDI=fd, RSI=buffer, EDX=length.
read_exact:
    mov r8, rsi
    mov r9d, edx
.read_loop:
    mov eax, SYS_READ
    mov rsi, r8
    mov edx, r9d
    syscall
    test rax, rax
    jle .read_bad
    add r8, rax
    sub r9, rax
    jnz .read_loop
    xor eax, eax
    ret
.read_bad:
    mov eax, 1
    ret

test_fail:
    mov edi, ebp
test_exit:
    mov eax, SYS_EXIT
    syscall
    ud2
