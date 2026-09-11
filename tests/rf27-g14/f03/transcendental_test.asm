bits 64
default rel
%include "runtime/math/transcendental.inc"
section .rodata
align 8
z dq 0.0
nz dq 0x8000000000000000
one dq 1.0
two dq 2.0
fneg12 dq -1.2
pos dq 1.6
tol dq 1.0e-12
ntol dq -1.0
inf dq 0x7ff0000000000000
nan dq 0x7ff8000000000001
subn dq 1
section .text
global _start
_start:
 movsd xmm0,[rel z]
 call nebo_math_sin_f64
 ucomisd xmm0,[rel z]
 jne .fail1
 movsd xmm0,[rel z]
 call nebo_math_cos_f64
 ucomisd xmm0,[rel one]
 jne .fail2
 movsd xmm0,[rel z]
 call nebo_math_exp_f64
 ucomisd xmm0,[rel one]
 jne .fail3
 movsd xmm0,[rel one]
 call nebo_math_log_f64
 ucomisd xmm0,[rel z]
 jne .fail4
 movsd xmm0,[rel z]
 call nebo_math_log_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail5
 movsd xmm0,[rel z]
 movsd xmm1,[rel one]
 call nebo_math_atan2_f64
 ucomisd xmm0,[rel z]
 jne .fail6
 movsd xmm0,[rel fneg12]
 call nebo_math_floor_f64
 mov rax,0xc000000000000000
 movq xmm1,rax
 ucomisd xmm0,xmm1
 jne .fail7
 movsd xmm0,[rel fneg12]
 call nebo_math_ceil_f64
 mov rax,0xbff0000000000000
 movq xmm1,rax
 ucomisd xmm0,xmm1
 jne .fail8
 movsd xmm0,[rel pos]
 call nebo_math_round_f64
 ucomisd xmm0,[rel two]
 jne .fail9
 movsd xmm0,[rel one]
 call nebo_float_classify_f64
 cmp eax,NEBO_FLOAT_FINITE
 jne .fail10
 movsd xmm0,[rel nz]
 call nebo_float_classify_f64
 cmp eax,NEBO_FLOAT_FINITE|NEBO_FLOAT_NEGATIVE_ZERO
 jne .fail11
 movsd xmm0,[rel inf]
 call nebo_float_classify_f64
 cmp eax,NEBO_FLOAT_INFINITE
 jne .fail12
 movsd xmm0,[rel nan]
 call nebo_float_classify_f64
 cmp eax,NEBO_FLOAT_NAN
 jne .fail13
 movsd xmm0,[rel subn]
 call nebo_float_classify_f64
 cmp eax,NEBO_FLOAT_FINITE|NEBO_FLOAT_SUBNORMAL
 jne .fail14
 movsd xmm0,[rel one]
 movsd xmm1,[rel one]
 movsd xmm2,[rel tol]
 movsd xmm3,[rel tol]
 call nebo_float_approx_equal_f64
 test eax,eax
 jnz .fail15
 cmp edx,1
 jne .fail16
 movsd xmm0,[rel one]
 movsd xmm1,[rel two]
 movsd xmm2,[rel tol]
 movsd xmm3,[rel tol]
 call nebo_float_approx_equal_f64
 test edx,edx
 jnz .fail17
 movsd xmm0,[rel one]
 movsd xmm1,[rel one]
 movsd xmm2,[rel ntol]
 movsd xmm3,[rel tol]
 call nebo_float_approx_equal_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail18
 movsd xmm0,[rel z]
 call nebo_math_tan_f64
 ucomisd xmm0,[rel z]
 jne .fail19
 movsd xmm0,[rel nan]
 call nebo_math_floor_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail20
 xor edi,edi
 jmp .exit
%assign i 1
%rep 20
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
