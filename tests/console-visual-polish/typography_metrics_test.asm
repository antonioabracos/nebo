; R4 bounded real-renderer typography, coverage, monospace and caret oracle.
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/live/live_console.inc"
%include "runtime/console/live/live_typography.inc"

extern nebo_console_document_init
extern nebo_console_document_append_text
extern nebo_runtime_live_visual_render

global _start

%define SYS_EXIT 60
%define TEST_WIDTH 640
%define TEST_HEIGHT 400
%define TEST_BYTES (TEST_WIDTH*TEST_HEIGHT*4)
%define GUARD_BYTES 64
%define NODE_CAPACITY 16
%define TEXT_CAPACITY 128
%define TEST_CHAR_COUNT 9
%define TEST_RENDER_COUNT 500
%define FRAME_BACKGROUND NEBO_LIVE_CONTENT_BACKGROUND_COLOR
%define CONTENT_FOREGROUND 0xffdce7f5
%define CARET_COLOR 0xff78a9ff

section .rodata align=8
document_bytes: db "AIli.gy"
document_length equ $-document_bytes
document_descriptor:
    dq document_bytes, document_length
    dd 0
    dw NEBO_RUNTIME_TEXT_ENCODING_UTF8, NEBO_RUNTIME_TEXT_LIFETIME_STATIC
editor_bytes: db "09"
title_bytes: db "NEBO CONSOLE"

section .bss align=64
document: resb NEBO_CONSOLE_DOCUMENT_SIZE
nodes: resb NODE_CAPACITY*NEBO_CONSOLE_NODE_HEADER_SIZE
text_store: resb TEXT_CAPACITY
surface: resb NEBO_SOFTWARE_SURFACE_SIZE
guard_before: resb GUARD_BYTES
pixels: resb TEST_BYTES
guard_after: resb GUARD_BYTES
config: resb NEBO_LIVE_CONFIG_SIZE
editor: resb NEBO_TEXT_EDIT_RECORD_SIZE

section .text
_start:
    lea rdi,[rel guard_before]
    mov al,0xa5
    mov ecx,GUARD_BYTES
    rep stosb
    lea rdi,[rel guard_after]
    mov al,0x5a
    mov ecx,GUARD_BYTES
    rep stosb

    mov r12d,TEST_RENDER_COUNT
.render_loop:
    lea rdi,[rel document]
    mov rsi,0x0000000100000000
    lea rdx,[rel nodes]
    mov ecx,NODE_CAPACITY
    lea r8,[rel text_store]
    mov r9d,TEXT_CAPACITY
    call nebo_console_document_init
    test eax,eax
    jnz .document_fail
    lea rdi,[rel document]
    lea rsi,[rel document_descriptor]
    call nebo_console_document_append_text
    test eax,eax
    jnz .document_fail

    lea rdi,[rel config]
    xor eax,eax
    mov ecx,NEBO_LIVE_CONFIG_QWORDS
    rep stosq
    mov qword [rel config+NEBO_LIVE_CONFIG_WIDTH_OFFSET],TEST_WIDTH
    mov qword [rel config+NEBO_LIVE_CONFIG_HEIGHT_OFFSET],TEST_HEIGHT
    lea rax,[rel title_bytes]
    mov [rel config+NEBO_LIVE_CONFIG_TITLE_PTR_OFFSET],rax
    mov qword [rel config+NEBO_LIVE_CONFIG_TITLE_LENGTH_OFFSET],12

    lea rax,[rel editor_bytes]
    mov [rel editor+NEBO_TEXT_EDIT_BUFFER_PTR_OFFSET],rax
    mov qword [rel editor+NEBO_TEXT_EDIT_CAPACITY_OFFSET],2
    mov qword [rel editor+NEBO_TEXT_EDIT_LENGTH_OFFSET],2
    mov qword [rel editor+NEBO_TEXT_EDIT_CARET_OFFSET],2

    lea rdi,[rel document]
    lea rsi,[rel editor]
    lea rdx,[rel surface]
    lea rcx,[rel pixels]
    mov r8d,TEST_BYTES
    lea r9,[rel config]
    call nebo_runtime_live_visual_render
    test eax,eax
    jnz .render_fail
    dec r12d
    jnz .render_loop
    cmp qword [rel surface+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET],TEST_WIDTH
    jne .geometry_fail
    cmp qword [rel surface+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET],TEST_HEIGHT
    jne .geometry_fail
    cmp qword [rel surface+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET],TEST_WIDTH*4
    jne .geometry_fail
    cmp qword [rel surface+NEBO_SOFTWARE_SURFACE_GENERATION_OFFSET],TEST_RENDER_COUNT
    jne .geometry_fail

    call verify_guards
    test eax,eax
    jnz .guard_fail
    call verify_content_pixels
    test eax,eax
    jnz .pixel_fail
    call verify_caret
    test eax,eax
    jnz .caret_fail
    ; The existing minimum-window contract is frozen. Every R4 profile must
    ; render there without changing that contract or writing beyond capacity.
    mov qword [rel config+NEBO_LIVE_CONFIG_WIDTH_OFFSET],NEBO_CHROME_MIN_WINDOW_WIDTH_PX
    mov qword [rel config+NEBO_LIVE_CONFIG_HEIGHT_OFFSET],NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
    lea rdi,[rel document]
    lea rsi,[rel editor]
    lea rdx,[rel surface]
    lea rcx,[rel pixels]
    mov r8d,TEST_BYTES
    lea r9,[rel config]
    call nebo_runtime_live_visual_render
    test eax,eax
    jnz .render_fail
    cmp qword [rel surface+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET],NEBO_CHROME_MIN_WINDOW_WIDTH_PX
    jne .geometry_fail
    cmp qword [rel surface+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET],NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
    jne .geometry_fail
    call verify_guards
    test eax,eax
    jnz .guard_fail
    xor edi,edi
    jmp .exit
