; Pre-fix TOP boundary fatal-path oracle with a real retained document.
; The runner globalizes private live symbols in a copied object. There is no
; X11 connection, input generation, display access, or pointer control.
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/live/live_console.inc"

extern nebo_console_document_init
extern nebo_console_document_append_text
extern nebo_x11_adapter_normalize_event
extern live_sync_geometry
extern live_handle_event
extern live_window
extern live_surface_capacity
extern live_render_width
extern live_render_height
extern live_input_ready
extern live_document

global _start

%define SYS_EXIT 60
%define TEST_XID 0x12345678
%define TEST_NODE_CAPACITY 16
%define TEST_TEXT_CAPACITY 128

section .rodata align=8
probe_bytes: db "Move: "
probe_descriptor:
    dq probe_bytes, 6
    dd 0
    dw NEBO_RUNTIME_TEXT_ENCODING_UTF8, NEBO_RUNTIME_TEXT_LIFETIME_STATIC

section .bss align=64
adapter: resb NEBO_X11_ADAPTER_SIZE
raw: resb NEBO_X11_EVENT_SIZE
event: resb NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
document: resb NEBO_CONSOLE_DOCUMENT_SIZE
nodes: resb TEST_NODE_CAPACITY*NEBO_CONSOLE_NODE_HEADER_SIZE
text_store: resb TEST_TEXT_CAPACITY

section .text
_start:
    lea rdi, [rel document]
    mov rsi, 0x0000000100000000
    lea rdx, [rel nodes]
    mov ecx, TEST_NODE_CAPACITY
    lea r8, [rel text_store]
    mov r9d, TEST_TEXT_CAPACITY
    call nebo_console_document_init
    test eax, eax
    jnz .document_fail
    lea rdi, [rel document]
    lea rsi, [rel probe_descriptor]
    call nebo_console_document_append_text
    test eax, eax
    jnz .document_fail

    lea rax, [rel adapter]
    mov [rel live_window+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], rax
    mov qword [rel live_window+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET], 1
    mov dword [rel live_window+NEBO_X11_WINDOW_XID_OFFSET], TEST_XID
    mov dword [rel live_window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    mov qword [rel live_window+NEBO_X11_WINDOW_MINIMUM_WIDTH_OFFSET], 128
    mov qword [rel live_window+NEBO_X11_WINDOW_MINIMUM_HEIGHT_OFFSET], 64
    mov dword [rel live_window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 1
    mov dword [rel live_window+NEBO_X11_WINDOW_MOVERESIZE_BUTTON_OFFSET], 1
    mov dword [rel live_window+NEBO_X11_WINDOW_MOVERESIZE_DIRECTION_OFFSET], NEBO_X11_NET_WM_MOVERESIZE_SIZE_TOP
    mov qword [rel live_surface_capacity], 1048576
    mov qword [rel live_render_width], 640
    mov qword [rel live_render_height], 400
    lea rax, [rel document]
    mov [rel live_document], rax
    mov qword [rel live_input_ready], 1

    ; A real TOP event one pixel below the advertised 64px minimum clamps to
    ; y=356,height=64 while preserving bottom_edge=420.
    mov byte [rel raw], NEBO_X11_EVENT_CONFIGURE_NOTIFY
    mov dword [rel raw+8], TEST_XID
    mov word [rel raw+16], 10
    mov word [rel raw+18], 357
    mov word [rel raw+20], 640
    mov word [rel raw+22], 63
    lea rdi, [rel adapter]
    lea rsi, [rel live_window]
    lea rdx, [rel raw]
    lea rcx, [rel event]
    call nebo_x11_adapter_normalize_event
    test eax, eax
    jnz .normalize_fail
    cmp qword [rel live_window+NEBO_X11_WINDOW_Y_OFFSET], 356
    jne .normalize_fail
    cmp qword [rel live_window+NEBO_X11_WINDOW_HEIGHT_OFFSET], 64
    jne .normalize_fail

    ; live_layout_resize rejects the 14px content box. live_sync maps that
    ; first layout status to render=6, and live_handle_event maps it to 3.
    call live_sync_geometry
    cmp eax, NEBO_LIVE_STATUS_RENDER
    jne .sync_fail
    lea rdi, [rel event]
    call live_handle_event
    cmp eax, NEBO_LIVE_EVENT_ERROR
    jne .handler_fail
    xor edi, edi
    jmp .exit
.document_fail:
    mov edi, 80
    jmp .exit
.normalize_fail:
    mov edi, 81
    jmp .exit
.sync_fail:
    mov edi, 82
    jmp .exit
.handler_fail:
    mov edi, 83
.exit:
    mov eax, SYS_EXIT
    syscall
    ud2

section .note.GNU-stack noalloc noexec nowrite progbits
