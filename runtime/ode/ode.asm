; AUTONOMIA-CONTROLADA-E-AGENTES-F04 bounded scalar Euler reference for y'=lambda*y.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/ode/ode.inc"
section .rodata
zero dq 0.0
section .text
; ctx {lambda,y0,t0,t1,event_threshold,steps u32}; out {t,y,last_delta}; report {steps,event,status}.
NEBOC_ABI_FUNCTION nebo_ode_euler_linear_f64
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    mov ecx,[rdi+40]
    test ecx,ecx
    jz .invalid
    cmp ecx,NEBO_ODE_MAX_STEPS
    ja .limit
    movsd xmm0,[rdi+16]
    movsd xmm1,[rdi+24]
    ucomisd xmm1,xmm0
    jbe .invalid
    subsd xmm1,xmm0
    cvtsi2sd xmm2,ecx
    divsd xmm1,xmm2
    movsd xmm2,[rdi+8]
    movsd xmm3,[rdi]
    movsd xmm4,[rdi+32]
    mov r8d,NEBO_ODE_NO_EVENT
    xor r9d,r9d
.loop:
    movapd xmm5,xmm2
    mulsd xmm5,xmm3
    mulsd xmm5,xmm1
    addsd xmm2,xmm5
    addsd xmm0,xmm1
    cmp r8d,NEBO_ODE_NO_EVENT
    jne .next
    ucomisd xmm2,xmm4
    jb .next
    mov r8d,r9d
    inc r8d
.next:
    inc r9d
    cmp r9d,ecx
    jb .loop
    movsd [rsi],xmm0
    movsd [rsi+8],xmm2
    movsd [rsi+16],xmm5
    mov [rdx],ecx
    mov [rdx+4],r8d
    mov dword [rdx+8],NEBO_ODE_OK
    xor eax,eax
    ret
.invalid: mov eax,NEBO_ODE_INVALID
    ret
.limit: mov eax,NEBO_ODE_LIMIT
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
