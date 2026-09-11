bits 64
default rel
%include "compiler/toolchain/tool_trace.inc"
global _start
extern neboc_toolchain_trace_start,neboc_trace_record_process,neboc_trace_record_file
extern neboc_trace_record_environment,neboc_trace_record_network,neboc_trace_external_tools
extern neboc_trace_external_libraries,neboc_trace_classify_maturity
extern neboc_trace_reproducibility_inputs,neboc_trace_redact
extern neboc_cli_build_trace_tools,neboc_cli_toolchain_report
extern neboc_cli_self_contained_audit,neboc_host_process_exit
section .bss align=16
trace: resb NEBOC_TRACE_SIZE
out: resq 12
section .text
_start:
 sub rsp,8
 lea rdi,[rel trace]
 mov esi,1
 mov edx,1
 call neboc_toolchain_trace_start
 test eax,eax
 jne .fail1
 mov esi,1
 mov edx,0x111
 xor ecx,ecx
 call neboc_trace_record_process
 test eax,eax
 jne .fail2
 mov esi,2
 mov edx,0x222
 call neboc_trace_record_process
 test eax,eax
 jne .fail3
 mov esi,3
 mov edx,1
 mov ecx,1
 call neboc_trace_record_file
 test eax,eax
 jne .fail4
 mov esi,1
 mov edx,3
 call neboc_trace_record_environment
 test eax,eax
 jne .fail5
 mov esi,1
 call neboc_trace_record_network
 cmp eax,6
 jne .fail6
 lea rsi,[rel out]
 call neboc_trace_external_tools
 test eax,eax
 jne .fail7
 cmp qword [rel out],3
 jne .fail8
 cmp qword [rel out+8],2
 jne .fail9
 call neboc_trace_external_libraries
 cmp qword [rel out],0
 jne .fail10
 call neboc_trace_classify_maturity
 cmp qword [rel out],3
 jne .fail11
 call neboc_trace_reproducibility_inputs
 cmp qword [rel out],0x3f
 jne .fail12
 mov esi,1
 call neboc_trace_redact
 test eax,eax
 jne .fail13
 lea rsi,[rel out]
 call neboc_cli_build_trace_tools
 test eax,eax
 jne .fail14
 cmp qword [rel out+16],2
 jne .fail15
 lea rdi,[rel trace]
 call neboc_cli_toolchain_report
 test eax,eax
 jne .fail16
 lea rdi,[rel trace]
 lea rsi,[rel out]
 call neboc_cli_self_contained_audit
 cmp eax,6
 jne .fail17
 cmp qword [rel out],1
 jne .fail18
 mov rsi,5
 mov rdx,1
 xor ecx,ecx
 call neboc_trace_record_process
 cmp eax,4
 jne .fail19
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 19
.fail%+n: mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
