; C05-F07 bounded private function/constant/type reachability oracle.
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/analysis/analysis.inc"
%include "compiler/analysis/warning_liveness.inc"
%include "compiler/lint/unused_bindings.inc"
global _start
extern neboc_analysis_session_new
extern neboc_warning_liveness_build
extern neboc_unused_private_symbol
extern neboc_host_process_exit
%define SNAPSHOT 0xC050F0700000001
section .data
compiler_snapshot: dq SNAPSHOT,1,1
options: dq 100,8,4096,query_cache,4
blocks: dq 0,0,7,2
events:
 dq 1800,18,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 1900,19,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 1901,19,NEBOC_ANALYSIS_EVENT_USE
 dq 2000,20,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 2100,21,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 2200,22,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 2201,22,NEBOC_ANALYSIS_EVENT_DEFINE
function: dq SNAPSHOT,93,blocks,1,0,0,events,7,0,0
candidate: dq SNAPSHOT,18,1800,0,NEBOC_UNUSED_KIND_PRIVATE_FUNCTION,0,0,110,120
section .bss align=16
session: resb NEBOC_ANALYSIS_SESSION_SIZE
query_cache: resb NEBOC_ANALYSIS_QUERY_ENTRY_SIZE*4
cfg: resb NEBOC_ANALYSIS_CFG_SIZE
plan: resb NEBOC_WARNING_LIVENESS_PLAN_SIZE
gen_masks: resq 1
kill_masks: resq 1
in_masks: resq 1
out_masks: resq 1
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
 mov qword [rel plan+NEBOC_WARNING_LIVENESS_PLAN_CAPACITY_OFFSET],1
 mov qword [rel plan+NEBOC_WARNING_LIVENESS_PLAN_MAX_ITERATIONS_OFFSET],100
 call .build
 test eax,eax
 jne .fail2
 ; Unreachable private function warns.
 call .lint
 test eax,eax
 jne .fail3
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],1
 jne .fail4
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_CODE_OFFSET],NEBOC_UNUSED_WARNING_PRIVATE_SYMBOL
 jne .fail5
 ; Referenced private constant is used.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET],19
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],1900
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET],NEBOC_UNUSED_KIND_PRIVATE_CONSTANT
 call .lint
 test eax,eax
 jne .fail6
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],0
 jne .fail7
 ; Explicit root and unknown reachability are conservative clean.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET],20
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],2000
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET],NEBOC_UNUSED_KIND_PRIVATE_TYPE
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_FLAGS_OFFSET],NEBOC_UNUSED_FLAG_REACHABILITY_ROOT
 call .lint
 test eax,eax
 jne .fail8
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],0
 jne .fail9
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET],21
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],2100
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET],NEBOC_UNUSED_KIND_PRIVATE_FUNCTION
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_FLAGS_OFFSET],NEBOC_UNUSED_FLAG_UNKNOWN_REACHABILITY
 call .lint
 test eax,eax
 jne .fail10
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],0
 jne .fail11
 ; Unknown flag and multiple definitions fail closed.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_FLAGS_OFFSET],16
 call .lint
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail12
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_FLAGS_OFFSET],0
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET],22
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],2200
 call .lint
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail13
 ; Non-private kinds cannot enter.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET],NEBOC_UNUSED_KIND_REEXPORT
 call .lint
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail14
 cmp qword [rel events],1800
 jne .fail15
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
 call neboc_unused_private_symbol
 ret
%assign n 1
%rep 15
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
