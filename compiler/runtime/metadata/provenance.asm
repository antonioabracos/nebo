default rel
section .text
global nebo_metadata_provenance
; rdi=origin identity, rsi=version, rdx=privacy 0..2,
; rcx=explicit disclosure capability, r8=caller out[5].
nebo_metadata_provenance:
    test r8, r8
    jz .invalid
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp rdx, 2
    ja .invalid
    cmp rdx, 2
    jne .publish
    test rcx, rcx
    jz .privacy
.publish:
    mov [r8], rdi
    mov [r8+8], rsi
    mov [r8+16], rdx
    mov [r8+24], rcx
    mov r9, rsi
    rol r9, 13
    xor r9, rdi
    xor r9, rdx
    mov [r8+32], r9
    xor eax, eax
    ret
.invalid:
    mov eax, 1
    ret
.privacy:
    mov eax, 2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
