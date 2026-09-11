; C05-F01 persistent oracle for exact, bounded warning liveness.
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/analysis/analysis.inc"
%include "compiler/analysis/warning_liveness.inc"

global _start
extern neboc_analysis_session_new
extern neboc_warning_liveness_build
extern neboc_warning_liveness_query
extern neboc_host_process_exit

%define SNAPSHOT 0xC050F0100000001

section .data
compiler_snapshot: dq SNAPSHOT,1,1
options: dq 100,8,4096,query_cache,4
blocks:
 dq 0,0,1,1
 dq 1,1,2,1
 dq 2,3,2,1
 dq 3,5,1,2
edges:
 dq 0,1,NEBOC_ANALYSIS_EDGE_KNOWN
 dq 0,2,NEBOC_ANALYSIS_EDGE_KNOWN
 dq 1,3,NEBOC_ANALYSIS_EDGE_KNOWN
 dq 2,3,NEBOC_ANALYSIS_EDGE_KNOWN
events:
 dq 100,1,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 101,1,NEBOC_ANALYSIS_EVENT_USE
 dq 102,2,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 103,2,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 104,2,NEBOC_ANALYSIS_EVENT_USE
 dq 105,2,NEBOC_ANALYSIS_EVENT_USE
function: dq SNAPSHOT,77,blocks,4,edges,4,events,6,0,0

section .bss align=16
session: resb NEBOC_ANALYSIS_SESSION_SIZE
query_cache: resb NEBOC_ANALYSIS_QUERY_ENTRY_SIZE*4
cfg: resb NEBOC_ANALYSIS_CFG_SIZE
plan: resb NEBOC_WARNING_LIVENESS_PLAN_SIZE
gen_masks: resq 4
kill_masks: resq 4
in_masks: resq 4
out_masks: resq 4
query: resb NEBOC_WARNING_LIVENESS_QUERY_SIZE

