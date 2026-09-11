; Post-fix TOP boundary oracle with retained layout and real live visual render.
; All event work is process-local; no display, pointer, or input is used.
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/live/live_console.inc"
%include "runtime/console/render/fake_glyph_provider.inc"

extern nebo_console_document_init
extern nebo_console_document_append_text
extern nebo_fake_glyph_provider_init
extern nebo_runtime_live_visual_render
extern nebo_x11_adapter_normalize_event
extern live_layout_resize
extern live_sync_geometry
extern live_handle_event
extern live_window
extern live_surface_capacity
extern live_render_width
extern live_render_height
extern live_input_ready
extern live_document
extern live_provider

global _start

%define SYS_EXIT 60
%define TEST_XID 0x12345678
%define TEST_NODE_CAPACITY 16
%define TEST_TEXT_CAPACITY 128
%define TEST_PIXELS (640*NEBO_CHROME_MIN_WINDOW_HEIGHT_PX)
%define TEST_BYTES (TEST_PIXELS*4)

section .rodata align=8
probe_bytes: db "Move: "
probe_descriptor:
    dq probe_bytes, 6
    dd 0
    dw NEBO_RUNTIME_TEXT_ENCODING_UTF8, NEBO_RUNTIME_TEXT_LIFETIME_STATIC
title_bytes: db "NEBO CONSOLE"

section .bss align=64
adapter: resb NEBO_X11_ADAPTER_SIZE
raw: resb NEBO_X11_EVENT_SIZE
event: resb NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
document: resb NEBO_CONSOLE_DOCUMENT_SIZE
nodes: resb TEST_NODE_CAPACITY*NEBO_CONSOLE_NODE_HEADER_SIZE
text_store: resb TEST_TEXT_CAPACITY
visual_surface: resb NEBO_SOFTWARE_SURFACE_SIZE
visual_pixels: resb TEST_BYTES
visual_config: resb NEBO_LIVE_CONFIG_SIZE

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
    lea rdi, [rel live_provider]
    call nebo_fake_glyph_provider_init
    test eax, eax
    jnz .layout_fail

    ; The exact 66px minimum must support one retained 16px line.
    lea rax, [rel document]
    mov [rel live_document], rax
    mov qword [rel live_render_width], 640
    mov qword [rel live_render_height], NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
    call live_layout_resize
    test eax, eax
    jnz .layout_fail

    ; Exercise the actual custom-chrome/document visual renderer at 640x66.
    mov qword [rel visual_config+NEBO_LIVE_CONFIG_WIDTH_OFFSET], 640
    mov qword [rel visual_config+NEBO_LIVE_CONFIG_HEIGHT_OFFSET], NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
    lea rax, [rel title_bytes]
    mov [rel visual_config+NEBO_LIVE_CONFIG_TITLE_PTR_OFFSET], rax
    mov qword [rel visual_config+NEBO_LIVE_CONFIG_TITLE_LENGTH_OFFSET], 12
    lea rdi, [rel document]
    xor esi, esi
    lea rdx, [rel visual_surface]
    lea rcx, [rel visual_pixels]
    mov r8d, TEST_BYTES
    lea r9, [rel visual_config]
    call nebo_runtime_live_visual_render
    test eax, eax
    jnz .visual_fail
    cmp qword [rel visual_surface+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET], 640
    jne .visual_fail
    cmp qword [rel visual_surface+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET], NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
    jne .visual_fail

    lea rax, [rel adapter]
    mov [rel live_window+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], rax
    mov qword [rel live_window+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET], 1
    mov dword [rel live_window+NEBO_X11_WINDOW_XID_OFFSET], TEST_XID
    mov dword [rel live_window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    mov qword [rel live_window+NEBO_X11_WINDOW_MINIMUM_WIDTH_OFFSET], NEBO_CHROME_MIN_WINDOW_WIDTH_PX
    mov qword [rel live_window+NEBO_X11_WINDOW_MINIMUM_HEIGHT_OFFSET], NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
    mov dword [rel live_window+NEBO_X11_WINDOW_MOVERESIZE_ACTIVE_OFFSET], 1
    mov dword [rel live_window+NEBO_X11_WINDOW_MOVERESIZE_BUTTON_OFFSET], 1
    mov dword [rel live_window+NEBO_X11_WINDOW_MOVERESIZE_DIRECTION_OFFSET], NEBO_X11_NET_WM_MOVERESIZE_SIZE_TOP
    mov qword [rel live_surface_capacity], TEST_BYTES

    ; raw bottom edge=420. Clamp to y=354,height=66.
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
    cmp qword [rel live_window+NEBO_X11_WINDOW_Y_OFFSET], 354
    jne .normalize_fail
    cmp qword [rel live_window+NEBO_X11_WINDOW_HEIGHT_OFFSET], NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
    jne .normalize_fail

    ; Geometry status is isolated from X11 presentation here; retained layout
    ; and actual visual rendering were already proven above with the same doc.
    mov qword [rel live_document], 0
    mov qword [rel live_input_ready], 0
    call live_sync_geometry
    test eax, eax
    jnz .sync_fail
    lea rdi, [rel event]
    call live_handle_event
    cmp eax, NEBO_LIVE_EVENT_CONSUMED
    jne .handler_fail
    xor edi, edi
    jmp .exit
.document_fail:
    mov edi, 90
    jmp .exit
.layout_fail:
    mov edi, 91
    jmp .exit
.visual_fail:
    mov edi, 92
    jmp .exit
.normalize_fail:
    mov edi, 93
    jmp .exit
.sync_fail:
    mov edi, 94
    jmp .exit
.handler_fail:
    mov edi, 95
.exit:
    mov eax, SYS_EXIT
    syscall
    ud2

section .note.GNU-stack noalloc noexec nowrite progbits
