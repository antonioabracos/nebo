default rel
section .text
global nebo_slash_directive_plan
; rdi=name, rsi=name length, rdx=arg count, rcx=depth,
; r8=step budget, r9=out[5]. ASCII identifier and anti-Turing bounds.
nebo_slash_directive_plan:
    test rdi, rdi
    jz .invalid
    test r9, r9
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp rsi, 64
    ja .limit
    cmp rdx, 32
    ja .limit
    cmp rcx, 64
    ja .limit
    test r8, r8
    jz .limit
    cmp r8, 4096
    ja .limit
    xor r10d, r10d
.name:
    movzx eax, byte [rdi+r10]
    cmp al, '_'
    je .accepted
    cmp al, 'A'
    jb .digit
    cmp al, 'Z'
    jbe .accepted
    cmp al, 'a'
    jb .digit
    cmp al, 'z'
    jbe .accepted
.digit:
    test r10, r10
    jz .invalid
    cmp al, '0'
    jb .invalid
    cmp al, '9'
    ja .invalid
.accepted:
    inc r10
    cmp r10, rsi
    jb .name
    mov qword [r9], 79
    mov [r9+8], rsi
    mov [r9+16], rdx
    mov [r9+24], rcx
    mov [r9+32], r8
    xor eax, eax
    ret
.invalid:
    mov eax, 1
    ret
.limit:
    mov eax, 2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
