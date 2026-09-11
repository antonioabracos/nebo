bits 64
default rel
%include "runtime/color_theme.inc"
%include "runtime/color_accessibility.inc"
%include "runtime/color_target.inc"
extern nebo_theme_resolve
extern nebo_color_pick_accessible
extern nebo_color_target_map
global _start
section .text
_start:
    lea rdi, [rel theme]
    mov esi, NEBO_THEME_TOKEN_ACCENT
    lea rdx, [rel candidate]
    call nebo_theme_resolve
    test eax, eax
    jnz fail
    mov edi, [rel candidate]
    mov esi, 0x000000ff
    mov edx, 0xffffffff
    mov ecx, NEBO_CONTRAST_DEFAULT_DELTA
    lea r8, [rel accessible]
    call nebo_color_pick_accessible
    test eax, eax
    jnz fail
    cmp dword [rel accessible], 0x000000ff
    jne fail
    mov edi, [rel accessible]
    mov esi, NEBO_COLOR_TARGET_ANSI
    xor edx, edx
    lea rcx, [rel mapped]
    call nebo_color_target_map
    test eax, eax
    jnz fail
    cmp qword [rel mapped + NEBO_COLOR_TARGET_MAP_MODE_OFFSET], NEBO_COLOR_MAP_ANSI256
    jne fail
    cmp qword [rel mapped + NEBO_COLOR_TARGET_MAP_VALUE_OFFSET], 16
    jne fail
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .data
align 8
theme:
    dd 0xffffffff, 0x101820ff, 0xff6600ff, 0x667788ff, 0x334455ff, 0x22aa77ff
    dq 0
    dq NEBO_THEME_VALID
candidate: dd 0
accessible: dd 0
section .bss
mapped: resb NEBO_COLOR_TARGET_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
