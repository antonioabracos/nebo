; Explicit rounding must ignore, and restore, the caller's ambient x87 mode.
bits 64
default rel
%include "runtime/math/transcendental.inc"
section .rodata
align 8
value: dq 2.5
expected: dq 2.0,2.0,3.0,2.0
; a, b, absolute, relative, status, Bool. Preserve the documented
; nonnegative tolerance contract, including infinity, and IEEE NaN rules.
approx_cases:
 dq 0x7ff0000000000000,0x7ff0000000000000,0.0,0.0,0,1
 dq 0xfff0000000000000,0xfff0000000000000,0.0,0.0,0,1
 dq 0x7ff0000000000000,0xfff0000000000000,0.0,2.0,0,0
 dq 0x7ff0000000000000,17.0,0x7ff0000000000000,2.0,0,0
 dq 17.0,0x7ff0000000000000,0.0,0x7ff0000000000000,0,0
 dq 0x7ff8000000000001,17.0,0.0,0.0,0,0
 dq 17.0,0x7ff8000000000001,0.0,0.0,0,0
 dq 0.0,0x8000000000000000,0.0,0.0,0,1
 dq 17.0,29.0,0x7ff0000000000000,0.0,0,1
 dq 17.0,17.0,-1.0,0.0,NEBO_NUMERIC_ERROR_DOMAIN,0
 dq 17.0,17.0,0.0,-1.0,NEBO_NUMERIC_ERROR_DOMAIN,0
 dq 17.0,17.0,0x7ff8000000000001,0.0,NEBO_NUMERIC_ERROR_DOMAIN,0
approx_end:
section .text
global _start
_start:
 sub rsp,16
 fnstcw [rsp]
 movzx eax,word [rsp]
 and eax,0xf3ff
 or eax,0x0800
 mov [rsp+2],ax
 fldcw [rsp+2]
 xor r12d,r12d
.mode:
 movsd xmm0,[rel value]
 mov edx,r12d
 call nebo_math_round_mode_f64
 test eax,eax
 jnz .fail
 lea rax,[rel expected]
 ucomisd xmm0,[rax+r12*8]
 jp .fail
 jne .fail
 fnstcw [rsp+4]
 mov ax,[rsp+4]
 cmp ax,[rsp+2]
 jne .fail
 inc r12
 cmp r12,4
 jb .mode
 movsd xmm0,[rel value]
 call nebo_math_round_f64
 test eax,eax
 jnz .fail
 ucomisd xmm0,[rel expected]
 jne .fail
 fnstcw [rsp+4]
 mov ax,[rsp+4]
 cmp ax,[rsp+2]
 jne .fail
 lea r12,[rel approx_cases]
.approx:
 movq xmm0,[r12]
 movq xmm1,[r12+8]
 movq xmm2,[r12+16]
 movq xmm3,[r12+24]
 call nebo_float_approx_equal_f64
 cmp rax,[r12+32]
 jne .fail
 cmp rdx,[r12+40]
 jne .fail
 add r12,48
 lea rax,[rel approx_end]
 cmp r12,rax
 jb .approx
 xor edi,edi
 jmp .exit
.fail:
 mov edi,1
.exit:
 fldcw [rsp]
 add rsp,16
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
