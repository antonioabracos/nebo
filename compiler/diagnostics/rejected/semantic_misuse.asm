default rel
section .rodata
form_0: db 0x25 ; NSR-REJ-019
form_1: db 0xe2,0x89,0x88 ; NSR-REJ-020
form_2: db 0xe2,0x88,0xab ; NSR-REJ-021
form_3: db 0xc2,0xb1 ; NSR-REJ-022
align 8
forms:
    dq form_0, 1, 19, 145019, 146019
    dq form_1, 3, 20, 145020, 146020
    dq form_2, 3, 21, 145021, 0
    dq form_3, 2, 22, 145022, 0
section .text
global nebo_reject_semantic_misuse
; rdi=exact lexeme bytes, rsi=length, rdx=out[id, diagnostic, quick-fix].
; eax: 1 rejected, 2 unknown, 3 invalid. Unknown/invalid are failure-atomic.
nebo_reject_semantic_misuse:
    test rdi, rdi
    jz .invalid
    test rdx, rdx
    jz .invalid
    test rsi, rsi
    jz .invalid
    lea r8, [forms]
    mov r9d, 4
.candidate:
    cmp rsi, [r8+8]
    jne .next
    mov r10, [r8]
    mov r11, rdi
    mov rcx, rsi
.bytes:
    mov al, [r10]
    cmp al, [r11]
    jne .next
    inc r10
    inc r11
    dec rcx
    jnz .bytes
    mov rax, [r8+16]
    mov [rdx], rax
    mov rax, [r8+24]
    mov [rdx+8], rax
    mov rax, [r8+32]
    mov [rdx+16], rax
    mov eax, 1
    ret
.next:
    add r8, 40
    dec r9
    jnz .candidate
    mov eax, 2
    ret
.invalid:
    mov eax, 3
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
