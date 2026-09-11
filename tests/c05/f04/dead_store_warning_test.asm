; C05-F04 conservative dead-store oracle.
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/analysis/analysis.inc"
%include "compiler/analysis/warning_liveness.inc"
%include "compiler/lint/unused_bindings.inc"
global _start
extern neboc_analysis_session_new
extern neboc_warning_liveness_build
extern neboc_dead_store
extern neboc_host_process_exit
%define SNAPSHOT 0xC050F0400000001
section .data
compiler_snapshot: dq SNAPSHOT,1,1
options: dq 100,8,4096,query_cache,4
blocks:
 dq 0,0,5,1
 dq 1,5,1,2
edges: dq 0,1,NEBOC_ANALYSIS_EDGE_KNOWN
events:
 dq 100,1,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 101,1,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 102,1,NEBOC_ANALYSIS_EVENT_USE
 dq 200,2,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 300,3,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 201,2,NEBOC_ANALYSIS_EVENT_USE
function: dq SNAPSHOT,90,blocks,2,edges,1,events,6,0,0
candidate: dq SNAPSHOT,1,100,0,NEBOC_UNUSED_KIND_MUTABLE_LOCAL,0,0x88,50,60
section .bss align=16
session: resb NEBOC_ANALYSIS_SESSION_SIZE
query_cache: resb NEBOC_ANALYSIS_QUERY_ENTRY_SIZE*4
cfg: resb NEBOC_ANALYSIS_CFG_SIZE
plan: resb NEBOC_WARNING_LIVENESS_PLAN_SIZE
gen_masks: resq 2
kill_masks: resq 2
in_masks: resq 2
out_masks: resq 2
finding: resb NEBOC_UNUSED_FINDING_SIZE
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
 mov qword [rel plan+NEBOC_WARNING_LIVENESS_PLAN_CAPACITY_OFFSET],2
 mov qword [rel plan+NEBOC_WARNING_LIVENESS_PLAN_MAX_ITERATIONS_OFFSET],100
 call .build
 test eax,eax
 jne .fail2
 ; Store 100 is killed by 101 before any read.
 call .lint
 test eax,eax
 jne .fail3
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],1
 jne .fail4
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_CODE_OFFSET],NEBOC_UNUSED_WARNING_DEAD_STORE
 jne .fail5
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_NODE_OFFSET],100
 jne .fail6
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_INITIALIZER_EFFECTS_OFFSET],0x88
 jne .fail7
 ; Store 101 is read before block end.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],101
 call .lint
 test eax,eax
 jne .fail8
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],0
 jne .fail9
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_READS_OFFSET],1
 jne .fail10
 ; Store 200 is live into its successor, hence conservative clean.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET],2
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],200
 call .lint
 test eax,eax
 jne .fail11
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],0
 jne .fail12
 ; Store 300 has no later read and is not live-out.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET],3
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],300
 call .lint
 test eax,eax
 jne .fail13
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],1
 jne .fail14
 ; Incomplete analysis never emits.
 mov qword [rel plan+NEBOC_WARNING_LIVENESS_PLAN_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 call .lint
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail15
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],0
 jne .fail16
 call .build
 test eax,eax
 jne .fail17
 ; A non-definition node and immutable kind fail closed.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],999
 call .lint
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail18
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],300
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET],NEBOC_UNUSED_KIND_IMMUTABLE_LOCAL
 call .lint
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail19
 cmp qword [rel events],100
 jne .fail20
 xor edi,edi
 call neboc_host_process_exit
.build:
 lea rdi,[rel session]
 lea rsi,[rel function]
 lea rdx,[rel plan]
 call neboc_warning_liveness_build
 ret
.lint:
 lea rdi,[rel session]
 lea rsi,[rel function]
 lea rdx,[rel plan]
 lea rcx,[rel candidate]
 lea r8,[rel finding]
 call neboc_dead_store
 ret
%assign n 1
%rep 20
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
