bits 64
default rel
global _start
extern nebo_jsonl_batch_validate
extern nebo_scan_event_validate

section .text
_start:
    mov rdi, 64
    mov rsi, 4096
    mov rdx, 1
    call nebo_jsonl_batch_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 4096
    mov rdx, 1
    call nebo_jsonl_batch_validate
    cmp eax, -1
    jne .fail
    mov rdi, 64
    mov rsi, 4096
    mov rdx, 4
    call nebo_jsonl_batch_validate
    cmp eax, -1
    jne .fail
    mov rdi, 64
    mov rsi, 4096
    mov rdx, 1
    call nebo_jsonl_batch_validate
    test eax, eax
    jne .fail
    mov rdi, 6
    mov rsi, 128
    mov rdx, 1
    call nebo_scan_event_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
