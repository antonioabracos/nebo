; AUTONOMIA-CONTROLADA-E-AGENTES-F06 failure-atomic projected step for a diagonal convex quadratic.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/optimization/optimization.inc"
section .rodata
zero dq 0.0
half dq 0.5
section .text
; rdi=caller output, rsi=context, rdx=report.
NEBOC_ABI_FUNCTION nebo_opt_projected_quadratic_step_f64
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    mov r8,[rsi+NEBO_OPT_CTX_Q]
    mov r9,[rsi+NEBO_OPT_CTX_C]
    mov r10,[rsi+NEBO_OPT_CTX_X]
    mov r11,[rsi+NEBO_OPT_CTX_LOWER]
    mov rax,[rsi+NEBO_OPT_CTX_UPPER]
    test r8,r8
    jz .invalid
    test r9,r9
    jz .invalid
    test r10,r10
    jz .invalid
    test r11,r11
    jz .invalid
    test rax,rax
    jz .invalid
    mov rcx,[rsi+NEBO_OPT_CTX_N]
    test rcx,rcx
    jz .invalid
    cmp rcx,NEBO_OPT_MAX_DIM
    ja .limit
    movsd xmm7,[rsi+NEBO_OPT_CTX_STEP]
    ucomisd xmm7,xmm7
    jp .invalid
    ucomisd xmm7,[zero]
    jbe .invalid
    pxor xmm4,xmm4
    pxor xmm5,xmm5
    xor ecx,ecx
.validate:
    movsd xmm0,[r8+rcx*8]
    movsd xmm1,[r9+rcx*8]
    movsd xmm2,[r10+rcx*8]
    movsd xmm3,[r11+rcx*8]
    movsd xmm6,[rax+rcx*8]
    ucomisd xmm0,xmm0
    jp .invalid
    ucomisd xmm1,xmm1
    jp .invalid
    ucomisd xmm2,xmm2
    jp .invalid
    ucomisd xmm3,xmm3
    jp .invalid
    ucomisd xmm6,xmm6
    jp .invalid
    ucomisd xmm0,[zero]
    jbe .invalid
    ucomisd xmm3,xmm6
    ja .invalid
    mulsd xmm0,xmm2
    addsd xmm1,xmm0
    movsd xmm3,xmm1
    mulsd xmm3,xmm3
    addsd xmm5,xmm3
    movsd xmm0,[r8+rcx*8]
    mulsd xmm0,xmm2
    mulsd xmm0,xmm2
    mulsd xmm0,[half]
    movsd xmm3,[r9+rcx*8]
    mulsd xmm3,xmm2
    addsd xmm0,xmm3
    addsd xmm4,xmm0
    inc rcx
    cmp rcx,[rsi+NEBO_OPT_CTX_N]
    jb .validate
    pxor xmm6,xmm6
    xor ecx,ecx
.project:
    movsd xmm0,[r8+rcx*8]
    mulsd xmm0,[r10+rcx*8]
    addsd xmm0,[r9+rcx*8]
    mulsd xmm0,xmm7
    movsd xmm1,[r10+rcx*8]
    subsd xmm1,xmm0
    ucomisd xmm1,[r11+rcx*8]
    jae .check_upper
    movsd xmm1,[r11+rcx*8]
.check_upper:
    ucomisd xmm1,[rax+rcx*8]
    jbe .store
    movsd xmm1,[rax+rcx*8]
.store:
    movsd [rdi+rcx*8],xmm1
    movsd xmm0,[r8+rcx*8]
    mulsd xmm0,xmm1
    mulsd xmm0,xmm1
    mulsd xmm0,[half]
    movsd xmm3,[r9+rcx*8]
    mulsd xmm3,xmm1
    addsd xmm0,xmm3
    addsd xmm6,xmm0
    inc rcx
    cmp rcx,[rsi+NEBO_OPT_CTX_N]
    jb .project
    movsd [rdx+NEBO_OPT_REPORT_BEFORE],xmm4
    movsd [rdx+NEBO_OPT_REPORT_AFTER],xmm6
    movsd [rdx+NEBO_OPT_REPORT_GRADIENT_NORM2],xmm5
    mov rcx,[rsi+NEBO_OPT_CTX_N]
    mov [rdx+NEBO_OPT_REPORT_DIMENSION],rcx
    mov dword [rdx+NEBO_OPT_REPORT_STATUS],NEBO_OPT_OK
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_OPT_INVALID
    ret
.limit:
    mov eax,NEBO_OPT_LIMIT
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
