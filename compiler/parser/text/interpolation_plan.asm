default rel
section .text
global nebo_interpolation_plan
; rdi=expression count, rsi=max depth, rdx=pure flag, rcx=out[4].
; Publishes one FormatPlan fragment only after complete validation.
nebo_interpolation_plan:
    test rcx, rcx
    jz .invalid
    test rdi, rdi
    jz .invalid
    cmp rdi, 64
    ja .limit
    test rsi, rsi
    jz .invalid
    cmp rsi, 64
    ja .limit
    cmp rdx, 1
    jne .effect
    mov qword [rcx], 77
    mov [rcx+8], rdi
    mov [rcx+16], rsi
    mov qword [rcx+24], 1
    xor eax, eax
    ret
.invalid:
    mov eax, 1
    ret
.limit:
    mov eax, 2
    ret
.effect:
    mov eax, 3
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
