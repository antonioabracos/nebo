bits 64
default rel
%include "runtime/textual/format_data.inc"
global _start

section .text
_start:
    mov edi, 5
    call format_front_state
    cmp eax, 2
    jne fail

    mov edi, FMT_JSON
    call format_validate_kind
    test eax, eax
    jnz fail
    xor edi, edi
    call format_validate_kind
    cmp eax, FMT_INVALID
    jne fail
    mov edi, FMT_MAX_BYTES
    mov esi, FMT_MAX_RECORDS
    mov edx, FMT_MAX_FIELDS
    mov ecx, FMT_MAX_DEPTH
    call format_check_limits
    test eax, eax
    jnz fail
    mov edi, FMT_MAX_BYTES + 1
    xor esi, esi
    xor edx, edx
    xor ecx, ecx
    call format_check_limits
    cmp eax, FMT_LIMIT
    jne fail
    lea rdi, [rel json_doc]
    mov esi, json_doc_len
    call format_detect
    cmp eax, FMT_JSON
    jne fail
    cmp edx, 95
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
json_doc: db ' ', '{', '}', 10
json_doc_len equ $ - json_doc
