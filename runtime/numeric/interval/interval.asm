; IA-ASSISTIDA-LLM-TOOLS-E-GERACAO-SEGURA-F05 closed binary64 intervals with outward one-ULP rounding.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/numeric/interval/interval.inc"

%macro NEXT_DOWN 1
    mov rax,%1
    mov rcx,rax
    shl rcx,1
    jnz %%nonzero
    mov %1,0x8000000000000001
    jmp %%done
%%nonzero:
    test %1,%1
    js %%negative
    mov rax,0x7ff0000000000000
    cmp %1,rax
    je %%done
    dec %1
    jmp %%done
%%negative:
    mov rax,0xfff0000000000000
    cmp %1,rax
    je %%done
    inc %1
%%done:
%endmacro

%macro NEXT_UP 1
    mov rax,%1
    mov rcx,rax
    shl rcx,1
    jnz %%nonzero
    mov %1,1
    jmp %%done
%%nonzero:
    test %1,%1
    js %%negative
    mov rax,0x7ff0000000000000
    cmp %1,rax
    je %%done
    inc %1
    jmp %%done
%%negative:
    mov rax,0xfff0000000000000
    cmp %1,rax
    je %%done
    dec %1
%%done:
%endmacro

section .text
; rdi=out {lo,hi}, rsi=a, rdx=b.
NEBOC_ABI_FUNCTION nebo_interval_add_f64
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    movsd xmm0,[rsi]
    addsd xmm0,[rdx]
    ucomisd xmm0,xmm0
    jp .invalid
    movsd xmm1,[rsi+8]
    addsd xmm1,[rdx+8]
    ucomisd xmm1,xmm1
    jp .invalid
    movq r8,xmm0
    movq r9,xmm1
    NEXT_DOWN r8
    NEXT_UP r9
    mov [rdi],r8
    mov [rdi+8],r9
    xor eax,eax
    ret
.invalid: mov eax,NEBO_INTERVAL_INVALID
    ret

; rdi=out, rsi=a, rdx=b. Empty intersection leaves out unchanged.
NEBOC_ABI_FUNCTION nebo_interval_intersect_f64
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    movsd xmm0,[rsi]
    maxsd xmm0,[rdx]
    movsd xmm1,[rsi+8]
    minsd xmm1,[rdx+8]
    ucomisd xmm0,xmm1
    jp .invalid
    ja .empty
    movsd [rdi],xmm0
    movsd [rdi+8],xmm1
    xor eax,eax
    ret
.invalid: mov eax,NEBO_INTERVAL_INVALID
    ret
.empty: mov eax,NEBO_INTERVAL_EMPTY
    ret

; rdi=out, rsi=a, rdx=b; active multiplication subset requires nonnegative intervals.
NEBOC_ABI_FUNCTION nebo_interval_mul_nonnegative_f64
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    xorpd xmm4,xmm4
    movsd xmm0,[rsi]
    movsd xmm1,[rsi+8]
    movsd xmm2,[rdx]
    movsd xmm3,[rdx+8]
    ucomisd xmm0,xmm4
    jb .domain
    ucomisd xmm2,xmm4
    jb .domain
    ucomisd xmm1,xmm0
    jb .invalid
    ucomisd xmm3,xmm2
    jb .invalid
    mulsd xmm0,xmm2
    mulsd xmm1,xmm3
    movq r8,xmm0
    movq r9,xmm1
    NEXT_DOWN r8
    NEXT_UP r9
    mov [rdi],r8
    mov [rdi+8],r9
    xor eax,eax
    ret
.invalid: mov eax,NEBO_INTERVAL_INVALID
    ret
.domain: mov eax,NEBO_INTERVAL_DOMAIN
    ret

; rdi=interval, xmm0=point, rsi=out bool.
NEBOC_ABI_FUNCTION nebo_interval_contains_f64
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    xor eax,eax
    ucomisd xmm0,[rdi]
    jp .invalid
    jb .store
    ucomisd xmm0,[rdi+8]
    ja .store
    mov eax,1
.store:
    mov [rsi],eax
    xor eax,eax
    ret
.invalid: mov eax,NEBO_INTERVAL_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
