default rel
section .text
global nebo_async_edge_construct
; source,dest,schema,capacity,backpressure 0..2,caller-owned out.
nebo_async_edge_construct:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    test rdx, rdx
    jz .invalid
    test rcx, rcx
    jz .capacity
    cmp r8, 2
    ja .invalid
    test r9, r9
    jz .invalid
    mov [r9], rdi
    mov [r9+8], rsi
    mov [r9+16], rdx
    mov [r9+24], rcx
    mov [r9+32], r8
    mov qword [r9+40], 2
    xor eax, eax
    ret
.invalid: mov eax, 1
    ret
.capacity: mov eax, 2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
