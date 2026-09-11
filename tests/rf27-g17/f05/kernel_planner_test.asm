bits 64
default rel
%include "runtime/kernel/kernel_planner.inc"
%define SAFE_AVX2 NEBO_CPU_FEATURE_SSE2|NEBO_CPU_FEATURE_AVX|NEBO_CPU_FEATURE_AVX2|NEBO_CPU_FEATURE_OSXSAVE|NEBO_CPU_FEATURE_XCR0_YMM
section .data
align 8
request: dq NEBO_KERNEL_OP_ADD,NEBO_KERNEL_DTYPE_F64,16,8,0,65536,SAFE_AVX2
section .bss
align 8
plan resb NEBO_PLAN_SIZE
section .text
global _start
_start:
 lea rdi,[request]
 lea rsi,[plan]
 call nebo_kernel_plan
 test eax,eax
 jnz .fail1
 cmp qword [plan+NEBO_PLAN_TIER],NEBO_KERNEL_AVX2
 jne .fail2
 cmp qword [plan+NEBO_PLAN_VECTOR_WIDTH],4
 jne .fail3
 mov r12,[plan+NEBO_PLAN_TRACE]
 lea rdi,[request]
 lea rsi,[plan]
 call nebo_kernel_plan
 cmp [plan+NEBO_PLAN_TRACE],r12
 jne .fail4
 ; Missing XCR0 falls back to SSE2.
 mov qword [request+NEBO_REQUEST_FEATURES],NEBO_CPU_FEATURE_SSE2|NEBO_CPU_FEATURE_AVX|NEBO_CPU_FEATURE_AVX2|NEBO_CPU_FEATURE_OSXSAVE
 call .plan_request
 cmp qword [plan+NEBO_PLAN_TIER],NEBO_KERNEL_SSE2
 jne .fail5
 ; No features and small shapes are scalar.
 mov qword [request+NEBO_REQUEST_FEATURES],0
 call .plan_request
 cmp qword [plan+NEBO_PLAN_TIER],NEBO_KERNEL_SCALAR
 jne .fail6
 mov qword [request+NEBO_REQUEST_FEATURES],SAFE_AVX2
 mov qword [request+NEBO_REQUEST_ELEMENTS],3
 call .plan_request
 cmp qword [plan+NEBO_PLAN_REASON],NEBO_PLAN_REASON_SMALL
 jne .fail7
 ; ReLU without AVX2 is scalar; conversion with SSE2 uses scalar conversion tail.
 mov qword [request+NEBO_REQUEST_OP],NEBO_KERNEL_OP_RELU
 mov qword [request+NEBO_REQUEST_ELEMENTS],16
 mov qword [request+NEBO_REQUEST_FEATURES],NEBO_CPU_FEATURE_SSE2
 call .plan_request
 cmp qword [plan+NEBO_PLAN_TIER],NEBO_KERNEL_SCALAR
 jne .fail8
 mov qword [request+NEBO_REQUEST_OP],NEBO_KERNEL_OP_CONVERT_I64_F64
 mov qword [request+NEBO_REQUEST_DTYPE],NEBO_KERNEL_DTYPE_I64_TO_F64
 call .plan_request
 cmp qword [plan+NEBO_PLAN_TIER],NEBO_KERNEL_SSE2
 jne .fail9
 cmp qword [plan+NEBO_PLAN_VECTOR_WIDTH],1
 jne .fail10
 ; Matmul stays on the reference scalar kernel.
 mov qword [request+NEBO_REQUEST_OP],NEBO_KERNEL_OP_MATMUL
 mov qword [request+NEBO_REQUEST_DTYPE],NEBO_KERNEL_DTYPE_F64
 mov qword [request+NEBO_REQUEST_FEATURES],SAFE_AVX2
 call .plan_request
 cmp qword [plan+NEBO_PLAN_TIER],NEBO_KERNEL_SCALAR
 jne .fail11
 cmp qword [nebo_kernel_tier_registry_count],3
 jne .fail12
 cmp qword [nebo_kernel_tier_registry+48],NEBO_KERNEL_AVX2
 jne .fail13
 ; Every failure after a valid output pointer is failure-atomic.
 mov qword [request+NEBO_REQUEST_OP],99
 call .expect_unsupported
 jne .fail14
 mov qword [request+NEBO_REQUEST_OP],NEBO_KERNEL_OP_ADD
 mov qword [request+NEBO_REQUEST_DTYPE],99
 call .expect_unsupported
 jne .fail15
 mov qword [request+NEBO_REQUEST_DTYPE],NEBO_KERNEL_DTYPE_F64
 mov qword [request+NEBO_REQUEST_ELEMENTS],4097
 call .plan_request
 cmp eax,NEBO_NUMERIC_ERROR_BOUNDS
 jne .fail16
 call .plan_zero
 jne .fail17
 mov qword [request+NEBO_REQUEST_ELEMENTS],16
 mov qword [request+NEBO_REQUEST_WORKSPACE],65537
 call .plan_request
 cmp eax,NEBO_NUMERIC_ERROR_WORKSPACE
 jne .fail18
 call .plan_zero
 jne .fail19
 mov qword [request+NEBO_REQUEST_WORKSPACE],65536
 mov qword [request+NEBO_REQUEST_OVERLAP],1
 call .plan_request
 cmp eax,NEBO_NUMERIC_ERROR_ALIAS
 jne .fail20
 mov qword [request+NEBO_REQUEST_OVERLAP],0
 mov qword [request+NEBO_REQUEST_ALIGNMENT],3
 call .plan_request
 cmp eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jne .fail21
 mov qword [request+NEBO_REQUEST_ALIGNMENT],8
 xor edi,edi
 lea rsi,[plan]
 call nebo_kernel_plan
 cmp eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jne .fail22
 call .plan_zero
 jne .fail23
 lea rdi,[request]
 xor esi,esi
 call nebo_kernel_plan
 cmp eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jne .fail24
 xor edi,edi
 jmp .exit
.plan_request:
 lea rdi,[request]
 lea rsi,[plan]
 call nebo_kernel_plan
 ret
.expect_unsupported:
 call .plan_request
 cmp eax,NEBO_NUMERIC_ERROR_UNSUPPORTED
 ret
.plan_zero:
 mov rax,[plan]
 or rax,[plan+8]
 or rax,[plan+16]
 or rax,[plan+24]
 or rax,[plan+32]
 ret
%assign i 1
%rep 24
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
