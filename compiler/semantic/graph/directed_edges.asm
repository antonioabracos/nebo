default rel
section .text
global nebo_directed_edge_construct
; source,dest,source schema,dest schema,out,kind 0 directed/1 bidirectional.
nebo_directed_edge_construct:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    test rdx, rdx
    jz .invalid
    cmp rdx, rcx
    jne .schema
    test r8, r8
    jz .invalid
    cmp r9, 1
    ja .invalid
    mov [r8], rdi
    mov [r8+8], rsi
    mov [r8+16], rdx
    mov [r8+24], r9
    mov qword [r8+32], 1
    xor eax, eax
    ret
.invalid: mov eax, 1
    ret
.schema: mov eax, 2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
