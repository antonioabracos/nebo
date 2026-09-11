bits 64
default rel
%include "runtime/kernel/numeric_benchmark.inc"
section .data
align 32
a dq 1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0
b dq 1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0
bench_request dq 4,1,0
kernel_request dq NEBO_KERNEL_OP_ADD,NEBO_KERNEL_DTYPE_F64,8,32,0,0,0
section .bss
align 32
features resb NEBO_CPU_SIZE
scalar_out resq 8
sse2_out resq 8
avx2_out resq 8
parallel_out resq 8
kernel_plan resb NEBO_PLAN_SIZE
bench_result resb NEBO_BENCH_RESULT_SIZE
section .text
global _start
_start:
 lea rdi,[features]
 call nebo_cpu_detect
 test eax,eax
 jnz .fail1
 test qword [features+NEBO_CPU_FEATURES],NEBO_CPU_FEATURE_SSE2
 jz .fail2
 lea rdi,[scalar_out]
 lea rsi,[a]
 lea rdx,[b]
 mov ecx,8
 call nebo_scalar_add_f64
 test eax,eax
 jnz .fail3
 lea rdi,[sse2_out]
 lea rsi,[a]
 lea rdx,[b]
 mov ecx,8
 call nebo_sse2_add_f64
 test eax,eax
 jnz .fail4
 lea rdi,[scalar_out]
 lea rsi,[sse2_out]
 call .compare8
 test eax,eax
 jnz .fail5
 mov rdi,[features+NEBO_CPU_FEATURES]
 call nebo_avx2_select_safe
 cmp eax,NEBO_KERNEL_AVX2
 jne .parallel
 lea rdi,[avx2_out]
 lea rsi,[a]
 lea rdx,[b]
 mov ecx,8
 call nebo_avx2_add_f64
 test eax,eax
 jnz .fail6
 lea rdi,[scalar_out]
 lea rsi,[avx2_out]
 call .compare8
 test eax,eax
 jnz .fail7
.parallel:
 lea rdi,[parallel_out]
 lea rsi,[a]
 lea rdx,[b]
 mov ecx,8
 mov r8d,8
 xor r9d,r9d
 call nebo_parallel_add_f64
 test eax,eax
 jnz .fail8
 lea rdi,[scalar_out]
 lea rsi,[parallel_out]
 call .compare8
 test eax,eax
 jnz .fail9
 ; Forced feature profiles select exact deterministic tiers.
 mov qword [kernel_request+NEBO_REQUEST_FEATURES],0
 call .plan
 cmp qword [kernel_plan+NEBO_PLAN_TIER],NEBO_KERNEL_SCALAR
 jne .fail10
 mov qword [kernel_request+NEBO_REQUEST_FEATURES],NEBO_CPU_FEATURE_SSE2
 call .plan
 cmp qword [kernel_plan+NEBO_PLAN_TIER],NEBO_KERNEL_SSE2
 jne .fail11
 mov qword [kernel_request+NEBO_REQUEST_FEATURES],NEBO_CPU_FEATURE_SSE2|NEBO_CPU_FEATURE_AVX|NEBO_CPU_FEATURE_AVX2|NEBO_CPU_FEATURE_OSXSAVE
 call .plan
 cmp qword [kernel_plan+NEBO_PLAN_TIER],NEBO_KERNEL_SSE2
 jne .fail12
 mov qword [kernel_request+NEBO_REQUEST_FEATURES],NEBO_CPU_FEATURE_SSE2|NEBO_CPU_FEATURE_AVX|NEBO_CPU_FEATURE_AVX2|NEBO_CPU_FEATURE_OSXSAVE|NEBO_CPU_FEATURE_XCR0_YMM
 call .plan
 cmp qword [kernel_plan+NEBO_PLAN_TIER],NEBO_KERNEL_AVX2
 jne .fail13
 mov r12,[kernel_plan+NEBO_PLAN_TRACE]
 call .plan
 cmp [kernel_plan+NEBO_PLAN_TRACE],r12
 jne .fail14
 lea rdi,[bench_request]
 lea rsi,[bench_result]
 call nebo_numeric_benchmark_run
 test eax,eax
 jnz .fail15
 mov rax,__float64__(2080.0)
 cmp [bench_result+NEBO_BENCH_RESULT_CHECKSUM],rax
 jne .fail16
 cmp qword [nebo_kernel_tier_registry_count],3
 jne .fail17
 mov rdi,NEBO_CPU_FEATURE_AVX2
 call nebo_cpu_sanitize_features
 test rax,NEBO_CPU_FEATURE_AVX2
 jnz .fail18
 xor edi,edi
 jmp .exit
.plan:
 lea rdi,[kernel_request]
 lea rsi,[kernel_plan]
 call nebo_kernel_plan
 ret
.compare8:
 xor ecx,ecx
.compare_loop:
 mov rax,[rdi+rcx*8]
 cmp rax,[rsi+rcx*8]
 jne .compare_fail
 inc rcx
 cmp rcx,8
 jb .compare_loop
 xor eax,eax
 ret
.compare_fail: mov eax,1
 ret
%assign i 1
%rep 18
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
