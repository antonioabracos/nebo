bits 64
default rel
%include "compiler/lint/api_maintainability.inc"
global _start
extern neboc_api_baseline_capture,neboc_cli_api_diff,neboc_host_process_exit
%define SNAPSHOT 0x5200480500000002
section .data
item: dq 7,70,80,90,100,1,0,0
current: dq SNAPSHOT,item,1,1
baseline: dq 0,baseline_item,0,1
section .bss align=16
baseline_item: resb NEBOC_API_ITEM_SIZE
result: resb NEBOC_API_DIFF_SIZE
section .text
_start:
 sub rsp,8
 lea rdi,[rel current]
 lea rsi,[rel baseline]
 call neboc_api_baseline_capture
 test eax,eax
 jne .done
 lea rdi,[rel baseline]
 lea rsi,[rel current]
 lea rdx,[rel result]
 call neboc_cli_api_diff
.done:
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
