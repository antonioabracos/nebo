bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/optimizer/global_dce.inc"
global _start
extern neboc_section_planner_function_sections,neboc_section_planner_data_sections
extern neboc_section_planner_comdat_group,neboc_global_dce_run
extern neboc_global_dce_prune_unused_exports,neboc_global_dce_prune_unused_diagnostics
extern neboc_global_dce_prune_unused_type_metadata,neboc_global_dce_report
extern neboc_section_verify_relocations,neboc_section_keep
extern neboc_cli_build_gc_sections,neboc_host_process_exit
section .data
sections:
 dq 1,NEBOC_DCE_SECTION_FUNCTION,10,1,0,0,0,0,0
 dq 2,NEBOC_DCE_SECTION_FUNCTION,20,0,0,0,0,0,0
 dq 3,NEBOC_DCE_SECTION_DATA,5,1,0,0,0,0,0
 dq 4,NEBOC_DCE_SECTION_FUNCTION,7,0,1,0,0,0,0
 dq 5,NEBOC_DCE_SECTION_DIAGNOSTIC,3,0,0,1,0,0,0
 dq 6,NEBOC_DCE_SECTION_DIAGNOSTIC,3,0,0,0,0,0,0
 dq 7,NEBOC_DCE_SECTION_METADATA,4,0,0,0,1,0,0
 dq 8,NEBOC_DCE_SECTION_METADATA,4,0,0,0,0,0,0
 dq 9,NEBOC_DCE_SECTION_FUNCTION,6,0,0,0,0,0,0
relocs: dq 1,3, 4,5, 9,7, 1,2
section .bss align=16
context: resb NEBOC_DCE_CONTEXT_SIZE
ids: resq 16
count: resq 1
group1: resq 1
group2: resq 1
report: resb NEBOC_DCE_REPORT_SIZE
section .text
_start:
 sub rsp,8
 lea rdi,[rel sections]
 mov esi,9
 lea rcx,[rel ids]
 mov r8d,16
 lea r9,[rel count]
 call neboc_section_planner_function_sections
 test eax,eax
 jne .fail1
 cmp qword [rel count],4
 jne .fail2
 cmp qword [rel ids],1
 jne .fail3
 lea rdi,[rel sections]
 mov esi,9
 lea rcx,[rel ids]
 mov r8d,16
 lea r9,[rel count]
 call neboc_section_planner_data_sections
 test eax,eax
 jne .fail4
 cmp qword [rel count],1
 jne .fail5
 cmp qword [rel ids],3
 jne .fail6
 mov edi,0xabc
 mov esi,1
 lea rdx,[rel group1]
 call neboc_section_planner_comdat_group
 test eax,eax
 jne .fail7
 mov edi,0xabc
 mov esi,1
 lea rdx,[rel group2]
 call neboc_section_planner_comdat_group
 test eax,eax
 jne .fail8
 mov rax,[rel group1]
 cmp rax,[rel group2]
 jne .fail9

 lea rax,[rel sections]
 mov [rel context+NEBOC_DCE_CONTEXT_SECTIONS_OFFSET],rax
 mov qword [rel context+NEBOC_DCE_CONTEXT_COUNT_OFFSET],9
 lea rax,[rel relocs]
 mov [rel context+NEBOC_DCE_CONTEXT_RELOCS_OFFSET],rax
 mov qword [rel context+NEBOC_DCE_CONTEXT_RELOC_COUNT_OFFSET],4
 mov qword [rel context+NEBOC_DCE_CONTEXT_PUBLIC_ABI_OFFSET],1
 ; Explicit security/tooling keep reason precedes DCE.
 lea rdi,[rel context]
 mov esi,9
 mov edx,1
 call neboc_section_keep
 test eax,eax
 jne .fail10
 lea rdi,[rel context]
 call neboc_global_dce_run
 test eax,eax
 jne .fail11
 lea rdi,[rel context]
 lea rsi,[rel report]
 call neboc_global_dce_report
 test eax,eax
 jne .fail12
 cmp qword [rel report+NEBOC_DCE_REPORT_RETAINED_OFFSET],6
 jne .fail13
 cmp qword [rel report+NEBOC_DCE_REPORT_PRUNED_OFFSET],3
 jne .fail14
 cmp qword [rel report+NEBOC_DCE_REPORT_RETAINED_BYTES_OFFSET],35
 jne .fail15
 cmp qword [rel report+NEBOC_DCE_REPORT_PRUNED_BYTES_OFFSET],27
 jne .fail16
 ; Retained source 1 to pruned target 2 is a dangling relocation.
 lea rdi,[rel context]
 call neboc_section_verify_relocations
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail17
 lea rdi,[rel context]
 mov esi,2
 mov edx,2
 call neboc_section_keep
 test eax,eax
 jne .fail18
 lea rdi,[rel context]
 call neboc_global_dce_run
 test eax,eax
 jne .fail19
 lea rdi,[rel context]
 call neboc_section_verify_relocations
 test eax,eax
 jne .fail20
 cmp qword [rel context+NEBOC_DCE_CONTEXT_RETAINED_COUNT_OFFSET],7
 jne .fail21
 ; Public ABI policy forbids pruning an unused export.
 lea rdi,[rel context]
 mov esi,1
 call neboc_global_dce_prune_unused_exports
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail22
 lea rdi,[rel context]
 mov esi,1
 call neboc_global_dce_prune_unused_diagnostics
 test eax,eax
 jne .fail23
 cmp qword [rel sections+NEBOC_DCE_SECTION_SIZE*4+NEBOC_DCE_SECTION_RETAINED_OFFSET],1
 jne .fail24
 lea rdi,[rel context]
 mov esi,1
 call neboc_global_dce_prune_unused_type_metadata
 test eax,eax
 jne .fail25
 cmp qword [rel sections+NEBOC_DCE_SECTION_SIZE*6+NEBOC_DCE_SECTION_RETAINED_OFFSET],1
 jne .fail26
 ; GC off is the reference and retains every section.
 lea rdi,[rel context]
 mov esi,NEBOC_DCE_GC_OFF
 call neboc_cli_build_gc_sections
 test eax,eax
 jne .fail27
 cmp qword [rel context+NEBOC_DCE_CONTEXT_RETAINED_COUNT_OFFSET],9
 jne .fail28
 lea rdi,[rel context]
 mov esi,NEBOC_DCE_GC_ON
 call neboc_cli_build_gc_sections
 test eax,eax
 jne .fail29
 cmp qword [rel context+NEBOC_DCE_CONTEXT_RETAINED_COUNT_OFFSET],7
 jne .fail30
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 30
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
