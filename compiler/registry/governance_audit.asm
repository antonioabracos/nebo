default rel
section .text
global nebo_registry_governance_audit
; rdi=monotonic approval sequence (qwords), rsi=count.
nebo_registry_governance_audit:
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    mov rax,[rdi]
    add rdi,8
    dec rsi
    jz .valid
.loop:
    mov rdx,[rdi]
    cmp rdx,rax
    jbe .denied
    mov rax,rdx
    add rdi,8
    dec rsi
    jnz .loop
.valid:
    mov eax,1
    ret
.denied:
    xor eax,eax
    ret
.invalid:
    mov eax,2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
