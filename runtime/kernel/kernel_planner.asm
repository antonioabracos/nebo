; OPERADORES-DE-FLUXO-E-BRANCHING-PIPELINES-F05 deterministic bounded KernelPlan and workspace policy.
bits 64
default rel
%define NEBO_KERNEL_PLANNER_IMPLEMENTATION 1
%include "runtime/kernel/kernel_planner.inc"
section .rodata
align 8
global nebo_kernel_tier_registry
global nebo_kernel_tier_registry_count
; tier, Float64 vector width, required safe feature mask
nebo_kernel_tier_registry:
 dq NEBO_KERNEL_SCALAR,1,0
 dq NEBO_KERNEL_SSE2,2,NEBO_CPU_FEATURE_SSE2
 dq NEBO_KERNEL_AVX2,4,NEBO_CPU_FEATURE_AVX|NEBO_CPU_FEATURE_AVX2|NEBO_CPU_FEATURE_OSXSAVE|NEBO_CPU_FEATURE_XCR0_YMM
nebo_kernel_tier_registry_count: dq 3
section .text
global nebo_kernel_plan
; request rdi, plan rsi -> status eax. Failure leaves an all-zero plan.
nebo_kernel_plan:
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 test r13,r13
 jz planner_argument_error
 mov rdi,r13
 xor eax,eax
 mov ecx,NEBO_PLAN_SIZE/8
 rep stosq
 test r12,r12
 jz planner_argument_error
 mov rax,[r12+NEBO_REQUEST_OP]
 cmp rax,NEBO_KERNEL_OP_ADD
 jb planner_unsupported_error
 cmp rax,NEBO_KERNEL_OP_MATMUL
 ja planner_unsupported_error
 cmp rax,NEBO_KERNEL_OP_CONVERT_I64_F64
 je .conversion_dtype
 cmp qword [r12+NEBO_REQUEST_DTYPE],NEBO_KERNEL_DTYPE_F64
 jne planner_unsupported_error
 jmp .shape
.conversion_dtype:
 cmp qword [r12+NEBO_REQUEST_DTYPE],NEBO_KERNEL_DTYPE_I64_TO_F64
 jne planner_unsupported_error
.shape:
 cmp qword [r12+NEBO_REQUEST_ELEMENTS],NEBO_NUMERIC_MAX_ELEMENTS
 ja planner_bounds_error
 mov rax,[r12+NEBO_REQUEST_ALIGNMENT]
 test rax,rax
 jz planner_argument_error
 cmp rax,NEBO_NUMERIC_MAX_ELEMENTS
 ja planner_argument_error
 lea rcx,[rax-1]
 test rax,rcx
 jnz planner_argument_error
 cmp qword [r12+NEBO_REQUEST_OVERLAP],0
 jne planner_alias_error
 cmp qword [r12+NEBO_REQUEST_WORKSPACE],NEBO_NUMERIC_MAX_WORKSPACE
 ja planner_workspace_error
 mov rdi,[r12+NEBO_REQUEST_FEATURES]
 call nebo_cpu_sanitize_features
 mov r14,rax
 mov qword [r13+NEBO_PLAN_TIER],NEBO_KERNEL_SCALAR
 mov qword [r13+NEBO_PLAN_REASON],NEBO_PLAN_REASON_SMALL
 mov qword [r13+NEBO_PLAN_VECTOR_WIDTH],1
 mov qword [r13+NEBO_PLAN_WORKSPACE],0
 mov rax,[r12+NEBO_REQUEST_OP]
 cmp rax,NEBO_KERNEL_OP_MATMUL
 je .operation_scalar
 cmp rax,NEBO_KERNEL_OP_CONVERT_I64_F64
 je .conversion
 cmp qword [r12+NEBO_REQUEST_ELEMENTS],4
 jb .trace
 cmp qword [r12+NEBO_REQUEST_ELEMENTS],8
 jb .try_sse2
 test r14,NEBO_CPU_FEATURE_AVX2
 jz .try_sse2
 mov qword [r13+NEBO_PLAN_TIER],NEBO_KERNEL_AVX2
 mov qword [r13+NEBO_PLAN_REASON],NEBO_PLAN_REASON_ISA
 mov qword [r13+NEBO_PLAN_VECTOR_WIDTH],4
 jmp .trace
.try_sse2:
 cmp rax,NEBO_KERNEL_OP_RELU
 je .operation_scalar
 test r14,NEBO_CPU_FEATURE_SSE2
 jz .isa_scalar
 mov qword [r13+NEBO_PLAN_TIER],NEBO_KERNEL_SSE2
 mov qword [r13+NEBO_PLAN_REASON],NEBO_PLAN_REASON_ISA
 mov qword [r13+NEBO_PLAN_VECTOR_WIDTH],2
 jmp .trace
.conversion:
 test r14,NEBO_CPU_FEATURE_SSE2
 jz .operation_scalar
 mov qword [r13+NEBO_PLAN_TIER],NEBO_KERNEL_SSE2
 mov qword [r13+NEBO_PLAN_VECTOR_WIDTH],1
 mov qword [r13+NEBO_PLAN_REASON],NEBO_PLAN_REASON_OPERATION
 jmp .trace
.operation_scalar:
 mov qword [r13+NEBO_PLAN_REASON],NEBO_PLAN_REASON_OPERATION
 jmp .trace
.isa_scalar:
 mov qword [r13+NEBO_PLAN_REASON],NEBO_PLAN_REASON_ISA
.trace:
 ; Versioned exact trace: op | dtype<<8 | tier<<16 | reason<<24 | elements<<32.
 mov rax,[r12+NEBO_REQUEST_OP]
 mov rcx,[r12+NEBO_REQUEST_DTYPE]
 shl rcx,8
 or rax,rcx
 mov rcx,[r13+NEBO_PLAN_TIER]
 shl rcx,16
 or rax,rcx
 mov rcx,[r13+NEBO_PLAN_REASON]
 shl rcx,24
 or rax,rcx
 mov rcx,[r12+NEBO_REQUEST_ELEMENTS]
 shl rcx,32
 or rax,rcx
 mov [r13+NEBO_PLAN_TRACE],rax
 xor eax,eax
 jmp planner_return
planner_argument_error: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp planner_return
planner_bounds_error: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp planner_return
planner_alias_error: mov eax,NEBO_NUMERIC_ERROR_ALIAS
 jmp planner_return
planner_unsupported_error: mov eax,NEBO_NUMERIC_ERROR_UNSUPPORTED
 jmp planner_return
planner_workspace_error: mov eax,NEBO_NUMERIC_ERROR_WORKSPACE
planner_return:
 pop r14
 pop r13
 pop r12
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
