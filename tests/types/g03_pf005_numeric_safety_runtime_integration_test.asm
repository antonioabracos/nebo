; Nebo Assembly — SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-PF005 product runtime integration proof
bits 64
default rel
extern nebo_runtime_numeric_safety_int_to_float
extern nebo_runtime_numeric_safety_is_finite
extern nebo_runtime_numeric_safety_is_nan
extern nebo_runtime_numeric_safety_is_infinite
extern nebo_runtime_numeric_safety_is_negative_zero
global _start
section .bss align=16
mxcsr_original: resd 1
mxcsr_ambient: resd 1
mxcsr_after: resd 1
section .text
_start:
 stmxcsr [rel mxcsr_original]
 mov eax,[rel mxcsr_original]
 or eax,0x6000
 mov [rel mxcsr_ambient],eax
 ldmxcsr [rel mxcsr_ambient]

 ; 42 -> exact binary64 and ambient MXCSR restored.
 mov rdi,42
 call nebo_runtime_numeric_safety_int_to_float
 movq rax,xmm0
 mov rdx,0x4045000000000000
 cmp rax,rdx
 jne .fail_1
 stmxcsr [rel mxcsr_after]
 mov eax,[rel mxcsr_after]
 cmp eax,[rel mxcsr_ambient]
 jne .fail_2

 ; 2^53+1 rounds ties-even to 2^53 despite ambient toward-zero mode.
 mov rdi,9007199254740993
 call nebo_runtime_numeric_safety_int_to_float
 movq rax,xmm0
 mov rdx,0x4340000000000000
 cmp rax,rdx
 jne .fail_3

 ; finite normal and subnormal.
 mov rax,0x3ff8000000000000
 movq xmm0,rax
 call nebo_runtime_numeric_safety_is_finite
 cmp eax,1
 jne .fail_4
 mov eax,1
 movq xmm0,rax
 call nebo_runtime_numeric_safety_is_finite
 cmp eax,1
 jne .fail_5

 ; quiet/signaling NaN.
 mov rax,0x7ff8000000000001
 movq xmm0,rax
 call nebo_runtime_numeric_safety_is_nan
 cmp eax,1
 jne .fail_6
 mov rax,0x7ff0000000000001
 movq xmm0,rax
 call nebo_runtime_numeric_safety_is_nan
 cmp eax,1
 jne .fail_7

 ; infinities and their non-finite classification.
 mov rax,0x7ff0000000000000
 movq xmm0,rax
 call nebo_runtime_numeric_safety_is_infinite
 cmp eax,1
 jne .fail_8
 mov rax,0xfff0000000000000
 movq xmm0,rax
 call nebo_runtime_numeric_safety_is_infinite
 cmp eax,1
 jne .fail_9
 mov rax,0x7ff0000000000000
 movq xmm0,rax
 call nebo_runtime_numeric_safety_is_finite
 test eax,eax
 jne .fail_10

 ; negative zero only.
 mov rax,0x8000000000000000
 movq xmm0,rax
 call nebo_runtime_numeric_safety_is_negative_zero
 cmp eax,1
 jne .fail_11
 pxor xmm0,xmm0
 call nebo_runtime_numeric_safety_is_negative_zero
 test eax,eax
 jne .fail_12

 ldmxcsr [rel mxcsr_original]
 xor edi,edi
 jmp .exit
.fail_1: mov edi,1
 jmp .restore
.fail_2: mov edi,2
 jmp .restore
.fail_3: mov edi,3
 jmp .restore
.fail_4: mov edi,4
 jmp .restore
.fail_5: mov edi,5
 jmp .restore
.fail_6: mov edi,6
 jmp .restore
.fail_7: mov edi,7
 jmp .restore
.fail_8: mov edi,8
 jmp .restore
.fail_9: mov edi,9
 jmp .restore
.fail_10: mov edi,10
 jmp .restore
.fail_11: mov edi,11
 jmp .restore
.fail_12: mov edi,12
.restore:
 ldmxcsr [rel mxcsr_original]
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
