bits 64
default rel
%include "runtime/kernel/avx2_kernels.inc"
section .data
align 32
a dq 1.0,2.0,3.0,4.0,5.0,6.0,7.0
b dq 7.0,6.0,5.0,4.0,3.0,2.0,1.0
relu_in dq -2.0,-0.0,0.0,3.0,-5.0,6.0,7.0
section .bss
align 32
features resb NEBO_CPU_SIZE
avx_out resq 8
ref_out resq 8
section .text
global _start
_start:
 ; Forced unsafe feature combinations must never select AVX2.
 mov edi,NEBO_CPU_FEATURE_AVX2
 call nebo_avx2_select_safe
 cmp eax,NEBO_KERNEL_SCALAR
 jne .fail1
 mov edi,NEBO_CPU_FEATURE_SSE2|NEBO_CPU_FEATURE_AVX2
 call nebo_avx2_select_safe
 cmp eax,NEBO_KERNEL_SSE2
 jne .fail2
 mov edi,NEBO_CPU_FEATURE_SSE2|NEBO_CPU_FEATURE_AVX|NEBO_CPU_FEATURE_AVX2|NEBO_CPU_FEATURE_OSXSAVE
 call nebo_avx2_select_safe
 cmp eax,NEBO_KERNEL_SSE2
 jne .fail3
 mov edi,NEBO_CPU_FEATURE_SSE2|NEBO_CPU_FEATURE_AVX|NEBO_CPU_FEATURE_AVX2|NEBO_CPU_FEATURE_OSXSAVE|NEBO_CPU_FEATURE_XCR0_YMM
 call nebo_avx2_select_safe
 cmp eax,NEBO_KERNEL_AVX2
 jne .fail4
 ; Actual CPUID path gates every AVX2 instruction below.
 lea rdi,[features]
 call nebo_cpu_detect
 test eax,eax
 jnz .fail5
 mov rdi,[features+NEBO_CPU_FEATURES]
 call nebo_avx2_select_safe
 cmp eax,NEBO_KERNEL_AVX2
 jne .fallback
 lea rdi,[avx_out]
 lea rsi,[a]
 lea rdx,[b]
 mov ecx,7
 call nebo_avx2_add_f64
 test eax,eax
 jnz .fail6
 lea rdi,[ref_out]
 lea rsi,[a]
 lea rdx,[b]
 mov ecx,7
 call nebo_scalar_add_f64
 test eax,eax
 jnz .fail7
 xor ecx,ecx
.compare_add: mov rax,[avx_out+rcx*8]
 cmp rax,[ref_out+rcx*8]
 jne .fail8
 inc rcx
 cmp rcx,7
 jb .compare_add
 lea rdi,[a]
 lea rsi,[b]
 mov edx,7
 call nebo_avx2_dot_f64
 movq r12,xmm0
 lea rdi,[a]
 lea rsi,[b]
 mov edx,7
 call nebo_scalar_dot_f64
 movq rax,xmm0
 cmp rax,r12
 jne .fail9
 lea rdi,[a]
 mov esi,7
 call nebo_avx2_reduce_sum_f64
 movq r12,xmm0
 lea rdi,[a]
 mov esi,7
 call nebo_scalar_reduce_sum_f64
 movq rax,xmm0
 cmp rax,r12
 jne .fail10
 lea rdi,[avx_out]
 lea rsi,[relu_in]
 mov edx,7
 call nebo_avx2_relu_f64
 test eax,eax
 jnz .fail11
 mov rax,__float64__(3.0)
 cmp [avx_out+24],rax
 jne .fail12
 cmp qword [avx_out],0
 jne .fail13
 cmp qword [avx_out+8],0
 jne .fail14
 jmp .negative
.fallback:
 cmp eax,NEBO_KERNEL_SSE2
 je .negative
 cmp eax,NEBO_KERNEL_SCALAR
 jne .fail15
.negative:
 lea rdi,[avx_out]
 lea rsi,[a]
 lea rdx,[b]
 mov ecx,4097
 ; Error path executes before any AVX2 instruction and is safe on every CPU.
 call nebo_avx2_add_f64
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail16
 xor edi,edi
 jmp .exit
%assign i 1
%rep 16
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
