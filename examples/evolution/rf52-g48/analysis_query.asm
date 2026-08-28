; ANALYSIS-F01 native composition: snapshot-bound memoized analysis query.
bits 64
default rel
%include "compiler/analysis/analysis.inc"
global _start
extern neboc_analysis_session_new
extern neboc_analysis_query
extern neboc_host_process_exit
%define SNAPSHOT 0x5200480100000001
section .data
compiler_snapshot: dq SNAPSHOT,1,1
options: dq 32,8,4096,cache,2
key: dq 1,SNAPSHOT,2,3,1
section .bss align=16
session: resb NEBOC_ANALYSIS_SESSION_SIZE
cache: resb NEBOC_ANALYSIS_QUERY_ENTRY_SIZE*2
result: resb NEBOC_ANALYSIS_QUERY_RESULT_SIZE
section .text
_start:
 sub rsp,8
 lea rdi,[rel session]
 lea rsi,[rel compiler_snapshot]
 lea rdx,[rel options]
 call neboc_analysis_session_new
 test eax,eax
 jne .fail
 lea rdi,[rel session]
 lea rsi,[rel key]
 lea rdx,[rel result]
 call neboc_analysis_query
 test eax,eax
 jne .fail
 cmp qword [rel result+NEBOC_ANALYSIS_QUERY_RESULT_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 jne .fail
 xor edi,edi
 call neboc_host_process_exit
.fail:
 mov edi,1
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
