default rel
section .text
global nebo_registry_protocol_coherent
; edi=edition, esi=target protocol version, edx=required protocol version.
nebo_registry_protocol_coherent:
    test edi,edi
    jz .invalid
    cmp esi,edx
    jne .denied
    mov eax,1
    ret
.denied:
    xor eax,eax
    ret
.invalid:
    mov eax,2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
