; Nebo Console maximize/restore direct-X11 protocol and state oracle.
bits 64
default rel

%include "runtime/console/platform/adapter_contract.inc"
%include "runtime/console/platform/linux-x11-ewmh-direct-v0/x11_adapter.inc"

extern nebo_platform_report_init
extern nebo_x11_adapter_maximize_window
extern nebo_x11_adapter_restore_window
extern nebo_x11_adapter_minimize_window
extern nebo_x11_adapter_begin_window_drag
extern nebo_x11_adapter_begin_window_resize
extern nebo_x11_adapter_normalize_event

global _start

%define SYS_READ 0
%define SYS_WRITE 1
%define SYS_CLOSE 3
%define SYS_SOCKETPAIR 53
%define SYS_EXIT 60

%define TEST_ROOT_XID 0x10203040
%define TEST_WINDOW_XID 0x50607080
%define TEST_WM_CHANGE_STATE_ATOM 0x8192a3b4
%define TEST_WM_STATE_ATOM 0x8293a4b5
%define TEST_NET_WM_STATE_ATOM 0x91a2b3c4
%define TEST_MAX_HORZ_ATOM 0xa1b2c3d4
%define TEST_MAX_VERT_ATOM 0xb1c2d3e4
%define TEST_HIDDEN_ATOM 0xb2c3d4e5
%define TEST_MOVERESIZE_ATOM 0xc1d2e3f4

section .bss align=64
adapter: resb NEBO_X11_ADAPTER_SIZE
window: resb NEBO_X11_WINDOW_SIZE
event: resb NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
raw: resb NEBO_X11_EVENT_SIZE
scratch: resb NEBO_X11_MIN_SCRATCH_CAPACITY
wire: resb 64
state_reply_wire: resb 128
state_query_wire: resb 48
socket_fds: resd 2
expected_action: resd 1
simulated_ewmh_flags: resd 1
simulated_wm_state: resd 1
defer_event_once: resd 1
normal_x: resq 1
normal_y: resq 1
normal_width: resq 1
normal_height: resq 1
inject_x: resq 1
inject_y: resq 1
inject_width: resq 1
inject_height: resq 1

section .text
_start:
    mov ebp, 1
    call initialize_fixture
    test eax, eax
    jnz test_fail

    ; RR-001/RR-005: maximize uses EWMH ADD and captures normal geometry once.
    mov ebp, 2
    call capture_normal_geometry
    call request_maximize
    test eax, eax
    jnz test_fail
    cmp qword [rel window+NEBO_X11_WINDOW_RESTORE_X_OFFSET], 40
    jne test_fail
    cmp qword [rel window+NEBO_X11_WINDOW_RESTORE_Y_OFFSET], 50
    jne test_fail
    cmp qword [rel window+NEBO_X11_WINDOW_RESTORE_WIDTH_OFFSET], 640
    jne test_fail
    cmp qword [rel window+NEBO_X11_WINDOW_RESTORE_HEIGHT_OFFSET], 400
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne test_fail

    ; RR-003/RR-006: ConfigureNotify owns geometry; the queried property owns
    ; the maximized state even when its request sequence happens to match.
    mov ebp, 3
    mov qword [rel inject_x], 0
    mov qword [rel inject_y], 0
    mov qword [rel inject_width], 1920
    mov qword [rel inject_height], 1036
    call inject_configure
    test eax, eax
    jnz test_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESIZED
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_MAXIMIZE
    jne test_fail
    call inject_net_wm_state_property
    test eax, eax
    jnz test_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_MAXIMIZED
    jne test_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    jz test_fail

    ; RR-002/RR-004/RR-007: restore uses REMOVE and commits restored geometry.
    mov ebp, 4
    call request_restore
    test eax, eax
    jnz test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne test_fail
    call inject_normal_configure
    test eax, eax
    jnz test_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESIZED
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_RESTORE
    jne test_fail
    call inject_net_wm_state_property
    test eax, eax
    jnz test_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESTORED
    jne test_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    jnz test_fail

    ; RR-010/RR-011: ten exact maximize/restore cycles remain moveresize-idle.
    mov ebp, 5
    mov r12d, 10
