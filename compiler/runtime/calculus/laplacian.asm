default rel
section .text
global nebo_laplacian_central_i64
; rdi=plus[], rsi=minus[], rdx=center, rcx=dims, r8=h_squared.
nebo_laplacian_central_i64:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    test rcx, rcx
    jz .invalid
    cmp rcx, 16
    ja .limit
    test r8, r8
    jle .invalid
    mov r9, rdx
    add r9, r9
    jo .overflow
    xor eax, eax
    xor r10d, r10d
.loop:
    mov r11, [rdi+r10*8]
    add r11, [rsi+r10*8]
    jo .overflow
    sub r11, r9
    jo .overflow
    add rax, r11
    jo .overflow
    inc r10
    cmp r10, rcx
    jb .loop
    cqo
    idiv r8
    xor edx, edx
    ret
.invalid: xor eax, eax
    mov edx, 1
    ret
.limit: xor eax, eax
    mov edx, 2
    ret
.overflow: xor eax, eax
    mov edx, 3
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
