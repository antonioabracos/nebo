; PLUGINS-FFI-E-EXTENSIBILIDADE-F06 two-chain split R-hat over caller-provided rank-normalized scores.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/probabilistic/posterior_diagnostics.inc"
section .rodata
zero dq 0.0
one dq 1.0
three dq 3.0
four dq 4.0
rhat_threshold dq 1.01
minimum_ess dq 4.0
section .text
; rdi=two contiguous chains of rank-normalized f64, rsi=samples/chain, rdx=report.
NEBOC_ABI_FUNCTION nebo_prob_rank_normalized_diagnostics_f64
    test rdi,rdi
    jz .invalid
    test rdx,rdx
    jz .invalid
    cmp rsi,4
    jb .insufficient
    cmp rsi,NEBO_DIAG_MAX_SAMPLES_CHAIN
    ja .limit
    test rsi,1
    jnz .invalid
    mov rcx,rsi
    shl rcx,1
    xor eax,eax
.finite:
    movsd xmm0,[rdi+rax*8]
    ucomisd xmm0,xmm0
    jp .invalid
    inc rax
    cmp rax,rcx
    jb .finite
    sub rsp,32                    ; four split-chain means
    mov r8,rsi
    shr r8,1                     ; samples per split chain
    xor r9d,r9d
    pxor xmm5,xmm5               ; sum within-chain variances
.segment:
    mov r10,r9
    cmp r10,2
    jb .base_first
    sub r10,2
    imul r10,r8
    add r10,rsi
    jmp .base_ready
.base_first:
    imul r10,r8
.base_ready:
    pxor xmm0,xmm0               ; sum
    pxor xmm1,xmm1               ; sum squares
    xor r11d,r11d
.segment_values:
    movsd xmm2,[rdi+r10*8]
    addsd xmm0,xmm2
    mulsd xmm2,xmm2
    addsd xmm1,xmm2
    inc r10
    inc r11
    cmp r11,r8
    jb .segment_values
    cvtsi2sd xmm2,r8
    movsd xmm3,xmm0
    divsd xmm3,xmm2
    movsd [rsp+r9*8],xmm3
    mulsd xmm0,xmm0
    divsd xmm0,xmm2
    subsd xmm1,xmm0
    mov rax,r8
    dec rax
    cvtsi2sd xmm2,rax
    divsd xmm1,xmm2
    addsd xmm5,xmm1
    inc r9
    cmp r9,4
    jb .segment
    divsd xmm5,[four]             ; W
    ucomisd xmm5,[zero]
    jbe .invalid_stack
    pxor xmm6,xmm6
    xor r9d,r9d
.mean_sum:
    addsd xmm6,[rsp+r9*8]
    inc r9
    cmp r9,4
    jb .mean_sum
    divsd xmm6,[four]             ; global mean
    pxor xmm7,xmm7
    xor r9d,r9d
.between:
    movsd xmm0,[rsp+r9*8]
    subsd xmm0,xmm6
    mulsd xmm0,xmm0
    addsd xmm7,xmm0
    inc r9
    cmp r9,4
    jb .between
    divsd xmm7,[three]
    cvtsi2sd xmm0,r8
    mulsd xmm7,xmm0               ; B
    mov rax,r8
    dec rax
    cvtsi2sd xmm1,rax
    divsd xmm1,xmm0
    mulsd xmm1,xmm5               ; ((m-1)/m)*W
    divsd xmm7,xmm0               ; B/m
    addsd xmm1,xmm7
    divsd xmm1,xmm5
    sqrtsd xmm1,xmm1
    maxsd xmm1,[one]              ; finite-sample R-hat cannot report below one
    mov rax,rsi
    shl rax,1
    cvtsi2sd xmm2,rax
    movsd xmm3,xmm1
    mulsd xmm3,xmm3
    divsd xmm2,xmm3               ; conservative bulk ESS v1 lower bound
    mov [rdx+NEBO_DIAG_REPORT_SAMPLES_CHAIN],rsi
    movsd [rdx+NEBO_DIAG_REPORT_MEAN],xmm6
    movsd [rdx+NEBO_DIAG_REPORT_SPLIT_RHAT],xmm1
    movsd [rdx+NEBO_DIAG_REPORT_BULK_ESS],xmm2
    mov eax,NEBO_DIAG_NOT_CONVERGED
    ucomisd xmm1,[rhat_threshold]
    ja .emit_status
    ucomisd xmm2,[minimum_ess]
    jb .emit_status
    xor eax,eax
.emit_status:
    mov [rdx+NEBO_DIAG_REPORT_STATUS],rax
    add rsp,32
    ret
.invalid_stack:
    add rsp,32
.invalid: mov eax,NEBO_DIAG_INVALID
    ret
.limit: mov eax,NEBO_DIAG_LIMIT
    ret
.insufficient: mov eax,NEBO_DIAG_INSUFFICIENT
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
