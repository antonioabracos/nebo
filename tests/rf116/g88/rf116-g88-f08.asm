bits 64
default rel
%include "runtime/color.inc"
%include "runtime/color_target.inc"
extern nebo_color_target_map
global _start
section .text
_start:
    mov edi, 0xff0000ff
    mov esi, NEBO_COLOR_TARGET_ANSI
    xor edx, edx
    lea rcx, [rel mapped]
    call nebo_color_target_map
    test eax, eax
    jnz fail
    cmp qword [rel mapped + NEBO_COLOR_TARGET_MAP_MODE_OFFSET], NEBO_COLOR_MAP_ANSI256
    jne fail
    cmp qword [rel mapped + NEBO_COLOR_TARGET_MAP_VALUE_OFFSET], 196
    jne fail
    mov edi, 0x123456ff
    mov esi, NEBO_COLOR_TARGET_ANSI
    mov edx, NEBO_COLOR_CAP_TRUECOLOR
    lea rcx, [rel mapped]
    call nebo_color_target_map
    test eax, eax
    jnz fail
    cmp qword [rel mapped + NEBO_COLOR_TARGET_MAP_VALUE_OFFSET], 0x123456
    jne fail
    mov edi, 0x12345680
    mov esi, NEBO_COLOR_TARGET_ANSI
    xor edx, edx
    lea rcx, [rel untouched]
    call nebo_color_target_map
    cmp eax, NEBO_COLOR_ALPHA_UNSUPPORTED
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
section .bss
mapped: resb NEBO_COLOR_TARGET_SIZE
section .data
untouched: times NEBO_COLOR_TARGET_SIZE db 0xaa
section .note.GNU-stack noalloc noexec nowrite progbits
