bits 64
default rel

%define TEXT_DATA 0
%define TEXT_LENGTH 8

global nebo_runtime_console_publish_text
global nebo_runtime_console_publish_int
global nebo_runtime_console_publish_bool
global nebo_runtime_scan_console_handle

section .rodata align=8
true_bytes: db "true"
false_bytes: db "false"
scan_bytes: db "buffer-oracle"
align 8
scan_desc:
    dq scan_bytes
    dq 13
    dd 0
    dw 1
    dw 1

section .bss align=8
int_buffer: resb 32

section .text
write_all:
    test rdx, rdx
    jz .done
.loop:
    mov eax, 1
    mov edi, 1
    syscall
    cmp rax, -4
    je .loop
    test rax, rax
    jle .failed
    add rsi, rax
    sub rdx, rax
    jnz .loop
.done:
    xor eax, eax
    ret
.failed:
    mov edi, 190
    mov eax, 60
    syscall
    ud2

nebo_runtime_console_publish_text:
    test rdi, rdi
    jz .text_done
    mov rsi, [rdi + TEXT_DATA]
    mov rdx, [rdi + TEXT_LENGTH]
    call write_all
.text_done:
    mov eax, 1
    ret

nebo_runtime_console_publish_bool:
    test rdi, rdi
    jz .bool_false
    lea rsi, [rel true_bytes]
    mov edx, 4
    jmp .bool_write
.bool_false:
    lea rsi, [rel false_bytes]
    mov edx, 5
.bool_write:
    call write_all
    mov eax, 1
    ret

nebo_runtime_console_publish_int:
    lea r8, [rel int_buffer + 32]
    mov rax, rdi
    xor r9d, r9d
    test rax, rax
    jns .magnitude
    mov r9d, 1
    neg rax
.magnitude:
    mov r10, r8
    test rax, rax
    jnz .digits
    dec r10
    mov byte [r10], '0'
    jmp .sign
.digits:
    mov ecx, 10
.digit_loop:
    xor edx, edx
    div rcx
    add dl, '0'
    dec r10
    mov [r10], dl
    test rax, rax
    jnz .digit_loop
.sign:
    test r9d, r9d
    jz .int_write
    dec r10
    mov byte [r10], '-'
.int_write:
    mov rsi, r10
    mov rdx, r8
    sub rdx, r10
    call write_all
    mov eax, 1
    ret

nebo_runtime_scan_console_handle:
    lea rax, [rel scan_desc]
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
