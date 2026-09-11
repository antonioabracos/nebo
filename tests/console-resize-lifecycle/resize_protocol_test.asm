; NPT-CONSOLE-RESIZE-R2 local hitbox, direction, geometry and event-state oracle.
; No display connection or system pointer input is used.
bits 64
default rel

%include "runtime/console/chrome/window_chrome.inc"
%include "runtime/console/platform/linux-x11-ewmh-direct-v0/x11_adapter.inc"

extern nebo_console_chrome_hit_test
extern nebo_console_chrome_motion_hit_test
extern nebo_console_chrome_resize_direction
extern nebo_x11_adapter_normalize_event
extern nebo_x11_adapter_set_resize_cursor
extern nebo_x11_adapter_shutdown
extern nebo_platform_report_init

global _start

%define SYS_EXIT 60
%define SYS_READ 0
%define SYS_CLOSE 3
%define SYS_SOCKETPAIR 53
%define TEST_WIDTH 640
%define TEST_HEIGHT 400
%define TEST_XID 0x12345678

section .bss align=64
out_value: resd 1
current_failure: resd 1
adapter: resb NEBO_X11_ADAPTER_SIZE
window: resb NEBO_X11_WINDOW_SIZE
raw: resb NEBO_X11_EVENT_SIZE
event: resb NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
scratch: resb NEBO_X11_MIN_SCRATCH_CAPACITY
wire: resb 256
socket_fds: resd 2
saved_cursor_ids: resd 4
boundary_direction: resd 1
boundary_raw_x: resd 1
boundary_raw_y: resd 1
boundary_raw_width: resd 1
boundary_raw_height: resd 1
boundary_expected_x: resd 1
boundary_expected_y: resd 1
boundary_expected_width: resd 1
boundary_expected_height: resd 1

section .text

%macro CHECK_DIRECTION 4
    mov dword [rel current_failure], %1
    mov edx, %2
    mov ecx, %3
    mov r9d, %4
    call check_direction
    test eax, eax
    jnz test_fail
%endmacro

%macro CHECK_BOUNDARY 10
    mov dword [rel current_failure], %1
    mov dword [rel boundary_direction], %2
    mov dword [rel boundary_raw_x], %3
    mov dword [rel boundary_raw_y], %4
    mov dword [rel boundary_raw_width], %5
    mov dword [rel boundary_raw_height], %6
    mov dword [rel boundary_expected_x], %7
    mov dword [rel boundary_expected_y], %8
    mov dword [rel boundary_expected_width], %9
    mov dword [rel boundary_expected_height], %10
    call check_boundary_cycle
    test eax, eax
    jnz test_fail
%endmacro

%macro CHECK_REGION 4
    mov dword [rel current_failure], %1
    mov edi, TEST_WIDTH
    mov esi, TEST_HEIGHT
    mov edx, %2
    mov ecx, %3
    lea r8, [rel out_value]
    call nebo_console_chrome_hit_test
    test eax, eax
    jnz test_fail
    cmp dword [rel out_value], %4
    jne test_fail
%endmacro

%macro CHECK_CYCLE 6
    mov dword [rel current_failure], %1
    mov edi, %2
    mov esi, %3
    mov edx, %4
    mov ecx, %5
    mov r8d, %6
    call check_resize_cycle
    test eax, eax
    jnz test_fail
%endmacro

