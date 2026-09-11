; Forensic-only NPT-CONSOLE-RESIZE-R2 minimum-boundary oracle.
;
; The runner links this against a copied live_console.o whose three local
; symbols below are globalized with objcopy.  No display, pointer, synthetic
; input, or product mutation is involved.  This freezes the pre-fix status
; chain observed when ConfigureNotify has already committed width=127.
bits 64
default rel

%include "runtime/console/platform/linux-x11-ewmh-direct-v0/x11_adapter.inc"

global _start

extern live_sync_geometry
extern live_handle_event
extern live_window
extern nebo_x11_adapter_normalize_event

%define SYS_EXIT 60
%define NEBO_LIVE_STATUS_RENDER 6
%define NEBO_LIVE_EVENT_ERROR 3
%define TEST_XID 0x12345678

section .bss
adapter: resb NEBO_X11_ADAPTER_SIZE
raw: resb NEBO_X11_EVENT_SIZE
event: resb 64

section .text
_start:
    lea rax, [rel adapter]
    mov [rel live_window+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], rax
    mov qword [rel live_window+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET], 1
    mov dword [rel live_window+NEBO_X11_WINDOW_XID_OFFSET], TEST_XID
    mov dword [rel live_window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    mov dword [rel live_window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 1
    mov dword [rel live_window+NEBO_X11_WINDOW_MOVERESIZE_BUTTON_OFFSET], 1
    mov dword [rel live_window+NEBO_X11_WINDOW_MOVERESIZE_DIRECTION_OFFSET], NEBO_X11_NET_WM_MOVERESIZE_SIZE_LEFT

    ; Raw ConfigureNotify at x=523, width=127 keeps the original right edge
    ; 523+127=650 but violates the chrome's minimum width of 128.
    mov byte [rel raw], NEBO_X11_EVENT_CONFIGURE_NOTIFY
    mov dword [rel raw+8], TEST_XID
    mov word [rel raw+16], 523
    mov word [rel raw+18], 20
    mov word [rel raw+20], 127
    mov word [rel raw+22], 400
    lea rdi, [rel adapter]
    lea rsi, [rel live_window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    test eax, eax
    jnz .normalize_mismatch
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESIZED
    jne .normalize_mismatch
    cmp qword [rel live_window+NEBO_X11_WINDOW_X_OFFSET], 523
    jne .normalize_mismatch
    cmp qword [rel live_window+NEBO_X11_WINDOW_WIDTH_OFFSET], 127
    jne .normalize_mismatch
    test dword [rel live_window+NEBO_X11_WINDOW_MOVERESIZE_FLAGS_OFFSET], NEBO_X11_WINDOW_MOVERESIZE_FLAG_WM_PROGRESS
    jz .normalize_mismatch

    call live_sync_geometry
    cmp eax, NEBO_LIVE_STATUS_RENDER
    jne .sync_mismatch

    lea rdi, [rel event]
    call live_handle_event
    cmp eax, NEBO_LIVE_EVENT_ERROR
    jne .handler_mismatch

    mov eax, SYS_EXIT
    xor edi, edi
    syscall

.normalize_mismatch:
    mov eax, SYS_EXIT
    mov edi, 90
    syscall

.sync_mismatch:
    mov eax, SYS_EXIT
    mov edi, 91
    syscall

.handler_mismatch:
    mov eax, SYS_EXIT
    mov edi, 92
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
