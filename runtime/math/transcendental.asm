; RF27-G14-F03 freestanding binary64 transcendental/classification profile
bits 64
default rel
%define NEBO_TRANSCENDENTAL_IMPLEMENTATION 1
%include "runtime/math/transcendental.inc"
section .rodata
align 8
tr_zero dq 0.0
tr_one dq 1.0
tr_ln2 dq 0x3fe62e42fefa39ef
tr_abs_mask dq 0x7fffffffffffffff
tr_exp_mask dq 0x7ff0000000000000
tr_frac_mask dq 0x000fffffffffffff
section .text
global nebo_math_sin_f64
global nebo_math_cos_f64
global nebo_math_tan_f64
global nebo_math_exp_f64
global nebo_math_log_f64
global nebo_math_log2_f64
global nebo_math_atan2_f64
global nebo_math_floor_f64
global nebo_math_ceil_f64
global nebo_math_round_f64
global nebo_math_round_mode_f64
global nebo_float_classify_f64
global nebo_float_approx_equal_f64

%macro X87_UNARY 2
%1:
 sub rsp,16
 movsd [rsp],xmm0
 fld qword [rsp]
 %2
 fstp qword [rsp+8]
 movsd xmm0,[rsp+8]
 add rsp,16
 xor eax,eax
 ret
%endmacro
X87_UNARY nebo_math_sin_f64, fsin
X87_UNARY nebo_math_cos_f64, fcos

nebo_math_tan_f64:
 sub rsp,16
 movsd [rsp],xmm0
 fld qword [rsp]
 fptan
 fstp st0
 fstp qword [rsp+8]
 movsd xmm0,[rsp+8]
 add rsp,16
 xor eax,eax
 ret

; exp(x) = 2^(x*log2(e)), bounded naturally by binary64.
nebo_math_exp_f64:
 sub rsp,16
 movsd [rsp],xmm0
 fld qword [rsp]
 fldl2e
 fmulp st1,st0
 fld st0
 frndint
 fxch st1
 fsub st0,st1
 f2xm1
 fld1
 faddp st1,st0
 fscale
 fstp st1
 fstp qword [rsp+8]
 movsd xmm0,[rsp+8]
 add rsp,16
 xor eax,eax
 ret

nebo_math_log_f64:
 ucomisd xmm0,[rel tr_zero]
 jp .log_domain
 jbe .log_domain
 sub rsp,16
 movsd [rsp],xmm0
 fldln2
 fld qword [rsp]
 fyl2x
 fstp qword [rsp+8]
 movsd xmm0,[rsp+8]
 add rsp,16
 xor eax,eax
 ret
.log_domain:
 mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 ret

nebo_math_log2_f64:
 ucomisd xmm0,[rel tr_zero]
 jp .log2_domain
 jbe .log2_domain
 sub rsp,16
 movsd [rsp],xmm0
 fld1
 fld qword [rsp]
 fyl2x
 fstp qword [rsp+8]
 movsd xmm0,[rsp+8]
 add rsp,16
 xor eax,eax
 ret
.log2_domain:
 mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 ret

; xmm0=y xmm1=x
nebo_math_atan2_f64:
 sub rsp,24
 movsd [rsp],xmm0
 movsd [rsp+8],xmm1
 fld qword [rsp]
 fld qword [rsp+8]
 fpatan
 fstp qword [rsp+16]
 movsd xmm0,[rsp+16]
 add rsp,24
 xor eax,eax
 ret

; Rounding functions accept finite values with magnitude below 2^63.
; Every declared mode enforces that domain before changing floating state.
nebo_math_floor_f64:
 mov edx,NEBO_ROUND_FLOOR
 jmp nebo_math_round_mode_f64
nebo_math_ceil_f64:
 mov edx,NEBO_ROUND_CEIL
 jmp nebo_math_round_mode_f64
nebo_math_round_f64:
 mov edx,NEBO_ROUND_NEAREST_EVEN

