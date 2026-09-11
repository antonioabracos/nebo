bits 64
default rel
%include "runtime/color_accessibility.inc"
extern nebo_color_contrast_check
extern nebo_color_pick_accessible
global _start
section .text
_start:
    mov edi, 0xffffffff
    mov esi, 0x000000ff
    mov edx, NEBO_CONTRAST_DEFAULT_DELTA
    call nebo_color_contrast_check
    test eax, eax
    jnz fail1
    mov edi, 0xd0d0d0ff
    mov esi, 0xffffffff
    mov edx, NEBO_CONTRAST_DEFAULT_DELTA
    call nebo_color_contrast_check
    cmp eax, NEBO_CONTRAST_INSUFFICIENT
    jne fail2
    mov edi, 0xd0d0d0ff
    mov esi, 0x000000ff
    mov edx, 0xffffffff
    mov ecx, NEBO_CONTRAST_DEFAULT_DELTA
    lea r8, [rel selected]
    call nebo_color_pick_accessible
    test eax, eax
    jnz fail2
    cmp dword [rel selected], 0x000000ff
    jne fail3
    mov edi, 0x555555ff
    mov esi, 0x666666ff
    mov edx, 0x606060ff
    mov ecx, NEBO_CONTRAST_DEFAULT_DELTA
    lea r8, [rel untouched]
    call nebo_color_pick_accessible
    cmp eax, NEBO_CONTRAST_NO_FALLBACK
    jne fail4
    cmp dword [rel untouched], 0xaaaaaaaa
    jne fail5
    mov eax, 60
    xor edi, edi
    syscall
fail1:
    mov edi, 11
    jmp fail
fail2:
    mov edi, 12
    jmp fail
fail3:
    mov edi, 13
    jmp fail
fail4:
    mov edi, 14
    jmp fail
fail5:
    mov edi, 15
fail:
    mov eax, 60
    syscall
section .data
selected: dd 0
untouched: dd 0xaaaaaaaa
section .note.GNU-stack noalloc noexec nowrite progbits
