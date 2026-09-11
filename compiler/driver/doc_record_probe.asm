; Stdin/stdout adapter for the native G156 semantic owners.  It performs no
; source parsing and has no libc, filesystem or network dependency.
bits 64
default rel
%include "compiler/semantic/docs/doc_record.inc"

global _start
extern neboc_doc_record_new
extern neboc_doc_serialize
extern neboc_doc_deserialize

section .text
arg_equals:
    xor eax, eax
.loop:
    mov dl, byte [rdi]
    cmp dl, byte [rsi]
    jne .no
    test dl, dl
    jz .yes
    inc rdi
    inc rsi
    jmp .loop
.yes:
    mov eax, 1
.no:
    ret

read_exact:
    mov r8, rdi
    mov r9, rsi
.loop:
    test r9, r9
    jz .success
    xor eax, eax
    xor edi, edi
    mov rsi, r8
    mov rdx, r9
    syscall
    test rax, rax
    jle .failure
    add r8, rax
    sub r9, rax
    jmp .loop
.success:
    xor eax, eax
    ret
.failure:
    mov eax, 1
    ret

write_all:
    mov r8, rdi
    mov r9, rsi
.loop:
    test r9, r9
    jz .success
    mov eax, 1
    mov edi, 1
    mov rsi, r8
    mov rdx, r9
    syscall
    test rax, rax
    jle .failure
    add r8, rax
    sub r9, rax
    jmp .loop
.success:
    xor eax, eax
    ret
.failure:
    mov eax, 1
    ret

_start:
    cmp qword [rsp], 2
    jne usage
    mov rdi, qword [rsp + 16]
    lea rsi, [rel arg_build]
    call arg_equals
    test eax, eax
    jnz mode_build
    mov rdi, qword [rsp + 16]
    lea rsi, [rel arg_serialize]
    call arg_equals
    test eax, eax
    jnz mode_serialize
    mov rdi, qword [rsp + 16]
    lea rsi, [rel arg_deserialize]
    call arg_equals
    test eax, eax
    jnz mode_deserialize
    jmp usage

mode_build:
    lea rdi, [rel input]
    mov esi, NEBOC_DOC_RECORD_BYTES
    call read_exact
    test eax, eax
    jnz io_failure
    lea rdi, [rel input]
    lea rsi, [rel output]
    call neboc_doc_record_new
    test eax, eax
    jnz semantic_failure
    lea rdi, [rel output]
    mov esi, NEBOC_DOC_RECORD_BYTES
    call write_all
    test eax, eax
    jnz io_failure
    jmp success

mode_serialize:
    lea rdi, [rel input]
    mov esi, NEBOC_DOC_RECORD_BYTES
    call read_exact
    test eax, eax
    jnz io_failure
    lea rdi, [rel input]
    lea rsi, [rel output]
    mov edx, 4192
    lea rcx, [rel output_length]
    call neboc_doc_serialize
    test eax, eax
    jnz semantic_failure
    lea rdi, [rel output]
    mov rsi, qword [rel output_length]
    call write_all
    test eax, eax
    jnz io_failure
    jmp success

mode_deserialize:
    lea rdi, [rel input]
    mov esi, 4192
    call read_exact
    test eax, eax
    jnz io_failure
    lea rdi, [rel input]
    mov esi, 4192
    lea rdx, [rel output]
    call neboc_doc_deserialize
    test eax, eax
    jnz semantic_failure
    lea rdi, [rel output]
    mov esi, NEBOC_DOC_RECORD_BYTES
    call write_all
    test eax, eax
    jnz io_failure

success:
    mov eax, 60
    xor edi, edi
    syscall
usage:
    mov eax, 60
    mov edi, 2
    syscall
io_failure:
    mov eax, 60
    mov edi, 3
    syscall
semantic_failure:
    mov eax, 60
    mov edi, 1
    syscall

section .rodata
arg_build: db '--build',0
arg_serialize: db '--serialize',0
arg_deserialize: db '--deserialize',0
section .bss
align 16
input: resb 4192
output: resb 4192
output_length: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