_start:
    ; RZ-001..RZ-008: every supported edge/corner has one exact direction.
    CHECK_DIRECTION 1, 2, 200, NEBO_CHROME_RESIZE_DIRECTION_LEFT
    CHECK_DIRECTION 2, TEST_WIDTH-2, 200, NEBO_CHROME_RESIZE_DIRECTION_RIGHT
    CHECK_DIRECTION 3, 320, 2, NEBO_CHROME_RESIZE_DIRECTION_TOP
    CHECK_DIRECTION 4, 320, TEST_HEIGHT-2, NEBO_CHROME_RESIZE_DIRECTION_BOTTOM
    CHECK_DIRECTION 5, 2, 2, NEBO_CHROME_RESIZE_DIRECTION_TOPLEFT
    ; TOP_RIGHT is a five-pixel grip immediately below the title controls.
    CHECK_DIRECTION 6, TEST_WIDTH-2, NEBO_CHROME_HEIGHT_PX+2, NEBO_CHROME_RESIZE_DIRECTION_TOPRIGHT
    CHECK_DIRECTION 7, 2, TEST_HEIGHT-2, NEBO_CHROME_RESIZE_DIRECTION_BOTTOMLEFT
    CHECK_DIRECTION 8, TEST_WIDTH-2, TEST_HEIGHT-2, NEBO_CHROME_RESIZE_DIRECTION_BOTTOMRIGHT

    ; RZ-009..RZ-012: frozen control precedence and title drag remain exact.
    CHECK_REGION 9, TEST_WIDTH-2, 14, NEBO_CHROME_REGION_CLOSE
    CHECK_REGION 10, TEST_WIDTH-42, 14, NEBO_CHROME_REGION_MAXIMIZE_RESTORE
    CHECK_REGION 11, TEST_WIDTH-70, 14, NEBO_CHROME_REGION_MINIMIZE
    CHECK_REGION 12, 100, 14, NEBO_CHROME_REGION_DRAG

    ; A control coordinate cannot be converted into a resize direction.
    mov dword [rel current_failure], 13
    mov edi, TEST_WIDTH
    mov esi, TEST_HEIGHT
    mov edx, TEST_WIDTH-2
    mov ecx, 14
    lea r8, [rel out_value]
    call nebo_console_chrome_resize_direction
    cmp eax, NEBO_CHROME_STATUS_INVALID_ARGUMENT
    jne test_fail

    ; Strict press hit-testing still rejects outside coordinates.
    mov dword [rel current_failure], 14
    mov edi, TEST_WIDTH
    mov esi, TEST_HEIGHT
    mov rdx, -1
    mov ecx, 200
    lea r8, [rel out_value]
    call nebo_console_chrome_hit_test
    cmp eax, NEBO_CHROME_STATUS_INVALID_ARGUMENT
    jne test_fail

    ; R2 causal correction: motion outside is valid and has no chrome owner.
    mov dword [rel current_failure], 15
    mov edi, TEST_WIDTH
    mov esi, TEST_HEIGHT
    mov rdx, -1
    mov ecx, 200
    lea r8, [rel out_value]
    call nebo_console_chrome_motion_hit_test
    test eax, eax
    jnz test_fail
    cmp dword [rel out_value], NEBO_CHROME_REGION_NONE
    jne test_fail
    mov dword [rel current_failure], 16
    mov edi, TEST_WIDTH
    mov esi, TEST_HEIGHT
    mov edx, TEST_WIDTH
    mov ecx, 200
    lea r8, [rel out_value]
    call nebo_console_chrome_motion_hit_test
    test eax, eax
    jnz test_fail
    cmp dword [rel out_value], NEBO_CHROME_REGION_NONE
    jne test_fail

    ; Invalid output and invalid geometry are not swallowed by motion policy.
    mov dword [rel current_failure], 17
    mov edi, TEST_WIDTH
    mov esi, TEST_HEIGHT
    xor edx, edx
    xor ecx, ecx
    xor r8d, r8d
    call nebo_console_chrome_motion_hit_test
    cmp eax, NEBO_CHROME_STATUS_INVALID_ARGUMENT
    jne test_fail
    mov dword [rel current_failure], 18
    mov edi, NEBO_CHROME_MIN_WINDOW_WIDTH_PX-1
    mov esi, TEST_HEIGHT
    xor edx, edx
    xor ecx, ecx
    lea r8, [rel out_value]
    call nebo_console_chrome_motion_hit_test
    cmp eax, NEBO_CHROME_STATUS_LIMIT
    jne test_fail

    ; Local raw-event trace: signed outside MotionNotify normalizes without
    ; altering the active resize transaction or setting Close state.
    lea rax, [rel adapter]
    mov [rel window+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], rax
    mov qword [rel window+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET], 1
    mov dword [rel window+NEBO_X11_WINDOW_XID_OFFSET], TEST_XID
    mov dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    mov qword [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET], TEST_WIDTH
    mov qword [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET], TEST_HEIGHT
    mov dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 1
    mov dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_BUTTON_OFFSET], 1
    mov dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_DIRECTION_OFFSET], NEBO_X11_NET_WM_MOVERESIZE_SIZE_RIGHT
    mov byte [rel raw], NEBO_X11_EVENT_MOTION_NOTIFY
    mov dword [rel raw+12], TEST_XID
    mov word [rel raw+24], -1
    mov word [rel raw+26], 200
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    mov dword [rel current_failure], 19
    test eax, eax
    jnz test_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_POINTER_MOVE
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 1
    jne test_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_CLOSE_REQUESTED
    jnz test_fail

    ; ConfigureNotify proves geometry adoption + WM progress, then the matching
    ; ButtonRelease clears the transaction exactly once without Close state.
    lea rdi, [rel raw]
    xor eax, eax
    mov ecx, NEBO_X11_EVENT_SIZE/8
    rep stosq
    mov byte [rel raw], NEBO_X11_EVENT_CONFIGURE_NOTIFY
    mov dword [rel raw+8], TEST_XID
    mov word [rel raw+16], 10
    mov word [rel raw+18], 20
    mov word [rel raw+20], 658
    mov word [rel raw+22], 418
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    mov dword [rel current_failure], 20
    test eax, eax
    jnz test_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESIZED
    jne test_fail
    cmp qword [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET], 658
    jne test_fail
    cmp qword [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET], 418
    jne test_fail
    test dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_FLAGS_OFFSET], NEBO_X11_WINDOW_MOVERESIZE_FLAG_WM_PROGRESS
    jz test_fail

    lea rdi, [rel raw]
    xor eax, eax
    mov ecx, NEBO_X11_EVENT_SIZE/8
    rep stosq
    mov byte [rel raw], NEBO_X11_EVENT_BUTTON_RELEASE
    mov byte [rel raw+1], 1
    mov dword [rel raw+12], TEST_XID
    mov word [rel raw+24], -1
    mov word [rel raw+26], 200
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    mov dword [rel current_failure], 21
    test eax, eax
    jnz test_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_POINTER_UP
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne test_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_CLOSE_REQUESTED
    jnz test_fail

    ; RZ-022..RZ-029: all eight directions independently adopt a valid
    ; ConfigureNotify geometry, remain active through WM progress, and return
    ; to idle on the matching release without setting Close state.
    CHECK_CYCLE 22, NEBO_CHROME_RESIZE_DIRECTION_LEFT, 5, 20, 645, 400
    CHECK_CYCLE 23, NEBO_CHROME_RESIZE_DIRECTION_RIGHT, 10, 20, 645, 400
    CHECK_CYCLE 24, NEBO_CHROME_RESIZE_DIRECTION_TOP, 10, 15, 640, 405
    CHECK_CYCLE 25, NEBO_CHROME_RESIZE_DIRECTION_BOTTOM, 10, 20, 640, 405
    CHECK_CYCLE 26, NEBO_CHROME_RESIZE_DIRECTION_TOPLEFT, 5, 15, 645, 405
    CHECK_CYCLE 27, NEBO_CHROME_RESIZE_DIRECTION_TOPRIGHT, 10, 15, 645, 405
    CHECK_CYCLE 28, NEBO_CHROME_RESIZE_DIRECTION_BOTTOMLEFT, 5, 20, 645, 405
    CHECK_CYCLE 29, NEBO_CHROME_RESIZE_DIRECTION_BOTTOMRIGHT, 10, 20, 645, 405

    ; BND-001..005: LEFT preserves right_edge=650 at, one pixel past,
    ; and far past the 128-pixel minimum.
    CHECK_BOUNDARY 60, NEBO_X11_NET_WM_MOVERESIZE_SIZE_LEFT, 522, 20, 128, 400, 522, 20, 128, 400
    CHECK_BOUNDARY 61, NEBO_X11_NET_WM_MOVERESIZE_SIZE_LEFT, 523, 20, 127, 400, 522, 20, 128, 400
    CHECK_BOUNDARY 62, NEBO_X11_NET_WM_MOVERESIZE_SIZE_LEFT, 649, 20, 1, 400, 522, 20, 128, 400
    CHECK_BOUNDARY 75, NEBO_X11_NET_WM_MOVERESIZE_SIZE_LEFT, 650, 20, 0, 400, 522, 20, 128, 400
    CHECK_BOUNDARY 76, NEBO_X11_NET_WM_MOVERESIZE_SIZE_LEFT, 645, 20, 5, 400, 522, 20, 128, 400

    ; BND-011: the same far-beyond clamp remains exact over 256 complete
    ; ConfigureNotify -> release transactions.
    mov dword [rel current_failure], 63
    mov dword [rel boundary_direction], NEBO_X11_NET_WM_MOVERESIZE_SIZE_LEFT
    mov dword [rel boundary_raw_x], 649
    mov dword [rel boundary_raw_y], 20
    mov dword [rel boundary_raw_width], 1
    mov dword [rel boundary_raw_height], 400
    mov dword [rel boundary_expected_x], 522
    mov dword [rel boundary_expected_y], 20
    mov dword [rel boundary_expected_width], 128
    mov dword [rel boundary_expected_height], 400
    mov r12d, 256
