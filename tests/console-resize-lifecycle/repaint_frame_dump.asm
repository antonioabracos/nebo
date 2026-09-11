; Bounded real-renderer raw BGRA snapshot for R3 frame hash/clear oracles.
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/live/live_console.inc"

extern nebo_console_document_init
extern nebo_console_document_append_text
extern nebo_runtime_live_visual_render

global _start

%define SYS_WRITE 1
%define SYS_EXIT 60
%define NODE_CAPACITY 16
%define TEXT_CAPACITY 128
%define MAX_WIDTH 700
%define MAX_HEIGHT 500
%define MAX_BYTES (MAX_WIDTH*MAX_HEIGHT*4)

section .rodata align=8
probe_bytes: db "R3 FRAME"
probe_length equ $-probe_bytes
probe_descriptor:
    dq probe_bytes, probe_length
    dd 0
    dw NEBO_RUNTIME_TEXT_ENCODING_UTF8, NEBO_RUNTIME_TEXT_LIFETIME_STATIC
title_bytes: db "NEBO CONSOLE"
geometry_table:
    dq 640,400
    dq 700,400
    dq 700,500
    dq 500,300
    dq NEBO_CHROME_MIN_WINDOW_WIDTH_PX,NEBO_CHROME_MIN_WINDOW_HEIGHT_PX

section .bss align=64
document: resb NEBO_CONSOLE_DOCUMENT_SIZE
nodes: resb NODE_CAPACITY*NEBO_CONSOLE_NODE_HEADER_SIZE
text_store: resb TEXT_CAPACITY
surface: resb NEBO_SOFTWARE_SURFACE_SIZE
pixels: resb MAX_BYTES
config: resb NEBO_LIVE_CONFIG_SIZE

section .text
_start:
    mov edi, 80
    cmp qword [rsp], 2
    jne .exit
    mov rax, [rsp+16]
    movzx eax, byte [rax]
    sub eax, '0'
    cmp eax, 4
    ja .exit
    mov ebx, eax
    shl rbx, 4
    lea r15, [rel geometry_table]
    add r15, rbx

    lea rdi, [rel document]
    mov rsi, 0x0000000100000000
    lea rdx, [rel nodes]
    mov ecx, NODE_CAPACITY
    lea r8, [rel text_store]
    mov r9d, TEXT_CAPACITY
    call nebo_console_document_init
    test eax, eax
    jnz .document_fail
    lea rdi, [rel document]
    lea rsi, [rel probe_descriptor]
    call nebo_console_document_append_text
    test eax, eax
    jnz .document_fail

    lea rdi, [rel config]
    xor eax, eax
    mov ecx, NEBO_LIVE_CONFIG_QWORDS
    cld
    rep stosq
    mov rax, [r15]
    mov [rel config+NEBO_LIVE_CONFIG_WIDTH_OFFSET], rax
    mov rax, [r15+8]
    mov [rel config+NEBO_LIVE_CONFIG_HEIGHT_OFFSET], rax
    lea rax, [rel title_bytes]
    mov [rel config+NEBO_LIVE_CONFIG_TITLE_PTR_OFFSET], rax
    mov qword [rel config+NEBO_LIVE_CONFIG_TITLE_LENGTH_OFFSET], 12

    mov rax, [r15]
    shl rax, 2
    mul qword [r15+8]
    test rdx, rdx
    jnz .render_fail
    cmp rax, MAX_BYTES
    ja .render_fail
    mov r14, rax
    lea rdi, [rel document]
    xor esi, esi
    lea rdx, [rel surface]
    lea rcx, [rel pixels]
    mov r8, r14
    lea r9, [rel config]
    call nebo_runtime_live_visual_render
    test eax, eax
    jnz .render_fail
    cmp qword [rel surface+NEBO_SOFTWARE_SURFACE_GENERATION_OFFSET], 1
    jne .render_fail
    mov rax, [r15]
    cmp [rel surface+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET], rax
    jne .render_fail
    mov rax, [r15+8]
    cmp [rel surface+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET], rax
    jne .render_fail

    lea rsi, [rel pixels]
    mov rdx, r14
.write:
    mov eax, SYS_WRITE
    mov edi, 1
    syscall
    test rax, rax
    jle .write_fail
    add rsi, rax
    sub rdx, rax
    jnz .write
    xor edi, edi
    jmp .exit
.document_fail:
    mov edi, 81
    jmp .exit
.render_fail:
    mov edi, 82
    jmp .exit
.write_fail:
    mov edi, 83
.exit:
    mov eax, SYS_EXIT
    syscall
    ud2

section .note.GNU-stack noalloc noexec nowrite progbits
