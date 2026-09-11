bits 64
default rel
%include "runtime/console_geometry.inc"
extern nebo_geometry_target_map
global _start
section .text
_start:
    lea rdi, [rel headless]
    lea rsi, [rel result]
    call nebo_geometry_target_map
    test eax, eax
    jnz fail
    cmp qword [rel result + NEBO_TARGET_MAP_RESULT_X_OFFSET], 5
    jne fail
    cmp qword [rel result + NEBO_TARGET_MAP_RESULT_HEIGHT_OFFSET], 24
    jne fail
    lea rdi, [rel unsupported_live]
    lea rsi, [rel untouched]
    call nebo_geometry_target_map
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
headless: dq 5, 2, 80, 24, NEBO_TARGET_HEADLESS, 1, 1, 0
    times 5 dq 0
unsupported_live: dq 5, 2, 80, 24, NEBO_TARGET_LIVE, 2, 1, 0
    times 5 dq 0
untouched: times NEBO_TARGET_MAP_SIZE db 0xaa
section .bss
result: resb NEBO_TARGET_MAP_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
