default rel
section .text
global nebo_registry_class_transition
; edi=old class, esi=new class, edx=approved change-control bit.
; classes 1 CORE, 2 ALIAS, 3 DOMAIN_GATED, 4 RESERVED, 5 REJECTED.
nebo_registry_class_transition:
    cmp edi,1
    jb .invalid
    cmp edi,5
    ja .invalid
    cmp esi,1
    jb .invalid
    cmp esi,5
    ja .invalid
    cmp edi,esi
    je .allowed
    cmp edi,5
    je .denied
    cmp edx,1
    jne .denied
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
