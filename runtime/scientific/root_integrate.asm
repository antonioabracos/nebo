; AUTONOMIA-CONTROLADA-E-AGENTES-F03 truthful bounded bisection and Simpson reference.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/scientific/root_integrate.inc"
section .rodata
two dq 2.0
three dq 3.0
four dq 4.0
zero dq 0.0
section .text
; ctx {target,lo,hi,tol,max_iter u32}, out {root,error}, report {iters,status}.
NEBOC_ABI_FUNCTION nebo_bisect_sqrt_f64
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    movsd xmm0,[rdi]
    movsd xmm1,[rdi+8]
    movsd xmm2,[rdi+16]
    movsd xmm3,[rdi+24]
    ucomisd xmm0,[zero]
    jb .invalid
    ucomisd xmm1,[zero]
    jb .invalid
    ucomisd xmm2,xmm1
    jbe .invalid
    ucomisd xmm3,[zero]
    jbe .invalid
    mov r8d,[rdi+32]
    test r8d,r8d
    jz .limit
    cmp r8d,NEBO_SOLVER_MAX_ITER
    ja .limit
    movapd xmm4,xmm1
    mulsd xmm4,xmm1
    ucomisd xmm4,xmm0
    ja .invalid
    movapd xmm4,xmm2
    mulsd xmm4,xmm2
    ucomisd xmm4,xmm0
    jb .invalid
    xor ecx,ecx
.loop:
    movapd xmm5,xmm2
    subsd xmm5,xmm1
    ucomisd xmm5,xmm3
    jbe .converged
    cmp ecx,r8d
    jae .budget
    movapd xmm4,xmm1
    addsd xmm4,xmm2
    divsd xmm4,[two]
    movapd xmm6,xmm4
    mulsd xmm6,xmm4
    ucomisd xmm6,xmm0
    ja .take_hi
    movapd xmm1,xmm4
    jmp .next
.take_hi:
    movapd xmm2,xmm4
.next:
    inc ecx
    jmp .loop
.converged:
    movapd xmm4,xmm1
    addsd xmm4,xmm2
    divsd xmm4,[two]
    divsd xmm5,[two]
    movsd [rsi],xmm4
    movsd [rsi+8],xmm5
    mov [rdx],ecx
    mov dword [rdx+4],NEBO_SOLVER_OK
    xor eax,eax
    ret
.budget:
    movapd xmm4,xmm1
    addsd xmm4,xmm2
    divsd xmm4,[two]
    divsd xmm5,[two]
    movsd [rsi],xmm4
    movsd [rsi+8],xmm5
    mov [rdx],ecx
    mov dword [rdx+4],NEBO_SOLVER_NOT_CONVERGED
    mov eax,NEBO_SOLVER_NOT_CONVERGED
    ret
.invalid: mov eax,NEBO_SOLVER_INVALID
    ret
.limit: mov eax,NEBO_SOLVER_LIMIT
    ret

; ctx {lo f64,hi f64,n u32}, out integral, report {evaluations,status}.
NEBOC_ABI_FUNCTION nebo_simpson_square_f64
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    mov ecx,[rdi+16]
    cmp ecx,2
    jb .invalid
    cmp ecx,NEBO_INTEGRATE_MAX_SUBDIV
    ja .limit
    test ecx,1
    jnz .invalid
    movsd xmm0,[rdi]
    movsd xmm1,[rdi+8]
    ucomisd xmm1,xmm0
    jbe .invalid
    movapd xmm2,xmm1
    subsd xmm2,xmm0
    cvtsi2sd xmm3,ecx
    divsd xmm2,xmm3
    xorpd xmm4,xmm4
    xor r8d,r8d
.sum:
    cvtsi2sd xmm5,r8d
    mulsd xmm5,xmm2
    addsd xmm5,xmm0
    mulsd xmm5,xmm5
    cmp r8d,0
    je .weight_done
    cmp r8d,ecx
    je .weight_done
    test r8d,1
    jz .weight_two
    mulsd xmm5,[four]
    jmp .weight_done
.weight_two:
    mulsd xmm5,[two]
.weight_done:
    addsd xmm4,xmm5
    inc r8d
    cmp r8d,ecx
    jbe .sum
    mulsd xmm4,xmm2
    divsd xmm4,[three]
    movsd [rsi],xmm4
    lea eax,[rcx+1]
    mov [rdx],eax
    mov dword [rdx+4],NEBO_SOLVER_OK
    xor eax,eax
    ret
.invalid: mov eax,NEBO_SOLVER_INVALID
    ret
.limit: mov eax,NEBO_SOLVER_LIMIT
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