.cycle_loop:
    call capture_normal_geometry
    call request_maximize
    test eax, eax
    jnz test_fail
    mov qword [rel inject_x], 0
    mov qword [rel inject_y], 0
    mov qword [rel inject_width], 1920
    mov qword [rel inject_height], 1036
    call inject_configure
    test eax, eax
    jnz test_fail
    call inject_net_wm_state_property
    test eax, eax
    jnz test_fail
    call request_restore
    test eax, eax
    jnz test_fail
    call inject_normal_configure
    test eax, eax
    jnz test_fail
    call inject_net_wm_state_property
    test eax, eax
    jnz test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne test_fail
    dec r12d
    jnz .cycle_loop

    ; RR-013: completed MOVE may precede maximize/restore without stale state.
    mov ebp, 6
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 140
    mov ecx, 150
    mov r8d, 1
    call nebo_x11_adapter_begin_window_drag
    test eax, eax
    jnz test_fail
    call drain_moveresize_start
    test eax, eax
    jnz test_fail
    mov qword [rel inject_x], 58
    mov qword [rel inject_y], 62
    mov rax, [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET]
    mov [rel inject_width], rax
    mov rax, [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET]
    mov [rel inject_height], rax
    call inject_configure
    test eax, eax
    jnz test_fail
    call inject_primary_release
    test eax, eax
    jnz test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne test_fail
    call run_max_restore_cycle
    test eax, eax
    jnz test_fail

    ; RR-014: completed SIZE may precede maximize/restore without stale state.
    mov ebp, 7
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 700
    mov ecx, 500
    mov r8d, NEBO_X11_NET_WM_MOVERESIZE_SIZE_BOTTOMRIGHT
    mov r9d, 1
    call nebo_x11_adapter_begin_window_resize
    test eax, eax
    jnz test_fail
    call drain_moveresize_start
    test eax, eax
    jnz test_fail
    mov rax, [rel window+NEBO_X11_WINDOW_X_OFFSET]
    mov [rel inject_x], rax
    mov rax, [rel window+NEBO_X11_WINDOW_Y_OFFSET]
    mov [rel inject_y], rax
    mov qword [rel inject_width], 680
    mov qword [rel inject_height], 440
    call inject_configure
    test eax, eax
    jnz test_fail
    call inject_primary_release
    test eax, eax
    jnz test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne test_fail
    call run_max_restore_cycle
    test eax, eax
    jnz test_fail

    ; RR-015: minimize/unmap -> map/restore -> maximize/restore.
    mov ebp, 8
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    call nebo_x11_adapter_minimize_window
    test eax, eax
    jnz test_fail
    mov edx, 44
    call drain_wire
    test eax, eax
    jnz test_fail
    call inject_unmap
    test eax, eax
    jnz test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_UNMAPPED
    jne test_fail
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    call nebo_x11_adapter_restore_window
    test eax, eax
    jnz test_fail
    call verify_map_wire
    test eax, eax
    jnz test_fail
    call inject_map
    test eax, eax
    jnz test_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESTORED
    jne test_fail
    call run_max_restore_cycle
    test eax, eax
    jnz test_fail

    ; Additional bounded audit for the human signal that maximize can appear
    ; unresponsive after interacting with another window. Focus transitions
    ; must not poison geometry/action state, and a fresh physical press must
    ; retire an orphaned WM resize transaction before the maximize request.
    mov ebp, 9
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 700
    mov ecx, 60
    mov r8d, NEBO_X11_NET_WM_MOVERESIZE_SIZE_TOP
    mov r9d, 1
    call nebo_x11_adapter_begin_window_resize
    test eax, eax
    jnz test_fail
    call drain_moveresize_start
    test eax, eax
    jnz test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 1
    jne test_fail
    call inject_focus_out
    test eax, eax
    jnz test_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_DEACTIVATED
    jne test_fail
    call inject_focus_in
    test eax, eax
    jnz test_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_ACTIVATED
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 1
    jne test_fail
    call inject_primary_press
    test eax, eax
    jnz test_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_POINTER_DOWN
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    jne test_fail
    call run_max_restore_cycle
    test eax, eax
    jnz test_fail

    ; NPT-CONSOLE-WINDOW-STATE-001 pre-fix oracle.  A focus/repaint request
    ; between EWMH SendEvent and the WM ConfigureNotify changes the event's
    ; sequence.  Geometry remains valid, but the pending MAXIMIZE transition
    ; must complete from _NET_WM_STATE PropertyNotify without a later title
    ; drag/move ConfigureNotify.
    mov ebp, 10
    call capture_normal_geometry
    call request_maximize
    test eax, eax
    jnz test_fail
    mov qword [rel inject_x], 0
    mov qword [rel inject_y], 0
    mov qword [rel inject_width], 1920
    mov qword [rel inject_height], 1036
    call inject_mismatched_configure
    test eax, eax
    jnz test_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESIZED
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_MAXIMIZE
    jne test_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    jnz test_fail
    call inject_net_wm_state_property
    test eax, eax
    jnz test_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_MAXIMIZED
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    jne test_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    jz test_fail
    call request_restore
    test eax, eax
    jnz test_fail
    call inject_normal_mismatched_configure
    test eax, eax
    jnz test_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESIZED
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_RESTORE
    jne test_fail
    call inject_net_wm_state_property
    test eax, eax
    jnz test_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESTORED
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    jne test_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    jnz test_fail

    ; WS-001 NORMAL -> MINIMIZE -> RESTORE.
    mov ebp, 11
    call run_minimize_restore_transition
    test eax, eax
    jnz test_fail

    ; WS-002 NORMAL -> MAXIMIZE -> RESTORE with mismatched Configure sequence.
    mov ebp, 12
    call run_property_max_restore_cycle
    test eax, eax
    jnz test_fail

    ; WS-003 MINIMIZE -> RESTORE -> MAXIMIZE.
    mov ebp, 13
    call run_minimize_restore_transition
    test eax, eax
    jnz test_fail
    call property_maximize_transition
    test eax, eax
    jnz test_fail
    call property_restore_transition
    test eax, eax
    jnz test_fail

    ; WS-004 MAXIMIZE -> MINIMIZE -> RESTORE.
    mov ebp, 14
    call property_maximize_transition
    test eax, eax
    jnz test_fail
    call minimize_transition
    test eax, eax
    jnz test_fail
    call map_restore_transition
    test eax, eax
    jnz test_fail
    call property_restore_transition
    test eax, eax
    jnz test_fail

    ; WS-005 MINIMIZE -> (map) -> MAXIMIZE -> MINIMIZE.
    mov ebp, 15
    call run_minimize_restore_transition
    test eax, eax
    jnz test_fail
    call property_maximize_transition
    test eax, eax
    jnz test_fail
    call minimize_transition
    test eax, eax
    jnz test_fail
    call map_restore_transition
    test eax, eax
    jnz test_fail
    call property_restore_transition
    test eax, eax
    jnz test_fail

    ; WS-006 MINIMIZE -> (map) -> MAXIMIZE -> RESTORE.
    mov ebp, 16
    call run_minimize_restore_transition
    test eax, eax
    jnz test_fail
    call run_property_max_restore_cycle
    test eax, eax
    jnz test_fail

    ; WS-007 MAXIMIZE -> MINIMIZE -> (map) -> MAXIMIZE.
    mov ebp, 17
    call property_maximize_transition
    test eax, eax
    jnz test_fail
    call minimize_transition
    test eax, eax
    jnz test_fail
    call map_restore_transition
    test eax, eax
    jnz test_fail
    call property_restore_transition
    test eax, eax
    jnz test_fail

    ; WS-008 MINIMIZE -> (map) -> MAXIMIZE -> MINIMIZE -> RESTORE.
    mov ebp, 18
    call run_minimize_restore_transition
    test eax, eax
    jnz test_fail
    call property_maximize_transition
    test eax, eax
    jnz test_fail
    call minimize_transition
    test eax, eax
    jnz test_fail
    call map_restore_transition
    test eax, eax
    jnz test_fail
    call property_restore_transition
    test eax, eax
    jnz test_fail

    ; WS-009 repeated maximize/restore 20x.
    mov ebp, 19
    mov r12d, 20
