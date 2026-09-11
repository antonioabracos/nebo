bits 64
default rel
%include "runtime/textual/format_data.inc"
global _start

section .text
_start:
    mov edi, 19
    call format_front_state
    cmp eax, 1
    jne fail

    lea rdi, [rel xml_sample]
    mov esi, xml_sample_len
    call format_detect
    cmp eax, FMT_XML
    jne fail
    cmp edx, 70
    jne fail
    lea rdi, [rel ini_sample]
    mov esi, ini_sample_len
    call format_detect
    cmp eax, FMT_INI
    jne fail

success:
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .rodata
xml_sample: db ' ', '<root/>'
xml_sample_len equ $ - xml_sample
ini_sample: db 'name=value', 10
ini_sample_len equ $ - ini_sample
