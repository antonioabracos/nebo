bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/stdlib/visual_summary_foundation.inc"
extern neboc_visual_summary_init
extern neboc_visual_summary_evaluate
extern neboc_host_process_exit
section .bss align=16
record: resb neboc_console_visual_dashboard_e_plots_RECORD_SIZE
section .text
global _start
_start:
 mov r15d,10
 xor edi,edi
 call neboc_visual_summary_init
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail
 lea rdi,[rel record]
 mov ecx,neboc_console_visual_dashboard_e_plots_RECORD_QWORDS
 xor eax,eax
 rep stosq
 mov r15d,20
 lea rdi,[rel record]
 mov esi,NEBOC_OP_SUMMARIZE
 mov edx,42
 mov ecx,2
 mov r8,0x3432
 mov r9d,neboc_console_visual_dashboard_e_plots_REQUIRED_FLAGS
 call neboc_visual_summary_init
 test eax,eax
 jnz fail
 lea rdi,[rel record]
 call neboc_visual_summary_evaluate
 test eax,eax
 jnz fail
 cmp qword [rel record+neboc_console_visual_dashboard_e_plots_RESULT_OFFSET],42
 jne fail
 mov r15d,30
 lea rdi,[rel record]
 mov ecx,neboc_console_visual_dashboard_e_plots_RECORD_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel record]
 mov esi,NEBOC_OP_SUMMARIZE
 xor edx,edx
 mov ecx,1
 mov r8,0x30
 mov r9d,neboc_console_visual_dashboard_e_plots_REQUIRED_FLAGS
 call neboc_visual_summary_init
 test eax,eax
 jne fail
 mov r15d,40
 lea rdi,[rel record]
 mov ecx,neboc_console_visual_dashboard_e_plots_RECORD_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel record]
 mov esi,NEBOC_OP_SUMMARIZE
 mov edx,255
 mov ecx,3
 mov r8,0x323535
 mov r9d,neboc_console_visual_dashboard_e_plots_REQUIRED_FLAGS
 call neboc_visual_summary_init
 test eax,eax
 jnz fail
 inc qword [rel record+neboc_console_visual_dashboard_e_plots_LITERAL_HASH_OFFSET]
 lea rdi,[rel record]
 call neboc_visual_summary_evaluate
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel record+neboc_console_visual_dashboard_e_plots_DIAGNOSTIC_OFFSET],neboc_console_visual_dashboard_e_plots_DIAG_SECURITY_codegen_stdlib_x86_64
 jne fail
 xor edi,edi
 jmp neboc_host_process_exit
fail:
 mov edi,r15d
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