.boundary_left_stress:
    call check_boundary_cycle
    test eax, eax
    jnz test_fail
    dec r12d
    jnz .boundary_left_stress

    ; BND-006..008: opposite single edges clamp without moving their
    ; anchored origin; TOP preserves bottom_edge=420.
    CHECK_BOUNDARY 64, NEBO_X11_NET_WM_MOVERESIZE_SIZE_RIGHT, 10, 20, 127, 400, 10, 20, 128, 400
    CHECK_BOUNDARY 77, NEBO_X11_NET_WM_MOVERESIZE_SIZE_TOP, 10, 354, 640, 66, 10, 354, 640, 66
    CHECK_BOUNDARY 65, NEBO_X11_NET_WM_MOVERESIZE_SIZE_TOP, 10, 355, 640, 65, 10, 354, 640, 66
    CHECK_BOUNDARY 78, NEBO_X11_NET_WM_MOVERESIZE_SIZE_TOP, 10, 419, 640, 1, 10, 354, 640, 66
    CHECK_BOUNDARY 66, NEBO_X11_NET_WM_MOVERESIZE_SIZE_BOTTOM, 10, 20, 640, 65, 10, 20, 640, 66

    ; BND-009..010 plus all-corners coverage: all four corners independently
    ; LEFT/TOP components preserve the opposite edge.
    CHECK_BOUNDARY 67, NEBO_X11_NET_WM_MOVERESIZE_SIZE_TOPLEFT, 523, 357, 127, 63, 522, 354, 128, 66
    CHECK_BOUNDARY 68, NEBO_X11_NET_WM_MOVERESIZE_SIZE_TOPRIGHT, 10, 357, 127, 63, 10, 354, 128, 66
    CHECK_BOUNDARY 69, NEBO_X11_NET_WM_MOVERESIZE_SIZE_BOTTOMLEFT, 523, 20, 127, 63, 522, 20, 128, 66
    CHECK_BOUNDARY 70, NEBO_X11_NET_WM_MOVERESIZE_SIZE_BOTTOMRIGHT, 10, 20, 127, 63, 10, 20, 128, 66

    ; Exact ICCCM PMinSize wire contract used before MapWindow.
    call minimum_size_wire_test
    test eax, eax
    jnz test_fail

    ; BND-012/BND-013/BND-015: minimum geometry remains live through a later
    ; normal grow, maximize/restore state, and normal close request.
    mov dword [rel current_failure], 79
    call boundary_grow_test
    test eax, eax
    jnz test_fail
    mov dword [rel current_failure], 80
    call boundary_maximize_restore_test
    test eax, eax
    jnz test_fail
    mov dword [rel current_failure], 81
    call boundary_close_test
    test eax, eax
    jnz test_fail

    ; RZ-031..RZ-033 local stress: 128 complete passes across all eight
    ; directions. No state, cursor, display, sleep, or global pointer is used.
    mov r12d, 128
.stress_loop:
    mov edx, 2
    mov ecx, 200
    mov r9d, NEBO_CHROME_RESIZE_DIRECTION_LEFT
    call check_direction
    test eax, eax
    jnz .stress_fail
    mov edx, TEST_WIDTH-2
    mov ecx, 200
    mov r9d, NEBO_CHROME_RESIZE_DIRECTION_RIGHT
    call check_direction
    test eax, eax
    jnz .stress_fail
    mov edx, 320
    mov ecx, 2
    mov r9d, NEBO_CHROME_RESIZE_DIRECTION_TOP
    call check_direction
    test eax, eax
    jnz .stress_fail
    mov edx, 320
    mov ecx, TEST_HEIGHT-2
    mov r9d, NEBO_CHROME_RESIZE_DIRECTION_BOTTOM
    call check_direction
    test eax, eax
    jnz .stress_fail
    mov edx, 2
    mov ecx, 2
    mov r9d, NEBO_CHROME_RESIZE_DIRECTION_TOPLEFT
    call check_direction
    test eax, eax
    jnz .stress_fail
    mov edx, TEST_WIDTH-2
    mov ecx, NEBO_CHROME_HEIGHT_PX+2
    mov r9d, NEBO_CHROME_RESIZE_DIRECTION_TOPRIGHT
    call check_direction
    test eax, eax
    jnz .stress_fail
    mov edx, 2
    mov ecx, TEST_HEIGHT-2
    mov r9d, NEBO_CHROME_RESIZE_DIRECTION_BOTTOMLEFT
    call check_direction
    test eax, eax
    jnz .stress_fail
    mov edx, TEST_WIDTH-2
    mov ecx, TEST_HEIGHT-2
    mov r9d, NEBO_CHROME_RESIZE_DIRECTION_BOTTOMRIGHT
    call check_direction
    test eax, eax
    jnz .stress_fail
    dec r12d
    jnz .stress_loop

    ; R2-B exact direct-X11 cursor wire/resource lifecycle.
    call cursor_wire_test
    test eax, eax
    jnz test_fail

    xor edi, edi
    jmp test_exit
.stress_fail:
    mov dword [rel current_failure], 31
test_fail:
    mov edi, [rel current_failure]
test_exit:
    mov eax, SYS_EXIT
    syscall
    ud2

; EDX=x, ECX=y, R9D=expected direction. Returns 0 on exact classification.
check_direction:
    push rbx
    mov ebx, r9d
    mov edi, TEST_WIDTH
    mov esi, TEST_HEIGHT
    lea r8, [rel out_value]
    call nebo_console_chrome_resize_direction
    test eax, eax
    jnz .check_fail
    cmp [rel out_value], ebx
    jne .check_fail
    xor eax, eax
    pop rbx
    ret
.check_fail:
    mov eax, 1
    pop rbx
    ret

