; TREE-GRAPH-NODE-E-EDGE-F02 bounded scalar fundamentals, no libc/libm
bits 64
default rel
%define NEBO_SCALAR_IMPLEMENTATION 1
%include "runtime/math/scalar.inc"

section .rodata
align 8
scalar_zero dq 0.0
scalar_one dq 1.0
scalar_abs_mask dq 0x7fffffffffffffff

section .text
global nebo_math_min_i64
global nebo_math_abs_i64
global nebo_math_clamp_i64
global nebo_math_sqrt_f64
global nebo_math_pow_f64
global nebo_math_hypot_f64

; (rdi, rsi) -> rax, exact signed minimum
nebo_math_min_i64:
    mov rax,rdi
    cmp rdi,rsi
    cmovg rax,rsi
    ret

; rdi -> status eax, result rdx
nebo_math_abs_i64:
    mov rdx,rdi
    test rdx,rdx
    jns .abs_ok
    mov rax,0x8000000000000000
    cmp rdx,rax
    je .abs_overflow
    neg rdx
.abs_ok:
    xor eax,eax
    ret
.abs_overflow:
    mov eax,NEBO_NUMERIC_ERROR_OVERFLOW
    ret

; rdi=value rsi=low rdx=high -> status eax, result rdx
nebo_math_clamp_i64:
    cmp rsi,rdx
    jg .clamp_domain
    mov rax,rdi
    cmp rax,rsi
    cmovl rax,rsi
    cmp rax,rdx
    cmovg rax,rdx
    mov rdx,rax
    xor eax,eax
    ret
.clamp_domain:
    mov eax,NEBO_NUMERIC_ERROR_DOMAIN
    ret

; xmm0=value -> eax status, xmm0=result
nebo_math_sqrt_f64:
    ucomisd xmm0,[rel scalar_zero]
    jp .sqrt_domain
    jb .sqrt_domain
    sqrtsd xmm0,xmm0
    xor eax,eax
    ret
.sqrt_domain:
    mov eax,NEBO_NUMERIC_ERROR_DOMAIN
    ret

; xmm0=base, xmm1=exponent -> eax status, xmm0=result.
; Bounded binary64 profile accepts positive bases, and zero with positive exp.
nebo_math_pow_f64:
    ucomisd xmm0,[rel scalar_zero]
    jp .pow_domain
    jb .pow_domain
    jne .pow_positive
    ucomisd xmm1,[rel scalar_zero]
    jbe .pow_domain
    xorpd xmm0,xmm0
    xor eax,eax
    ret
.pow_positive:
    sub rsp,24
    movsd [rsp],xmm0
    movsd [rsp+8],xmm1
    fld qword [rsp+8]
    fld qword [rsp]
    fyl2x
    fld st0
    frndint
    fxch st1
    fsub st0,st1
    f2xm1
    fld1
    faddp st1,st0
    fscale
    fstp st1
    fstp qword [rsp+16]
    movsd xmm0,[rsp+16]
    add rsp,24
    xor eax,eax
    ret
.pow_domain:
    mov eax,NEBO_NUMERIC_ERROR_DOMAIN
    ret

; xmm0=x, xmm1=y -> eax status, xmm0=sqrt(x*x+y*y), scaled.
nebo_math_hypot_f64:
    movq rax,xmm0
    movq rcx,xmm1
    and rax,[rel scalar_abs_mask]
    and rcx,[rel scalar_abs_mask]
    movq xmm0,rax
    movq xmm1,rcx
    ucomisd xmm0,xmm1
    jp .hypot_domain
    jae .ordered
    movapd xmm2,xmm0
    movapd xmm0,xmm1
    movapd xmm1,xmm2
.ordered:
    ucomisd xmm0,[rel scalar_zero]
    je .hypot_zero
    divsd xmm1,xmm0
    mulsd xmm1,xmm1
    addsd xmm1,[rel scalar_one]
    sqrtsd xmm1,xmm1
    mulsd xmm0,xmm1
    xor eax,eax
    ret
.hypot_zero:
    xorpd xmm0,xmm0
    xor eax,eax
    ret
.hypot_domain:
    mov eax,NEBO_NUMERIC_ERROR_DOMAIN
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
