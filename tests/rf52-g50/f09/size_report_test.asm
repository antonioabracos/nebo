bits 64
default rel
%include "compiler/linker/size_report.inc"
global _start
extern neboc_size_report_from_artifact,neboc_size_report_by_section
extern neboc_size_report_by_symbol,neboc_size_report_by_component,neboc_size_report_by_source
extern neboc_size_report_why_linked,neboc_size_report_compare,neboc_binary_size_budget_new
extern neboc_size_budget_evaluate,neboc_size_report_top,neboc_cli_size_report
extern neboc_cli_why_linked,neboc_cli_binary_diff,neboc_cli_size_gate,neboc_host_process_exit
section .data
entries:
 dq 1,10,100,1000,7,100,100,0
 dq 1,11,101,1001,8,50,4096,4096
 dq 2,12,100,1002,9,200,200,0
section .bss align=16
current: resb NEBOC_SIZE_CTX_SIZE
baseline: resb NEBOC_SIZE_CTX_SIZE
budget: resb NEBOC_SIZE_BUDGET_SIZE
out: resq 3
section .text
_start:
 sub rsp,8
 lea rdi,[rel current]
 lea rsi,[rel entries]
 mov edx,3
 mov ecx,0xabc
 mov r8d,1
 call neboc_size_report_from_artifact
 test eax,eax
 jne .fail1
 cmp qword [rel current+NEBOC_SIZE_CTX_FILE_OFFSET],350
 jne .fail2
 cmp qword [rel current+NEBOC_SIZE_CTX_MEMORY_OFFSET],4396
 jne .fail3
 cmp qword [rel current+NEBOC_SIZE_CTX_BSS_OFFSET],4096
 jne .fail4
%macro GROUP_TEST 2
 lea rdi,[rel current]
 lea rsi,[rel out]
 call %1
 test eax,eax
 jne .fail%2
%endmacro
GROUP_TEST neboc_size_report_by_section,5
GROUP_TEST neboc_size_report_by_symbol,6
GROUP_TEST neboc_size_report_by_component,7
GROUP_TEST neboc_size_report_by_source,8
 lea rdi,[rel current]
 mov esi,11
 lea rdx,[rel out]
 call neboc_size_report_why_linked
 test eax,eax
 jne .fail9
 cmp qword [rel out],8
 jne .fail10
 lea rdi,[rel baseline]
 lea rsi,[rel entries]
 mov edx,2
 mov ecx,0xabc
 xor r8d,r8d
 call neboc_size_report_from_artifact
 test eax,eax
 jne .fail11
 lea rdi,[rel current]
 lea rsi,[rel baseline]
 lea rdx,[rel out]
 call neboc_size_report_compare
 test eax,eax
 jne .fail12
 cmp qword [rel out],200
 jne .fail13
 lea rdi,[rel budget]
 mov esi,1
 mov edx,400
 mov ecx,50
 mov r8d,1
 call neboc_binary_size_budget_new
 test eax,eax
 jne .fail14
 lea rdi,[rel budget]
 lea rsi,[rel current]
 lea rdx,[rel out]
 call neboc_size_budget_evaluate
 test eax,eax
 jne .fail15
 cmp qword [rel out],1
 jne .fail16
 lea rdi,[rel current]
 mov esi,2
 lea rdx,[rel out]
 call neboc_size_report_top
 test eax,eax
 jne .fail17
 mov rax,[rel out]
 cmp qword [rax+NEBOC_SIZE_ENTRY_SYMBOL_OFFSET],12
 jne .fail18
 lea rdi,[rel current]
 lea rsi,[rel out]
 call neboc_cli_size_report
 test eax,eax
 jne .fail19
 lea rdi,[rel current]
 mov esi,10
 lea rdx,[rel out]
 call neboc_cli_why_linked
 test eax,eax
 jne .fail20
 lea rdi,[rel current]
 lea rsi,[rel baseline]
 lea rdx,[rel out]
 call neboc_cli_binary_diff
 test eax,eax
 jne .fail21
 lea rdi,[rel budget]
 lea rsi,[rel current]
 lea rdx,[rel out]
 call neboc_cli_size_gate
 test eax,eax
 jne .fail22
 ; Stripped report without validated sidecar is rejected.
 lea rdi,[rel current]
 lea rsi,[rel entries]
 mov edx,1
 xor ecx,ecx
 mov r8d,1
 call neboc_size_report_from_artifact
 test eax,eax
 jz .fail23
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 23
.fail%+n: mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