; EDI=direction, ESI=x, EDX=y, ECX=width, R8D=height.
; Returns 0 only for a complete ConfigureNotify -> ButtonRelease transaction.
check_resize_cycle:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12d, edi
    mov r13d, esi
    mov r14d, edx
    mov r15d, ecx
    mov ebx, r8d

    lea rdi, [rel adapter]
    xor eax, eax
    mov ecx, NEBO_X11_ADAPTER_QWORDS
    cld
    rep stosq
    lea rdi, [rel window]
    mov ecx, NEBO_X11_WINDOW_QWORDS
    rep stosq
    lea rdi, [rel raw]
    mov ecx, NEBO_X11_EVENT_SIZE/8
    rep stosq
    lea rdi, [rel event]
    mov ecx, NEBO_CONSOLE_EVENT_DESCRIPTOR_QWORDS
    rep stosq

    lea rax, [rel adapter]
    mov [rel window+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], rax
    mov qword [rel window+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET], 1
    mov dword [rel window+NEBO_X11_WINDOW_XID_OFFSET], TEST_XID
    mov dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    mov qword [rel window+NEBO_X11_WINDOW_X_OFFSET], 10
    mov qword [rel window+NEBO_X11_WINDOW_Y_OFFSET], 20
    mov qword [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET], TEST_WIDTH
    mov qword [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET], TEST_HEIGHT
    mov dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 1
    mov dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_BUTTON_OFFSET], 1
    mov [rel window+NEBO_X11_WINDOW_MOVERESIZE_DIRECTION_OFFSET], r12d
    mov dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_RESIZE

    mov byte [rel raw], NEBO_X11_EVENT_CONFIGURE_NOTIFY
    mov dword [rel raw+8], TEST_XID
    mov [rel raw+16], r13w
    mov [rel raw+18], r14w
    mov [rel raw+20], r15w
    mov [rel raw+22], bx
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    test eax, eax
    jnz .cycle_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESIZED
    jne .cycle_fail
    movsxd rax, r13d
    cmp [rel window+NEBO_X11_WINDOW_X_OFFSET], rax
    jne .cycle_fail
    movsxd rax, r14d
    cmp [rel window+NEBO_X11_WINDOW_Y_OFFSET], rax
    jne .cycle_fail
    mov eax, r15d
    cmp [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET], rax
    jne .cycle_fail
    mov eax, ebx
    cmp [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET], rax
    jne .cycle_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 1
    jne .cycle_fail
    cmp [rel window+NEBO_X11_WINDOW_MOVERESIZE_DIRECTION_OFFSET], r12d
    jne .cycle_fail
    test dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_FLAGS_OFFSET], NEBO_X11_WINDOW_MOVERESIZE_FLAG_WM_PROGRESS
    jz .cycle_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_CLOSE_REQUESTED
    jnz .cycle_fail

    lea rdi, [rel raw]
    xor eax, eax
    mov ecx, NEBO_X11_EVENT_SIZE/8
    rep stosq
    mov byte [rel raw], NEBO_X11_EVENT_BUTTON_RELEASE
    mov byte [rel raw+1], 1
    mov dword [rel raw+12], TEST_XID
    mov word [rel raw+24], -1
    mov word [rel raw+26], 200
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    test eax, eax
    jnz .cycle_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_POINTER_UP
    jne .cycle_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne .cycle_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_BUTTON_OFFSET], 0
    jne .cycle_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_DIRECTION_OFFSET], 0
    jne .cycle_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_FLAGS_OFFSET], 0
    jne .cycle_fail
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    jne .cycle_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_CLOSE_REQUESTED
    jnz .cycle_fail
    xor eax, eax
    jmp .cycle_done
.cycle_fail:
    mov eax, 1
.cycle_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; One complete minimum-boundary transaction using only raw event/state seams.
; The expected tuple is provided by CHECK_BOUNDARY globals so the assertions do
; not duplicate the adapter's clamp arithmetic.
check_boundary_cycle:
    push rbx
    push r12
    push r13
    push r14
    push r15

    lea rdi, [rel adapter]
    xor eax, eax
    mov ecx, NEBO_X11_ADAPTER_QWORDS
    cld
    rep stosq
    lea rdi, [rel window]
    mov ecx, NEBO_X11_WINDOW_QWORDS
    rep stosq
    lea rdi, [rel raw]
    mov ecx, NEBO_X11_EVENT_SIZE/8
    rep stosq
    lea rdi, [rel event]
    mov ecx, NEBO_CONSOLE_EVENT_DESCRIPTOR_QWORDS
    rep stosq

    lea rax, [rel adapter]
    mov [rel window+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], rax
    mov qword [rel window+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET], 1
    mov dword [rel window+NEBO_X11_WINDOW_XID_OFFSET], TEST_XID
    mov dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    mov qword [rel window+NEBO_X11_WINDOW_X_OFFSET], 10
    mov qword [rel window+NEBO_X11_WINDOW_Y_OFFSET], 20
    mov qword [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET], TEST_WIDTH
    mov qword [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET], TEST_HEIGHT
    mov qword [rel window+NEBO_X11_WINDOW_MINIMUM_WIDTH_OFFSET], NEBO_CHROME_MIN_WINDOW_WIDTH_PX
    mov qword [rel window+NEBO_X11_WINDOW_MINIMUM_HEIGHT_OFFSET], NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
    mov dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 1
    mov dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_BUTTON_OFFSET], 1
    mov eax, [rel boundary_direction]
    mov [rel window+NEBO_X11_WINDOW_MOVERESIZE_DIRECTION_OFFSET], eax
    mov dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_RESIZE
    ; Model one already-normalized pending Scan text event. Geometry and
    ; moveresize cleanup must not consume or corrupt it.
    mov dword [rel window+NEBO_X11_WINDOW_PENDING_INPUT_KIND_OFFSET], NEBO_CONSOLE_EVENT_TEXT_INPUT
    mov qword [rel window+NEBO_X11_WINDOW_PENDING_INPUT_PAYLOAD0_OFFSET], 0x6b4f
    mov qword [rel window+NEBO_X11_WINDOW_PENDING_INPUT_PAYLOAD1_OFFSET], 2

    mov byte [rel raw], NEBO_X11_EVENT_CONFIGURE_NOTIFY
    mov dword [rel raw+8], TEST_XID
    mov eax, [rel boundary_raw_x]
    mov [rel raw+16], ax
    mov eax, [rel boundary_raw_y]
    mov [rel raw+18], ax
    mov eax, [rel boundary_raw_width]
    mov [rel raw+20], ax
    mov eax, [rel boundary_raw_height]
    mov [rel raw+22], ax
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    test eax, eax
    jnz .boundary_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESIZED
    jne .boundary_fail
    movsxd rax, dword [rel boundary_expected_x]
    cmp [rel window+NEBO_X11_WINDOW_X_OFFSET], rax
    jne .boundary_fail
    movsxd rax, dword [rel boundary_expected_y]
    cmp [rel window+NEBO_X11_WINDOW_Y_OFFSET], rax
    jne .boundary_fail
    mov eax, [rel boundary_expected_width]
    cmp [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET], rax
    jne .boundary_fail
    cmp [rel event+NEBO_CONSOLE_EVENT_PAYLOAD0_OFFSET], rax
    jne .boundary_fail
    cmp rax, NEBO_CHROME_MIN_WINDOW_WIDTH_PX
    jb .boundary_fail
    mov eax, [rel boundary_expected_height]
    cmp [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET], rax
    jne .boundary_fail
    cmp [rel event+NEBO_CONSOLE_EVENT_PAYLOAD1_OFFSET], rax
    jne .boundary_fail
    cmp rax, NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
    jb .boundary_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 1
    jne .boundary_fail
    test dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_FLAGS_OFFSET], NEBO_X11_WINDOW_MOVERESIZE_FLAG_WM_PROGRESS
    jz .boundary_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_CLOSE_REQUESTED
    jnz .boundary_fail
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_INPUT_KIND_OFFSET], NEBO_CONSOLE_EVENT_TEXT_INPUT
    jne .boundary_fail
    cmp qword [rel window+NEBO_X11_WINDOW_PENDING_INPUT_PAYLOAD0_OFFSET], 0x6b4f
    jne .boundary_fail
    cmp qword [rel window+NEBO_X11_WINDOW_PENDING_INPUT_PAYLOAD1_OFFSET], 2
    jne .boundary_fail

    ; Matching release remains the only cleanup owner.
    lea rdi, [rel raw]
    xor eax, eax
    mov ecx, NEBO_X11_EVENT_SIZE/8
    rep stosq
    mov byte [rel raw], NEBO_X11_EVENT_BUTTON_RELEASE
    mov byte [rel raw+1], 1
    mov dword [rel raw+12], TEST_XID
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    test eax, eax
    jnz .boundary_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_POINTER_UP
    jne .boundary_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne .boundary_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_BUTTON_OFFSET], 0
    jne .boundary_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_DIRECTION_OFFSET], 0
    jne .boundary_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_FLAGS_OFFSET], 0
    jne .boundary_fail
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    jne .boundary_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_CLOSE_REQUESTED
    jnz .boundary_fail
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_INPUT_KIND_OFFSET], NEBO_CONSOLE_EVENT_TEXT_INPUT
    jne .boundary_fail
    cmp qword [rel window+NEBO_X11_WINDOW_PENDING_INPUT_PAYLOAD0_OFFSET], 0x6b4f
    jne .boundary_fail
    cmp qword [rel window+NEBO_X11_WINDOW_PENDING_INPUT_PAYLOAD1_OFFSET], 2
    jne .boundary_fail
    xor eax, eax
    jmp .boundary_done
