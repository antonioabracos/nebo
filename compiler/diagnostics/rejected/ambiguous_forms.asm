default rel
section .rodata
form_0: db 0x21,0x21 ; NSR-REJ-014
form_1: db 0x2f,0x2f ; NSR-REJ-015
form_2: db 0x3d,0x3e ; NSR-REJ-016
form_3: db 0x2e,0x2e ; NSR-REJ-017
form_4: db 0x2d,0x3e ; NSR-REJ-018
align 8
forms:
    dq form_0, 2, 14, 145014, 146014
    dq form_1, 2, 15, 145015, 146015
    dq form_2, 2, 16, 145016, 146016
    dq form_3, 2, 17, 145017, 146017
    dq form_4, 2, 18, 145018, 146018
section .text
global nebo_reject_ambiguous_form
; rdi=exact lexeme bytes, rsi=length, rdx=out[id, diagnostic, quick-fix].
; eax: 1 rejected, 2 unknown, 3 invalid. Unknown/invalid are failure-atomic.
nebo_reject_ambiguous_form:
    test rdi, rdi
    jz .invalid
    test rdx, rdx
    jz .invalid
    test rsi, rsi
    jz .invalid
    lea r8, [forms]
    mov r9d, 5
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
