; BENCHMARK-F09 deterministic bounded benchmark sample analysis.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/metrics/benchmark.inc"

section .text
; rdi=samples rsi=count rdx=kth -> rax=value. Inputs are validated by caller.
bench_select:
 xor r8d,r8d
.candidate:
 cmp r8,rsi
 jae .missing
 mov rax,[rdi+r8*8]
 xor r9d,r9d
 xor r10d,r10d
 xor r11d,r11d
.rank:
 cmp r9,rsi
 jae .ranked
 mov rcx,[rdi+r9*8]
 cmp rcx,rax
 jb .less
 je .equal
 jmp .next
.less: inc r10
 jmp .next
.equal: inc r11
.next: inc r9
 jmp .rank
.ranked:
 cmp rdx,r10
 jb .candidate_next
 add r10,r11
 cmp rdx,r10
 jb .done
.candidate_next: inc r8
 jmp .candidate
.missing: xor eax,eax
.done: ret

NEBOC_ABI_FUNCTION neboc_compiler_budget_new
 ; rdi=budget rsi=metric rdx=limit rcx=scope.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 mov [rdi+NEBOC_BUDGET_METRIC_OFFSET],rsi
 mov [rdi+NEBOC_BUDGET_LIMIT_OFFSET],rdx
 mov [rdi+NEBOC_BUDGET_SCOPE_OFFSET],rcx
 mov qword [rdi+NEBOC_BUDGET_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_budget_evaluate
 ; rdi=budget rsi=value rdx=baseline rcx=noise r8=result.
 test rdi,rdi
 jz .invalid
 test r8,r8
 jz .invalid
 cmp qword [rdi+NEBOC_BUDGET_ACTIVE_OFFSET],1
 jne .invalid
 mov [r8+NEBOC_BUDGET_RESULT_VALUE_OFFSET],rsi
 mov rax,[rdi+NEBOC_BUDGET_LIMIT_OFFSET]
 mov [r8+NEBOC_BUDGET_RESULT_LIMIT_OFFSET],rax
 cmp rsi,rax
 jbe .within
 mov r9,rsi
 sub r9,rax
 cmp r9,rcx
 jbe .inconclusive
 mov qword [r8+NEBOC_BUDGET_RESULT_CLASS_OFFSET],NEBOC_BENCH_CLASS_REGRESSION
 xor eax,eax
 ret
.within:
 cmp rsi,rdx
 jae .pass
 mov r9,rdx
 sub r9,rsi
 cmp r9,rcx
 jbe .pass
 mov qword [r8+NEBOC_BUDGET_RESULT_CLASS_OFFSET],NEBOC_BENCH_CLASS_IMPROVEMENT
 xor eax,eax
 ret
.pass:
 mov qword [r8+NEBOC_BUDGET_RESULT_CLASS_OFFSET],NEBOC_BENCH_CLASS_PASS
 xor eax,eax
 ret
.inconclusive:
 mov qword [r8+NEBOC_BUDGET_RESULT_CLASS_OFFSET],NEBOC_BENCH_CLASS_INCONCLUSIVE
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_benchmark_suite_load
 ; rdi=suite rsi=config.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rsi+NEBOC_SUITE_CONFIG_CORPUS_OFFSET],0
 je .invalid
 cmp qword [rsi+NEBOC_SUITE_CONFIG_CASES_OFFSET],0
 je .invalid
 cmp qword [rsi+NEBOC_SUITE_CONFIG_VERSION_OFFSET],0
 je .invalid
 cmp qword [rsi+NEBOC_SUITE_CONFIG_HOST_OFFSET],0
 je .invalid
 cmp qword [rsi+NEBOC_SUITE_CONFIG_TARGET_OFFSET],0
 je .invalid
 cmp qword [rsi+NEBOC_SUITE_CONFIG_CORPUS_HASH_OFFSET],0
 je .invalid
 mov r8,rdi
 xor eax,eax
 mov ecx,NEBOC_SUITE_SIZE/8
 rep stosq
 mov rax,[rsi+NEBOC_SUITE_CONFIG_CORPUS_OFFSET]
 mov [r8+NEBOC_SUITE_CORPUS_OFFSET],rax
 mov rax,[rsi+NEBOC_SUITE_CONFIG_CASES_OFFSET]
 mov [r8+NEBOC_SUITE_CASES_OFFSET],rax
 mov rax,[rsi+NEBOC_SUITE_CONFIG_VERSION_OFFSET]
 mov [r8+NEBOC_SUITE_VERSION_OFFSET],rax
 mov rax,[rsi+NEBOC_SUITE_CONFIG_HOST_OFFSET]
 mov [r8+NEBOC_SUITE_HOST_OFFSET],rax
 mov rax,[rsi+NEBOC_SUITE_CONFIG_TARGET_OFFSET]
 mov [r8+NEBOC_SUITE_TARGET_OFFSET],rax
 mov rax,[rsi+NEBOC_SUITE_CONFIG_CORPUS_HASH_OFFSET]
 mov [r8+NEBOC_SUITE_CORPUS_HASH_OFFSET],rax
 mov qword [r8+NEBOC_SUITE_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; rdi=suite rsi=samples rdx=count rcx=stats r8=mode.
suite_run:
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_SUITE_ACTIVE_OFFSET],1
 jne .invalid
 test rsi,rsi
 jz .invalid
 cmp rdx,3
 jb .invalid
 cmp rdx,NEBOC_BENCH_MAX_SAMPLES
 ja .limit
 test rcx,rcx
 jz .invalid
 mov [rdi+NEBOC_SUITE_LAST_MODE_OFFSET],r8
 mov [rdi+NEBOC_SUITE_LAST_COUNT_OFFSET],rdx
 inc qword [rdi+NEBOC_SUITE_RUNS_OFFSET]
 mov r9,rdx
 mov rdi,rsi
 mov rsi,r9
 mov rdx,rcx
 jmp neboc_benchmark_statistics
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_suite_run_cold
 mov r8d,NEBOC_BENCH_MODE_COLD
 jmp suite_run