.ws_max_restore_loop:
    call run_property_max_restore_cycle
    test eax, eax
    jnz test_fail
    dec r12d
    jnz .ws_max_restore_loop

    ; WS-010 repeated minimize/restore 20x.
    mov ebp, 20
    mov r12d, 20
.ws_min_restore_loop:
    call run_minimize_restore_transition
    test eax, eax
    jnz test_fail
    dec r12d
    jnz .ws_min_restore_loop

    ; WS-011 alternating minimize/maximize/restore 20x.
    mov ebp, 21
    mov r12d, 20
.ws_alternating_loop:
    call run_minimize_restore_transition
    test eax, eax
    jnz test_fail
    call run_property_max_restore_cycle
    test eax, eax
    jnz test_fail
    dec r12d
    jnz .ws_alternating_loop

    ; Bounded PropertyNotify filters and delete semantics.
    mov ebp, 22
    call inject_net_wm_state_property
    cmp eax, NEBO_PLATFORM_STATUS_NO_EVENT
    jne test_fail
    mov edi, TEST_WINDOW_XID
    mov esi, TEST_NET_WM_STATE_ATOM+1
    mov edx, NEBO_X11_PROPERTY_NEW_VALUE
    call inject_property_custom
    cmp eax, NEBO_PLATFORM_STATUS_NO_EVENT
    jne test_fail
    mov edi, TEST_WINDOW_XID+1
    mov esi, TEST_NET_WM_STATE_ATOM
    mov edx, NEBO_X11_PROPERTY_NEW_VALUE
    call inject_property_custom
    cmp eax, NEBO_PLATFORM_STATUS_NO_EVENT
    jne test_fail
    call capture_normal_geometry
    call request_maximize
    test eax, eax
    jnz test_fail
    mov edi, TEST_WINDOW_XID
    mov esi, TEST_NET_WM_STATE_ATOM
    mov edx, NEBO_X11_PROPERTY_DELETE
    call inject_property_custom
    cmp eax, NEBO_PLATFORM_STATUS_NO_EVENT
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_MAXIMIZE
    jne test_fail
    call inject_net_wm_state_property
    test eax, eax
    jnz test_fail
    call request_restore
    test eax, eax
    jnz test_fail
    mov edi, TEST_WINDOW_XID
    mov esi, TEST_NET_WM_STATE_ATOM
    mov edx, NEBO_X11_PROPERTY_DELETE
    call inject_property_custom
    test eax, eax
    jnz test_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESTORED
    jne test_fail

    ; WS-BND pre-fix oracle for the exact residual human sequence.  A window
    ; that was maximized before entering Iconic/Unmapped state retains both
    ; EWMH maximize atoms.  External activation may map it directly as
    ; maximized, so MapNotify must not rewrite that actual state to NORMAL.
    ; The signal-only implementation clears MAXIMIZED here and exits at step
    ; 23, reproducing the first cached-state divergence without pointer input.
    mov ebp, 23
    call property_maximize_transition
    test eax, eax
    jnz test_fail
    call minimize_transition
    test eax, eax
    jnz test_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    jz test_fail
    call inject_map
    test eax, eax
    jnz test_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_MAXIMIZED
    jne test_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    jz test_fail

    ; WS-BND-001 NORMAL -> MINIMIZE -> RESTORE.
    mov ebp, 24
    call property_restore_if_maximized
    test eax, eax
    jnz test_fail
    call run_minimize_restore_transition
    test eax, eax
    jnz test_fail

    ; WS-BND-002 NORMAL -> MAXIMIZE -> RESTORE.
    mov ebp, 25
    call run_property_max_restore_cycle
    test eax, eax
    jnz test_fail

    ; WS-BND-003 MINIMIZE -> MAXIMIZE -> MINIMIZE.
    mov ebp, 26
    call external_minimized_to_maximized_transition
    test eax, eax
    jnz test_fail
    call minimize_transition
    test eax, eax
    jnz test_fail
    call external_map_maximized_transition
    test eax, eax
    jnz test_fail
    call property_restore_transition
    test eax, eax
    jnz test_fail

    ; WS-BND-004 MINIMIZE -> MAXIMIZE -> RESTORE.
    mov ebp, 27
    call external_minimized_to_maximized_transition
    test eax, eax
    jnz test_fail
    call property_restore_transition
    test eax, eax
    jnz test_fail

    ; WS-BND-005 MAXIMIZE -> MINIMIZE -> MAXIMIZE.
    mov ebp, 28
    call property_maximize_transition
    test eax, eax
    jnz test_fail
    call minimize_transition
    test eax, eax
    jnz test_fail
    call external_map_maximized_transition
    test eax, eax
    jnz test_fail
    call property_restore_transition
    test eax, eax
    jnz test_fail

    ; WS-BND-006 MINIMIZE -> MAXIMIZE -> MINIMIZE -> RESTORE.
    mov ebp, 29
    call external_minimized_to_maximized_transition
    test eax, eax
    jnz test_fail
    call minimize_transition
    test eax, eax
    jnz test_fail
    call external_map_maximized_transition
    test eax, eax
    jnz test_fail
    call property_restore_transition
    test eax, eax
    jnz test_fail

    ; WS-BND-007 alternating MIN/MAX 20x.
    mov ebp, 30
    mov r12d, 20
