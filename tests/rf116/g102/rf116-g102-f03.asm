bits 64
default rel
global _start
extern nebo_playback_validate
extern nebo_timebase_validate

section .text
_start:
    mov rdi, 60
    mov rsi, 1
    mov rdx, 10000
    call nebo_playback_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 1
    mov rdx, 10000
    call nebo_playback_validate
    cmp eax, -1
    jne .fail
    mov rdi, 60
    mov rsi, 1
    mov rdx, 86400001
    call nebo_playback_validate
    cmp eax, -1
    jne .fail
    mov rdi, 60
    mov rsi, 1
    mov rdx, 10000
    call nebo_playback_validate
    test eax, eax
    jne .fail
    mov rdi, 120
    mov rsi, 1000
    mov rdx, 1
    call nebo_timebase_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