NEBOC_ABI_FUNCTION neboc_suite_run_warm
 mov r8d,NEBOC_BENCH_MODE_WARM
 jmp suite_run
NEBOC_ABI_FUNCTION neboc_suite_run_incremental
 mov r8d,NEBOC_BENCH_MODE_INCREMENTAL
 jmp suite_run

NEBOC_ABI_FUNCTION neboc_benchmark_statistics
 ; rdi=samples rsi=count rdx=stats. Median/p95/MAD use order statistics.
 test rdi,rdi
 jz .invalid0
 cmp rsi,3
 jb .invalid0
 cmp rsi,NEBOC_BENCH_MAX_SAMPLES
 ja .limit0
 test rdx,rdx
 jz .invalid0
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,256
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,[rbx]
 mov r15,r14
 xor ecx,ecx
.minmax:
 cmp rcx,r12
 jae .median
 mov rax,[rbx+rcx*8]
 cmp rax,r14
 cmovb r14,rax
 cmp rax,r15
 cmova r15,rax
 inc rcx
 jmp .minmax
.median:
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r12
 shr rdx,1
 call bench_select
 mov [r13+NEBOC_STATS_MEDIAN_OFFSET],rax
 mov r10,rax
 mov rax,r12
 imul rax,95
 add rax,99
 xor edx,edx
 mov ecx,100
 div rcx
 dec rax
 mov rdx,rax
 mov rdi,rbx
 mov rsi,r12
 call bench_select
 mov [r13+NEBOC_STATS_P95_OFFSET],rax
 mov r10,[r13+NEBOC_STATS_MEDIAN_OFFSET]
 xor ecx,ecx
.deviations:
 cmp rcx,r12
 jae .mad
 mov rax,[rbx+rcx*8]
 cmp rax,r10
 jae .positive
 mov rdx,r10
 sub rdx,rax
 mov rax,rdx
 jmp .store
.positive: sub rax,r10
.store: mov [rsp+rcx*8],rax
 inc rcx
 jmp .deviations
