default rel
section .text
global nebo_random_variable_validate
; descriptor: type,distribution,support_min,support_max,dimensions,measure.
nebo_random_variable_validate:
    test rdi, rdi
    jz .invalid
    cmp qword [rdi], 0
    jle .invalid
    cmp qword [rdi+8], 0
    jle .invalid
    mov rax, [rdi+16]
    cmp rax, [rdi+24]
    jg .support
    mov rax, [rdi+32]
    test rax, rax
    jz .invalid
    cmp rax, 16
    ja .limit
    cmp qword [rdi+40], 0
    jle .invalid
    xor eax, eax
    ret
.invalid: mov eax, 1
    ret
.support: mov eax, 2
    ret
.limit: mov eax, 3
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
