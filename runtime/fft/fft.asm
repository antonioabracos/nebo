; AUTONOMIA-CONTROLADA-E-AGENTES-F02 deterministic scalar binary64 radix-2 reference kernel (N=4).
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/fft/fft.inc"
section .rodata
four dq 4.0
section .text
NEBOC_ABI_FUNCTION nebo_fft4_f64
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp edx,NEBO_FFT_INVERSE
    ja .invalid
    movsd xmm8,[rsi]
    addsd xmm8,[rsi+16]
    addsd xmm8,[rsi+32]
    addsd xmm8,[rsi+48]
    movsd xmm9,[rsi+8]
    addsd xmm9,[rsi+24]
    addsd xmm9,[rsi+40]
    addsd xmm9,[rsi+56]
    movsd xmm12,[rsi]
    subsd xmm12,[rsi+16]
    addsd xmm12,[rsi+32]
    subsd xmm12,[rsi+48]
    movsd xmm13,[rsi+8]
    subsd xmm13,[rsi+24]
    addsd xmm13,[rsi+40]
    subsd xmm13,[rsi+56]
    test edx,edx
    jnz .inverse_sides
    movsd xmm10,[rsi]
    addsd xmm10,[rsi+24]
    subsd xmm10,[rsi+32]
    subsd xmm10,[rsi+56]
    movsd xmm11,[rsi+8]
    subsd xmm11,[rsi+16]
    subsd xmm11,[rsi+40]
    addsd xmm11,[rsi+48]
    movsd xmm14,[rsi]
    subsd xmm14,[rsi+24]
    subsd xmm14,[rsi+32]
    addsd xmm14,[rsi+56]
    movsd xmm15,[rsi+8]
    addsd xmm15,[rsi+16]
    subsd xmm15,[rsi+40]
    subsd xmm15,[rsi+48]
    jmp .store
.inverse_sides:
    movsd xmm10,[rsi]
    subsd xmm10,[rsi+24]
    subsd xmm10,[rsi+32]
    addsd xmm10,[rsi+56]
    movsd xmm11,[rsi+8]
    addsd xmm11,[rsi+16]
    subsd xmm11,[rsi+40]
    subsd xmm11,[rsi+48]
    movsd xmm14,[rsi]
    addsd xmm14,[rsi+24]
    subsd xmm14,[rsi+32]
    subsd xmm14,[rsi+56]
    movsd xmm15,[rsi+8]
    subsd xmm15,[rsi+16]
    subsd xmm15,[rsi+40]
    addsd xmm15,[rsi+48]
    divsd xmm8,[four]
    divsd xmm9,[four]
    divsd xmm10,[four]
    divsd xmm11,[four]
    divsd xmm12,[four]
    divsd xmm13,[four]
    divsd xmm14,[four]
    divsd xmm15,[four]
.store:
    movsd [rdi],xmm8
    movsd [rdi+8],xmm9
    movsd [rdi+16],xmm10
    movsd [rdi+24],xmm11
    movsd [rdi+32],xmm12
    movsd [rdi+40],xmm13
    movsd [rdi+48],xmm14
    movsd [rdi+56],xmm15
    xor eax,eax
    ret
.invalid: mov eax,NEBO_FFT_INVALID
    ret

NEBOC_ABI_FUNCTION nebo_power_spectrum4_f64
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    xor ecx,ecx
.loop:
    mov rax,rcx
    shl rax,4
    movsd xmm0,[rsi+rax]
    movsd xmm1,[rsi+rax+8]
    mulsd xmm0,xmm0
    mulsd xmm1,xmm1
    addsd xmm0,xmm1
    movsd [rdi+rcx*8],xmm0
    inc ecx
    cmp ecx,4
    jb .loop
    xor eax,eax
    ret
.invalid: mov eax,NEBO_FFT_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
