bits 64
default rel
%include "runtime/textual/format_data.inc"
global _start

section .text
_start:
    mov edi, 11
    call format_front_state
    cmp eax, 2
    jne fail

    lea rdi, [rel csv_doc]
    mov esi, csv_doc_len
    mov edx, ','
    mov ecx, 8
    call delimited_scan
    test eax, eax
    jnz fail
    cmp edx, 6
    jne fail
    cmp ecx, 2
    jne fail
    lea rdi, [rel csv_bad]
    mov esi, csv_bad_len
    mov edx, ','
    mov ecx, 8
    call delimited_scan
    cmp eax, FMT_SYNTAX
    jne fail
    lea rdi, [rel json_good]
    mov esi, json_good_len
    mov edx, 8
    call json_validate
    test eax, eax
    jnz fail
    lea rdi, [rel json_bad]
    mov esi, json_bad_len
    mov edx, 8
    call json_validate
    cmp eax, FMT_SYNTAX
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
csv_doc: db 'a,', 34, 'b,c', 34, ',d', 10, '1,2,3', 10
csv_doc_len equ $ - csv_doc
csv_bad: db 'a,', 34, 'b,c', 10
csv_bad_len equ $ - csv_bad
json_good: db '{', 34, 'a', 34, ':', '[', '1', ',', '2', ']', '}'
json_good_len equ $ - json_good
json_bad: db '{', 34, 'a', 34, ':', '[', '1', ',', '2', ']'
json_bad_len equ $ - json_bad
