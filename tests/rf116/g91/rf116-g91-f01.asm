bits 64
default rel
%include "runtime/console_geometry.inc"
extern nebo_geometry_position
global _start
section .text
_start:
    lea rdi, [rel canonical]
    lea rsi, [rel result]
    call nebo_geometry_position
    test eax, eax
    jnz fail
    cmp qword [rel result + NEBO_POSITION_RESULT_X_OFFSET], 7
    jne fail
    cmp qword [rel result + NEBO_POSITION_RESULT_Y_OFFSET], 3
    jne fail
    lea rdi, [rel legacy]
    lea rsi, [rel result]
    call nebo_geometry_position
    test eax, eax
    jnz fail
    cmp qword [rel result + NEBO_POSITION_RESULT_X_OFFSET], 7
    jne fail
    cmp qword [rel result + NEBO_POSITION_RESULT_DIAGNOSTIC_OFFSET], NEBO_GEOMETRY_LEGACY_AT_DIAGNOSTIC
    jne fail
    lea rdi, [rel oversized]
    lea rsi, [rel untouched]
    call nebo_geometry_position
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
canonical: dq 7, 3, 0
legacy: dq 3, 7, 1
oversized: dq 0x100000000, 0, 0
untouched: times NEBO_POSITION_RESULT_SIZE db 0xaa
section .bss
result: resb NEBO_POSITION_RESULT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
