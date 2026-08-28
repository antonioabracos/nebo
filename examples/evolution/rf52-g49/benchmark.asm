bits 64
default rel
%include "compiler/metrics/benchmark.inc"
global _start
extern neboc_benchmark_statistics,neboc_host_process_exit
section .data
samples: dq 11,9,10,12,10
section .bss align=16
stats: resb NEBOC_STATS_SIZE
section .text
_start:
 sub rsp,8
 lea rdi,[rel samples]
 mov esi,5
 lea rdx,[rel stats]
 call neboc_benchmark_statistics
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