section .text
_start:
 sub rsp,8
 lea rdi,[rel session]
 lea rsi,[rel compiler_snapshot]
 lea rdx,[rel options]
 call neboc_analysis_session_new
 test eax,eax
 jne .fail1
 lea rax,[rel cfg]
 mov [rel plan+NEBOC_WARNING_LIVENESS_PLAN_CFG_OFFSET],rax
 lea rax,[rel gen_masks]
 mov [rel plan+NEBOC_WARNING_LIVENESS_PLAN_GEN_OFFSET],rax
 lea rax,[rel kill_masks]
 mov [rel plan+NEBOC_WARNING_LIVENESS_PLAN_KILL_OFFSET],rax
 lea rax,[rel in_masks]
 mov [rel plan+NEBOC_WARNING_LIVENESS_PLAN_IN_OFFSET],rax
 lea rax,[rel out_masks]
 mov [rel plan+NEBOC_WARNING_LIVENESS_PLAN_OUT_OFFSET],rax
 mov qword [rel plan+NEBOC_WARNING_LIVENESS_PLAN_CAPACITY_OFFSET],4
 mov qword [rel plan+NEBOC_WARNING_LIVENESS_PLAN_MAX_ITERATIONS_OFFSET],100
 call .call_build
 test eax,eax
 jne .fail2
 cmp qword [rel plan+NEBOC_WARNING_LIVENESS_PLAN_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 jne .fail3
 cmp qword [rel plan+NEBOC_WARNING_LIVENESS_PLAN_BLOCK_COUNT_OFFSET],4
 jne .fail4

 ; GEN={};{s1};{};{s2}, KILL={s1};{s2};{s2};{}.
 cmp qword [rel gen_masks],0
 jne .fail5
 cmp qword [rel gen_masks+8],1
 jne .fail6
 cmp qword [rel gen_masks+16],0
 jne .fail7
 cmp qword [rel gen_masks+24],2
 jne .fail8
 cmp qword [rel kill_masks],1
 jne .fail9
 cmp qword [rel kill_masks+8],2
 jne .fail10
 cmp qword [rel kill_masks+16],2
 jne .fail11
 cmp qword [rel kill_masks+24],0
 jne .fail12

 ; IN={};{s1};{};{s2}, OUT={s1};{s2};{s2};{}.
 cmp qword [rel in_masks],0
 jne .fail13
 cmp qword [rel in_masks+8],1
 jne .fail14
 cmp qword [rel in_masks+16],0
 jne .fail15
 cmp qword [rel in_masks+24],2
 jne .fail16
 cmp qword [rel out_masks],1
 jne .fail17
 cmp qword [rel out_masks+8],2
 jne .fail18
 cmp qword [rel out_masks+16],2
 jne .fail19
 cmp qword [rel out_masks+24],0
 jne .fail20

 lea rdi,[rel session]
 lea rsi,[rel plan]
 mov edx,1
 mov ecx,2
 lea r8,[rel query]
 call neboc_warning_liveness_query
 test eax,eax
 jne .fail21
 cmp qword [rel query+NEBOC_WARNING_LIVENESS_QUERY_LIVE_IN_OFFSET],0
 jne .fail22
 cmp qword [rel query+NEBOC_WARNING_LIVENESS_QUERY_LIVE_OUT_OFFSET],1
 jne .fail23
 cmp qword [rel query+NEBOC_WARNING_LIVENESS_QUERY_GENERATED_OFFSET],0
 jne .fail24
 cmp qword [rel query+NEBOC_WARNING_LIVENESS_QUERY_KILLED_OFFSET],1
 jne .fail25

 ; Unknown edges are never silently treated as absent.
 mov qword [rel edges+NEBOC_ANALYSIS_EDGE_KIND_OFFSET],NEBOC_ANALYSIS_EDGE_UNKNOWN
 call .call_build
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail26
 mov qword [rel edges+NEBOC_ANALYSIS_EDGE_KIND_OFFSET],NEBOC_ANALYSIS_EDGE_KNOWN

 ; Symbol identity zero is invalid and identities beyond the 64-bit bound fail.
 mov qword [rel events+NEBOC_ANALYSIS_EVENT_SYMBOL_OFFSET],0
 call .call_build
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail27
 mov qword [rel events+NEBOC_ANALYSIS_EVENT_SYMBOL_OFFSET],65
 call .call_build
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail28
 mov qword [rel events+NEBOC_ANALYSIS_EVENT_SYMBOL_OFFSET],1

 ; Capacity and fixed-point exhaustion are explicit.
 mov qword [rel plan+NEBOC_WARNING_LIVENESS_PLAN_CAPACITY_OFFSET],3
 call .call_build
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail29
 mov qword [rel plan+NEBOC_WARNING_LIVENESS_PLAN_CAPACITY_OFFSET],4
 mov qword [rel plan+NEBOC_WARNING_LIVENESS_PLAN_MAX_ITERATIONS_OFFSET],1
 call .call_build
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail30
 cmp qword [rel plan+NEBOC_WARNING_LIVENESS_PLAN_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 jne .fail31
 lea rdi,[rel session]
 lea rsi,[rel plan]
 xor edx,edx
 mov ecx,1
 lea r8,[rel query]
 call neboc_warning_liveness_query
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail32

 ; Rebuild, then prove that snapshot invalidation rejects the cached plan.
 mov qword [rel plan+NEBOC_WARNING_LIVENESS_PLAN_MAX_ITERATIONS_OFFSET],100
 call .call_build
 test eax,eax
 jne .fail33
 mov qword [rel compiler_snapshot],0xdead
 lea rdi,[rel session]
 lea rsi,[rel plan]
 xor edx,edx
 mov ecx,1
 lea r8,[rel query]
 call neboc_warning_liveness_query
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail34
 mov rax,SNAPSHOT
 mov [rel compiler_snapshot],rax

 ; Query coordinates are exact and bounded.
 lea rdi,[rel session]
 lea rsi,[rel plan]
 mov edx,4
 mov ecx,1
 lea r8,[rel query]
 call neboc_warning_liveness_query
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail35
 lea rdi,[rel session]
 lea rsi,[rel plan]
 xor edx,edx
 mov ecx,65
 lea r8,[rel query]
 call neboc_warning_liveness_query
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail36

 ; CFG source structures remain byte-identical at their sentinel coordinates.
 cmp qword [rel blocks],0
 jne .fail37
 cmp qword [rel edges+8],1
 jne .fail38
 cmp qword [rel events+16],NEBOC_ANALYSIS_EVENT_DEFINE
 jne .fail39
 xor edi,edi
 call neboc_host_process_exit

.call_build:
 lea rdi,[rel session]
 lea rsi,[rel function]
 lea rdx,[rel plan]
 call neboc_warning_liveness_build
 ret

%assign n 1
%rep 39
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
