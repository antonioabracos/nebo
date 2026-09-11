bits 64
default rel
global _start
extern nebo_replay_validate
extern nebo_playback_validate

section .text
_start:
    mov rdi, 120
    mov rsi, 17
    mov rdx, 1
    call nebo_replay_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 17
    mov rdx, 1
    call nebo_replay_validate
    cmp eax, -1
    jne .fail
    mov rdi, 120
    mov rsi, 17
    mov rdx, 2
    call nebo_replay_validate
    cmp eax, -1
    jne .fail
    mov rdi, 120
    mov rsi, 17
    mov rdx, 1
    call nebo_replay_validate
    test eax, eax
    jne .fail
    mov rdi, 60
    mov rsi, 1
    mov rdx, 10000
    call nebo_playback_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
