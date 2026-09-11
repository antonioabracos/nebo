bits 64
default rel
%include "runtime/console_geometry.inc"
extern nebo_geometry_surface
global _start
section .text
_start:
    lea rdi, [rel headless]
    lea rsi, [rel result]
    call nebo_geometry_surface
    test eax, eax
    jnz fail
    cmp qword [rel result + NEBO_SURFACE_KIND_OFFSET], NEBO_SURFACE_HEADLESS_WINDOW
    jne fail
    cmp qword [rel result + NEBO_SURFACE_STATE_OFFSET], NEBO_SURFACE_READY
    jne fail
    lea rdi, [rel live_without_capability]
    lea rsi, [rel untouched]
    call nebo_geometry_surface
    cmp eax, NEBO_GEOMETRY_TARGET
    jne fail
    mov rax, 0xaaaaaaaaaaaaaaaa
    cmp qword [rel untouched], rax
    jne fail
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .data
headless: dq NEBO_SURFACE_HEADLESS_WINDOW, 1, 0, 0, 80, 24, 0, 0, 0
live_without_capability: dq NEBO_SURFACE_LIVE_WINDOW, 2, 0, 0, 80, 24, 99, 0, 0
untouched: times NEBO_SURFACE_SIZE db 0xaa
section .bss
result: resb NEBO_SURFACE_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
