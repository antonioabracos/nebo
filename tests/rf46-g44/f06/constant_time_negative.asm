bits 64
section .text
audit_target:
; secret-begin
    test rax,rax
    jnz leaked
; secret-end
leaked:
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