; xmm0=value, rdx=declared NEBO_ROUND_* mode. Save and restore the caller's
; complete x87 control word; explicit nearest-even must not inherit ambient RC.
nebo_math_round_mode_f64:
 cmp rdx,NEBO_ROUND_TOWARD_ZERO
 ja round_domain
 movq rax,xmm0
 mov rcx,0x7fffffffffffffff
 and rax,rcx
 mov rcx,0x43e0000000000000
 cmp rax,rcx
 jae round_domain
 sub rsp,16
 fnstcw [rsp]
 movzx eax,word [rsp]
 and eax,0xf3ff
 shl edx,10
 or eax,edx
 mov [rsp+2],ax
 movsd [rsp+8],xmm0
 fld qword [rsp+8]
 fldcw [rsp+2]
 frndint
 fstp qword [rsp+8]
 fldcw [rsp]
 movsd xmm0,[rsp+8]
 add rsp,16
 xor eax,eax
 ret
round_domain:
 mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 ret

; xmm0 -> classification flags eax.
nebo_float_classify_f64:
 movq rax,xmm0
 mov rcx,rax
 and rcx,[rel tr_exp_mask]
 cmp rcx,[rel tr_exp_mask]
 je .nonfinite
 mov rdx,rax
 and rax,[rel tr_abs_mask]
 jnz .finite_nonzero
 mov eax,NEBO_FLOAT_FINITE
 test rdx,rdx
 jns .class_done
 or eax,NEBO_FLOAT_NEGATIVE_ZERO
 ret
.finite_nonzero:
 movq rcx,xmm0
 mov rdx,rcx
 and rdx,[rel tr_exp_mask]
 mov eax,NEBO_FLOAT_FINITE
 test rdx,rdx
 jnz .class_done
 or eax,NEBO_FLOAT_SUBNORMAL
.class_done:
 ret
.nonfinite:
 and rax,[rel tr_frac_mask]
 mov eax,NEBO_FLOAT_INFINITE
 jz .class_done
 mov eax,NEBO_FLOAT_NAN
 ret

; xmm0=a xmm1=b xmm2=absTol xmm3=relTol -> eax status, edx bool.
nebo_float_approx_equal_f64:
 ucomisd xmm2,[rel tr_zero]
 jp .approx_domain
 jb .approx_domain
 ucomisd xmm3,[rel tr_zero]
 jp .approx_domain
 jb .approx_domain
 ucomisd xmm0,xmm0
 jp .approx_false
 ucomisd xmm1,xmm1
 jp .approx_false
 ; Exact IEEE equality handles signed zero and equal infinities before any
 ; subtraction. A distinct infinity never becomes equal through an infinite
 ; intermediate tolerance product. NaN inputs were rejected above.
 ucomisd xmm0,xmm1
 je .approx_true
 movq rax,xmm0
 and rax,[rel tr_abs_mask]
 cmp rax,[rel tr_exp_mask]
 jae .approx_false
 movq rax,xmm1
 and rax,[rel tr_abs_mask]
 cmp rax,[rel tr_exp_mask]
 jae .approx_false
 movapd xmm4,xmm0
 subsd xmm4,xmm1
 movq rax,xmm4
 and rax,[rel tr_abs_mask]
 movq xmm4,rax
 ucomisd xmm4,xmm2
 jbe .approx_true
 movq rax,xmm0
 movq rcx,xmm1
 and rax,[rel tr_abs_mask]
 and rcx,[rel tr_abs_mask]
 movq xmm5,rax
 movq xmm6,rcx
 maxsd xmm5,xmm6
 mulsd xmm5,xmm3
 ucomisd xmm4,xmm5
 jbe .approx_true
.approx_false:
 xor edx,edx
 xor eax,eax
 ret
.approx_true:
 mov edx,1
 xor eax,eax
 ret
.approx_domain:
 xor edx,edx
 mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
