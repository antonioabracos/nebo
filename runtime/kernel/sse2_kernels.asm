; OPERADORES-DE-FLUXO-E-BRANCHING-PIPELINES-F03 SSE2 kernels with unaligned loads and scalar tails.
bits 64
default rel
%define NEBO_SSE2_KERNELS_IMPLEMENTATION 1
%include "runtime/kernel/sse2_kernels.inc"
section .text
global nebo_sse2_add_f64
global nebo_sse2_dot_f64
global nebo_sse2_reduce_sum_f64
global nebo_sse2_i64_to_f64
nebo_sse2_add_f64:
 cmp rcx,NEBO_NUMERIC_MAX_ELEMENTS
 ja sse_bounds_error
 test rcx,rcx
 jz sse_ok
 test rdi,rdi
 jz sse_argument_error
 test rsi,rsi
 jz sse_argument_error
 test rdx,rdx
 jz sse_argument_error
 cmp rdi,rsi
 je sse_alias_error
 cmp rdi,rdx
 je sse_alias_error
 xor r8d,r8d
 mov r9,rcx
 and r9,-2
.add_pairs: cmp r8,r9
 jae .add_tail
 movupd xmm0,[rsi+r8*8]
 movupd xmm1,[rdx+r8*8]
 addpd xmm0,xmm1
 movupd [rdi+r8*8],xmm0
 add r8,2
 jmp .add_pairs
.add_tail: cmp r8,rcx
 jae sse_ok
 movsd xmm0,[rsi+r8*8]
 addsd xmm0,[rdx+r8*8]
 movsd [rdi+r8*8],xmm0
 jmp sse_ok
nebo_sse2_dot_f64:
 cmp rdx,NEBO_NUMERIC_MAX_ELEMENTS
 ja sse_bounds_error
 test rdx,rdx
 jz sse_zero
 test rdi,rdi
 jz sse_argument_error
 test rsi,rsi
 jz sse_argument_error
 pxor xmm0,xmm0
 xor ecx,ecx
 mov r8,rdx
 and r8,-2
.dot_pairs: cmp rcx,r8
 jae .dot_horizontal
 movupd xmm1,[rdi+rcx*8]
 movupd xmm2,[rsi+rcx*8]
 mulpd xmm1,xmm2
 addpd xmm0,xmm1
 add rcx,2
 jmp .dot_pairs
.dot_horizontal:
 movapd xmm1,xmm0
 unpckhpd xmm1,xmm1
 addsd xmm0,xmm1
 cmp rcx,rdx
 jae sse_ok
 movsd xmm1,[rdi+rcx*8]
 mulsd xmm1,[rsi+rcx*8]
 addsd xmm0,xmm1
 jmp sse_ok
nebo_sse2_reduce_sum_f64:
 cmp rsi,NEBO_NUMERIC_MAX_ELEMENTS
 ja sse_bounds_error
 test rsi,rsi
 jz sse_zero
 test rdi,rdi
 jz sse_argument_error
 pxor xmm0,xmm0
 xor ecx,ecx
 mov r8,rsi
 and r8,-2
.sum_pairs: cmp rcx,r8
 jae .sum_horizontal
 movupd xmm1,[rdi+rcx*8]
 addpd xmm0,xmm1
 add rcx,2
 jmp .sum_pairs
.sum_horizontal:
 movapd xmm1,xmm0
 unpckhpd xmm1,xmm1
 addsd xmm0,xmm1
 cmp rcx,rsi
 jae sse_ok
 addsd xmm0,[rdi+rcx*8]
 jmp sse_ok
; Int64 conversion uses the defined scalar tail for every lane (SSE2 has no packed i64 conversion).
nebo_sse2_i64_to_f64:
 jmp nebo_scalar_i64_to_f64
sse_zero: pxor xmm0,xmm0
sse_ok: xor eax,eax
 ret
sse_argument_error: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
sse_alias_error: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 ret
sse_bounds_error: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
