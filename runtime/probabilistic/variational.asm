; PLUGINS-FFI-E-EXTENSIBILIDADE-F05 analytic mean-field update for a unit-noise conjugate Normal.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/probabilistic/variational.inc"
section .rodata
zero dq 0.0
one dq 1.0
section .text
; rdi=context, rsi=report. Values are f64 pointers except count u64 pointer.
NEBOC_ABI_FUNCTION nebo_prob_vi_normal_meanfield_update
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    mov r8,[rdi+NEBO_VI_CTX_PRIOR_MEAN]
    mov r9,[rdi+NEBO_VI_CTX_PRIOR_PRECISION]
    mov r10,[rdi+NEBO_VI_CTX_OBSERVATION_SUM]
    mov r11,[rdi+NEBO_VI_CTX_OBSERVATION_COUNT]
    test r8,r8
    jz .invalid
    test r9,r9
    jz .invalid
    test r10,r10
    jz .invalid
    test r11,r11
    jz .invalid
    mov rcx,[r11]
    cmp rcx,NEBO_VI_MAX_LATENTS
    ja .limit
    movsd xmm0,[r8]
    movsd xmm1,[r9]
    movsd xmm2,[r10]
    ucomisd xmm0,xmm0
    jp .invalid
    ucomisd xmm1,xmm1
    jp .invalid
    ucomisd xmm2,xmm2
    jp .invalid
    ucomisd xmm1,[zero]
    jbe .invalid
    ; posterior precision = prior precision + n.
    cvtsi2sd xmm3,rcx
    addsd xmm3,xmm1
    ; posterior mean = (prior precision * prior mean + observation sum)/precision.
    mulsd xmm0,xmm1
    addsd xmm0,xmm2
    divsd xmm0,xmm3
    movsd xmm4,[one]
    divsd xmm4,xmm3
    movsd [rsi+NEBO_VI_REPORT_MEAN],xmm0
    movsd [rsi+NEBO_VI_REPORT_PRECISION],xmm3
    movsd [rsi+NEBO_VI_REPORT_VARIANCE],xmm4
    mov qword [rsi+NEBO_VI_REPORT_STATUS],NEBO_VI_OK
    xor eax,eax
    ret
.invalid: mov eax,NEBO_VI_INVALID
    ret
.limit: mov eax,NEBO_VI_LIMIT
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
