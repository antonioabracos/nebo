; PLUGINS-FFI-E-EXTENSIBILIDADE-F01 explicit streams, exact-weight categorical sampling, normal log-pdf.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/probabilistic/distributions.inc"
section .rodata
zero dq 0.0
one dq 1.0
half dq 0.5
log_sqrt_2pi dq 0.91893853320467274178
section .text
; rdi=state, rsi=out. Versioned SplitMix64 step.
NEBOC_ABI_FUNCTION nebo_prob_splitmix64_next
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    mov rax,[rdi]
    mov rcx,0x9e3779b97f4a7c15
    add rax,rcx
    mov [rdi],rax
    mov rcx,rax
    shr rcx,30
    xor rax,rcx
    mov rcx,0xbf58476d1ce4e5b9
    imul rax,rcx
    mov rcx,rax
    shr rcx,27
    xor rax,rcx
    mov rcx,0x94d049bb133111eb
    imul rax,rcx
    mov rcx,rax
    shr rcx,31
    xor rax,rcx
    mov [rsi],rax
    xor eax,eax
    ret
.invalid: mov eax,NEBO_PROB_INVALID
    ret

; rdi=nonzero state, rsi=out. xorshift64* v1.
NEBOC_ABI_FUNCTION nebo_prob_xorshift64star_next
    test rdi,rdi
    jz .xs_invalid
    test rsi,rsi
    jz .xs_invalid
    mov rax,[rdi]
    test rax,rax
    jz .xs_invalid
    mov rcx,rax
    shr rcx,12
    xor rax,rcx
    mov rcx,rax
    shl rcx,25
    xor rax,rcx
    mov rcx,rax
    shr rcx,27
    xor rax,rcx
    mov [rdi],rax
    mov rcx,0x2545f4914f6cdd1d
    imul rax,rcx
    mov [rsi],rax
    xor eax,eax
    ret
.xs_invalid: mov eax,NEBO_PROB_INVALID
    ret

; rdi=out f64, rsi=x f64, rdx=mean f64. Unit-sigma normal log-pdf.
NEBOC_ABI_FUNCTION nebo_prob_normal_unit_logpdf_f64
    test rdi,rdi
    jz .normal_invalid
    test rsi,rsi
    jz .normal_invalid
    test rdx,rdx
    jz .normal_invalid
    movsd xmm0,[rsi]
    movsd xmm1,[rdx]
    ucomisd xmm0,xmm0
    jp .normal_invalid
    ucomisd xmm1,xmm1
    jp .normal_invalid
    subsd xmm0,xmm1
    mulsd xmm0,xmm0
    mulsd xmm0,[half]
    addsd xmm0,[log_sqrt_2pi]
    xorpd xmm1,xmm1
    subsd xmm1,xmm0
    movsd [rdi],xmm1
    xor eax,eax
    ret
.normal_invalid: mov eax,NEBO_PROB_INVALID
    ret

; rdi=state, rsi=positive u64 weights, rdx=count, rcx=out index.
NEBOC_ABI_FUNCTION nebo_prob_categorical_u64
    test rdi,rdi
    jz .cat_invalid
    test rsi,rsi
    jz .cat_invalid
    test rcx,rcx
    jz .cat_invalid
    test rdx,rdx
    jz .cat_invalid
    cmp rdx,NEBO_PROB_MAX_CATEGORIES
    ja .cat_limit
    cmp qword [rdi],0
    je .cat_invalid
    xor r8d,r8d
    xor r9d,r9d
.sum:
    mov rax,[rsi+r9*8]
    test rax,rax
    jz .cat_invalid
    add r8,rax
    jc .cat_invalid
    inc r9
    cmp r9,rdx
    jb .sum
    ; Rejection threshold removes modulo bias.
    xor eax,eax
    sub rax,r8
    xor edx,edx
    div r8
    mov r9,rdx                    ; threshold
.draw:
    mov rax,[rdi]
    mov rdx,rax
    shr rdx,12
    xor rax,rdx
    mov rdx,rax
    shl rdx,25
    xor rax,rdx
    mov rdx,rax
    shr rdx,27
    xor rax,rdx
    mov [rdi],rax
    mov rdx,0x2545f4914f6cdd1d
    imul rax,rdx
    cmp rax,r9
    jb .draw
    xor edx,edx
    div r8
    mov rax,rdx                   ; target in [0,total)
    xor r10d,r10d
    xor r11d,r11d
.select:
    add r10,[rsi+r11*8]
    cmp rax,r10
    jb .selected
    inc r11
    jmp .select
.selected:
    mov [rcx],r11
    xor eax,eax
    ret
.cat_invalid: mov eax,NEBO_PROB_INVALID
    ret
.cat_limit: mov eax,NEBO_PROB_LIMIT
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
