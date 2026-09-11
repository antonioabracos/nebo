bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/metrics/benchmark.inc"
global _start
extern neboc_compiler_budget_new,neboc_budget_evaluate
extern neboc_benchmark_suite_load,neboc_suite_run_cold
extern neboc_suite_run_warm,neboc_suite_run_incremental
extern neboc_benchmark_statistics,neboc_benchmark_compare
extern neboc_benchmark_reproducibility_manifest
extern neboc_cli_compiler_bench,neboc_cli_compiler_bench_compare
extern neboc_cli_performance_gate,neboc_host_process_exit
section .data
cold_samples: dq 12,10,11,13,9
warm_samples: dq 8,7,9,8,7
incremental_samples: dq 3,4,3,5,3
corpus: dq 1,2,3
section .bss align=16
budget: resb neboc_benchmark_BUDGET_SIZE
budget_result: resb NEBOC_BUDGET_RESULT_SIZE
suite: resb NEBOC_SUITE_SIZE
config: resb NEBOC_SUITE_CONFIG_SIZE
cold_stats: resb NEBOC_STATS_SIZE
warm_stats: resb NEBOC_STATS_SIZE
incremental_stats: resb NEBOC_STATS_SIZE
compare_result: resb NEBOC_COMPARE_SIZE
repro: resb NEBOC_REPRO_SIZE
section .text
_start:
 sub rsp,8
 lea rdi,[rel budget]
 mov esi,1
 mov edx,10
 mov ecx,1
 call neboc_compiler_budget_new
 test eax,eax
 jne .fail1
 ; Regression, noise-floor inconclusive, improvement and pass classes.
 lea rdi,[rel budget]
 mov esi,12
 mov edx,11
 mov ecx,1
 lea r8,[rel budget_result]
 call neboc_budget_evaluate
 test eax,eax
 jne .fail2
 cmp qword [rel budget_result+NEBOC_BUDGET_RESULT_CLASS_OFFSET],NEBOC_BENCH_CLASS_REGRESSION
 jne .fail3
 lea rdi,[rel budget]
 mov esi,11
 mov edx,11
 mov ecx,1
 lea r8,[rel budget_result]
 call neboc_cli_performance_gate
 test eax,eax
 jne .fail4
 cmp qword [rel budget_result+NEBOC_BUDGET_RESULT_CLASS_OFFSET],NEBOC_BENCH_CLASS_INCONCLUSIVE
 jne .fail5
 lea rdi,[rel budget]
 mov esi,8
 mov edx,11
 mov ecx,1
 lea r8,[rel budget_result]
 call neboc_budget_evaluate
 test eax,eax
 jne .fail6
 cmp qword [rel budget_result+NEBOC_BUDGET_RESULT_CLASS_OFFSET],NEBOC_BENCH_CLASS_IMPROVEMENT
 jne .fail7

 lea rax,[rel corpus]
 mov [rel config+NEBOC_SUITE_CONFIG_CORPUS_OFFSET],rax
 mov qword [rel config+NEBOC_SUITE_CONFIG_CASES_OFFSET],3
 mov qword [rel config+NEBOC_SUITE_CONFIG_VERSION_OFFSET],1
 mov qword [rel config+NEBOC_SUITE_CONFIG_HOST_OFFSET],0x111
 mov qword [rel config+NEBOC_SUITE_CONFIG_TARGET_OFFSET],0x222
 mov qword [rel config+NEBOC_SUITE_CONFIG_CORPUS_HASH_OFFSET],0x333
 lea rdi,[rel suite]
 lea rsi,[rel config]
 call neboc_benchmark_suite_load
 test eax,eax
 jne .fail8
 lea rdi,[rel suite]
 lea rsi,[rel cold_samples]
 mov edx,5
 lea rcx,[rel cold_stats]
 call neboc_suite_run_cold
 test eax,eax
 jne .fail9
 cmp qword [rel cold_stats+NEBOC_STATS_MEDIAN_OFFSET],11
 jne .fail10
 cmp qword [rel cold_stats+NEBOC_STATS_P95_OFFSET],13
 jne .fail11
 cmp qword [rel cold_stats+NEBOC_STATS_MAD_OFFSET],1
 jne .fail12
 cmp qword [rel cold_stats+NEBOC_STATS_MIN_OFFSET],9
 jne .fail13
 cmp qword [rel cold_stats+NEBOC_STATS_MAX_OFFSET],13
 jne .fail14
 lea rdi,[rel suite]
 lea rsi,[rel warm_samples]
 mov edx,5
 lea rcx,[rel warm_stats]
 call neboc_suite_run_warm
 test eax,eax
 jne .fail15
 cmp qword [rel warm_stats+NEBOC_STATS_MEDIAN_OFFSET],8
 jne .fail16
 cmp qword [rel warm_stats+NEBOC_STATS_MAD_OFFSET],1
 jne .fail17
 lea rdi,[rel suite]
 lea rsi,[rel incremental_samples]
 mov edx,5
 lea rcx,[rel incremental_stats]
 call neboc_suite_run_incremental
 test eax,eax
 jne .fail18
 cmp qword [rel incremental_stats+NEBOC_STATS_MEDIAN_OFFSET],3
 jne .fail19
 cmp qword [rel incremental_stats+NEBOC_STATS_P95_OFFSET],5
 jne .fail20
 cmp qword [rel incremental_stats+NEBOC_STATS_MAD_OFFSET],0
 jne .fail21

 ; Host-independent compare uses a declared noise floor.
 lea rdi,[rel warm_stats]
 lea rsi,[rel cold_stats]
 mov edx,1
 lea rcx,[rel compare_result]
 call neboc_benchmark_compare
 test eax,eax
 jne .fail22
 cmp qword [rel compare_result+NEBOC_COMPARE_CLASS_OFFSET],NEBOC_BENCH_CLASS_IMPROVEMENT
 jne .fail23
 lea rdi,[rel cold_stats]
 lea rsi,[rel warm_stats]
 mov edx,1
 lea rcx,[rel compare_result]
 call neboc_cli_compiler_bench_compare
 test eax,eax
 jne .fail24
 cmp qword [rel compare_result+NEBOC_COMPARE_CLASS_OFFSET],NEBOC_BENCH_CLASS_REGRESSION
 jne .fail25

 ; Reproducibility manifest records the last run classification and count.
 lea rdi,[rel suite]
 mov esi,0x444
 mov edx,0x555
 lea rcx,[rel repro]
 call neboc_benchmark_reproducibility_manifest
 test eax,eax
 jne .fail26
 cmp qword [rel repro+NEBOC_REPRO_VERSION_OFFSET],1
 jne .fail27
 cmp qword [rel repro+NEBOC_REPRO_HOST_OFFSET],0x111
 jne .fail28
 cmp qword [rel repro+NEBOC_REPRO_TARGET_OFFSET],0x222
 jne .fail29
 cmp qword [rel repro+NEBOC_REPRO_MODE_OFFSET],NEBOC_BENCH_MODE_INCREMENTAL
 jne .fail30
 cmp qword [rel repro+NEBOC_REPRO_SAMPLES_OFFSET],5
 jne .fail31

 ; CLI bench uses cold mode and multiple samples.
 lea rdi,[rel suite]
 lea rsi,[rel cold_samples]
 mov edx,5
 lea rcx,[rel cold_stats]
 call neboc_cli_compiler_bench
 test eax,eax
 jne .fail32
 cmp qword [rel suite+NEBOC_SUITE_LAST_MODE_OFFSET],NEBOC_BENCH_MODE_COLD
 jne .fail33
 ; A single sample cannot close a performance gate.
 lea rdi,[rel cold_samples]
 mov esi,1
 lea rdx,[rel cold_stats]
 call neboc_benchmark_statistics
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail34

 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 34
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
