default rel
section .text
global nebo_registry_resolution_budget
; rdi=input units, rsi=caller budget, rdx=out work units. Atomic on failure.
nebo_registry_resolution_budget:
    test rdx,rdx
    jz .invalid
    cmp rdi,65536
    ja .exceeded
    cmp rdi,rsi
    ja .exceeded
    lea rax,[rdi+rdi*2]
    mov [rdx],rax
    mov eax,1
    ret
.exceeded:
    xor eax,eax
    ret
.invalid:
    mov eax,2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
