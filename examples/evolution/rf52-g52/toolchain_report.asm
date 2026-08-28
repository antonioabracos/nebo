bits 64
default rel
%include "compiler/toolchain/tool_trace.inc"
global _start
extern neboc_toolchain_trace_start,neboc_trace_record_process
extern neboc_cli_toolchain_report,neboc_host_process_exit
section .bss align=16
trace: resb NEBOC_TRACE_SIZE
out: resq 11
section .text
_start:
 sub rsp,8
 lea rdi,[rel trace]
 mov esi,1
 mov edx,1
 call neboc_toolchain_trace_start
 mov esi,1
 mov edx,1
 xor ecx,ecx
 call neboc_trace_record_process
 lea rsi,[rel out]
 call neboc_cli_toolchain_report
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
