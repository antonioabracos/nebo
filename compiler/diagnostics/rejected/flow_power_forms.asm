default rel
section .rodata
form_0: db 0x7c,0x3e ; NSR-REJ-001
form_1: db 0x3c,0x2d,0x3e ; NSR-REJ-002
form_2: db 0x2a,0x2a ; NSR-REJ-003
form_3: db 0x5e ; NSR-REJ-004
align 8
forms:
    dq form_0, 2, 1, 145001, 146001
    dq form_1, 3, 2, 145002, 146002
    dq form_2, 2, 3, 145003, 146003
    dq form_3, 1, 4, 145004, 0
section .text
global nebo_reject_flow_power
; rdi=exact lexeme bytes, rsi=length, rdx=out[id, diagnostic, quick-fix].
; eax: 1 rejected, 2 unknown, 3 invalid. Unknown/invalid are failure-atomic.
nebo_reject_flow_power:
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
