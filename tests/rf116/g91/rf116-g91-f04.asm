bits 64
default rel
%include "runtime/console_geometry.inc"
extern nebo_geometry_panel_layer
global _start
section .text
_start:
    lea rdi, [rel panel]
    lea rsi, [rel result]
    call nebo_geometry_panel_layer
    test eax, eax
    jnz fail
    cmp qword [rel result + NEBO_PANEL_LAYER_OFFSET], 2
    jne fail
    lea rdi, [rel unbounded]
    lea rsi, [rel untouched]
    call nebo_geometry_panel_layer
    cmp eax, NEBO_GEOMETRY_LIMIT
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
panel: dq 1, 2, 2, -1, 4, 0
unbounded: dq 1, 2, 2, 0, NEBO_GEOMETRY_MAX_INSTANCES + 1, 0
untouched: times NEBO_PANEL_SIZE db 0xaa
section .bss
result: resb NEBO_PANEL_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