.boundary_fail:
    mov eax, 1
.boundary_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; BND-012: a clamped LEFT transaction can immediately grow normally.
boundary_grow_test:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov dword [rel boundary_direction], NEBO_X11_NET_WM_MOVERESIZE_SIZE_LEFT
    mov dword [rel boundary_raw_x], 649
    mov dword [rel boundary_raw_y], 20
    mov dword [rel boundary_raw_width], 1
    mov dword [rel boundary_raw_height], 400
    mov dword [rel boundary_expected_x], 522
    mov dword [rel boundary_expected_y], 20
    mov dword [rel boundary_expected_width], 128
    mov dword [rel boundary_expected_height], 400
    call check_boundary_cycle
    test eax, eax
    jnz .grow_fail

    mov dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 1
    mov dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_BUTTON_OFFSET], 1
    mov dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_DIRECTION_OFFSET], NEBO_X11_NET_WM_MOVERESIZE_SIZE_LEFT
    mov dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_RESIZE
    lea rdi, [rel raw]
    xor eax, eax
    mov ecx, NEBO_X11_EVENT_SIZE/8
    rep stosq
    mov byte [rel raw], NEBO_X11_EVENT_CONFIGURE_NOTIFY
    mov dword [rel raw+8], TEST_XID
    mov word [rel raw+16], 500
    mov word [rel raw+18], 20
    mov word [rel raw+20], 150
    mov word [rel raw+22], 400
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    test eax, eax
    jnz .grow_fail
    cmp qword [rel window+NEBO_X11_WINDOW_X_OFFSET], 500
    jne .grow_fail
    cmp qword [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET], 150
    jne .grow_fail
    cmp qword [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET], 400
    jne .grow_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_CLOSE_REQUESTED
    jnz .grow_fail

    lea rdi, [rel raw]
    xor eax, eax
    mov ecx, NEBO_X11_EVENT_SIZE/8
    rep stosq
    mov byte [rel raw], NEBO_X11_EVENT_BUTTON_RELEASE
    mov byte [rel raw+1], 1
    mov dword [rel raw+12], TEST_XID
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    test eax, eax
    jnz .grow_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne .grow_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_FLAGS_OFFSET], 0
    jne .grow_fail
    xor eax, eax
    jmp .grow_done
.grow_fail:
    mov eax, 1
