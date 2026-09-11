bits 64
default rel
%include "runtime/color.inc"
%include "runtime/colormap.inc"
extern nebo_colormap_normalize
global _start
section .text
_start:
    lea rdi, [rel stops]
    mov esi, 3
    mov edx, NEBO_COLOR_BY_VALUE
    lea rcx, [rel descriptor]
    call nebo_colormap_normalize
    test eax, eax
    jnz fail
    cmp qword [rel descriptor + NEBO_COLORMAP_DESC_COUNT_OFFSET], 3
    jne fail
    cmp qword [rel descriptor + NEBO_COLORMAP_DESC_COLOR_BY_OFFSET], NEBO_COLOR_BY_VALUE
    jne fail
    lea rdi, [rel unordered]
    mov esi, 2
    mov edx, NEBO_COLOR_BY_INDEX
    lea rcx, [rel untouched]
    call nebo_colormap_normalize
    cmp eax, NEBO_COLORMAP_ORDER
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
section .rodata
stops:
    dd 0, 0x000000ff
    dd 32768, 0x808080ff
    dd 65535, 0xffffffff
unordered:
    dd 200, 0x111111ff
    dd 100, 0x222222ff
section .bss
descriptor: resb NEBO_COLORMAP_DESC_SIZE
section .data
untouched: times NEBO_COLORMAP_DESC_SIZE db 0xaa
section .note.GNU-stack noalloc noexec nowrite progbits
