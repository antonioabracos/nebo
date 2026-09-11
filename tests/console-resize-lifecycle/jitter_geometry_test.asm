; NPT-CONSOLE-RESIZE-JITTER-001 chronological geometry oracle.
; Raw ConfigureNotify records are normalized locally. No display, pointer,
; keyboard, libc, or generated system input is used.
bits 64
default rel

%include "runtime/console/chrome/window_chrome.inc"
%include "runtime/console/platform/linux-x11-ewmh-direct-v0/x11_adapter.inc"

extern nebo_x11_adapter_normalize_event

global _start

%define SYS_EXIT 60
%define TEST_XID 0x12345678
%define TEST_LEFT 100
%define TEST_TOP 100
%define TEST_RIGHT 740
%define TEST_BOTTOM 500
%define TEST_STRESS_CYCLES 100
%define TEST_STEPS 5

section .rodata align=4
widths:  dd 640,650,660,650,640
heights: dd 400,410,420,410,400

section .bss align=64
adapter: resb NEBO_X11_ADAPTER_SIZE
window: resb NEBO_X11_WINDOW_SIZE
raw: resb NEBO_X11_EVENT_SIZE
event: resb NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
expected_event_sequence: resq 1
raw_sequence: resw 1
expected_x: resq 1
expected_y: resq 1

section .text
_start:
    lea rdi, [rel adapter]
    xor eax, eax
    mov ecx, NEBO_X11_ADAPTER_QWORDS
    cld
    rep stosq
    mov qword [rel expected_event_sequence], 0
    mov word [rel raw_sequence], 0
    mov ebp, TEST_STRESS_CYCLES
.stress_loop:
    xor r12d, r12d
.direction_loop:
    lea rdi, [rel window]
    xor eax, eax
    mov ecx, NEBO_X11_WINDOW_QWORDS
    cld
    rep stosq
    lea rax, [rel adapter]
    mov [rel window+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], rax
    mov qword [rel window+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET], 1
    mov dword [rel window+NEBO_X11_WINDOW_XID_OFFSET], TEST_XID
    mov dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    mov qword [rel window+NEBO_X11_WINDOW_MINIMUM_WIDTH_OFFSET], NEBO_CHROME_MIN_WINDOW_WIDTH_PX
    mov qword [rel window+NEBO_X11_WINDOW_MINIMUM_HEIGHT_OFFSET], NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
    mov dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 1
    mov dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_BUTTON_OFFSET], 1
    mov [rel window+NEBO_X11_WINDOW_MOVERESIZE_DIRECTION_OFFSET], r12d
    mov dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_RESIZE
    xor r13d, r13d
.step_loop:
    ; Horizontal-only directions retain the baseline height. Vertical-only
    ; directions retain the baseline width. Corners exercise both axes.
    lea rax, [rel widths]
    mov r14d, [rax+r13*4]
    cmp r12d, NEBO_X11_NET_WM_MOVERESIZE_SIZE_TOP
    je .baseline_width
    cmp r12d, NEBO_X11_NET_WM_MOVERESIZE_SIZE_BOTTOM
    jne .width_ready
.baseline_width:
    mov r14d, 640
.width_ready:
    lea rax, [rel heights]
    mov r15d, [rax+r13*4]
    cmp r12d, NEBO_X11_NET_WM_MOVERESIZE_SIZE_LEFT
    je .baseline_height
    cmp r12d, NEBO_X11_NET_WM_MOVERESIZE_SIZE_RIGHT
    jne .height_ready
.baseline_height:
    mov r15d, 400
.height_ready:
    mov r10d, TEST_LEFT
    cmp r12d, NEBO_X11_NET_WM_MOVERESIZE_SIZE_TOPLEFT
    je .anchor_right
    cmp r12d, NEBO_X11_NET_WM_MOVERESIZE_SIZE_BOTTOMLEFT
    je .anchor_right
    cmp r12d, NEBO_X11_NET_WM_MOVERESIZE_SIZE_LEFT
    jne .x_ready
.anchor_right:
    mov r10d, TEST_RIGHT
    sub r10d, r14d
.x_ready:
    mov r11d, TEST_TOP
    cmp r12d, NEBO_X11_NET_WM_MOVERESIZE_SIZE_TOPLEFT
    je .anchor_bottom
    cmp r12d, NEBO_X11_NET_WM_MOVERESIZE_SIZE_TOP
    je .anchor_bottom
    cmp r12d, NEBO_X11_NET_WM_MOVERESIZE_SIZE_TOPRIGHT
    jne .y_ready
.anchor_bottom:
    mov r11d, TEST_BOTTOM
    sub r11d, r15d
