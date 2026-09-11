bits 64
default rel

section .text
global nebo_stack_alignment_sentinel

; Return 1 exactly when this normal callee observed the SysV entry contract.
; The first instruction measures the incoming stack without mutating it.
nebo_stack_alignment_sentinel:
    lea rax, [rsp + 8]
    and eax, 15
    sete al
    movzx eax, al
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
