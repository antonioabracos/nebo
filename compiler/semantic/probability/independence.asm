default rel
section .text
global nebo_independence_relation
; rdi=model context,rsi=left id,rdx=right id,rcx=0 unknown/1 independent/2 dependent.
nebo_independence_relation:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    test rdx, rdx
    jz .invalid
    cmp rcx, 2
    ja .invalid
    test rcx, rcx
    jz .unknown
    xor eax, eax
    cmp rcx, 1
    sete al
    xor edx, edx
    ret
.unknown: mov eax, 2
    mov edx, 2
    ret
.invalid: xor eax, eax
    mov edx, 1
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
