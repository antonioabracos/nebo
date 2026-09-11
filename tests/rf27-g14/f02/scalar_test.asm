bits 64
default rel
%include "runtime/math/scalar.inc"
section .rodata
align 8
f0 dq 0.0
f2 dq 2.0
f3 dq 3.0
f4 dq 4.0
f8 dq 8.0
f9 dq 9.0
f27 dq 27.0
fneg dq -1.0
section .text
global _start
_start:
 mov rdi,-7
 mov rsi,3
 call nebo_math_min_i64
 cmp rax,-7
 jne .fail1
 mov rdi,-9
 call nebo_math_abs_i64
 test eax,eax
 jnz .fail2
 cmp rdx,9
 jne .fail3
 mov rdi,0x8000000000000000
 call nebo_math_abs_i64
 cmp eax,NEBO_NUMERIC_ERROR_OVERFLOW
 jne .fail4
 mov rdi,12
 mov rsi,2
 mov rdx,8
 call nebo_math_clamp_i64
 test eax,eax
 jnz .fail5
 cmp rdx,8
 jne .fail6
 mov rdi,4
 mov rsi,8
 mov rdx,2
 call nebo_math_clamp_i64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail7
 movsd xmm0,[rel f9]
 call nebo_math_sqrt_f64
 test eax,eax
 jnz .fail8
 ucomisd xmm0,[rel f3]
 jne .fail9
 movsd xmm0,[rel fneg]
 call nebo_math_sqrt_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail10
 movsd xmm0,[rel f3]
 movsd xmm1,[rel f3]
 call nebo_math_pow_f64
 test eax,eax
 jnz .fail11
 ucomisd xmm0,[rel f27]
 jne .fail12
 movsd xmm0,[rel fneg]
 movsd xmm1,[rel f2]
 call nebo_math_pow_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail13
 movsd xmm0,[rel f0]
 movsd xmm1,[rel fneg]
 call nebo_math_pow_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail14
 movsd xmm0,[rel f3]
 movsd xmm1,[rel f4]
 call nebo_math_hypot_f64
 test eax,eax
 jnz .fail15
 mov rax,0x4014000000000000
 movq xmm1,rax
 ucomisd xmm0,xmm1
 jne .fail16
 movsd xmm0,[rel f0]
 movsd xmm1,[rel f0]
 call nebo_math_hypot_f64
 test eax,eax
 jnz .fail17
 ucomisd xmm0,[rel f0]
 jne .fail18
 xor edi,edi
 jmp .exit
%assign i 1
%rep 18
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
