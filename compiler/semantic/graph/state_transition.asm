default rel
section .text
global nebo_state_transition_construct
; source,dest,guard bool,effect mask,capability mask,caller-owned out.
nebo_state_transition_construct:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp rdx, 1
    ja .invalid
    mov rax, r8
    not rax
    and rax, rcx
    jnz .capability
    test r9, r9
    jz .invalid
    mov [r9], rdi
    mov [r9+8], rsi
    mov [r9+16], rdx
    mov [r9+24], rcx
    mov qword [r9+32], 3
    xor eax, eax
    ret
.invalid: mov eax, 1
    ret
.capability: mov eax, 2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
