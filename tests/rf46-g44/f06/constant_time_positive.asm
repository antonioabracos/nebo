bits 64
section .text
audit_target:
; secret-begin
    xor rax,rbx
    rol rax,13
    and rax,rcx
; secret-end
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
