default rel
section .text
global nebo_registry_deprecation_state
; edi=current edition, esi=deprecated edition, edx=removal edition, rcx=out state.
nebo_registry_deprecation_state:
    test rcx,rcx
    jz .invalid
    test esi,esi
    jz .invalid
    cmp edx,esi
    jbe .invalid
    mov eax,1
    cmp edi,esi
    jb .publish
    mov eax,2
    cmp edi,edx
    jb .publish
    mov eax,3
.publish:
    mov [rcx],rax
    mov eax,1
    ret
.invalid:
    mov eax,2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