.ws_bnd_20_loop:
    call external_minimized_to_maximized_transition
    test eax, eax
    jnz test_fail
    call property_restore_transition
    test eax, eax
    jnz test_fail
    dec r12d
    jnz .ws_bnd_20_loop

    ; WS-BND-008 alternating MIN/MAX/RESTORE 50x.
    mov ebp, 31
    mov r12d, 50
.ws_bnd_50_loop:
    call external_minimized_to_maximized_transition
    test eax, eax
    jnz test_fail
    call minimize_transition
    test eax, eax
    jnz test_fail
    call external_map_maximized_transition
    test eax, eax
    jnz test_fail
    call property_restore_transition
    test eax, eax
    jnz test_fail
    dec r12d
    jnz .ws_bnd_50_loop

    ; A native event already queued ahead of GetProperty's reply is preserved
    ; exactly once and replayed by poll_raw; no socket item is discarded.
    mov ebp, 32
    call capture_normal_geometry
    call request_maximize
    test eax, eax
    jnz test_fail
    mov dword [rel simulated_ewmh_flags], NEBO_X11_WINDOW_EWMH_FLAG_MAXIMIZED
    mov dword [rel simulated_wm_state], NEBO_X11_ICCCM_NORMAL_STATE
    mov dword [rel defer_event_once], 1
    mov edi, TEST_WINDOW_XID
    mov esi, TEST_NET_WM_STATE_ATOM
    mov edx, NEBO_X11_PROPERTY_NEW_VALUE
    call inject_property_custom
    test eax, eax
    jnz test_fail
    cmp qword [rel adapter+NEBO_X11_ADAPTER_DEFERRED_EVENT_COUNT_OFFSET], 1
    jne test_fail
    lea rdi, [rel adapter]
    xor esi, esi
    lea rdx, [rel raw]
    call nebo_x11_adapter_poll_raw
    test eax, eax
    jnz test_fail
    cmp byte [rel raw], NEBO_X11_EVENT_FOCUS_IN
    jne test_fail
    cmp dword [rel raw+4], TEST_WINDOW_XID
    jne test_fail
    cmp qword [rel adapter+NEBO_X11_ADAPTER_DEFERRED_EVENT_COUNT_OFFSET], 0
    jne test_fail
    call property_restore_transition
    test eax, eax
    jnz test_fail

    ; NPT-CONSOLE-WINDOW-MINIMIZE-001: PropertyNotify may report
    ; HIDDEN/Iconic before UnmapNotify.  It is a cache update, not the
    ; canonical visibility completion point.  Keep the native window
    ; presentable through an intervening FocusOut; only UnmapNotify commits
    ; MINIMIZED/UNMAPPED and clears the pending transition.
    mov ebp, 33
    mov dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    mov dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAPPED
    mov dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_MINIMIZE
    mov dword [rel simulated_ewmh_flags], NEBO_X11_WINDOW_EWMH_FLAG_HIDDEN
    mov dword [rel simulated_wm_state], NEBO_X11_ICCCM_ICONIC_STATE
    call inject_net_wm_state_property
    cmp eax, NEBO_PLATFORM_STATUS_NO_EVENT
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    jne test_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MINIMIZED
    jnz test_fail
    test dword [rel window+NEBO_X11_WINDOW_EWMH_STATE_FLAGS_OFFSET], NEBO_X11_WINDOW_EWMH_FLAG_HIDDEN
    jz test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_WM_STATE_OFFSET], NEBO_X11_ICCCM_ICONIC_STATE
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_MINIMIZE
    jne test_fail
    call inject_focus_out
    test eax, eax
    jnz test_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_DEACTIVATED
    jne test_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MINIMIZED
    jnz test_fail
    call inject_unmap
    test eax, eax
    jnz test_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_MINIMIZED
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_UNMAPPED
    jne test_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MINIMIZED
    jz test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    jne test_fail

    mov ebp, 34
    mov edi, [rel socket_fds]
    mov eax, SYS_CLOSE
    syscall
    mov edi, [rel socket_fds+4]
    mov eax, SYS_CLOSE
    syscall
    xor edi, edi
    jmp test_exit

; Capture the current normal geometry for exact post-maximize restoration.
capture_normal_geometry:
    mov rax, [rel window+NEBO_X11_WINDOW_X_OFFSET]
    mov [rel normal_x], rax
    mov rax, [rel window+NEBO_X11_WINDOW_Y_OFFSET]
    mov [rel normal_y], rax
    mov rax, [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET]
    mov [rel normal_width], rax
    mov rax, [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET]
    mov [rel normal_height], rax
    ret

request_maximize:
    sub rsp, 8
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    call nebo_x11_adapter_maximize_window
    test eax, eax
    jnz .maximize_done
    mov dword [rel expected_action], NEBO_X11_NET_WM_STATE_ADD
    call verify_state_wire
.maximize_done:
    add rsp, 8
    ret

request_restore:
    sub rsp, 8
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    call nebo_x11_adapter_restore_window
    test eax, eax
    jnz .restore_done
    mov dword [rel expected_action], NEBO_X11_NET_WM_STATE_REMOVE
    call verify_state_wire
.restore_done:
    add rsp, 8
    ret

run_max_restore_cycle:
    sub rsp, 8
    call capture_normal_geometry
    call request_maximize
    test eax, eax
    jnz .cycle_done
    mov qword [rel inject_x], 0
    mov qword [rel inject_y], 0
    mov qword [rel inject_width], 1920
    mov qword [rel inject_height], 1036
    call inject_configure
    test eax, eax
    jnz .cycle_done
    call inject_net_wm_state_property
    test eax, eax
    jnz .cycle_done
    call request_restore
    test eax, eax
    jnz .cycle_done
    call inject_normal_configure
    test eax, eax
    jnz .cycle_done
    call inject_net_wm_state_property
