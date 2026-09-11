bits 64
default rel
%include "runtime/pde/pde.inc"
extern nebo_pde_heat1d_step_f64
section .data
grid dq 0.0,0.0,1.0,0.0,0.0
alpha dq 0.25
qtr dq 0.25
half dq 0.5
bad_alpha dq 0.75
section .bss
next resq 5
section .text
global _start
_start:
    lea rdi,[next]
    lea rsi,[grid]
    mov edx,5
    lea rcx,[alpha]
    call nebo_pde_heat1d_step_f64
    test eax,eax
    jnz fail
    mov rax,[qtr]
    cmp [next+8],rax
    jne fail
    cmp [next+24],rax
    jne fail
    mov rax,[half]
    cmp [next+16],rax
    jne fail
    mov qword [next],0x1234
    lea rdi,[next]
    lea rsi,[grid]
    mov edx,5
    lea rcx,[bad_alpha]
    call nebo_pde_heat1d_step_f64
    cmp eax,NEBO_PDE_INVALID
    jne fail
    cmp qword [next],0x1234
    jne fail
    xor edi,edi
    jmp exit
fail: mov edi,1
exit: mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
