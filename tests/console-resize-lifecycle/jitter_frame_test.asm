; NPT-CONSOLE-RESIZE-JITTER-001 renderer border-coordinate oracle.
; Exercises 500 current-geometry renders and rejects the border colour at any
; interior pixel. No X11 connection, input generation, or libc is used.
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/live/live_console.inc"

extern nebo_console_document_init
extern nebo_console_document_append_text
extern nebo_runtime_live_visual_render

global _start

%define SYS_EXIT 60
%define TEST_COUNT 500
%define NODE_CAPACITY 16
%define TEXT_CAPACITY 128
%define MAX_WIDTH 700
%define MAX_HEIGHT 500
%define MAX_BYTES (MAX_WIDTH*MAX_HEIGHT*4)
%define INNER_STRIP_DEPTH 12

section .rodata align=8
probe_bytes: db "JITTER FRAME"
probe_length equ $-probe_bytes
probe_descriptor:
    dq probe_bytes, probe_length
    dd 0
    dw NEBO_RUNTIME_TEXT_ENCODING_UTF8, NEBO_RUNTIME_TEXT_LIFETIME_STATIC
title_bytes: db "NEBO CONSOLE"
geometry_table:
    dq 640,400
    dq 650,400
    dq 660,400
    dq 650,400
    dq 640,400
    dq 640,410
    dq 640,420
    dq 640,410
geometry_count equ ($-geometry_table)/16

section .bss align=64
document: resb NEBO_CONSOLE_DOCUMENT_SIZE
nodes: resb NODE_CAPACITY*NEBO_CONSOLE_NODE_HEADER_SIZE
text_store: resb TEXT_CAPACITY
surface: resb NEBO_SOFTWARE_SURFACE_SIZE
pixels: resb MAX_BYTES
config: resb NEBO_LIVE_CONFIG_SIZE
previous_width: resq 1
previous_height: resq 1

section .text
_start:
    lea rdi, [rel document]
    mov rsi, 0x0000000100000000
    lea rdx, [rel nodes]
    mov ecx, NODE_CAPACITY
    lea r8, [rel text_store]
    mov r9d, TEXT_CAPACITY
    call nebo_console_document_init
    test eax, eax
    jnz test_document_fail
    lea rdi, [rel document]
    lea rsi, [rel probe_descriptor]
    call nebo_console_document_append_text
    test eax, eax
    jnz test_document_fail
    lea rdi, [rel config]
    xor eax, eax
    mov ecx, NEBO_LIVE_CONFIG_QWORDS
    cld
    rep stosq
    lea rax, [rel title_bytes]
    mov [rel config+NEBO_LIVE_CONFIG_TITLE_PTR_OFFSET], rax
    mov qword [rel config+NEBO_LIVE_CONFIG_TITLE_LENGTH_OFFSET], 12
    xor r12d, r12d
    mov r13d, TEST_COUNT
.render_loop:
    mov eax, r12d
    xor edx, edx
    mov ecx, geometry_count
    div ecx
    mov ebx, edx
    shl rbx, 4
    lea r15, [rel geometry_table]
    add r15, rbx
    mov rax, [r15]
    mov [rel config+NEBO_LIVE_CONFIG_WIDTH_OFFSET], rax
    mov rax, [r15+8]
    mov [rel config+NEBO_LIVE_CONFIG_HEIGHT_OFFSET], rax
    mov rax, [r15]
    shl rax, 2
    mul qword [r15+8]
    test rdx, rdx
    jnz test_render_fail
    cmp rax, MAX_BYTES
    ja test_render_fail
    mov r14, rax
    lea rdi, [rel document]
    xor esi, esi
    lea rdx, [rel surface]
    lea rcx, [rel pixels]
    mov r8, r14
    lea r9, [rel config]
    call nebo_runtime_live_visual_render
    test eax, eax
    jnz test_render_fail
    mov eax, r12d
    inc rax
    cmp [rel surface+NEBO_SOFTWARE_SURFACE_GENERATION_OFFSET], rax
    jne test_generation_fail
    mov rax, [r15]
    cmp [rel surface+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET], rax
    jne test_geometry_fail
    shl rax, 2
    cmp [rel surface+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET], rax
    jne test_geometry_fail
    mov rax, [r15+8]
    cmp [rel surface+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET], rax
    jne test_geometry_fail
    call check_border_frame
    test eax, eax
    jnz test_border_fail
    call check_inner_border_residue
    test eax, eax
    jnz test_residue_fail
    mov rax, [r15]
    mov [rel previous_width], rax
    mov rax, [r15+8]
    mov [rel previous_height], rax
    inc r12d
    dec r13d
    jnz .render_loop
    mov eax, SYS_EXIT
    xor edi, edi
    syscall

; Returns zero when the canonical border occupies exactly the perimeter and
; never appears in the interior. R15 points at width,height.
check_border_frame:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, [r15]
    mov r13, [r15+8]
    lea r14, [rel pixels]
    xor ebx, ebx