.cycle_done:
    add rsp, 8
    ret

; Complete EWMH transitions from PropertyNotify after a deliberately
; nonmatching Configure sequence.  These helpers are local protocol/state
; oracles and never control the desktop pointer.
property_maximize_transition:
    sub rsp, 8
    call capture_normal_geometry
    call request_maximize
    test eax, eax
    jnz .property_maximize_done
    mov qword [rel inject_x], 0
    mov qword [rel inject_y], 0
    mov qword [rel inject_width], 1920
    mov qword [rel inject_height], 1036
    call inject_mismatched_configure
    test eax, eax
    jnz .property_maximize_done
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESIZED
    jne .property_maximize_bad
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_MAXIMIZE
    jne .property_maximize_bad
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    jnz .property_maximize_bad
    call inject_net_wm_state_property
    test eax, eax
    jnz .property_maximize_done
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_MAXIMIZED
    jne .property_maximize_bad
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    jne .property_maximize_bad
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    jz .property_maximize_bad
    xor eax, eax
    jmp .property_maximize_done
.property_maximize_bad:
    mov eax, 1
.property_maximize_done:
    add rsp, 8
    ret

property_restore_transition:
    sub rsp, 8
    call request_restore
    test eax, eax
    jnz .property_restore_done
    call inject_normal_mismatched_configure
    test eax, eax
    jnz .property_restore_done
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESIZED
    jne .property_restore_bad
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_RESTORE
    jne .property_restore_bad
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    jz .property_restore_bad
    call inject_net_wm_state_property
    test eax, eax
    jnz .property_restore_done
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESTORED
    jne .property_restore_bad
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    jne .property_restore_bad
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], (NEBO_X11_WINDOW_NATIVE_FLAG_MINIMIZED | NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED)
    jnz .property_restore_bad
    xor eax, eax
    jmp .property_restore_done
.property_restore_bad:
    mov eax, 1
.property_restore_done:
    add rsp, 8
    ret

run_property_max_restore_cycle:
    sub rsp, 8
    call property_maximize_transition
    test eax, eax
    jnz .property_cycle_done
    call property_restore_transition
.property_cycle_done:
    add rsp, 8
    ret

minimize_transition:
    sub rsp, 8
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    call nebo_x11_adapter_minimize_window
    test eax, eax
    jnz .minimize_transition_done
    mov edx, 44
    call drain_wire
    test eax, eax
    jnz .minimize_transition_done
    call inject_unmap
    test eax, eax
    jnz .minimize_transition_done
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_MINIMIZED
    jne .minimize_transition_bad
    cmp dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_UNMAPPED
    jne .minimize_transition_bad
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    jne .minimize_transition_bad
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MINIMIZED
    jz .minimize_transition_bad
    xor eax, eax
    jmp .minimize_transition_done
.minimize_transition_bad:
    mov eax, 1
.minimize_transition_done:
    add rsp, 8
    ret

map_restore_transition:
    sub rsp, 8
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    call nebo_x11_adapter_restore_window
    test eax, eax
    jnz .map_restore_done
    call verify_map_wire
    test eax, eax
    jnz .map_restore_done
    call inject_map
    test eax, eax
    jnz .map_restore_done
    mov eax, [rel simulated_ewmh_flags]
    and eax, NEBO_X11_WINDOW_EWMH_FLAG_MAXIMIZED
    cmp eax, NEBO_X11_WINDOW_EWMH_FLAG_MAXIMIZED
    jne .map_restore_expect_normal
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_MAXIMIZED
    jne .map_restore_bad
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    jz .map_restore_bad
    jmp .map_restore_state
.map_restore_expect_normal:
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESTORED
    jne .map_restore_bad
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    jnz .map_restore_bad
.map_restore_state:
    cmp dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    jne .map_restore_bad
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    jne .map_restore_bad
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MINIMIZED
    jnz .map_restore_bad
    xor eax, eax
    jmp .map_restore_done
.map_restore_bad:
    mov eax, 1
.map_restore_done:
    add rsp, 8
    ret

run_minimize_restore_transition:
    sub rsp, 8
    call minimize_transition
    test eax, eax
    jnz .minimize_restore_done
    call map_restore_transition
.minimize_restore_done:
    add rsp, 8
    ret

; Model the WM/taskbar transition directly: no application pending action is
; installed. MapNotify plus the actual property replies must be sufficient.
external_minimized_to_maximized_transition:
    sub rsp, 8
    call minimize_transition
    test eax, eax
    jnz .external_min_max_done
    call external_map_maximized_transition
.external_min_max_done:
    add rsp, 8
    ret

external_map_maximized_transition:
    sub rsp, 8
    mov dword [rel simulated_ewmh_flags], NEBO_X11_WINDOW_EWMH_FLAG_MAXIMIZED
    mov dword [rel simulated_wm_state], NEBO_X11_ICCCM_NORMAL_STATE
    mov dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    call inject_map
    test eax, eax
    jnz .external_map_max_done
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_MAXIMIZED
    jne .external_map_max_bad
    cmp dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    jne .external_map_max_bad
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    jne .external_map_max_bad
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    jz .external_map_max_bad
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MINIMIZED
    jnz .external_map_max_bad
    mov eax, [rel window+NEBO_X11_WINDOW_EWMH_STATE_FLAGS_OFFSET]
    and eax, NEBO_X11_WINDOW_EWMH_FLAG_MAXIMIZED
    cmp eax, NEBO_X11_WINDOW_EWMH_FLAG_MAXIMIZED
    jne .external_map_max_bad
    xor eax, eax
    jmp .external_map_max_done
