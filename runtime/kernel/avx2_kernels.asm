; OPERADORES-DE-FLUXO-E-BRANCHING-PIPELINES-F04 AVX2 kernels. Callers must use the CPUID/OSXSAVE/XCR0 gate.
bits 64
default rel
%define NEBO_AVX2_KERNELS_IMPLEMENTATION 1
%include "runtime/kernel/avx2_kernels.inc"
section .rodata
align 32
avx2_zero: dq 0,0,0,0
section .text
global nebo_avx2_select_safe
global nebo_avx2_add_f64
global nebo_avx2_dot_f64
global nebo_avx2_reduce_sum_f64
global nebo_avx2_relu_f64
; raw feature mask rdi -> scalar/SSE2/AVX2 selection eax.
nebo_avx2_select_safe:
 push rdi
 call nebo_cpu_sanitize_features
 pop rdi
 test rax,NEBO_CPU_FEATURE_AVX2
 jnz avx2_selected
 test rdi,NEBO_CPU_FEATURE_SSE2
 jnz sse2_selected
 xor eax,eax
 ret
avx2_selected: mov eax,NEBO_KERNEL_AVX2
 ret
sse2_selected: mov eax,NEBO_KERNEL_SSE2
 ret
nebo_avx2_add_f64:
 cmp rcx,NEBO_NUMERIC_MAX_ELEMENTS
 ja avx2_bounds_error
 test rcx,rcx
 jz avx2_ok
 test rdi,rdi
 jz avx2_argument_error
 test rsi,rsi
 jz avx2_argument_error
 test rdx,rdx
 jz avx2_argument_error
 cmp rdi,rsi
 je avx2_alias_error
 cmp rdi,rdx
 je avx2_alias_error
 xor r8d,r8d
 mov r9,rcx
 and r9,-4
.loop: cmp r8,r9
 jae .tail
 vmovupd ymm0,[rsi+r8*8]
 vaddpd ymm0,ymm0,[rdx+r8*8]
 vmovupd [rdi+r8*8],ymm0
 add r8,4
 jmp .loop
.tail: cmp r8,rcx
 jae .done
 movsd xmm0,[rsi+r8*8]
 addsd xmm0,[rdx+r8*8]
 movsd [rdi+r8*8],xmm0
 inc r8
 jmp .tail
.done: vzeroupper
 jmp avx2_ok
nebo_avx2_dot_f64:
 cmp rdx,NEBO_NUMERIC_MAX_ELEMENTS
 ja avx2_bounds_error
 test rdx,rdx
 jz avx2_zero_result
 test rdi,rdi
 jz avx2_argument_error
 test rsi,rsi
 jz avx2_argument_error
 vxorpd ymm0,ymm0,ymm0
 xor ecx,ecx
 mov r8,rdx
 and r8,-4
.loop: cmp rcx,r8
 jae .horizontal
 vmovupd ymm1,[rdi+rcx*8]
 vmulpd ymm1,ymm1,[rsi+rcx*8]
 vaddpd ymm0,ymm0,ymm1
 add rcx,4
 jmp .loop
.horizontal:
 vextractf128 xmm1,ymm0,1
 vaddpd xmm0,xmm0,xmm1
 vhaddpd xmm0,xmm0,xmm0
.tail: cmp rcx,rdx
 jae .done
 movsd xmm1,[rdi+rcx*8]
 mulsd xmm1,[rsi+rcx*8]
 addsd xmm0,xmm1
 inc rcx
 jmp .tail
.done: vzeroupper
 jmp avx2_ok
nebo_avx2_reduce_sum_f64:
 cmp rsi,NEBO_NUMERIC_MAX_ELEMENTS
 ja avx2_bounds_error
 test rsi,rsi
 jz avx2_zero_result
 test rdi,rdi
 jz avx2_argument_error
 vxorpd ymm0,ymm0,ymm0
 xor ecx,ecx
 mov r8,rsi
 and r8,-4
.loop: cmp rcx,r8
 jae .horizontal
 vaddpd ymm0,ymm0,[rdi+rcx*8]
 add rcx,4
 jmp .loop
.horizontal:
 vextractf128 xmm1,ymm0,1
 vaddpd xmm0,xmm0,xmm1
 vhaddpd xmm0,xmm0,xmm0
.tail: cmp rcx,rsi
 jae .done
 addsd xmm0,[rdi+rcx*8]
 inc rcx
 jmp .tail
.done: vzeroupper
 jmp avx2_ok
nebo_avx2_relu_f64:
 cmp rdx,NEBO_NUMERIC_MAX_ELEMENTS
 ja avx2_bounds_error
 test rdx,rdx
 jz avx2_ok
 test rdi,rdi
 jz avx2_argument_error
 test rsi,rsi
 jz avx2_argument_error
 cmp rdi,rsi
 je avx2_alias_error
 xor ecx,ecx
 mov r8,rdx
 and r8,-4
.loop: cmp rcx,r8
 jae .tail
 vmovupd ymm0,[rsi+rcx*8]
 vmaxpd ymm0,ymm0,[rel avx2_zero]
 vmovupd [rdi+rcx*8],ymm0
 add rcx,4
 jmp .loop
.tail: cmp rcx,rdx
 jae .done
 movsd xmm0,[rsi+rcx*8]
 pxor xmm1,xmm1
 maxsd xmm0,xmm1
 movsd [rdi+rcx*8],xmm0
 inc rcx
 jmp .tail
.done: vzeroupper
 jmp avx2_ok
avx2_zero_result: vxorpd xmm0,xmm0,xmm0
 vzeroupper
avx2_ok: xor eax,eax
 ret
avx2_argument_error: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
avx2_alias_error: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 ret
avx2_bounds_error: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
