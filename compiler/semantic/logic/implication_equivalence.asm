default rel
section .text
global nebo_logic_implies, nebo_logic_iff
nebo_logic_implies:
    cmp edi, 1
    ja .invalid
    cmp esi, 1
    ja .invalid
    test edi, edi
    jz .true
    mov eax, esi
    ret
.true: mov eax, 1
    ret
.invalid: mov eax, 4
    ret
nebo_logic_iff:
    cmp edi, 1
    ja .invalid2
    cmp esi, 1
    ja .invalid2
    xor eax, eax
    cmp edi, esi
    sete al
    ret
.invalid2: mov eax, 4
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
