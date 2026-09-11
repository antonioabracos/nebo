bits 64
default rel
%include "runtime/ode/ode.inc"
extern nebo_ode_euler_linear_f64
section .data
ctx dq 1.0,1.0,0.0,1.0,2.0
    dd 1024,0
lo dq 2.716
hi dq 2.719
section .bss
ode_out resq 3
ode_report resb 16
section .text
global _start
_start:
    lea rdi,[ctx]
    lea rsi,[ode_out]
    lea rdx,[ode_report]
    call nebo_ode_euler_linear_f64
    test eax,eax
    jnz fail
    movsd xmm0,[ode_out+8]
    ucomisd xmm0,[lo]
    jb fail
    ucomisd xmm0,[hi]
    ja fail
    cmp dword [ode_report],1024
    jne fail
    cmp dword [ode_report+4],NEBO_ODE_NO_EVENT
    je fail
    xor edi,edi
    jmp exit
fail: mov edi,1
exit: mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
