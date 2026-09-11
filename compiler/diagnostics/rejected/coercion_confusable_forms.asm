default rel
section .rodata
form_0: db 0x54,0x65,0x78,0x74,0x2b,0x4e,0x75,0x6d,0x62,0x65,0x72 ; NSR-REJ-023
form_1: db 0x6f,0x70,0x65,0x72,0x61,0x74,0x6f,0x72 ; NSR-REJ-024
form_2: db 0xef,0xbc,0x8b ; NSR-REJ-025
form_3: db 0x25,0x25 ; NSR-REJ-026
align 8
forms:
    dq form_0, 11, 23, 145023, 146023
    dq form_1, 8, 24, 145024, 0
    dq form_2, 3, 25, 145025, 146025
    dq form_3, 2, 26, 145026, 146026
section .text
global nebo_reject_coercion_confusable
; rdi=exact lexeme bytes, rsi=length, rdx=out[id, diagnostic, quick-fix].
; eax: 1 rejected, 2 unknown, 3 invalid. Unknown/invalid are failure-atomic.
nebo_reject_coercion_confusable:
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
