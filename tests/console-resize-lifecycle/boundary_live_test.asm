; Post-fix NPT-CONSOLE-RESIZE-R2 minimum-boundary live oracle.
;
; The runner globalizes selected local symbols in a copied live_console.o.
; This uses only the raw event normalizer and internal event handler: no X11
; connection, pointer input, or synthetic system event is involved.
bits 64
default rel

%include "runtime/console/platform/linux-x11-ewmh-direct-v0/x11_adapter.inc"
%include "runtime/console/chrome/window_chrome.inc"

global _start

extern live_sync_geometry
extern live_handle_event
extern live_window
extern live_surface_capacity
extern live_render_width
extern live_render_height
extern nebo_x11_adapter_normalize_event

%define SYS_EXIT 60
%define NEBO_LIVE_EVENT_CONSUMED 1
%define TEST_XID 0x12345678
%define BOUNDARY_CASE_DWORDS 9
%define BOUNDARY_CASE_BYTES (BOUNDARY_CASE_DWORDS*4)

section .rodata align=4
; raw x,y,width,height; moveresize direction; expected x,y,width,height.
; The first ten rows are BND-001..010. The remaining four complete the eight
; supported resize directions at a below-minimum boundary.
boundary_cases:
    dd 522,20,128,400,NEBO_X11_NET_WM_MOVERESIZE_SIZE_LEFT,522,20,128,400
    dd 523,20,127,400,NEBO_X11_NET_WM_MOVERESIZE_SIZE_LEFT,522,20,128,400
    dd 649,20,1,400,NEBO_X11_NET_WM_MOVERESIZE_SIZE_LEFT,522,20,128,400
    dd 650,20,0,400,NEBO_X11_NET_WM_MOVERESIZE_SIZE_LEFT,522,20,128,400
    dd 645,20,5,400,NEBO_X11_NET_WM_MOVERESIZE_SIZE_LEFT,522,20,128,400
    dd 10,354,640,66,NEBO_X11_NET_WM_MOVERESIZE_SIZE_TOP,10,354,640,66
    dd 10,355,640,65,NEBO_X11_NET_WM_MOVERESIZE_SIZE_TOP,10,354,640,66
    dd 10,419,640,1,NEBO_X11_NET_WM_MOVERESIZE_SIZE_TOP,10,354,640,66
    dd 10,20,127,63,NEBO_X11_NET_WM_MOVERESIZE_SIZE_BOTTOMRIGHT,10,20,128,66
    dd 523,357,127,63,NEBO_X11_NET_WM_MOVERESIZE_SIZE_TOPLEFT,522,354,128,66
    dd 10,20,127,400,NEBO_X11_NET_WM_MOVERESIZE_SIZE_RIGHT,10,20,128,400
    dd 10,20,640,63,NEBO_X11_NET_WM_MOVERESIZE_SIZE_BOTTOM,10,20,640,66
    dd 10,357,127,63,NEBO_X11_NET_WM_MOVERESIZE_SIZE_TOPRIGHT,10,354,128,66
    dd 523,20,127,63,NEBO_X11_NET_WM_MOVERESIZE_SIZE_BOTTOMLEFT,522,20,128,66
boundary_case_count equ ($-boundary_cases)/BOUNDARY_CASE_BYTES

section .bss
adapter: resb NEBO_X11_ADAPTER_SIZE
raw: resb NEBO_X11_EVENT_SIZE
event: resb NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE

section .text
_start:
    lea rax, [rel adapter]
    mov [rel live_window+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], rax
    mov qword [rel live_window+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET], 1
    mov dword [rel live_window+NEBO_X11_WINDOW_XID_OFFSET], TEST_XID
    mov dword [rel live_window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    mov qword [rel live_window+NEBO_X11_WINDOW_MINIMUM_WIDTH_OFFSET], NEBO_CHROME_MIN_WINDOW_WIDTH_PX
    mov qword [rel live_window+NEBO_X11_WINDOW_MINIMUM_HEIGHT_OFFSET], NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
    ; Capacity is screen-owned in the real runtime. A null document makes
    ; repaint a deterministic no-op while retaining the exact geometry path.
    mov qword [rel live_surface_capacity], 204800
    lea r12, [rel boundary_cases]
    mov r13d, boundary_case_count
.case_loop:
    mov dword [rel live_window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 1
    mov dword [rel live_window+NEBO_X11_WINDOW_MOVERESIZE_BUTTON_OFFSET], 1
    mov eax, [r12+16]
    mov [rel live_window+NEBO_X11_WINDOW_MOVERESIZE_DIRECTION_OFFSET], eax

    mov byte [rel raw], NEBO_X11_EVENT_CONFIGURE_NOTIFY
    mov dword [rel raw+8], TEST_XID
    mov eax, [r12]
    mov [rel raw+16], ax
    mov eax, [r12+4]
    mov [rel raw+18], ax
    mov eax, [r12+8]
    mov [rel raw+20], ax
    mov eax, [r12+12]
    mov [rel raw+22], ax
    lea rdi, [rel adapter]
    lea rsi, [rel live_window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    test eax, eax
    jnz .normalize_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESIZED
    jne .normalize_fail
    movsxd rax, dword [r12+20]
    cmp [rel live_window+NEBO_X11_WINDOW_X_OFFSET], rax
    jne .normalize_fail
    movsxd rax, dword [r12+24]
    cmp [rel live_window+NEBO_X11_WINDOW_Y_OFFSET], rax
    jne .normalize_fail
    mov eax, [r12+28]
    cmp [rel live_window+NEBO_X11_WINDOW_WIDTH_OFFSET], rax
    jne .normalize_fail
    cmp [rel event+NEBO_CONSOLE_EVENT_PAYLOAD0_OFFSET], rax
    jne .normalize_fail
    mov eax, [r12+32]
    cmp [rel live_window+NEBO_X11_WINDOW_HEIGHT_OFFSET], rax
    jne .normalize_fail
    cmp [rel event+NEBO_CONSOLE_EVENT_PAYLOAD1_OFFSET], rax
    jne .normalize_fail

    call live_sync_geometry
    test eax, eax
    jnz .sync_fail
    mov eax, [r12+28]
    cmp [rel live_render_width], rax
    jne .sync_fail
    mov eax, [r12+32]
    cmp [rel live_render_height], rax
    jne .sync_fail

    lea rdi, [rel event]
    call live_handle_event
    cmp eax, NEBO_LIVE_EVENT_CONSUMED
    jne .handler_fail

    add r12, BOUNDARY_CASE_BYTES
    dec r13d
    jnz .case_loop

    mov eax, SYS_EXIT
    xor edi, edi
    syscall

.normalize_fail:
    mov edi, 90
    jmp .exit
.sync_fail:
    mov edi, 91
    jmp .exit
.handler_fail:
    mov edi, 92
.exit:
    mov eax, SYS_EXIT
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