.external_map_max_bad:
    mov eax, 1
.external_map_max_done:
    add rsp, 8
    ret

property_restore_if_maximized:
    sub rsp, 8
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    jz .restore_if_max_done
    call property_restore_transition
.restore_if_max_done:
    add rsp, 8
    ret

; Verify the exact 44-byte SendEvent carrying _NET_WM_STATE ADD or REMOVE.
verify_state_wire:
    sub rsp, 8
    mov edi, [rel socket_fds+4]
    lea rsi, [rel wire]
    mov edx, 44
    call read_exact
    test eax, eax
    jnz .state_bad
    cmp byte [rel wire], NEBO_X11_OP_SEND_EVENT
    jne .state_bad
    cmp word [rel wire+2], 11
    jne .state_bad
    cmp dword [rel wire+4], TEST_ROOT_XID
    jne .state_bad
    cmp byte [rel wire+12], NEBO_X11_EVENT_CLIENT_MESSAGE
    jne .state_bad
    cmp byte [rel wire+13], 32
    jne .state_bad
    cmp dword [rel wire+16], TEST_WINDOW_XID
    jne .state_bad
    cmp dword [rel wire+20], TEST_NET_WM_STATE_ATOM
    jne .state_bad
    mov eax, [rel expected_action]
    cmp [rel wire+24], eax
    jne .state_bad
    cmp dword [rel wire+28], TEST_MAX_HORZ_ATOM
    jne .state_bad
    cmp dword [rel wire+32], TEST_MAX_VERT_ATOM
    jne .state_bad
    cmp dword [rel wire+36], NEBO_X11_NET_WM_SOURCE_APPLICATION
    jne .state_bad
    cmp dword [rel wire+40], 0
    jne .state_bad
    xor eax, eax
    jmp .state_done
.state_bad:
    mov eax, 1
.state_done:
    add rsp, 8
    ret

inject_normal_configure:
    mov rax, [rel normal_x]
    mov [rel inject_x], rax
    mov rax, [rel normal_y]
    mov [rel inject_y], rax
    mov rax, [rel normal_width]
    mov [rel inject_width], rax
    mov rax, [rel normal_height]
    mov [rel inject_height], rax
    jmp inject_configure

inject_normal_mismatched_configure:
    mov rax, [rel normal_x]
    mov [rel inject_x], rax
    mov rax, [rel normal_y]
    mov [rel inject_y], rax
    mov rax, [rel normal_width]
    mov [rel inject_width], rax
    mov rax, [rel normal_height]
    mov [rel inject_height], rax
    jmp inject_mismatched_configure

inject_mismatched_configure:
    mov edi, 1
    jmp inject_configure_with_delta

inject_configure:
    xor edi, edi
inject_configure_with_delta:
    sub rsp, 8
    mov r8d, edi
    lea rdi, [rel raw]
    xor eax, eax
    mov ecx, (NEBO_X11_EVENT_SIZE/8)
    cld
    rep stosq
    mov byte [rel raw], NEBO_X11_EVENT_CONFIGURE_NOTIFY
    mov ax, [rel window+NEBO_X11_WINDOW_PENDING_PROTOCOL_SEQUENCE_OFFSET]
    add ax, r8w
    mov [rel raw+2], ax
    mov dword [rel raw+8], TEST_WINDOW_XID
    mov rax, [rel inject_x]
    mov [rel raw+16], ax
    mov rax, [rel inject_y]
    mov [rel raw+18], ax
    mov rax, [rel inject_width]
    mov [rel raw+20], ax
    mov rax, [rel inject_height]
    mov [rel raw+22], ax
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    add rsp, 8
    ret

inject_net_wm_state_property:
    mov eax, [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET]
    cmp eax, NEBO_X11_WINDOW_ACTION_MAXIMIZE
    jne .property_not_maximize
    mov dword [rel simulated_ewmh_flags], NEBO_X11_WINDOW_EWMH_FLAG_MAXIMIZED
    mov dword [rel simulated_wm_state], NEBO_X11_ICCCM_NORMAL_STATE
    jmp .property_state_ready
.property_not_maximize:
    cmp eax, NEBO_X11_WINDOW_ACTION_RESTORE
    jne .property_state_ready
    mov dword [rel simulated_ewmh_flags], 0
    mov dword [rel simulated_wm_state], NEBO_X11_ICCCM_NORMAL_STATE
.property_state_ready:
    mov edi, TEST_WINDOW_XID
    mov esi, TEST_NET_WM_STATE_ATOM
    mov edx, NEBO_X11_PROPERTY_NEW_VALUE
inject_property_custom:
    sub rsp, 8
    mov r8d, edi
    mov r9d, esi
    mov r10d, edx
    lea rdi, [rel raw]
    xor eax, eax
    mov ecx, (NEBO_X11_EVENT_SIZE/8)
    cld
    rep stosq
    mov byte [rel raw], NEBO_X11_EVENT_PROPERTY_NOTIFY
    mov dword [rel raw+4], r8d
    mov dword [rel raw+8], r9d
    mov byte [rel raw+16], r10b
    cmp r8d, TEST_WINDOW_XID
    jne .property_normalize
    cmp r9d, TEST_NET_WM_STATE_ATOM
    je .property_prepare_query
    cmp r9d, TEST_WM_STATE_ATOM
    jne .property_normalize
.property_prepare_query:
    cmp r10d, NEBO_X11_PROPERTY_DELETE
    jne .property_queue_query
    mov dword [rel simulated_ewmh_flags], 0
.property_queue_query:
    call queue_state_query_replies
    test eax, eax
    jnz .property_inject_done
