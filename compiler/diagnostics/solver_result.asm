default rel
section .text
global nebo_solver_result_code
; rdi=status 0..5,rsi=steps; rax=stable code,rdx=proof-pass flag,rcx=status.
nebo_solver_result_code:
    cmp rdi, 5
    ja .invalid
    cmp rsi, 1000000
    ja .limit
    lea rax, [rdi+139000]
    xor edx, edx
    test rdi, rdi
    sete dl
    mov rcx, rdi
    ret
.limit: xor eax, eax
    xor edx, edx
    mov ecx, 5
    ret
.invalid: xor eax, eax
    xor edx, edx
    mov ecx, 6
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
