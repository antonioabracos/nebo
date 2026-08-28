; CORRECTNESS-F02 native composition: typed unused-binding fact to stable finding.
bits 64
default rel
%include "compiler/lint/correctness.inc"
global _start
extern neboc_analysis_session_new
extern neboc_lint_unused_binding
extern neboc_host_process_exit
%define SNAPSHOT 0x5200480200000001
section .data
compiler_snapshot: dq SNAPSHOT,1,1
options: dq 32,8,4096,cache,1
input: dq SNAPSHOT,1,1,NEBOC_LINT_FACT_UNUSED_BINDING,NEBOC_LINT_ALL_CORRECTNESS,0,3,0,NEBOC_ANALYSIS_COMPLETE
section .bss align=16
session: resb NEBOC_ANALYSIS_SESSION_SIZE
cache: resb NEBOC_ANALYSIS_QUERY_ENTRY_SIZE
finding: resb NEBOC_LINT_FINDING_SIZE
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
 lea rsi,[rel input]
 lea rdx,[rel finding]
 call neboc_lint_unused_binding
 test eax,eax
 jne .fail
 cmp qword [rel finding+NEBOC_LINT_FINDING_PRESENT_OFFSET],1
 jne .fail
 xor edi,edi
 call neboc_host_process_exit
.fail:
 mov edi,1
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
