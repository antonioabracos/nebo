default rel
section .text
global nebo_metadata_compile_time_validate
; rdi=phase 0 const/1 meta, rsi=pure flag, rdx=runtime-access flag,
; rcx=step budget, r8=out[phase,budget,pure,runtime access].
nebo_metadata_compile_time_validate:
    test r8, r8
    jz .invalid
    cmp rdi, 1
    ja .invalid
    cmp rsi, 1
    jne .effect
    test rdx, rdx
    jnz .effect
    test rcx, rcx
    jz .limit
    cmp rcx, 4096
    ja .limit
    mov [r8], rdi
    mov [r8+8], rcx
    mov qword [r8+16], 1
    mov qword [r8+24], 0
    xor eax, eax
    ret
.invalid:
    mov eax, 1
    ret
.effect:
    mov eax, 2
    ret
.limit:
    mov eax, 3
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
