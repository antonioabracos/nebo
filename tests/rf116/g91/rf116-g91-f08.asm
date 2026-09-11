bits 64
default rel
%include "runtime/console_geometry.inc"
extern nebo_geometry_multi_validate
global _start
section .text
_start:
    lea rdi, [rel multi]
    lea rsi, [rel result]
    call nebo_geometry_multi_validate
    test eax, eax
    jnz fail
    cmp qword [rel result + NEBO_MULTI_TOTAL_OFFSET], 5
    jne fail
    lea rdi, [rel unbounded]
    lea rsi, [rel untouched]
    call nebo_geometry_multi_validate
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
windows: dq 1, 2
panels: dq 11, 12
layers: dq 21
multi: dq windows, 2, panels, 2, layers, 1, NEBO_TARGET_HEADLESS, 0, 0, 0, 0
unbounded: dq windows, NEBO_GEOMETRY_MAX_INSTANCES + 1, panels, 0, layers, 0, NEBO_TARGET_HEADLESS, 0, 0, 0, 0
untouched: times NEBO_MULTI_SIZE db 0xaa
section .bss
result: resb NEBO_MULTI_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
