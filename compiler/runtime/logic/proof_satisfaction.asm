default rel
section .text
global nebo_proof_accepts, nebo_model_satisfies
; status: 0 PROVED,1 DISPROVED,2 SAT,3 UNSAT,4 UNKNOWN,5 TIMEOUT.
nebo_proof_accepts:
    cmp edi, 5
    ja .invalid
    cmp rsi, 1000000
    ja .invalid
    xor eax, eax
    test edi, edi
    sete al
    mov edx, edi
    ret
.invalid: xor eax, eax
    mov edx, 6
    ret
nebo_model_satisfies:
    cmp edi, 5
    ja .invalid2
    cmp rsi, 1000000
    ja .invalid2
    xor eax, eax
    cmp edi, 2
    sete al
    mov edx, edi
    ret
.invalid2: xor eax, eax
    mov edx, 6
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
