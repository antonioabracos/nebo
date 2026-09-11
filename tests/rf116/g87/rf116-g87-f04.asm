bits 64
default rel
%include "runtime/color.inc"
extern nebo_color_parse_hex
global _start
section .text
_start:
    lea rdi, [rel valid]
    mov esi, valid_len
    lea rdx, [rel ok_result]
    call nebo_color_parse_hex
    test eax, eax
    jnz fail
    cmp qword [rel ok_result + NEBO_COLOR_RESULT_IS_OK_OFFSET], 1
    jne fail
    cmp dword [rel ok_result + NEBO_COLOR_RESULT_VALUE_OFFSET], 0x010203ff
    jne fail
    lea rdi, [rel invalid]
    mov esi, invalid_len
    lea rdx, [rel error_result]
    call nebo_color_parse_hex
    test eax, eax
    jnz fail
    cmp qword [rel error_result + NEBO_COLOR_RESULT_IS_OK_OFFSET], 0
    jne fail
    cmp qword [rel error_result + NEBO_COLOR_RESULT_ERROR_OFFSET], NEBO_COLOR_PARSE_ERROR_INVALID_HEX
    jne fail
    cmp qword [rel error_result + NEBO_COLOR_RESULT_ERROR_INDEX_OFFSET], 3
    jne fail
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .rodata
valid: db "#010203"
valid_len equ $ - valid
invalid: db "#12G000"
invalid_len equ $ - invalid
section .bss
ok_result: resb NEBO_COLOR_RESULT_SIZE
error_result: resb NEBO_COLOR_RESULT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