.property_normalize:
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    mov [rsp], rax
    cmp dword [rel raw+4], TEST_WINDOW_XID
    jne .property_no_query_drain
    cmp dword [rel raw+8], TEST_NET_WM_STATE_ATOM
    je .property_drain_query
    cmp dword [rel raw+8], TEST_WM_STATE_ATOM
    jne .property_no_query_drain
.property_drain_query:
    call drain_state_query_requests
    test eax, eax
    jnz .property_drain_bad
.property_no_query_drain:
    mov rax, [rsp]
    jmp .property_inject_done
.property_drain_bad:
    mov eax, 1
.property_inject_done:
    add rsp, 8
    ret

inject_primary_release:
    sub rsp, 8
    lea rdi, [rel raw]
    xor eax, eax
    mov ecx, (NEBO_X11_EVENT_SIZE/8)
    cld
    rep stosq
    mov byte [rel raw], NEBO_X11_EVENT_BUTTON_RELEASE
    mov byte [rel raw+1], 1
    mov dword [rel raw+12], TEST_WINDOW_XID
    mov word [rel raw+24], 14
    mov word [rel raw+26], 14
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    add rsp, 8
    ret

inject_primary_press:
    mov edi, NEBO_X11_EVENT_BUTTON_PRESS
    jmp inject_primary_button_common

inject_primary_button_common:
    sub rsp, 8
    mov r8d, edi
    lea rdi, [rel raw]
    xor eax, eax
    mov ecx, (NEBO_X11_EVENT_SIZE/8)
    cld
    rep stosq
    mov [rel raw], r8b
    mov byte [rel raw+1], 1
    mov dword [rel raw+12], TEST_WINDOW_XID
    mov word [rel raw+24], 600
    mov word [rel raw+26], 14
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    add rsp, 8
    ret

inject_focus_out:
    mov edi, NEBO_X11_EVENT_FOCUS_OUT
    jmp inject_focus_common

inject_focus_in:
    mov edi, NEBO_X11_EVENT_FOCUS_IN
inject_focus_common:
    sub rsp, 8
    mov r8d, edi
    lea rdi, [rel raw]
    xor eax, eax
    mov ecx, (NEBO_X11_EVENT_SIZE/8)
    cld
    rep stosq
    mov [rel raw], r8b
    mov dword [rel raw+4], TEST_WINDOW_XID
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    add rsp, 8
    ret

inject_unmap:
    mov edi, NEBO_X11_EVENT_UNMAP_NOTIFY
    jmp inject_map_common

inject_map:
    mov edi, NEBO_X11_EVENT_MAP_NOTIFY
inject_map_common:
    sub rsp, 8
    mov r8d, edi
    lea rdi, [rel raw]
    xor eax, eax
    mov ecx, (NEBO_X11_EVENT_SIZE/8)
    cld
    rep stosq
    mov [rel raw], r8b
    mov dword [rel raw+8], TEST_WINDOW_XID
    cmp byte [rel raw], NEBO_X11_EVENT_UNMAP_NOTIFY
    jne .map_prepare_query
    or dword [rel simulated_ewmh_flags], NEBO_X11_WINDOW_EWMH_FLAG_HIDDEN
    mov dword [rel simulated_wm_state], NEBO_X11_ICCCM_ICONIC_STATE
    jmp .map_normalize
.map_prepare_query:
    and dword [rel simulated_ewmh_flags], ~NEBO_X11_WINDOW_EWMH_FLAG_HIDDEN
    mov dword [rel simulated_wm_state], NEBO_X11_ICCCM_NORMAL_STATE
    call queue_state_query_replies
    test eax, eax
    jnz .map_inject_done
.map_normalize:
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    cmp byte [rel raw], NEBO_X11_EVENT_UNMAP_NOTIFY
    je .map_inject_done
    mov [rsp], rax
    call drain_state_query_requests
    test eax, eax
    jnz .map_drain_bad
    mov rax, [rsp]
    jmp .map_inject_done
.map_drain_bad:
    mov eax, 1
.map_inject_done:
    add rsp, 8
    ret

