; OPERADORES-DE-FLUXO-E-BRANCHING-PIPELINES-F07 local bounded benchmark. Correctness always precedes timing.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%define NEBO_NUMERIC_BENCHMARK_IMPLEMENTATION 1
%include "runtime/kernel/numeric_benchmark.inc"
%include "compiler/semantic/cpu/cpu_contract.inc"
%define SYS_WRITE 1
%define SYS_CLOCK_GETTIME 228
%define CLOCK_MONOTONIC 1
section .rodata
bench_cli_report:
 db 'neboc bench numeric',10
 db 'program=NUMERIC-BENCHMARK-WAVE-C-NUMERIC-VISUAL-PROGRAM-03 kernel_version=1',10
 db 'iterations=100 warmup=10 samples=100 workspace=0 workers=1',10
 db 'clock=monotonic checksum=2080 correctness=pass dispersion=aggregate_elapsed_ns',10
 db 'cpu_features=locally_detected cache_line=locally_detected toolchain=nasm+ld target=x86_64-systemv-elf-linux',10
 db 'measurement=local_observation descriptive_only=yes superiority_claim=no',10
bench_cli_report_end:
bench_cli_request: dq 100,10,0
section .bss
align 32
bench_a resq 64
bench_b resq 64
bench_out resq 64
bench_start resq 2
bench_end resq 2
bench_cli_result resb NEBO_BENCH_RESULT_SIZE
bench_cli_features resb NEBO_CPU_SIZE
section .text
global nebo_numeric_benchmark_run
global nebo_bench_cli_run
; request rdi, result rsi -> NumericError.
nebo_numeric_benchmark_run:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r14,rsi
 test r14,r14
 jz .argument
 mov rdi,r14
 xor eax,eax
 mov ecx,NEBO_BENCH_RESULT_SIZE/8
 rep stosq
 test r12,r12
 jz .argument
 mov r13,[r12+NEBO_BENCH_REQUEST_ITERATIONS]
 test r13,r13
 jz .bounds
 cmp r13,NEBO_BENCH_MAX_ITERATIONS
 ja .bounds
 mov r15,[r12+NEBO_BENCH_REQUEST_WARMUP]
 cmp r15,NEBO_BENCH_MAX_WARMUP
 ja .bounds
 cmp qword [r12+NEBO_BENCH_REQUEST_WORKSPACE],NEBO_NUMERIC_MAX_WORKSPACE
 ja .workspace
 xor ecx,ecx
.init:
 mov rax,rcx
 cvtsi2sd xmm0,rax
 movsd [bench_a+rcx*8],xmm0
 mov rax,__float64__(1.0)
 mov [bench_b+rcx*8],rax
 inc rcx
 cmp rcx,64
 jb .init
 call .kernel_once
 test eax,eax
 jnz .return
 pxor xmm0,xmm0
 xor ecx,ecx
.checksum:
 addsd xmm0,[bench_out+rcx*8]
 inc rcx
 cmp rcx,64
 jb .checksum
 mov rax,__float64__(2080.0)
 movq rdx,xmm0
 cmp rdx,rax
 jne .contract
 movq [r14+NEBO_BENCH_RESULT_CHECKSUM],xmm0
 xor ebx,ebx
.warmup:
 cmp rbx,r15
 jae .clock_start
 call .kernel_once
 test eax,eax
 jnz .return
 inc rbx
 jmp .warmup
.clock_start:
 mov eax,SYS_CLOCK_GETTIME
 mov edi,CLOCK_MONOTONIC
 lea rsi,[bench_start]
 syscall
 cmp rax,-4095
 jae .contract
 xor ebx,ebx
.measure:
 cmp rbx,r13
 jae .clock_end
 call .kernel_once
 test eax,eax
 jnz .return
 inc rbx
 jmp .measure
.clock_end:
 mov eax,SYS_CLOCK_GETTIME
 mov edi,CLOCK_MONOTONIC
 lea rsi,[bench_end]
 syscall
 cmp rax,-4095
 jae .contract
 mov rax,[bench_end]
 sub rax,[bench_start]
 imul rax,1000000000
 add rax,[bench_end+8]
 sub rax,[bench_start+8]
 mov [r14+NEBO_BENCH_RESULT_ELAPSED_NS],rax
 mov [r14+NEBO_BENCH_RESULT_DISPERSION],rax
 mov [r14+NEBO_BENCH_RESULT_ITERATIONS],r13
 mov [r14+NEBO_BENCH_RESULT_WARMUP],r15
 xor eax,eax
 jmp .return
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
.kernel_once:
 lea rdi,[bench_out]
 lea rsi,[bench_a]
 lea rdx,[bench_b]
 mov ecx,64
 call nebo_scalar_add_f64
 ret
.argument: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .return
.bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .return
.workspace: mov eax,NEBO_NUMERIC_ERROR_WORKSPACE
 jmp .return
.contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
.return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
; Exact public bounded command used by the canonical CLI.
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
nebo_bench_cli_run:
 lea rdi,[bench_cli_features]
 call nebo_cpu_detect
 test eax,eax
 jnz .cli_return
 lea rdi,[bench_cli_request]
 lea rsi,[bench_cli_result]
 call nebo_numeric_benchmark_run
 test eax,eax
 jnz .cli_return
 mov eax,SYS_WRITE
 mov edi,1
 lea rsi,[bench_cli_report]
 mov edx,bench_cli_report_end-bench_cli_report
 syscall
 cmp rax,-4095
 jae .cli_error
 xor eax,eax
.cli_return: ret
.cli_error: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
%undef call
