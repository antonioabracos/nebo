default rel
section .rodata
form_0: db 0x3a,0x3d ; NSR-REJ-009
form_1: db 0x2c ; NSR-REJ-010
form_2: db 0x3d ; NSR-REJ-011
form_3: db 0x3c,0x3e ; NSR-REJ-012
form_4: db 0x61,0x6e,0x64 ; NSR-REJ-013
form_5: db 0x6f,0x72 ; NSR-REJ-013
form_6: db 0x6e,0x6f,0x74 ; NSR-REJ-013
align 8
forms:
    dq form_0, 2, 9, 145009, 146009
    dq form_1, 1, 10, 145010, 0
    dq form_2, 1, 11, 145011, 146011
    dq form_3, 2, 12, 145012, 146012
    dq form_4, 3, 13, 145013, 146013
    dq form_5, 2, 13, 145013, 146013
    dq form_6, 3, 13, 145013, 146013
section .text
global nebo_reject_binding_equality
; rdi=exact lexeme bytes, rsi=length, rdx=out[id, diagnostic, quick-fix].
; eax: 1 rejected, 2 unknown, 3 invalid. Unknown/invalid are failure-atomic.
nebo_reject_binding_equality:
    test rdi, rdi
    jz .invalid
    test rdx, rdx
    jz .invalid
    test rsi, rsi
    jz .invalid
    lea r8, [forms]
    mov r9d, 7
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
