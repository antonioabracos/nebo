default rel
section .text
global nebo_differentiation_bridge_plan
; rdi=0 autodiff/1 symbolic/2 numeric, rsi=budget 1..65536.
nebo_differentiation_bridge_plan:
    cmp rdi, 2
    ja .method
    test rsi, rsi
    jz .budget
    cmp rsi, 65536
    ja .budget
    mov rax, rdi
    xor edx, edx
    ret
.method: xor eax, eax
    mov edx, 1
    ret
.budget: xor eax, eax
    mov edx, 2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
