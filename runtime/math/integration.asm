; TREE-GRAPH-NODE-E-EDGE-F07 bounded composite Simpson integration
bits 64
default rel
%define NEBO_INTEGRATION_IMPLEMENTATION 1
%include "runtime/math/integration.inc"
section .rodata
align 8
integration_two dq 2.0
integration_three dq 3.0
integration_four dq 4.0
section .text
global nebo_math_integrate_simpson_f64

; rdi=fn(context rdi,x xmm0 -> xmm0), rsi=context, rdx=even steps,
; xmm0=a, xmm1=b. eax=status, xmm0=integral.
nebo_math_integrate_simpson_f64:
 test rdi,rdi
 jz .argument
 cmp rdx,2
 jb .bounds
 cmp rdx,NEBO_NUMERIC_MAX_ELEMENTS
 ja .bounds
 test rdx,1
 jnz .bounds
 ucomisd xmm0,xmm0
 jp .domain
 ucomisd xmm1,xmm1
 jp .domain
 ucomisd xmm0,xmm1
 jae .domain
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 movsd [rsp],xmm0
 movsd [rsp+8],xmm1
 subsd xmm1,xmm0
 cvtsi2sd xmm2,r14
 divsd xmm1,xmm2
 movsd [rsp+16],xmm1
 mov rdi,r13
 call r12
 movsd [rsp+24],xmm0
 movsd xmm0,[rsp+8]
 mov rdi,r13
 call r12
 addsd xmm0,[rsp+24]
 movsd [rsp+24],xmm0
 mov r15,1
.loop:
 cmp r15,r14
 jae .finish
 cvtsi2sd xmm0,r15
 mulsd xmm0,[rsp+16]
 addsd xmm0,[rsp]
 mov rdi,r13
 call r12
 test r15,1
 jz .even
 mulsd xmm0,[rel integration_four]
 jmp .accumulate
.even:
 mulsd xmm0,[rel integration_two]
.accumulate:
 addsd xmm0,[rsp+24]
 movsd [rsp+24],xmm0
 inc r15
 jmp .loop
.finish:
 movsd xmm0,[rsp+24]
 mulsd xmm0,[rsp+16]
 divsd xmm0,[rel integration_three]
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 xor eax,eax
 ret
.argument: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
.bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 ret
.domain: mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
