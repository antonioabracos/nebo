bits 64
default rel
%include "runtime/numeric/interval/interval.inc"
extern nebo_interval_add_f64
extern nebo_interval_intersect_f64
extern nebo_interval_mul_nonnegative_f64
extern nebo_interval_contains_f64
section .data
a dq 0.1,0.1
b dq 0.2,0.2
point3 dq 0.3
c dq 1.0,3.0
d dq 2.0,4.0
empty_a dq 1.0,2.0
empty_b dq 3.0,4.0
mul_a dq 2.0,3.0
mul_b dq 4.0,5.0
section .bss
iv_out resq 2
contains_out resd 1
section .text
global _start
_start:
    lea rdi,[iv_out]
    lea rsi,[a]
    lea rdx,[b]
    call nebo_interval_add_f64
    test eax,eax
    jnz fail
    lea rdi,[iv_out]
    movsd xmm0,[point3]
    lea rsi,[contains_out]
    call nebo_interval_contains_f64
    test eax,eax
    jnz fail
    cmp dword [contains_out],1
    jne fail
    lea rdi,[iv_out]
    lea rsi,[c]
    lea rdx,[d]
    call nebo_interval_intersect_f64
    test eax,eax
    jnz fail
    mov rax,[d]
    cmp [iv_out],rax
    jne fail
    mov rax,[c+8]
    cmp [iv_out+8],rax
    jne fail
    mov qword [iv_out],0x1234
    lea rdi,[iv_out]
    lea rsi,[empty_a]
    lea rdx,[empty_b]
    call nebo_interval_intersect_f64
    cmp eax,NEBO_INTERVAL_EMPTY
    jne fail
    cmp qword [iv_out],0x1234
    jne fail
    lea rdi,[iv_out]
    lea rsi,[mul_a]
    lea rdx,[mul_b]
    call nebo_interval_mul_nonnegative_f64
    test eax,eax
    jnz fail
    xor edi,edi
    jmp exit
fail: mov edi,1
exit: mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
