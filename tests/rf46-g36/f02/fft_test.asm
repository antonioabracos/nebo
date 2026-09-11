bits 64
default rel
%include "runtime/fft/fft.inc"
extern nebo_fft4_f64
extern nebo_power_spectrum4_f64
section .data
impulse dq 1.0,0.0, 0.0,0.0, 0.0,0.0, 0.0,0.0
one dq 1.0
zero dq 0.0
section .bss
freq resq 8
back resq 8
power resq 4
section .text
global _start
_start:
    lea rdi,[freq]
    lea rsi,[impulse]
    mov edx,NEBO_FFT_FORWARD
    call nebo_fft4_f64
    test eax,eax
    jnz fail
    xor ecx,ecx
.ones:
    mov rax,[one]
    cmp [freq+rcx*8],rax
    jne fail
    mov rax,[zero]
    cmp [freq+rcx*8+8],rax
    jne fail
    add ecx,2
    cmp ecx,8
    jb .ones
    lea rdi,[back]
    lea rsi,[freq]
    mov edx,NEBO_FFT_INVERSE
    call nebo_fft4_f64
    test eax,eax
    jnz fail
    mov rax,[one]
    cmp [back],rax
    jne fail
    lea rdi,[power]
    lea rsi,[freq]
    call nebo_power_spectrum4_f64
    test eax,eax
    jnz fail
    mov rax,[one]
    cmp [power+24],rax
    jne fail
    xor edi,edi
    jmp exit
fail: mov edi,1
exit: mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