.grow_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; BND-013: clamp -> maximized geometry -> restored geometry preserves the
; minimum viewport and idle moveresize state. Actual EWMH state completion is
; owned by the WS-BND GetProperty suite; ConfigureNotify is geometry-only.
boundary_maximize_restore_test:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov dword [rel boundary_direction], NEBO_X11_NET_WM_MOVERESIZE_SIZE_LEFT
    mov dword [rel boundary_raw_x], 649
    mov dword [rel boundary_raw_y], 20
    mov dword [rel boundary_raw_width], 1
    mov dword [rel boundary_raw_height], 400
    mov dword [rel boundary_expected_x], 522
    mov dword [rel boundary_expected_y], 20
    mov dword [rel boundary_expected_width], 128
    mov dword [rel boundary_expected_height], 400
    call check_boundary_cycle
    test eax, eax
    jnz .max_restore_fail

    mov dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_MAXIMIZE
    mov qword [rel window+NEBO_X11_WINDOW_PENDING_PROTOCOL_SEQUENCE_OFFSET], 1
    lea rdi, [rel raw]
    xor eax, eax
    mov ecx, NEBO_X11_EVENT_SIZE/8
    rep stosq
    mov byte [rel raw], NEBO_X11_EVENT_CONFIGURE_NOTIFY
    mov word [rel raw+2], 1
    mov dword [rel raw+8], TEST_XID
    mov word [rel raw+16], 0
    mov word [rel raw+18], 0
    mov word [rel raw+20], 1000
    mov word [rel raw+22], 700
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    test eax, eax
    jnz .max_restore_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESIZED
    jne .max_restore_fail
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_MAXIMIZE
    jne .max_restore_fail
    or dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    mov dword [rel window+NEBO_X11_WINDOW_EWMH_STATE_FLAGS_OFFSET], NEBO_X11_WINDOW_EWMH_FLAG_MAXIMIZED
    mov dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE

    mov dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_RESTORE
    mov qword [rel window+NEBO_X11_WINDOW_PENDING_PROTOCOL_SEQUENCE_OFFSET], 2
    lea rdi, [rel raw]
    xor eax, eax
    mov ecx, NEBO_X11_EVENT_SIZE/8
    rep stosq
    mov byte [rel raw], NEBO_X11_EVENT_CONFIGURE_NOTIFY
    mov word [rel raw+2], 2
    mov dword [rel raw+8], TEST_XID
    mov word [rel raw+16], 522
    mov word [rel raw+18], 20
    mov word [rel raw+20], 128
    mov word [rel raw+22], 400
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    test eax, eax
    jnz .max_restore_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESIZED
    jne .max_restore_fail
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_RESTORE
    jne .max_restore_fail
    and dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], ~NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    mov dword [rel window+NEBO_X11_WINDOW_EWMH_STATE_FLAGS_OFFSET], 0
    mov dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    jnz .max_restore_fail
    cmp qword [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET], 128
    jne .max_restore_fail
    cmp qword [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET], 400
    jne .max_restore_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne .max_restore_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_CLOSE_REQUESTED
    jnz .max_restore_fail
    xor eax, eax
    jmp .max_restore_done
.max_restore_fail:
    mov eax, 1
.max_restore_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; BND-015: normal WM_DELETE after a minimum clamp remains a clean close event.
boundary_close_test:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov dword [rel boundary_direction], NEBO_X11_NET_WM_MOVERESIZE_SIZE_LEFT
    mov dword [rel boundary_raw_x], 649
    mov dword [rel boundary_raw_y], 20
    mov dword [rel boundary_raw_width], 1
    mov dword [rel boundary_raw_height], 400
    mov dword [rel boundary_expected_x], 522
    mov dword [rel boundary_expected_y], 20
    mov dword [rel boundary_expected_width], 128
    mov dword [rel boundary_expected_height], 400
    call check_boundary_cycle
    test eax, eax
    jnz .boundary_close_fail

    mov dword [rel adapter+NEBO_X11_ADAPTER_WM_PROTOCOLS_ATOM_OFFSET], 0x11112222
    mov dword [rel adapter+NEBO_X11_ADAPTER_WM_DELETE_WINDOW_ATOM_OFFSET], 0x33334444
    lea rdi, [rel raw]
    xor eax, eax
    mov ecx, NEBO_X11_EVENT_SIZE/8
    rep stosq
    mov byte [rel raw], NEBO_X11_EVENT_CLIENT_MESSAGE
    mov byte [rel raw+1], 32
    mov dword [rel raw+4], TEST_XID
    mov dword [rel raw+8], 0x11112222
    mov dword [rel raw+12], 0x33334444
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    test eax, eax
    jnz .boundary_close_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_CLOSE_REQUESTED
    jne .boundary_close_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_CLOSE_REQUESTED
    jz .boundary_close_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne .boundary_close_fail
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_INPUT_KIND_OFFSET], NEBO_CONSOLE_EVENT_TEXT_INPUT
    jne .boundary_close_fail
    xor eax, eax
    jmp .boundary_close_done
.boundary_close_fail:
    mov eax, 1
.boundary_close_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

minimum_size_wire_test:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov dword [rel current_failure], 74
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
    js .minimum_test_fail
    mov eax, [rel socket_fds]
    mov [rel adapter+NEBO_X11_ADAPTER_FD_OFFSET], rax
    mov dword [rel adapter+NEBO_X11_ADAPTER_STATE_OFFSET], NEBO_PLATFORM_ADAPTER_STATE_READY
    mov dword [rel adapter+NEBO_X11_ADAPTER_FLAGS_OFFSET], NEBO_X11_ADAPTER_REQUIRED_FLAGS
    mov qword [rel adapter+NEBO_X11_ADAPTER_CAPABILITIES_OFFSET], NEBO_PLATFORM_MF053_REQUIRED_CAPABILITIES
    mov qword [rel adapter+NEBO_X11_ADAPTER_REQUIRED_CAPABILITIES_OFFSET], NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
    lea rax, [rel scratch]
    mov [rel adapter+NEBO_X11_ADAPTER_SCRATCH_PTR_OFFSET], rax
    mov qword [rel adapter+NEBO_X11_ADAPTER_SCRATCH_CAPACITY_OFFSET], NEBO_X11_MIN_SCRATCH_CAPACITY
    mov qword [rel adapter+NEBO_X11_ADAPTER_SCALE_FACTOR_OFFSET], NEBO_PLATFORM_SCALE_ONE
    lea rdi, [rel adapter+NEBO_X11_ADAPTER_REPORT_OFFSET]
    mov rsi, NEBO_X11_ADAPTER_ID_HASH
    mov rdx, NEBO_PLATFORM_MF053_REQUIRED_CAPABILITIES
    mov rcx, NEBO_PLATFORM_SCALE_ONE
    mov r8d, NEBO_PLATFORM_REPORT_REQUIRED_FLAGS
    call nebo_platform_report_init
    test eax, eax
    jnz .minimum_test_close
    mov qword [rel adapter+NEBO_X11_ADAPTER_REPORT_OFFSET+NEBO_PLATFORM_REPORT_REQUIRED_CAPABILITIES_OFFSET], NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
    lea rax, [rel adapter]
    mov [rel window+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], rax
    mov qword [rel window+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET], 1
    mov dword [rel window+NEBO_X11_WINDOW_XID_OFFSET], TEST_XID
    mov dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_UNMAPPED

    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, NEBO_CHROME_MIN_WINDOW_WIDTH_PX
    mov ecx, NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
    call nebo_x11_adapter_set_window_minimum_size
    test eax, eax
    jnz .minimum_test_close
    mov edi, [rel socket_fds+4]
    lea rsi, [rel wire]
    mov edx, NEBO_X11_ICCCM_SIZE_HINT_REQUEST_BYTES
    call read_exact
    test eax, eax
    jnz .minimum_test_close
    cmp byte [rel wire], NEBO_X11_OP_CHANGE_PROPERTY
    jne .minimum_test_close
    cmp byte [rel wire+1], NEBO_X11_PROP_MODE_REPLACE
    jne .minimum_test_close
    cmp word [rel wire+2], NEBO_X11_ICCCM_SIZE_HINT_REQUEST_UNITS
    jne .minimum_test_close
    cmp dword [rel wire+4], TEST_XID
    jne .minimum_test_close
    cmp dword [rel wire+8], NEBO_X11_ATOM_WM_NORMAL_HINTS
    jne .minimum_test_close
    cmp dword [rel wire+12], NEBO_X11_ATOM_WM_SIZE_HINTS
    jne .minimum_test_close
    cmp byte [rel wire+16], 32
    jne .minimum_test_close
    cmp dword [rel wire+20], NEBO_X11_ICCCM_SIZE_HINT_ELEMENT_COUNT
    jne .minimum_test_close
    cmp dword [rel wire+24], NEBO_X11_ICCCM_SIZE_HINT_P_MIN_SIZE
    jne .minimum_test_close
    cmp dword [rel wire+44], NEBO_CHROME_MIN_WINDOW_WIDTH_PX
    jne .minimum_test_close
    cmp dword [rel wire+48], NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
    jne .minimum_test_close
    cmp qword [rel window+NEBO_X11_WINDOW_MINIMUM_WIDTH_OFFSET], NEBO_CHROME_MIN_WINDOW_WIDTH_PX
    jne .minimum_test_close
    cmp qword [rel window+NEBO_X11_WINDOW_MINIMUM_HEIGHT_OFFSET], NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
    jne .minimum_test_close
    cmp qword [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET], 1
    jne .minimum_test_close

    ; Invalid zero width cannot mutate state or emit another request.
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    xor edx, edx
    mov ecx, NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
    call nebo_x11_adapter_set_window_minimum_size
    cmp eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
    jne .minimum_test_close
    cmp qword [rel window+NEBO_X11_WINDOW_MINIMUM_WIDTH_OFFSET], NEBO_CHROME_MIN_WINDOW_WIDTH_PX
    jne .minimum_test_close
    cmp qword [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET], 1
    jne .minimum_test_close

    mov eax, SYS_CLOSE
    mov edi, [rel socket_fds]
    syscall
    mov eax, SYS_CLOSE
    mov edi, [rel socket_fds+4]
    syscall
    xor eax, eax
    jmp .minimum_test_done
