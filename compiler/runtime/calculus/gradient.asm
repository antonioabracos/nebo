default rel
section .text
global nebo_gradient_central_i64
; rdi=plus[], rsi=minus[], rdx=dims, rcx=step, r8=out[], r9=capacity.
nebo_gradient_central_i64:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    test r8, r8
    jz .invalid
    test rcx, rcx
    jle .invalid
    test rdx, rdx
    jz .invalid
    cmp rdx, 16
    ja .limit
    cmp r9, rdx
    jb .limit
    mov r9, rdx
    mov r10, rcx
    add r10, r10
    jo .overflow
    xor r11d, r11d
.preflight:
    mov rax, [rdi+r11*8]
    sub rax, [rsi+r11*8]
    jo .overflow
    inc r11
    cmp r11, r9
    jb .preflight
    xor r11d, r11d
.write:
    mov rax, [rdi+r11*8]
    sub rax, [rsi+r11*8]
    cqo
    idiv r10
    mov [r8+r11*8], rax
    inc r11
    cmp r11, r9
    jb .write
    xor eax, eax
    ret
.invalid: mov eax, 1
    ret
.limit: mov eax, 2
    ret
.overflow: mov eax, 3
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
