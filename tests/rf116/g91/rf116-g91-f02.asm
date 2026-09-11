bits 64
default rel
%include "runtime/console_geometry.inc"
extern nebo_geometry_size
global _start
section .text
_start:
    lea rdi, [rel requested]
    lea rsi, [rel result]
    call nebo_geometry_size
    test eax, eax
    jnz fail
    cmp qword [rel result + NEBO_SIZE_AREA_OFFSET], 1920
    jne fail
    lea rdi, [rel zero_width]
    lea rsi, [rel untouched]
    call nebo_geometry_size
    cmp eax, NEBO_GEOMETRY_INVALID
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
requested: dq 80, 24, NEBO_SIZE_UNIT_CELLS, 0, 0
zero_width: dq 0, 24, NEBO_SIZE_UNIT_CELLS, 0, 0
untouched: times NEBO_SIZE_SIZE db 0xaa
section .bss
result: resb NEBO_SIZE_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