.top_bottom:
    mov eax, [r14+rbx*4]
    cmp eax, NEBO_CHROME_COLOR_BORDER
    jne .bad
    mov rax, r13
    dec rax
    imul rax, r12
    add rax, rbx
    cmp dword [r14+rax*4], NEBO_CHROME_COLOR_BORDER
    jne .bad
    inc rbx
    cmp rbx, r12
    jb .top_bottom
    mov rbx, 1
.row:
    cmp rbx, r13
    jae .ok
    mov rax, rbx
    imul rax, r12
    cmp dword [r14+rax*4], NEBO_CHROME_COLOR_BORDER
    jne .bad
    add rax, r12
    dec rax
    cmp dword [r14+rax*4], NEBO_CHROME_COLOR_BORDER
    jne .bad
    mov rcx, 1
.interior:
    mov rax, rbx
    imul rax, r12
    add rax, rcx
    cmp dword [r14+rax*4], NEBO_CHROME_COLOR_BORDER
    je .bad
    inc rcx
    mov rax, r12
    dec rax
    cmp rcx, rax
    jb .interior
    inc rbx
    mov rax, r13
    dec rax
    cmp rbx, rax
    jb .row
.ok:
    xor eax, eax
    jmp .done
.bad:
    mov eax, 1
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Reject the canonical border colour in the 12-pixel interior strips adjacent
; to RIGHT/BOTTOM. On growth, also inspect the previous frame's legal RIGHT or
; BOTTOM border coordinate when that coordinate has become interior.
check_inner_border_residue:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, [r15]
    mov r13, [r15+8]
    lea r14, [rel pixels]

    ; RIGHT interior strip: x=[max(1,width-1-N), width-2], y=[1,height-2].
    mov r15, r12
    sub r15, (INNER_STRIP_DEPTH+1)
    cmp r15, 1
    jae .right_start_ready
    mov r15, 1
.right_start_ready:
    mov rbx, 1
.right_row:
    mov rcx, r15
.right_pixel:
    mov rax, rbx
    imul rax, r12
    add rax, rcx
    cmp dword [r14+rax*4], NEBO_CHROME_COLOR_BORDER
    je .residue
    inc rcx
    mov rax, r12
    dec rax
    cmp rcx, rax
    jb .right_pixel
    inc rbx
    mov rax, r13
    dec rax
    cmp rbx, rax
    jb .right_row

    ; BOTTOM interior strip: y=[max(1,height-1-N), height-2], x=[1,width-2].
    mov r15, r13
    sub r15, (INNER_STRIP_DEPTH+1)
    cmp r15, 1
    jae .bottom_start_ready
    mov r15, 1
.bottom_start_ready:
    mov rbx, r15
.bottom_row:
    mov rcx, 1
.bottom_pixel:
    mov rax, rbx
    imul rax, r12
    add rax, rcx
    cmp dword [r14+rax*4], NEBO_CHROME_COLOR_BORDER
    je .residue
    inc rcx
    mov rax, r12
    dec rax
    cmp rcx, rax
    jb .bottom_pixel
    inc rbx
    mov rax, r13
    dec rax
    cmp rbx, rax
    jb .bottom_row

    ; After horizontal growth, old_right=previous_width-1 is now interior.
    mov r15, [rel previous_width]
    cmp r15, 2
    jb .old_bottom
    cmp r15, r12
    jae .old_bottom
    dec r15
    mov rbx, 1
.old_right_pixel:
    mov rax, rbx
    imul rax, r12
    add rax, r15
    cmp dword [r14+rax*4], NEBO_CHROME_COLOR_BORDER
    je .residue
    inc rbx
    mov rax, r13
    dec rax
    cmp rbx, rax
    jb .old_right_pixel

    ; After vertical growth, old_bottom=previous_height-1 is now interior.
.old_bottom:
    mov r15, [rel previous_height]
    cmp r15, 2
    jb .clean
    cmp r15, r13
    jae .clean
    dec r15
    mov rcx, 1
.old_bottom_pixel:
    mov rax, r15
    imul rax, r12
    add rax, rcx
    cmp dword [r14+rax*4], NEBO_CHROME_COLOR_BORDER
    je .residue
    inc rcx
    mov rax, r12
    dec rax
    cmp rcx, rax
    jb .old_bottom_pixel
.clean:
    xor eax, eax
    jmp .residue_done
.residue:
    mov eax, 1
.residue_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

test_document_fail:
    mov edi, 91
    jmp test_exit
test_render_fail:
    mov edi, 92
    jmp test_exit
test_generation_fail:
    mov edi, 93
    jmp test_exit
test_geometry_fail:
    mov edi, 94
    jmp test_exit
test_border_fail:
    mov edi, 95
    jmp test_exit
test_residue_fail:
    mov edi, 96
test_exit:
    mov eax, SYS_EXIT
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
