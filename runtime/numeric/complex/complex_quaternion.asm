; IA-ASSISTIDA-LLM-TOOLS-E-GERACAO-SEGURA-F03 binary64 complex and Hamilton quaternion core.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/numeric/complex/complex_quaternion.inc"
section .text

; rdi=out {re,im}, rsi=a, rdx=b.
NEBOC_ABI_FUNCTION nebo_complex_mul_f64
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    movsd xmm0,[rsi]
    movsd xmm1,[rsi+8]
    movsd xmm2,[rdx]
    movsd xmm3,[rdx+8]
    movapd xmm4,xmm0
    mulsd xmm4,xmm2
    movapd xmm5,xmm1
    mulsd xmm5,xmm3
    subsd xmm4,xmm5
    mulsd xmm0,xmm3
    mulsd xmm1,xmm2
    addsd xmm0,xmm1
    movsd [rdi],xmm4
    movsd [rdi+8],xmm0
    xor eax,eax
    ret
.invalid: mov eax,NEBO_COMPLEX_INVALID
    ret

; rdi=out, rsi=input.
NEBOC_ABI_FUNCTION nebo_complex_conjugate_f64
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    mov rax,[rsi]
    mov [rdi],rax
    mov rax,[rsi+8]
    btc rax,63
    mov [rdi+8],rax
    xor eax,eax
    ret
.invalid: mov eax,NEBO_COMPLEX_INVALID
    ret

; rdi=input, rsi=out f64.
NEBOC_ABI_FUNCTION nebo_complex_norm2_f64
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    movsd xmm0,[rdi]
    movsd xmm1,[rdi+8]
    mulsd xmm0,xmm0
    mulsd xmm1,xmm1
    addsd xmm0,xmm1
    movsd [rsi],xmm0
    xor eax,eax
    ret
.invalid: mov eax,NEBO_COMPLEX_INVALID
    ret

; Hamilton product out=(w,x,y,z), a, b.
NEBOC_ABI_FUNCTION nebo_quaternion_mul_f64
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    ; w
    movsd xmm0,[rsi]
    mulsd xmm0,[rdx]
    movsd xmm1,[rsi+8]
    mulsd xmm1,[rdx+8]
    subsd xmm0,xmm1
    movsd xmm1,[rsi+16]
    mulsd xmm1,[rdx+16]
    subsd xmm0,xmm1
    movsd xmm1,[rsi+24]
    mulsd xmm1,[rdx+24]
    subsd xmm0,xmm1
    ; x
    movsd xmm2,[rsi]
    mulsd xmm2,[rdx+8]
    movsd xmm1,[rsi+8]
    mulsd xmm1,[rdx]
    addsd xmm2,xmm1
    movsd xmm1,[rsi+16]
    mulsd xmm1,[rdx+24]
    addsd xmm2,xmm1
    movsd xmm1,[rsi+24]
    mulsd xmm1,[rdx+16]
    subsd xmm2,xmm1
    ; y
    movsd xmm3,[rsi]
    mulsd xmm3,[rdx+16]
    movsd xmm1,[rsi+8]
    mulsd xmm1,[rdx+24]
    subsd xmm3,xmm1
    movsd xmm1,[rsi+16]
    mulsd xmm1,[rdx]
    addsd xmm3,xmm1
    movsd xmm1,[rsi+24]
    mulsd xmm1,[rdx+8]
    addsd xmm3,xmm1
    ; z
    movsd xmm4,[rsi]
    mulsd xmm4,[rdx+24]
    movsd xmm1,[rsi+8]
    mulsd xmm1,[rdx+16]
    addsd xmm4,xmm1
    movsd xmm1,[rsi+16]
    mulsd xmm1,[rdx+8]
    subsd xmm4,xmm1
    movsd xmm1,[rsi+24]
    mulsd xmm1,[rdx]
    addsd xmm4,xmm1
    movsd [rdi],xmm0
    movsd [rdi+8],xmm2
    movsd [rdi+16],xmm3
    movsd [rdi+24],xmm4
    xor eax,eax
    ret
.invalid: mov eax,NEBO_COMPLEX_INVALID
    ret

; rdi=out, rsi=input; rejects zero/NaN norm without mutation.
NEBOC_ABI_FUNCTION nebo_quaternion_normalize_f64
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    movsd xmm0,[rsi]
    mulsd xmm0,xmm0
    movsd xmm1,[rsi+8]
    mulsd xmm1,xmm1
    addsd xmm0,xmm1
    movsd xmm1,[rsi+16]
    mulsd xmm1,xmm1
    addsd xmm0,xmm1
    movsd xmm1,[rsi+24]
    mulsd xmm1,xmm1
    addsd xmm0,xmm1
    xorpd xmm1,xmm1
    ucomisd xmm0,xmm1
    jbe .invalid
    jp .nonfinite
    sqrtsd xmm0,xmm0
    movsd xmm1,[rsi]
    divsd xmm1,xmm0
    movsd xmm2,[rsi+8]
    divsd xmm2,xmm0
    movsd xmm3,[rsi+16]
    divsd xmm3,xmm0
    movsd xmm4,[rsi+24]
    divsd xmm4,xmm0
    movsd [rdi],xmm1
    movsd [rdi+8],xmm2
    movsd [rdi+16],xmm3
    movsd [rdi+24],xmm4
    xor eax,eax
    ret
.invalid: mov eax,NEBO_COMPLEX_INVALID
    ret
.nonfinite: mov eax,NEBO_COMPLEX_NONFINITE
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
