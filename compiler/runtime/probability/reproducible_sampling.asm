default rel
section .text
global nebo_reproducible_sample_u64
; rdi=explicit nonzero state pointer,rsi=exclusive bound; rax=sample,rdx=status.
nebo_reproducible_sample_u64:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    mov rax, [rdi]
    test rax, rax
    jz .invalid
    mov rcx, rax
    shl rcx, 13
    xor rax, rcx
    mov rcx, rax
    shr rcx, 7
    xor rax, rcx
    mov rcx, rax
    shl rcx, 17
    xor rax, rcx
    mov [rdi], rax
    xor edx, edx
    div rsi
    mov rax, rdx
    xor edx, edx
    ret
.invalid: xor eax, eax
    mov edx, 1
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