.document_fail:
    mov edi,80
    jmp .exit
.render_fail:
    mov edi,81
    jmp .exit
.geometry_fail:
    mov edi,82
    jmp .exit
.guard_fail:
    mov edi,83
    jmp .exit
.pixel_fail:
    mov edi,84
    jmp .exit
.caret_fail:
    mov edi,85
.exit:
    mov eax,SYS_EXIT
    syscall
    ud2

verify_guards:
    lea rdi,[rel guard_before]
    mov ecx,GUARD_BYTES
.guard_before_loop:
    cmp byte [rdi],0xa5
    jne .guard_bad
    inc rdi
    dec ecx
    jnz .guard_before_loop
    lea rdi,[rel guard_after]
    mov ecx,GUARD_BYTES
.guard_after_loop:
    cmp byte [rdi],0x5a
    jne .guard_bad
    inc rdi
    dec ecx
    jnz .guard_after_loop
    xor eax,eax
    ret
.guard_bad:
    mov eax,1
    ret

; Require ink, enforce grayscale for A/B and reject content-colour writes
; outside the nine fixed cells' bounded ink/caret row.
verify_content_pixels:
    push rbx
    push r12
    push r13
    push r14
    push r15
    xor r12d,r12d                    ; exact foreground pixels
    xor r13d,r13d                    ; intermediate grayscale pixels
    mov r14,NEBO_CHROME_HEIGHT_PX+NEBO_LIVE_CONTENT_TOP_PADDING_PX
    mov r15,r14
    add r15,NEBO_LIVE_CONTENT_CELL_HEIGHT_PX
    lea rdx,[rel pixels]
    xor ebx,ebx
.pixel_row:
    cmp rbx,TEST_HEIGHT
    jae .pixel_scanned
    mov ecx,1
.pixel_col:
    cmp ecx,TEST_WIDTH-1
    jae .pixel_next_row
    mov rax,rbx
    imul rax,TEST_WIDTH
    add rax,rcx
    mov eax,[rdx+rax*4]
    cmp eax,CONTENT_FOREGROUND
    je .pixel_exact
    cmp eax,CARET_COLOR
    je .pixel_legal_bounds
    cmp eax,FRAME_BACKGROUND
    je .pixel_continue
    ; The title/chrome has other legal colours; only classify the content row.
    cmp rbx,r14
    jb .pixel_continue
    cmp rbx,r15
    jae .pixel_continue
    inc r13
    jmp .pixel_legal_bounds
.pixel_exact:
    inc r12
.pixel_legal_bounds:
    cmp rbx,r14
    jb .pixel_bad
    cmp rbx,r15
    jae .pixel_bad
    cmp rcx,NEBO_LIVE_CONTENT_LEFT_PADDING_PX
    jb .pixel_bad
    mov rax,NEBO_LIVE_CONTENT_LEFT_PADDING_PX+(TEST_CHAR_COUNT*NEBO_LIVE_CONTENT_CELL_WIDTH_PX)+NEBO_LIVE_CONTENT_CARET_WIDTH_PX
    cmp rcx,rax
    jae .pixel_bad
.pixel_continue:
    inc ecx
    jmp .pixel_col
.pixel_next_row:
    inc rbx
    jmp .pixel_row
.pixel_scanned:
    test r12,r12
    jz .pixel_bad
%if NEBO_LIVE_CONTENT_SMOOTHING_MODE != NEBO_LIVE_SMOOTHING_OPAQUE_2X
    test r13,r13
    jz .pixel_bad
%else
    test r13,r13
    jnz .pixel_bad
%endif
    xor eax,eax
    jmp .pixel_done
.pixel_bad:
    mov eax,1
.pixel_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

verify_caret:
    mov r8,NEBO_LIVE_CONTENT_LEFT_PADDING_PX+(TEST_CHAR_COUNT*NEBO_LIVE_CONTENT_CELL_WIDTH_PX)
    mov r9,NEBO_CHROME_HEIGHT_PX+NEBO_LIVE_CONTENT_TOP_PADDING_PX+NEBO_LIVE_CONTENT_GLYPH_Y_OFFSET_PX
    lea rdx,[rel pixels]
    xor r10d,r10d
.caret_y:
    cmp r10d,NEBO_LIVE_CONTENT_GLYPH_HEIGHT_PX
    jae .caret_ok
    xor r11d,r11d
.caret_x:
    cmp r11d,NEBO_LIVE_CONTENT_CARET_WIDTH_PX
    jae .caret_next_y
    mov rax,r9
    add rax,r10
    imul rax,TEST_WIDTH
    add rax,r8
    add rax,r11
    cmp dword [rdx+rax*4],CARET_COLOR
    jne .caret_bad
    inc r11d
    jmp .caret_x
.caret_next_y:
    inc r10d
    jmp .caret_y
.caret_ok:
    xor eax,eax
    ret
.caret_bad:
    mov eax,1
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
