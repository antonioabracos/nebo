default rel
section .text
global nebo_registry_migration_restore
; rdi=source ids, rsi=count, rdx=destination, rcx=capacity. Copy is all-or-nothing.
nebo_registry_migration_restore:
    test rdi,rdi
    jz .invalid
    test rdx,rdx
    jz .invalid
    cmp rsi,rcx
    ja .capacity
    mov r8,rsi
    test r8,r8
    jz .ok
.copy:
    mov rax,[rdi]
    mov [rdx],rax
    add rdi,8
    add rdx,8
    dec r8
    jnz .copy
.ok:
    mov eax,1
    ret
.capacity:
    xor eax,eax
    ret
.invalid:
    mov eax,2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