.minimum_test_close:
    mov eax, SYS_CLOSE
    mov edi, [rel socket_fds]
    syscall
    mov eax, SYS_CLOSE
    mov edi, [rel socket_fds+4]
    syscall
.minimum_test_fail:
    mov eax, 1
.minimum_test_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

cursor_wire_test:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov dword [rel current_failure], 40
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
    js .cursor_test_fail
    mov eax, [rel socket_fds]
    mov [rel adapter+NEBO_X11_ADAPTER_FD_OFFSET], rax
    mov dword [rel adapter+NEBO_X11_ADAPTER_STATE_OFFSET], NEBO_PLATFORM_ADAPTER_STATE_READY
    mov dword [rel adapter+NEBO_X11_ADAPTER_FLAGS_OFFSET], NEBO_X11_ADAPTER_REQUIRED_FLAGS
    mov qword [rel adapter+NEBO_X11_ADAPTER_CAPABILITIES_OFFSET], NEBO_PLATFORM_MF053_REQUIRED_CAPABILITIES
    mov qword [rel adapter+NEBO_X11_ADAPTER_REQUIRED_CAPABILITIES_OFFSET], NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
    mov dword [rel adapter+NEBO_X11_ADAPTER_RESOURCE_ID_BASE_OFFSET], 0x02000000
    mov dword [rel adapter+NEBO_X11_ADAPTER_RESOURCE_ID_MASK_OFFSET], 0x001fffff
    lea rax, [rel scratch]
    mov [rel adapter+NEBO_X11_ADAPTER_SCRATCH_PTR_OFFSET], rax
    mov qword [rel adapter+NEBO_X11_ADAPTER_SCRATCH_CAPACITY_OFFSET], NEBO_X11_MIN_SCRATCH_CAPACITY
    mov qword [rel adapter+NEBO_X11_ADAPTER_SCALE_FACTOR_OFFSET], NEBO_PLATFORM_SCALE_ONE
    lea rdi, [rel adapter+NEBO_X11_ADAPTER_REPORT_OFFSET]
    mov rsi, NEBO_X11_ADAPTER_ID_HASH
    mov rdx, NEBO_PLATFORM_MF053_REQUIRED_CAPABILITIES
    mov rcx, NEBO_PLATFORM_SCALE_ONE
    mov r8d, NEBO_PLATFORM_REPORT_REQUIRED_FLAGS
    call nebo_platform_report_init
    test eax, eax
    jnz .cursor_test_close
    mov qword [rel adapter+NEBO_X11_ADAPTER_REPORT_OFFSET+NEBO_PLATFORM_REPORT_REQUIRED_CAPABILITIES_OFFSET], NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
    lea rax, [rel adapter]
    mov [rel window+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], rax
    mov rax, 0x0000000100000001
    mov [rel window+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET], rax
    mov dword [rel window+NEBO_X11_WINDOW_XID_OFFSET], TEST_XID
    mov dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    mov dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAPPED

    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, NEBO_X11_CURSOR_KIND_HORIZONTAL
    call nebo_x11_adapter_set_resize_cursor
    test eax, eax
    jnz .cursor_test_close
    mov edi, [rel socket_fds+4]
    lea rsi, [rel wire]
    mov edx, 172
    call read_exact
    test eax, eax
    jnz .cursor_test_close

    cmp byte [rel wire], NEBO_X11_OP_OPEN_FONT
    jne .cursor_test_close
    cmp word [rel wire+2], 5
    jne .cursor_test_close
    cmp word [rel wire+8], NEBO_X11_CURSOR_FONT_NAME_LENGTH
    jne .cursor_test_close
    cmp dword [rel wire+12], 0x73727563
    jne .cursor_test_close
    cmp word [rel wire+16], 0x726f
    jne .cursor_test_close
    mov r12d, [rel wire+4]
    test r12d, r12d
    jz .cursor_test_close

    lea r13, [rel wire+20]
    lea r14, [rel saved_cursor_ids]
    lea r15, [rel cursor_expected_glyphs]
    xor ebx, ebx
