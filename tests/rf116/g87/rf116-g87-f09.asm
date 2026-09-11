bits 64
default rel
%include "runtime/color.inc"
%include "compiler/diagnostics/p01.inc"
extern nebo_color_rgba_lowering
extern nebo_color_serialize_hex
extern nebo_color_parse_hex
extern nebo_color_equal
extern neboc_diag_from_color_status
global _start
section .text
_start:
    mov edi, 17
    mov esi, 34
    mov edx, 51
    mov ecx, 68
    lea r8, [rel original]
    call nebo_color_rgba_lowering
    test eax, eax
    jnz fail
    mov edi, [rel original]
    lea rsi, [rel encoded]
    mov edx, 9
    mov ecx, 1
    call nebo_color_serialize_hex
    test eax, eax
    jnz fail
    lea rdi, [rel encoded]
    mov esi, 9
    lea rdx, [rel parsed]
    call nebo_color_parse_hex
    test eax, eax
    jnz fail
    mov edi, [rel original]
    mov esi, [rel parsed + NEBO_COLOR_RESULT_VALUE_OFFSET]
    call nebo_color_equal
    cmp eax, 1
    jne fail
    mov edi, NEBO_COLOR_HEX_INVALID
    mov esi, 3
    mov edx, 100
    mov ecx, 109
    lea r8, [rel diagnostic]
    call neboc_diag_from_color_status
    test eax, eax
    jnz fail
    cmp qword [rel diagnostic + NEBOC_DIAG_CODE_OFFSET], NEBOC_DIAG_COLOR_HEX
    jne fail
    cmp qword [rel diagnostic + NEBOC_DIAG_START_OFFSET], 103
    jne fail
    cmp qword [rel diagnostic + NEBOC_DIAG_END_OFFSET], 109
    jne fail
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .bss
original: resd 1
encoded: resb 9
parsed: resb NEBO_COLOR_RESULT_SIZE
diagnostic: resb NEBOC_DIAG_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
