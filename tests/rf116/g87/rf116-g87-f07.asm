bits 64
default rel
%include "runtime/color.inc"
%include "runtime/color_target.inc"
extern nebo_color_target_validate
extern nebo_color_with_alpha
extern nebo_color_is_opaque
global _start
section .text
_start:
    mov edi, 0x112233ff
    mov esi, 0x44
    lea rdx, [rel changed]
    call nebo_color_with_alpha
    test eax, eax
    jnz fail
    cmp dword [rel changed], 0x11223344
    jne fail
    mov edi, [rel changed]
    call nebo_color_is_opaque
    test eax, eax
    jnz fail
    mov edi, 0x112233ff
    call nebo_color_is_opaque
    cmp eax, 1
    jne fail
    mov edi, 0x112233ff
    mov esi, 256
    lea rdx, [rel untouched_color]
    call nebo_color_with_alpha
    cmp eax, NEBO_COLOR_CHANNEL_RANGE
    jne fail
    cmp dword [rel untouched_color], 0xaaaaaaaa
    jne fail
    mov edi, 0x11223344
    mov esi, NEBO_COLOR_TARGET_HEADLESS
    mov edx, NEBO_COLOR_CAP_ALPHA
    lea rcx, [rel descriptor]
    call nebo_color_target_validate
    test eax, eax
    jnz fail
    mov edi, 0x11223344
    mov esi, NEBO_COLOR_TARGET_ANSI
    xor edx, edx
    lea rcx, [rel untouched]
    call nebo_color_target_validate
    cmp eax, NEBO_COLOR_ALPHA_UNSUPPORTED
    jne fail
    mov edi, 0x112233ff
    mov esi, NEBO_COLOR_TARGET_ANSI
    xor edx, edx
    lea rcx, [rel ansi]
    call nebo_color_target_validate
    test eax, eax
    jnz fail
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
descriptor: resb NEBO_COLOR_TARGET_SIZE
ansi: resb NEBO_COLOR_TARGET_SIZE
changed: resd 1
section .data
untouched: times NEBO_COLOR_TARGET_SIZE db 0xaa
untouched_color: dd 0xaaaaaaaa
section .note.GNU-stack noalloc noexec nowrite progbits
