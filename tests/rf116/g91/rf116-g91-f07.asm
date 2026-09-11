bits 64
default rel
%include "runtime/console_geometry.inc"
extern nebo_geometry_address
global _start
section .text
_start:
    lea rdi, [rel address]
    lea rsi, [rel result]
    call nebo_geometry_address
    test eax, eax
    jnz fail
    cmp qword [rel result + NEBO_ADDRESS_LINEAR_OFFSET], 11
    jne fail
    lea rdi, [rel outside]
    lea rsi, [rel untouched]
    call nebo_geometry_address
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
address: dq NEBO_SCOPE_PANEL, 7, 2, 3, 4, 4, NEBO_ADDRESS_SELECTED | NEBO_ADDRESS_FOCUSED, 0, 0
outside: dq NEBO_SCOPE_PANEL, 7, 4, 0, 4, 4, NEBO_ADDRESS_SELECTED, 0, 0
untouched: times NEBO_ADDRESS_SIZE db 0xaa
section .bss
result: resb NEBO_ADDRESS_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
