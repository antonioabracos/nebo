default rel
section .text
global nebo_registry_snapshot_valid
; rdi=observed digest, rsi=expected digest, edx=length. Exact 32-byte authority.
nebo_registry_snapshot_valid:
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp edx,32
    jne .invalid
    mov ecx,32
.loop:
    mov al,[rdi]
    cmp al,[rsi]
    jne .different
    inc rdi
    inc rsi
    dec ecx
    jnz .loop
    mov eax,1
    ret
.different:
    xor eax,eax
    ret
.invalid:
    mov eax,2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
