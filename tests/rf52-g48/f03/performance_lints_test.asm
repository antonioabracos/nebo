bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/lint/performance.inc"
global _start
extern neboc_analysis_session_new
extern neboc_lint_unnecessary_clone,neboc_lint_unnecessary_allocation
extern neboc_lint_redundant_materialization,neboc_lint_repeated_computation
extern neboc_lint_bounds_check_barrier,neboc_lint_vectorization_blocker
extern neboc_lint_noncontiguous_tensor_hot_path,neboc_lint_blocking_in_async_context
extern neboc_lint_excessive_synchronization,neboc_lint_repeated_serialization
extern neboc_lint_large_value_by_copy,neboc_lint_estimated_impact
extern neboc_host_process_exit
%define SNAPSHOT 0x5200480300000001
section .data
compiler_snapshot: dq SNAPSHOT,1,1
options: dq 64,8,4096,cache,2
input: dq SNAPSHOT,77,NEBOC_PERF_ALL,NEBOC_PERF_ALL,150,75,3,2,1,10,20,NEBOC_ANALYSIS_COMPLETE
functions:
 dq neboc_lint_unnecessary_clone,neboc_lint_unnecessary_allocation
 dq neboc_lint_redundant_materialization,neboc_lint_repeated_computation
 dq neboc_lint_bounds_check_barrier,neboc_lint_vectorization_blocker
 dq neboc_lint_noncontiguous_tensor_hot_path,neboc_lint_blocking_in_async_context
 dq neboc_lint_excessive_synchronization,neboc_lint_repeated_serialization
 dq neboc_lint_large_value_by_copy
section .bss align=16
session: resb NEBOC_ANALYSIS_SESSION_SIZE
cache: resb NEBOC_ANALYSIS_QUERY_ENTRY_SIZE*2
finding: resb NEBOC_LINT_FINDING_SIZE
impact: resb NEBOC_PERF_IMPACT_SIZE
section .text
_start:
 sub rsp,8
 lea rdi,[rel session]
 lea rsi,[rel compiler_snapshot]
 lea rdx,[rel options]
 call neboc_analysis_session_new
 test eax,eax
 jne .fail1
 xor ebx,ebx
.rules:
 cmp ebx,NEBOC_PERF_COUNT
 jae .disabled
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel finding]
 lea rax,[rel functions]
 call [rax+rbx*8]
 test eax,eax
 jne .fail2
 cmp qword [rel finding+NEBOC_LINT_FINDING_PRESENT_OFFSET],1
 jne .fail3
 cmp qword [rel finding+NEBOC_LINT_FINDING_GROUP_OFFSET],NEBOC_LINT_GROUP_PERFORMANCE
 jne .fail4
 cmp qword [rel finding+NEBOC_LINT_FINDING_CONFIDENCE_OFFSET],75
 jne .fail5
 mov rax,rbx
 inc rax
 add rax,NEBOC_PERF_CODE_BASE
 cmp [rel finding+NEBOC_LINT_FINDING_CODE_OFFSET],rax
 jne .fail6
 inc ebx
 jmp .rules
.disabled:
 mov qword [rel input+NEBOC_PERF_INPUT_ENABLED_OFFSET],0
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel finding]
 call neboc_lint_unnecessary_clone
 test eax,eax
 jne .fail7
 cmp qword [rel finding+NEBOC_LINT_FINDING_PRESENT_OFFSET],0
 jne .fail8
 mov qword [rel input+NEBOC_PERF_INPUT_ENABLED_OFFSET],NEBOC_PERF_ALL
.impact_high:
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel impact]
 call neboc_lint_estimated_impact
 test eax,eax
 jne .fail9
 cmp qword [rel impact+NEBOC_PERF_IMPACT_CLASS_OFFSET],NEBOC_PERF_COST_HIGH
 jne .fail10
 cmp qword [rel impact+NEBOC_PERF_IMPACT_REQUIRES_BENCHMARK_OFFSET],1
 jne .fail11
 cmp qword [rel impact+NEBOC_PERF_IMPACT_MEASURED_OFFSET],0
 jne .fail12
 cmp qword [rel impact+NEBOC_PERF_IMPACT_CONFIDENCE_OFFSET],75
 jne .fail13
 mov qword [rel input+NEBOC_PERF_INPUT_COST_OFFSET],5
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel impact]
 call neboc_lint_estimated_impact
 test eax,eax
 jne .fail14
 cmp qword [rel impact+NEBOC_PERF_IMPACT_CLASS_OFFSET],NEBOC_PERF_COST_LOW
 jne .fail15
 mov qword [rel input+NEBOC_PERF_INPUT_COST_OFFSET],50
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel impact]
 call neboc_lint_estimated_impact
 test eax,eax
 jne .fail16
 cmp qword [rel impact+NEBOC_PERF_IMPACT_CLASS_OFFSET],NEBOC_PERF_COST_MEDIUM
 jne .fail17
.incomplete:
 mov qword [rel input+NEBOC_PERF_INPUT_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel impact]
 call neboc_lint_estimated_impact
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail18
 cmp qword [rel impact+NEBOC_PERF_IMPACT_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 jne .fail19
.stale:
 mov qword [rel input+NEBOC_PERF_INPUT_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 mov qword [rel compiler_snapshot],0xdead
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel finding]
 call neboc_lint_unnecessary_clone
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail20
 mov rax,SNAPSHOT
 mov [rel compiler_snapshot],rax
.invalid_atomic:
 mov qword [rel finding],0x51515151
 mov qword [rel input+NEBOC_PERF_INPUT_CONFIDENCE_OFFSET],101
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel finding]
 call neboc_lint_unnecessary_clone
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail21
 cmp qword [rel finding],0x51515151
 jne .fail22
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 22
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
