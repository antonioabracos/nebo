bits 64
default rel
%include "runtime/console_geometry.inc"
extern nebo_geometry_update
global _start
section .text
_start:
    lea rdi, [rel clear_panel]
    lea rsi, [rel result]
    call nebo_geometry_update
    test eax, eax
    jnz fail
    cmp qword [rel result + NEBO_UPDATE_RESULT_GENERATION_OFFSET], 5
    jne fail
    lea rdi, [rel stale_refresh]
    lea rsi, [rel untouched]
    call nebo_geometry_update
    cmp eax, NEBO_GEOMETRY_LIFECYCLE
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
clear_panel: dq NEBO_UPDATE_CLEAR, NEBO_SCOPE_PANEL, 7, 4, 0, 0, 0
stale_refresh: dq NEBO_UPDATE_REFRESH, NEBO_SCOPE_REGION, 8, 4, 4, 0, 0
untouched: times NEBO_UPDATE_SIZE db 0xaa
section .bss
result: resb NEBO_UPDATE_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