.mad:
 mov rdi,rsp
 mov rsi,r12
 mov rdx,r12
 shr rdx,1
 call bench_select
 mov [r13+NEBOC_STATS_MAD_OFFSET],rax
 mov [r13+NEBOC_STATS_MIN_OFFSET],r14
 mov [r13+NEBOC_STATS_MAX_OFFSET],r15
 mov [r13+NEBOC_STATS_COUNT_OFFSET],r12
 add rsp,256
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 xor eax,eax
 ret
.limit0: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid0: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_benchmark_compare
 ; rdi=current stats rsi=baseline stats rdx=noise floor rcx=result.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp qword [rdi+NEBOC_STATS_COUNT_OFFSET],3
 jb .invalid
 cmp qword [rsi+NEBOC_STATS_COUNT_OFFSET],3
 jb .invalid
 mov r8,[rdi+NEBOC_STATS_MEDIAN_OFFSET]
 mov r9,[rsi+NEBOC_STATS_MEDIAN_OFFSET]
 mov [rcx+NEBOC_COMPARE_CURRENT_OFFSET],r8
 mov [rcx+NEBOC_COMPARE_BASELINE_OFFSET],r9
 mov rax,r8
 sub rax,r9
 mov [rcx+NEBOC_COMPARE_DELTA_OFFSET],rax
 cmp r8,r9
 jae .higher
 mov rax,r9
 sub rax,r8
 cmp rax,rdx
 jbe .inconclusive
 mov qword [rcx+NEBOC_COMPARE_CLASS_OFFSET],NEBOC_BENCH_CLASS_IMPROVEMENT
 xor eax,eax
 ret
.higher:
 mov rax,r8
 sub rax,r9
 cmp rax,rdx
 jbe .inconclusive
 mov qword [rcx+NEBOC_COMPARE_CLASS_OFFSET],NEBOC_BENCH_CLASS_REGRESSION
 xor eax,eax
 ret
.inconclusive:
 mov qword [rcx+NEBOC_COMPARE_CLASS_OFFSET],NEBOC_BENCH_CLASS_INCONCLUSIVE
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_benchmark_reproducibility_manifest
 ; rdi=suite rsi=options hash rdx=commit token rcx=manifest.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp qword [rdi+NEBOC_SUITE_ACTIVE_OFFSET],1
 jne .invalid
 mov rax,[rdi+NEBOC_SUITE_VERSION_OFFSET]
 mov [rcx+NEBOC_REPRO_VERSION_OFFSET],rax
 mov rax,[rdi+NEBOC_SUITE_CORPUS_HASH_OFFSET]
 mov [rcx+NEBOC_REPRO_CORPUS_HASH_OFFSET],rax
 mov rax,[rdi+NEBOC_SUITE_HOST_OFFSET]
 mov [rcx+NEBOC_REPRO_HOST_OFFSET],rax
 mov rax,[rdi+NEBOC_SUITE_TARGET_OFFSET]
 mov [rcx+NEBOC_REPRO_TARGET_OFFSET],rax
 mov [rcx+NEBOC_REPRO_OPTIONS_OFFSET],rsi
 mov [rcx+NEBOC_REPRO_COMMIT_OFFSET],rdx
 mov rax,[rdi+NEBOC_SUITE_LAST_MODE_OFFSET]
 mov [rcx+NEBOC_REPRO_MODE_OFFSET],rax
 mov rax,[rdi+NEBOC_SUITE_LAST_COUNT_OFFSET]
 mov [rcx+NEBOC_REPRO_SAMPLES_OFFSET],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_compiler_bench
 mov r8d,NEBOC_BENCH_MODE_COLD
 jmp suite_run
NEBOC_ABI_FUNCTION neboc_cli_compiler_bench_compare
 jmp neboc_benchmark_compare
NEBOC_ABI_FUNCTION neboc_cli_performance_gate
 jmp neboc_budget_evaluate

section .note.GNU-stack noalloc noexec nowrite progbits
