default rel
section .text
global nebo_distributed_as_validate
; rdi=RV type,rsi=distribution sample type,rdx=RV shape,rcx=distribution shape.
nebo_distributed_as_validate:
    test rdi, rdi
    jz .invalid
    cmp rdi, rsi
    jne .mismatch
    test rdx, rdx
    jz .invalid
    cmp rdx, rcx
    jne .mismatch
    mov eax, 1
    xor edx, edx
    ret
.mismatch: xor eax, eax
    mov edx, 2
    ret
.invalid: xor eax, eax
    mov edx, 1
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
