; R4 deterministic raw BGRA candidate frame using the actual live renderer.
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
%define TEST_WIDTH 640
%define TEST_HEIGHT 400
%define TEST_BYTES (TEST_WIDTH*TEST_HEIGHT*4)
%define NODE_CAPACITY 32
%define TEXT_CAPACITY 512

section .rodata align=8
coverage_bytes:
    db "ABCDEFGHIJKLMNOPQRSTUVWXYZ",10
    db "abcdefghijklmnopqrstuvwxyz",10
    db "0123456789 true false",10
    db "! ? . , : ; + - * / ( ) [ ] { } = _",10
    db "Scan: "
coverage_length equ $-coverage_bytes
coverage_descriptor:
    dq coverage_bytes,coverage_length
    dd 0
    dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
editor_bytes: db "MoveOK ResizeOK"
editor_length equ $-editor_bytes
title_bytes: db "NEBO CONSOLE"

section .bss align=64
document: resb NEBO_CONSOLE_DOCUMENT_SIZE
nodes: resb NODE_CAPACITY*NEBO_CONSOLE_NODE_HEADER_SIZE
text_store: resb TEXT_CAPACITY
surface: resb NEBO_SOFTWARE_SURFACE_SIZE
pixels: resb TEST_BYTES
config: resb NEBO_LIVE_CONFIG_SIZE
editor: resb NEBO_TEXT_EDIT_RECORD_SIZE

section .text
_start:
    lea rdi,[rel document]
    mov rsi,0x0000000100000000
    lea rdx,[rel nodes]
    mov ecx,NODE_CAPACITY
    lea r8,[rel text_store]
    mov r9d,TEXT_CAPACITY
    call nebo_console_document_init
    test eax,eax
    jnz .fail
    lea rdi,[rel document]
    lea rsi,[rel coverage_descriptor]
    call nebo_console_document_append_text
    test eax,eax
    jnz .fail
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
    mov qword [rel editor+NEBO_TEXT_EDIT_CAPACITY_OFFSET],editor_length
    mov qword [rel editor+NEBO_TEXT_EDIT_LENGTH_OFFSET],editor_length
    mov qword [rel editor+NEBO_TEXT_EDIT_CARET_OFFSET],editor_length
    lea rdi,[rel document]
    lea rsi,[rel editor]
    lea rdx,[rel surface]
    lea rcx,[rel pixels]
    mov r8d,TEST_BYTES
    lea r9,[rel config]
    call nebo_runtime_live_visual_render
    test eax,eax
    jnz .fail
    lea rsi,[rel pixels]
    mov edx,TEST_BYTES
.write:
    mov eax,SYS_WRITE
    mov edi,1
    syscall
    test rax,rax
    jle .fail
    add rsi,rax
    sub rdx,rax
    jnz .write
    xor edi,edi
    jmp .exit
.fail:
    mov edi,90
.exit:
    mov eax,SYS_EXIT
    syscall
    ud2

section .note.GNU-stack noalloc noexec nowrite progbits

