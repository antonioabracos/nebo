bits 64
default rel
global _start
extern nebo_roundtrip_validate
extern nebo_jsonl_batch_validate
extern nebo_event_pack

section .text
_start:
    mov rdi, 1
    mov rsi, 1
    mov rdx, 8
    call nebo_roundtrip_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 1
    mov rdx, 8
    call nebo_roundtrip_validate
    cmp eax, -1
    jne .fail
    mov rdi, 1
    mov rsi, 1
    mov rdx, 65
    call nebo_roundtrip_validate
    cmp eax, -1
    jne .fail
    mov rdi, 1
    mov rsi, 2
    mov rdx, 8
    call nebo_roundtrip_validate
    cmp eax, -1
    jne .fail
    mov rdi, 1
    mov rsi, 1
    mov rdx, 8
    call nebo_roundtrip_validate
    test eax, eax
    jne .fail
    mov rdi, 64
    mov rsi, 4096
    mov rdx, 1
    call nebo_jsonl_batch_validate
    test eax, eax
    jne .fail
    mov rdi, 3
    mov rsi, 42
    mov rdx, 1
    call nebo_event_pack
    mov rbx, 0x010300000000002a
    cmp rax, rbx
    jne .fail
    mov rdi, 0
    mov rsi, 42
    mov rdx, 1
    call nebo_event_pack
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
