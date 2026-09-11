bits 64
default rel
%include "runtime/numeric/exact/decimal_rational.inc"
extern nebo_rational_normalize_i64
extern nebo_rational_add_i64
extern nebo_decimal_round_u64
extern nebo_exact_i64_to_f64
section .data
ra dq 1,3
rb dq 1,6
section .bss
rat_out resq 2
rounded resq 1
loss_report resb 16
float_out resq 1
section .text
global _start
_start:
    lea rdi,[rat_out]
    mov rsi,-6
    mov rdx,-8
    call nebo_rational_normalize_i64
    test eax,eax
    jnz fail
    cmp qword [rat_out],3
    jne fail
    cmp qword [rat_out+8],4
    jne fail
    lea rdi,[rat_out]
    lea rsi,[ra]
    lea rdx,[rb]
    call nebo_rational_add_i64
    test eax,eax
    jnz fail
    cmp qword [rat_out],1
    jne fail
    cmp qword [rat_out+8],2
    jne fail
    mov edi,7
    mov esi,2
    mov edx,NEBO_ROUND_HALF_EVEN
    lea rcx,[rounded]
    lea r8,[loss_report]
    call nebo_decimal_round_u64
    test eax,eax
    jnz fail
    cmp qword [rounded],4
    jne fail
    cmp dword [loss_report],0
    jne fail
    mov qword [rounded],0x1234
    mov edi,7
    mov esi,2
    mov edx,NEBO_ROUND_EXACT
    lea rcx,[rounded]
    lea r8,[loss_report]
    call nebo_decimal_round_u64
    cmp eax,NEBO_EXACT_INEXACT
    jne fail
    cmp qword [rounded],0x1234
    jne fail
    mov rdi,9007199254740993
    lea rsi,[float_out]
    lea rdx,[loss_report]
    call nebo_exact_i64_to_f64
    test eax,eax
    jnz fail
    cmp dword [loss_report],0
    jne fail
    cmp dword [loss_report+4],1
    jne fail
    xor edi,edi
    jmp exit
fail: mov edi,1
exit: mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
