bits 64
default rel
%include "compiler/optimizer/data_footprint.inc"
global _start
extern neboc_cli_data_footprint,neboc_host_process_exit
section .data
context: dq 16,16,4096,0,256,512,4096,1024,1,1,1,32,32,0,0,4096,NEBOC_DATA_FLAG_SINGLE_THREAD,0
section .bss align=16
report: resb NEBOC_DATA_REPORT_SIZE
section .text
_start:
 sub rsp,8
 lea rdi,[rel context]
 lea rsi,[rel report]
 call neboc_cli_data_footprint
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
