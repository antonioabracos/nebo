bits 64
default rel
%include "compiler/lint/performance.inc"
global _start
extern neboc_analysis_session_new,neboc_lint_estimated_impact,neboc_host_process_exit
%define SNAPSHOT 0x5200480300000001
section .data
compiler_snapshot: dq SNAPSHOT,1,1
options: dq 32,8,4096,cache,1
input: dq SNAPSHOT,1,1,1,25,80,0,0,1,0,1,NEBOC_ANALYSIS_COMPLETE
section .bss align=16
session: resb NEBOC_ANALYSIS_SESSION_SIZE
cache: resb NEBOC_ANALYSIS_QUERY_ENTRY_SIZE
impact: resb NEBOC_PERF_IMPACT_SIZE
section .text
_start:
 sub rsp,8
 lea rdi,[rel session]
 lea rsi,[rel compiler_snapshot]
 lea rdx,[rel options]
 call neboc_analysis_session_new
 test eax,eax
 jne .fail
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel impact]
 call neboc_lint_estimated_impact
 test eax,eax
 jne .fail
 cmp qword [rel impact+NEBOC_PERF_IMPACT_REQUIRES_BENCHMARK_OFFSET],1
 jne .fail
 cmp qword [rel impact+NEBOC_PERF_IMPACT_MEASURED_OFFSET],0
 jne .fail
 xor edi,edi
 call neboc_host_process_exit
.fail:
 mov edi,1
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
