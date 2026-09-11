bits 64
default rel
%include "compiler/target/portability.inc"
global _start
extern neboc_target_predicate_architecture,neboc_target_predicate_os
extern neboc_target_predicate_has_capability,neboc_target_predicate_has_feature
extern neboc_target_selection_contract,neboc_portable_api_require,neboc_portable_api_fallback
extern neboc_portability_analyzer_analyze,neboc_portability_report_common_subset
extern neboc_portability_report_target_specific_items,neboc_cli_portability_check
extern neboc_cli_portability_report,neboc_host_process_exit
section .data
target: dq 1,1,1,64,16,1,1,1,1,1,0x1f,0x3f,3
capsets: dq 0x3f,0x1f,0x0f
section .bss align=16
pred: resb NEBOC_PRED_SIZE
report: resb NEBOC_PORT_REPORT_SIZE
out: resq 8
section .text
_start:
 sub rsp,8
 lea rdi,[rel pred]
 mov esi,1
 call neboc_target_predicate_architecture
 test eax,eax
 jne .fail1
 lea rsi,[rel target]
 lea rdx,[rel out]
 call neboc_target_selection_contract
 test eax,eax
 jne .fail2
 cmp qword [rel out],1
 jne .fail3
 lea rdi,[rel pred]
 mov esi,1
 call neboc_target_predicate_os
 test eax,eax
 jne .fail4
 lea rsi,[rel target]
 call neboc_target_selection_contract
 cmp qword [rel out],1
 jne .fail5
 lea rdi,[rel pred]
 mov esi,0x20
 call neboc_target_predicate_has_capability
 test eax,eax
 jne .fail6
 lea rsi,[rel target]
 call neboc_target_selection_contract
 cmp qword [rel out],1
 jne .fail7
 lea rdi,[rel pred]
 mov esi,0x10
 call neboc_target_predicate_has_feature
 test eax,eax
 jne .fail8
 lea rsi,[rel target]
 call neboc_target_selection_contract
 cmp qword [rel out],1
 jne .fail9
 lea rdi,[rel target]
 mov esi,0x3f
 call neboc_portable_api_require
 test eax,eax
 jne .fail10
 mov esi,0x40
 call neboc_portable_api_require
 cmp eax,6
 jne .fail11
 mov edi,0x0f
 mov esi,0x10
 mov edx,0x08
 lea rcx,[rel out]
 call neboc_portable_api_fallback
 test eax,eax
 jne .fail12
 cmp qword [rel out],2
 jne .fail13
 lea rdi,[rel report]
 lea rsi,[rel capsets]
 mov edx,3
 mov ecx,0x1f
 call neboc_portability_analyzer_analyze
 test eax,eax
 jne .fail14
 lea rsi,[rel out]
 call neboc_portability_report_common_subset
 test eax,eax
 jne .fail15
 cmp qword [rel out],0x0f
 jne .fail16
 call neboc_portability_report_target_specific_items
 test eax,eax
 jne .fail17
 cmp qword [rel out+8],0x10
 jne .fail18
 lea rdi,[rel report]
 lea rsi,[rel capsets]
 mov edx,17
 mov ecx,1
 call neboc_cli_portability_check
 cmp eax,8
 jne .fail19
 mov edx,3
 call neboc_cli_portability_check
 test eax,eax
 jne .fail20
 lea rdi,[rel report]
 lea rsi,[rel out]
 call neboc_cli_portability_report
 test eax,eax
 jne .fail21
 cmp qword [rel out],0x0f
 jne .fail22
 cmp qword [rel out+24],3
 jne .fail23
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 23
.fail%+n: mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
