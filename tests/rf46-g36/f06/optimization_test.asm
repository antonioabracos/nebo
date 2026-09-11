bits 64
default rel
%include "runtime/optimization/optimization.inc"
extern nebo_opt_projected_quadratic_step_f64
section .data
q dq 2.0,2.0
c dq -2.0,-4.0
x dq 0.0,0.0
lower dq 0.0,0.0
upper dq 10.0,10.0
bad_upper dq -1.0,10.0
expected0 dq 0.5
expected1 dq 1.0
ctx dq q,c,x,lower,upper,2
    dq 0.25
badctx dq q,c,x,lower,bad_upper,2
    dq 0.25
section .bss
result resq 2
report resb NEBO_OPT_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[result]
    lea rsi,[ctx]
    lea rdx,[report]
    call nebo_opt_projected_quadratic_step_f64
    test eax,eax
    jnz fail
    mov rax,[expected0]
    cmp [result],rax
    jne fail
    mov rax,[expected1]
    cmp [result+8],rax
    jne fail
    cmp qword [report+NEBO_OPT_REPORT_DIMENSION],2
    jne fail
    mov qword [result],0x1234
    lea rdi,[result]
    lea rsi,[badctx]
    lea rdx,[report]
    call nebo_opt_projected_quadratic_step_f64
    cmp eax,NEBO_OPT_INVALID
    jne fail
    cmp qword [result],0x1234
    jne fail
    xor edi,edi
    jmp exit
fail: mov edi,1
exit: mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
