default rel
section .text
global nebo_registry_edition_profile
; edi=edition (1 stable,2 extended), esi=profile bitset, edx=required gate.
nebo_registry_edition_profile:
    cmp edi,1
    jb .invalid
    cmp edi,2
    ja .invalid
    test esi,0xffff0000
    jnz .invalid
    test edx,edx
    jz .allowed
    test esi,edx
    jz .denied
.allowed:
    mov eax,1
    ret
.denied:
    xor eax,eax
    ret
.invalid:
    mov eax,2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
