default rel
section .text
global nebo_probability_status_code
; status 0 OK,1 INVALID,2 UNKNOWN,3 TIMEOUT,4 LIMIT.
nebo_probability_status_code:
    cmp rdi, 4
    ja .invalid
    lea rax, [rdi+138000]
    xor edx, edx
    ret
.invalid: xor eax, eax
    mov edx, 1
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
