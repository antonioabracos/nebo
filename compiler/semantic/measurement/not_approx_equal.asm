bits 64
default rel

extern nebo_approx_equal_i64

section .text

; The negative relation is defined from the same explicit-tolerance predicate.
; Errors are preserved and never converted to boolean true.
global nebo_not_approx_equal_i64
nebo_not_approx_equal_i64:
    sub rsp, 8
    call nebo_approx_equal_i64
    add rsp, 8
    test edx, edx
    jnz .done
    xor eax, 1
.done:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
