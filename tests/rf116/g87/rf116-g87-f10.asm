bits 64
default rel
%include "runtime/color.inc"
%include "runtime/color_target.inc"
%include "compiler/semantic/color.inc"
%include "compiler/codegen/color.inc"
extern nebo_color_rgba_lowering
extern neboc_color_codegen
global _start
section .text
_start:
    mov edi, 1
    mov esi, 2
    mov edx, 3
    mov ecx, 4
    lea r8, [rel color]
    call nebo_color_rgba_lowering
    test eax, eax
    jnz fail
    mov edi, [rel color]
    mov esi, NEBO_COLOR_TARGET_HEADLESS
    mov edx, NEBO_COLOR_CAP_ALPHA
    lea rcx, [rel ir]
    call neboc_color_codegen
    test eax, eax
    jnz fail
    cmp qword [rel ir + NEBOC_COLOR_IR_TYPE_ID_OFFSET], NEBOC_COLOR_TYPE_ID
    jne fail
    cmp qword [rel ir + NEBOC_COLOR_IR_STATE_OFFSET], NEBOC_COLOR_IR_READY
    jne fail
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .bss
color: resd 1
ir: resb NEBOC_COLOR_IR_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
