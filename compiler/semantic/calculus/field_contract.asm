default rel
section .text
global nebo_field_contract_validate
; descriptor: dimensions, unit, method, boundary policy, budget.
nebo_field_contract_validate:
    test rdi, rdi
    jz .invalid
    mov rax, [rdi]
    test rax, rax
    jz .invalid
    cmp rax, 16
    ja .limit
    cmp qword [rdi+8], 0
    jle .invalid
    cmp qword [rdi+16], 2
    ja .invalid
    cmp qword [rdi+24], 3
    ja .invalid
    mov rax, [rdi+32]
    test rax, rax
    jz .limit
    cmp rax, 65536
    ja .limit
    xor eax, eax
    ret
.invalid: mov eax, 1
    ret
.limit: mov eax, 2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