.y_ready:
    movsxd rax, r10d
    mov [rel expected_x], rax
    movsxd rax, r11d
    mov [rel expected_y], rax
    lea rdi, [rel raw]
    xor eax, eax
    mov ecx, NEBO_X11_EVENT_SIZE/8
    cld
    rep stosq
    lea rdi, [rel event]
    mov ecx, NEBO_CONSOLE_EVENT_DESCRIPTOR_QWORDS
    rep stosq
    mov byte [rel raw], NEBO_X11_EVENT_CONFIGURE_NOTIFY
    inc word [rel raw_sequence]
    mov ax, [rel raw_sequence]
    mov [rel raw+2], ax
    mov dword [rel raw+8], TEST_XID
    mov [rel raw+16], r10w
    mov [rel raw+18], r11w
    mov [rel raw+20], r14w
    mov [rel raw+22], r15w
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    test eax, eax
    jnz .normalize_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESIZED
    jne .normalize_fail
    inc qword [rel expected_event_sequence]
    mov rax, [rel expected_event_sequence]
    cmp [rel event+NEBO_CONSOLE_EVENT_ID_OFFSET], rax
    jne .generation_fail
    cmp [rel event+NEBO_CONSOLE_EVENT_SEQUENCE_OFFSET], rax
    jne .generation_fail
    cmp [rel window+NEBO_X11_WINDOW_LAST_EVENT_SEQUENCE_OFFSET], rax
    jne .generation_fail
    mov rax, [rel expected_x]
    cmp [rel window+NEBO_X11_WINDOW_X_OFFSET], rax
    jne .geometry_fail
    mov rax, [rel expected_y]
    cmp [rel window+NEBO_X11_WINDOW_Y_OFFSET], rax
    jne .geometry_fail
    mov eax, r14d
    cmp [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET], rax
    jne .geometry_fail
    cmp [rel event+NEBO_CONSOLE_EVENT_PAYLOAD0_OFFSET], rax
    jne .geometry_fail
    mov eax, r15d
    cmp [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET], rax
    jne .geometry_fail
    cmp [rel event+NEBO_CONSOLE_EVENT_PAYLOAD1_OFFSET], rax
    jne .geometry_fail

    ; RJ-001/RJ-005/RJ-007: LEFT-bearing resize keeps RIGHT exact.
    cmp r12d, NEBO_X11_NET_WM_MOVERESIZE_SIZE_TOPLEFT
    je .check_right
    cmp r12d, NEBO_X11_NET_WM_MOVERESIZE_SIZE_BOTTOMLEFT
    je .check_right
    cmp r12d, NEBO_X11_NET_WM_MOVERESIZE_SIZE_LEFT
    jne .check_left
.check_right:
    mov rax, [rel window+NEBO_X11_WINDOW_X_OFFSET]
    add rax, [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET]
    cmp rax, TEST_RIGHT
    jne .opposite_edge_fail
    ; The three title controls are anchored to the current local RIGHT edge.
    ; Their derived root coordinates must therefore remain exact while LEFT,
    ; TOP_LEFT or BOTTOM_LEFT moves and the exterior RIGHT edge stays fixed.
    sub rax, NEBO_CHROME_CONTROL_WIDTH_PX
    cmp rax, TEST_RIGHT-NEBO_CHROME_CONTROL_WIDTH_PX
    jne .control_anchor_fail
    sub rax, NEBO_CHROME_CONTROL_WIDTH_PX
    cmp rax, TEST_RIGHT-(NEBO_CHROME_CONTROL_WIDTH_PX*2)
    jne .control_anchor_fail
    sub rax, NEBO_CHROME_CONTROL_WIDTH_PX
    cmp rax, TEST_RIGHT-NEBO_CHROME_CONTROLS_WIDTH_PX
    jne .control_anchor_fail
    jmp .check_vertical
.check_left:
    cmp qword [rel window+NEBO_X11_WINDOW_X_OFFSET], TEST_LEFT
    jne .opposite_edge_fail
.check_vertical:
    ; RJ-003/RJ-005/RJ-006: TOP-bearing resize keeps BOTTOM exact.
    cmp r12d, NEBO_X11_NET_WM_MOVERESIZE_SIZE_TOPLEFT
    je .check_bottom
    cmp r12d, NEBO_X11_NET_WM_MOVERESIZE_SIZE_TOP
    je .check_bottom
    cmp r12d, NEBO_X11_NET_WM_MOVERESIZE_SIZE_TOPRIGHT
    jne .check_top
.check_bottom:
    mov rax, [rel window+NEBO_X11_WINDOW_Y_OFFSET]
    add rax, [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET]
    cmp rax, TEST_BOTTOM
    jne .opposite_edge_fail
    jmp .step_done
.check_top:
    cmp qword [rel window+NEBO_X11_WINDOW_Y_OFFSET], TEST_TOP
    jne .opposite_edge_fail
.step_done:
    test dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_FLAGS_OFFSET], NEBO_X11_WINDOW_MOVERESIZE_FLAG_WM_PROGRESS
    jz .transaction_fail
    inc r13d
    cmp r13d, TEST_STEPS
    jb .step_loop

    ; The transaction settles to idle after the physical release event seam.
    lea rdi, [rel raw]
    xor eax, eax
    mov ecx, NEBO_X11_EVENT_SIZE/8
    cld
    rep stosq
    mov byte [rel raw], NEBO_X11_EVENT_BUTTON_RELEASE
    mov byte [rel raw+1], 1
    inc word [rel raw_sequence]
    mov ax, [rel raw_sequence]
    mov [rel raw+2], ax
    mov dword [rel raw+12], TEST_XID
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    test eax, eax
    jnz .normalize_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_POINTER_UP
    jne .transaction_fail
    inc qword [rel expected_event_sequence]
    mov rax, [rel expected_event_sequence]
    cmp [rel event+NEBO_CONSOLE_EVENT_ID_OFFSET], rax
    jne .generation_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 0
    jne .transaction_fail
    cmp dword [rel window+NEBO_X11_WINDOW_MOVERESIZE_FLAGS_OFFSET], 0
    jne .transaction_fail
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    jne .transaction_fail
    inc r12d
    cmp r12d, 8
    jb .direction_loop
    dec ebp
    jnz .stress_loop
    mov eax, SYS_EXIT
    xor edi, edi
    syscall

.normalize_fail:
    mov edi, 81
    jmp .exit
.generation_fail:
    mov edi, 82
    jmp .exit
.geometry_fail:
    mov edi, 83
    jmp .exit
.opposite_edge_fail:
    mov edi, 84
    jmp .exit
.control_anchor_fail:
    mov edi, 86
    jmp .exit
.transaction_fail:
    mov edi, 85
.exit:
    mov eax, SYS_EXIT
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