; Preload exact replies for the two bounded state queries performed by the
; product normalizer, then verify the two GetProperty requests afterward.
queue_state_query_replies:
    push rbx
    push r12
    push r13
    push r14
    push r15
    lea rdi, [rel state_reply_wire]
    xor eax, eax
    mov ecx, 16
    cld
    rep stosq
    mov r12, [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    inc r12
    lea r13, [rel state_reply_wire]
    cmp dword [rel defer_event_once], 0
    je .reply_stream_ready
    mov byte [r13], NEBO_X11_EVENT_FOCUS_IN
    mov dword [r13+4], TEST_WINDOW_XID
    add r13, NEBO_X11_EVENT_SIZE
    mov dword [rel defer_event_once], 0
.reply_stream_ready:
    mov byte [r13], NEBO_X11_REPLY
    mov byte [r13+1], 32
    mov [r13+2], r12w
    mov dword [r13+8], NEBO_X11_ATOM_ATOM
    xor r14d, r14d
    mov ebx, [rel simulated_ewmh_flags]
    test ebx, NEBO_X11_WINDOW_EWMH_FLAG_HIDDEN
    jz .reply_horz
    mov dword [r13+32+r14*4], TEST_HIDDEN_ATOM
    inc r14d
.reply_horz:
    test ebx, NEBO_X11_WINDOW_EWMH_FLAG_MAX_HORZ
    jz .reply_vert
    mov dword [r13+32+r14*4], TEST_MAX_HORZ_ATOM
    inc r14d
.reply_vert:
    test ebx, NEBO_X11_WINDOW_EWMH_FLAG_MAX_VERT
    jz .reply_net_ready
    mov dword [r13+32+r14*4], TEST_MAX_VERT_ATOM
    inc r14d
.reply_net_ready:
    mov [r13+4], r14d
    mov [r13+16], r14d
    lea r15, [r13+32+r14*4]
    inc r12
    mov byte [r15], NEBO_X11_REPLY
    mov byte [r15+1], 32
    mov [r15+2], r12w
    mov dword [r15+4], 2
    mov dword [r15+8], TEST_WM_STATE_ATOM
    mov dword [r15+16], 2
    mov eax, [rel simulated_wm_state]
    mov [r15+32], eax
    mov dword [r15+36], 0
    lea rdx, [r15+40]
    lea rax, [rel state_reply_wire]
    sub rdx, rax
    mov edi, [rel socket_fds+4]
    lea rsi, [rel state_reply_wire]
    call write_all
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

drain_state_query_requests:
    sub rsp, 8
    mov edi, [rel socket_fds+4]
    lea rsi, [rel state_query_wire]
    mov edx, 48
    call read_exact
    test eax, eax
    jnz .query_drain_done
    cmp byte [rel state_query_wire], NEBO_X11_OP_GET_PROPERTY
    jne .query_drain_bad
    cmp word [rel state_query_wire+2], NEBO_X11_GET_PROPERTY_REQUEST_UNITS
    jne .query_drain_bad
    cmp dword [rel state_query_wire+4], TEST_WINDOW_XID
    jne .query_drain_bad
    cmp dword [rel state_query_wire+8], TEST_NET_WM_STATE_ATOM
    jne .query_drain_bad
    cmp dword [rel state_query_wire+12], NEBO_X11_ATOM_ATOM
    jne .query_drain_bad
    cmp dword [rel state_query_wire+20], NEBO_X11_GET_PROPERTY_MAX_ITEMS
    jne .query_drain_bad
    cmp byte [rel state_query_wire+24], NEBO_X11_OP_GET_PROPERTY
    jne .query_drain_bad
    cmp word [rel state_query_wire+26], NEBO_X11_GET_PROPERTY_REQUEST_UNITS
    jne .query_drain_bad
    cmp dword [rel state_query_wire+28], TEST_WINDOW_XID
    jne .query_drain_bad
    cmp dword [rel state_query_wire+32], TEST_WM_STATE_ATOM
    jne .query_drain_bad
    cmp dword [rel state_query_wire+36], TEST_WM_STATE_ATOM
    jne .query_drain_bad
    cmp dword [rel state_query_wire+44], 2
    jne .query_drain_bad
    xor eax, eax
    jmp .query_drain_done
.query_drain_bad:
    mov eax, 1
.query_drain_done:
    add rsp, 8
    ret

drain_moveresize_start:
    mov edx, 52
    jmp drain_wire

verify_map_wire:
    sub rsp, 8
    mov edi, [rel socket_fds+4]
    lea rsi, [rel wire]
    mov edx, 8
    call read_exact
    test eax, eax
    jnz .map_done
    cmp byte [rel wire], NEBO_X11_OP_MAP_WINDOW
    jne .map_bad
    cmp word [rel wire+2], 2
    jne .map_bad
    cmp dword [rel wire+4], TEST_WINDOW_XID
    jne .map_bad
    xor eax, eax
    jmp .map_done
.map_bad:
    mov eax, 1
.map_done:
    add rsp, 8
    ret

drain_wire:
    sub rsp, 8
    mov edi, [rel socket_fds+4]
    lea rsi, [rel wire]
    call read_exact
    add rsp, 8
    ret

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
    mov dword [rel adapter+NEBO_X11_ADAPTER_WM_CHANGE_STATE_ATOM_OFFSET], TEST_WM_CHANGE_STATE_ATOM
    mov dword [rel adapter+NEBO_X11_ADAPTER_WM_STATE_ATOM_OFFSET], TEST_WM_STATE_ATOM
    mov dword [rel adapter+NEBO_X11_ADAPTER_NET_WM_STATE_ATOM_OFFSET], TEST_NET_WM_STATE_ATOM
    mov dword [rel adapter+NEBO_X11_ADAPTER_NET_WM_STATE_MAX_HORZ_ATOM_OFFSET], TEST_MAX_HORZ_ATOM
    mov dword [rel adapter+NEBO_X11_ADAPTER_NET_WM_STATE_MAX_VERT_ATOM_OFFSET], TEST_MAX_VERT_ATOM
    mov dword [rel adapter+NEBO_X11_ADAPTER_NET_WM_STATE_HIDDEN_ATOM_OFFSET], TEST_HIDDEN_ATOM
    mov dword [rel adapter+NEBO_X11_ADAPTER_NET_WM_MOVERESIZE_ATOM_OFFSET], TEST_MOVERESIZE_ATOM
    mov qword [rel adapter+NEBO_X11_ADAPTER_SCALE_FACTOR_OFFSET], NEBO_PLATFORM_SCALE_ONE
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
    mov qword [rel window+NEBO_X11_WINDOW_X_OFFSET], 40
    mov qword [rel window+NEBO_X11_WINDOW_Y_OFFSET], 50
    mov qword [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET], 640
    mov qword [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET], 400
    mov dword [rel simulated_ewmh_flags], 0
    mov dword [rel simulated_wm_state], NEBO_X11_ICCCM_NORMAL_STATE
    mov dword [rel defer_event_once], 0
    xor eax, eax
.fixture_done:
    add rsp, 8
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

; EDI=fd, RSI=buffer, EDX=length.
write_all:
    mov r8, rsi
    mov r9d, edx
.write_loop:
    mov eax, SYS_WRITE
    mov rsi, r8
    mov edx, r9d
    syscall
    test rax, rax
    jle .write_bad
    add r8, rax
    sub r9, rax
    jnz .write_loop
    xor eax, eax
    ret
.write_bad:
    mov eax, 1
    ret

test_fail:
    mov edi, ebp
test_exit:
    mov eax, SYS_EXIT
    syscall
    ud2

section .note.GNU-stack noalloc noexec nowrite progbits