.verify_create_loop:
    cmp byte [r13], NEBO_X11_OP_CREATE_GLYPH_CURSOR
    jne .cursor_test_close
    cmp word [r13+2], 8
    jne .cursor_test_close
    mov eax, [r13+4]
    test eax, eax
    jz .cursor_test_close
    mov [r14+rbx*4], eax
    cmp [r13+8], r12d
    jne .cursor_test_close
    cmp [r13+12], r12d
    jne .cursor_test_close
    movzx eax, word [r15+rbx*2]
    cmp [r13+16], ax
    jne .cursor_test_close
    inc eax
    cmp [r13+18], ax
    jne .cursor_test_close
    add r13, 32
    inc ebx
    cmp ebx, 4
    jb .verify_create_loop
    cmp byte [rel wire+148], NEBO_X11_OP_CLOSE_FONT
    jne .cursor_test_close
    cmp dword [rel wire+152], r12d
    jne .cursor_test_close
    cmp byte [rel wire+156], NEBO_X11_OP_CHANGE_WINDOW_ATTRIBUTES
    jne .cursor_test_close
    cmp word [rel wire+158], 4
    jne .cursor_test_close
    cmp dword [rel wire+160], TEST_XID
    jne .cursor_test_close
    cmp dword [rel wire+164], NEBO_X11_CW_CURSOR
    jne .cursor_test_close
    mov eax, [rel saved_cursor_ids]
    cmp [rel wire+168], eax
    jne .cursor_test_close
    cmp qword [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET], 7
    jne .cursor_test_close
    cmp dword [rel adapter+NEBO_X11_ADAPTER_CURSOR_RESOURCE_STATE_OFFSET], NEBO_X11_CURSOR_RESOURCE_STATE_READY
    jne .cursor_test_close
    cmp dword [rel window+NEBO_X11_WINDOW_CURSOR_KIND_OFFSET], NEBO_X11_CURSOR_KIND_HORIZONTAL
    jne .cursor_test_close

    ; Same-kind motion performs no request or allocation.
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, NEBO_X11_CURSOR_KIND_HORIZONTAL
    call nebo_x11_adapter_set_resize_cursor
    test eax, eax
    jnz .cursor_test_close
    cmp qword [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET], 7
    jne .cursor_test_close
    cmp dword [rel adapter+NEBO_X11_ADAPTER_RESOURCE_COUNTER_OFFSET], 5
    jne .cursor_test_close

    ; Direction change reuses the vertical cursor and emits one bounded request.
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, NEBO_X11_CURSOR_KIND_VERTICAL
    call nebo_x11_adapter_set_resize_cursor
    test eax, eax
    jnz .cursor_test_close
    mov edi, [rel socket_fds+4]
    lea rsi, [rel wire]
    mov edx, 16
    call read_exact
    test eax, eax
    jnz .cursor_test_close
    mov eax, [rel saved_cursor_ids+4]
    cmp [rel wire+12], eax
    jne .cursor_test_close

    ; Controls/title/content restore the inherited cursor with XID None.
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, NEBO_X11_CURSOR_KIND_DEFAULT
    call nebo_x11_adapter_set_resize_cursor
    test eax, eax
    jnz .cursor_test_close
    mov edi, [rel socket_fds+4]
    lea rsi, [rel wire]
    mov edx, 16
    call read_exact
    test eax, eax
    jnz .cursor_test_close
    cmp dword [rel wire+12], 0
    jne .cursor_test_close
    cmp qword [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET], 9
    jne .cursor_test_close

    ; Shutdown emits one FreeCursor per resource, clears ownership, then closes.
    lea rdi, [rel adapter]
    call nebo_x11_adapter_shutdown
    test eax, eax
    jnz .cursor_test_close_peer
    mov edi, [rel socket_fds+4]
    lea rsi, [rel wire]
    mov edx, 32
    call read_exact
    test eax, eax
    jnz .cursor_test_close_peer
    xor ebx, ebx
    lea r13, [rel wire]
.verify_free_loop:
    cmp byte [r13], NEBO_X11_OP_FREE_CURSOR
    jne .cursor_test_close_peer
    cmp word [r13+2], 2
    jne .cursor_test_close_peer
    mov eax, [r14+rbx*4]
    cmp [r13+4], eax
    jne .cursor_test_close_peer
    add r13, 8
    inc ebx
    cmp ebx, 4
    jb .verify_free_loop
    cmp dword [rel adapter+NEBO_X11_ADAPTER_CURSOR_RESOURCE_STATE_OFFSET], NEBO_X11_CURSOR_RESOURCE_STATE_EMPTY
    jne .cursor_test_close_peer
    cmp dword [rel adapter+NEBO_X11_ADAPTER_CURSOR_HORIZONTAL_XID_OFFSET], 0
    jne .cursor_test_close_peer
    cmp dword [rel adapter+NEBO_X11_ADAPTER_CURSOR_VERTICAL_XID_OFFSET], 0
    jne .cursor_test_close_peer
    cmp dword [rel adapter+NEBO_X11_ADAPTER_CURSOR_NWSE_XID_OFFSET], 0
    jne .cursor_test_close_peer
    cmp dword [rel adapter+NEBO_X11_ADAPTER_CURSOR_NESW_XID_OFFSET], 0
    jne .cursor_test_close_peer
    mov eax, SYS_CLOSE
    mov edi, [rel socket_fds+4]
    syscall
    xor eax, eax
    jmp .cursor_test_done
.cursor_test_close:
    mov eax, SYS_CLOSE
    mov edi, [rel socket_fds]
    syscall
.cursor_test_close_peer:
    mov eax, SYS_CLOSE
    mov edi, [rel socket_fds+4]
    syscall
.cursor_test_fail:
    mov eax, 1
.cursor_test_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; EDI=fd, RSI=buffer, EDX=exact byte count.
read_exact:
    mov r8, rsi
    mov r9d, edx
.read_loop:
    mov eax, SYS_READ
    mov rsi, r8
    mov edx, r9d
    syscall
    test rax, rax
    jle .read_fail
    add r8, rax
    sub r9, rax
    jnz .read_loop
    xor eax, eax
    ret
.read_fail:
    mov eax, 1
    ret

section .rodata align=2
cursor_expected_glyphs: dw NEBO_X11_CURSOR_GLYPH_HORIZONTAL, NEBO_X11_CURSOR_GLYPH_VERTICAL, NEBO_X11_CURSOR_GLYPH_NWSE, NEBO_X11_CURSOR_GLYPH_NESW
