bits 64
default rel
%include "runtime/scientific/root_integrate.inc"
extern nebo_bisect_sqrt_f64
extern nebo_simpson_square_f64
section .data
root_ctx dq 9.0,0.0,4.0,0.000000001
         dd 128,0
bad_ctx dq 9.0,-1.0,4.0,0.000000001
        dd 128,0
int_ctx dq 0.0,1.0
        dd 4,0
root_lo dq 2.999999
root_hi dq 3.000001
third_lo dq 0.333333
third_hi dq 0.333334
section .bss
solver_out resq 2
solver_report resq 1
integral_out resq 1
section .text
global _start
_start:
    lea rdi,[root_ctx]
    lea rsi,[solver_out]
    lea rdx,[solver_report]
    call nebo_bisect_sqrt_f64
    test eax,eax
    jnz fail
    movsd xmm0,[solver_out]
    ucomisd xmm0,[root_lo]
    jb fail
    ucomisd xmm0,[root_hi]
    ja fail
    mov qword [solver_out],0x1234
    lea rdi,[bad_ctx]
    lea rsi,[solver_out]
    lea rdx,[solver_report]
    call nebo_bisect_sqrt_f64
    cmp eax,NEBO_SOLVER_INVALID
    jne fail
    cmp qword [solver_out],0x1234
    jne fail
    lea rdi,[int_ctx]
    lea rsi,[integral_out]
    lea rdx,[solver_report]
    call nebo_simpson_square_f64
    test eax,eax
    jnz fail
    movsd xmm0,[integral_out]
    ucomisd xmm0,[third_lo]
    jb fail
    ucomisd xmm0,[third_hi]
    ja fail
    xor edi,edi
    jmp exit
fail: mov edi,1
exit: mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
