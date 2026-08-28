bits 64
default rel
%include "compiler/metrics/compiler_metrics.inc"
global _start
extern neboc_compiler_metrics_new,neboc_compiler_metrics_phase_timer
extern neboc_cli_timings,neboc_host_process_exit

section .data
context:
 dq 0x20260810,0x1001,0x2001,0x3001,0x4001
 dq NEBOC_METRICS_MODE_COLD,1,NEBOC_METRICS_CORRECTNESS_PASS
 dq 0,0,0,0,0,0,0
section .bss align=16
events: resb NEBOC_METRICS_EVENT_SIZE*4
summary: resb NEBOC_METRICS_SUMMARY_SIZE
section .text
_start:
 sub rsp,8
 lea rdi,[rel context]
 lea rsi,[rel events]
 mov edx,4
 call neboc_compiler_metrics_new
 test eax,eax
 jnz .done
 lea rdi,[rel context]
 mov esi,1
 mov edx,1
 mov ecx,120
 mov r8d,100
 call neboc_compiler_metrics_phase_timer
 test eax,eax
 jnz .done
 lea rdi,[rel context]
 lea rsi,[rel summary]
 call neboc_cli_timings
.done:
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
