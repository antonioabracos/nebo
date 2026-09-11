bits 64
default rel
%include "runtime/math/integration.inc"
section .rodata
align 8
zero dq 0.0
one dq 1.0
third dq 0.33333333333333333333
tol_bits dq 0x3d719799812dea11
section .text
global _start
square:
 mulsd xmm0,xmm0
 ret
_start:
 lea rdi,[rel square]
 xor esi,esi
 mov edx,100
 movsd xmm0,[rel zero]
 movsd xmm1,[rel one]
 call nebo_math_integrate_simpson_f64
 test eax,eax
 jnz .fail1
 subsd xmm0,[rel third]
 movq rax,xmm0
 btr rax,63
 cmp rax,[rel tol_bits]
 ja .fail2
 lea rdi,[rel square]
 xor esi,esi
 mov edx,3
 movsd xmm0,[rel zero]
 movsd xmm1,[rel one]
 call nebo_math_integrate_simpson_f64
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail3
 lea rdi,[rel square]
 xor esi,esi
 mov edx,4098
 movsd xmm0,[rel zero]
 movsd xmm1,[rel one]
 call nebo_math_integrate_simpson_f64
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail4
 xor edi,edi
 mov edx,2
 movsd xmm0,[rel zero]
 movsd xmm1,[rel one]
 call nebo_math_integrate_simpson_f64
 cmp eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jne .fail5
 lea rdi,[rel square]
 mov edx,2
 movsd xmm0,[rel one]
 movsd xmm1,[rel zero]
 call nebo_math_integrate_simpson_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail6
 xor edi,edi
 jmp .exit
%assign i 1
%rep 6
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
