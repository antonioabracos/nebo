; AUTONOMIA-CONTROLADA-E-AGENTES-F05 one-dimensional explicit heat stencil with fixed boundaries.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/pde/pde.inc"
section .rodata
zero dq 0.0
half dq 0.5
one dq 1.0
two dq 2.0
section .text
; rdi=out, rsi=input, rdx=count, rcx=&alpha.
NEBOC_ABI_FUNCTION nebo_pde_heat1d_step_f64
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rcx,rcx
    jz .invalid
    cmp rdx,3
    jb .invalid
    cmp rdx,NEBO_PDE_MAX_AXIS
    ja .limit
    movsd xmm0,[rcx]
    ucomisd xmm0,[zero]
    jp .invalid
    jb .invalid
    ucomisd xmm0,[half]
    ja .invalid
    mov rax,[rsi]
    mov [rdi],rax
    mov rax,[rsi+rdx*8-8]
    mov [rdi+rdx*8-8],rax
    movsd xmm4,[one]
    movsd xmm5,xmm0
    mulsd xmm5,[two]
    subsd xmm4,xmm5
    mov r8d,1
.loop:
    movsd xmm1,[rsi+r8*8-8]
    mulsd xmm1,xmm0
    movsd xmm2,[rsi+r8*8]
    mulsd xmm2,xmm4
    addsd xmm1,xmm2
    movsd xmm2,[rsi+r8*8+8]
    mulsd xmm2,xmm0
    addsd xmm1,xmm2
    movsd [rdi+r8*8],xmm1
    inc r8
    mov rax,rdx
    dec rax
    cmp r8,rax
    jb .loop
    xor eax,eax
    ret
.invalid: mov eax,NEBO_PDE_INVALID
    ret
.limit: mov eax,NEBO_PDE_LIMIT
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
