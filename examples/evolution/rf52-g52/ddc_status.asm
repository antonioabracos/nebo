bits 64
default rel
%include "compiler/bootstrap/ddc.inc"
global _start
extern neboc_ddc_plan_new,neboc_cli_diverse_build_report,neboc_host_process_exit
section .bss align=16
plan: resb NEBOC_DDC_SIZE
report: resq 2
section .text
_start:
 sub rsp,8
 lea rdi,[rel plan]
 mov esi,1
 mov edx,2
 mov ecx,3
 call neboc_ddc_plan_new
 lea rdi,[rel plan]
 lea rsi,[rel report]
 call neboc_cli_diverse_build_report
 cmp qword [rel report],5
 jne .fail
 xor edi,edi
 call neboc_host_process_exit
.fail: mov edi,1
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
