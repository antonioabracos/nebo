; C05-F05 parameters, receiver and captures use resolved identities.
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/analysis/analysis.inc"
%include "compiler/analysis/warning_liveness.inc"
%include "compiler/lint/unused_bindings.inc"
global _start
extern neboc_analysis_session_new
extern neboc_warning_liveness_build
extern neboc_unused_callable_input
extern neboc_host_process_exit
%define SNAPSHOT 0xC050F0500000001
section .data
compiler_snapshot: dq SNAPSHOT,1,1
options: dq 100,8,4096,query_cache,4
blocks: dq 0,0,7,2
events:
 dq 700,7,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 800,8,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 801,8,NEBOC_ANALYSIS_EVENT_USE
 dq 900,9,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 1000,10,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 1001,10,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 1100,11,NEBOC_ANALYSIS_EVENT_DEFINE
function: dq SNAPSHOT,91,blocks,1,0,0,events,7,0,0
candidate: dq SNAPSHOT,7,700,0,NEBOC_UNUSED_KIND_PARAMETER,0,0,70,80
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
 ; Unread parameter.
 call .lint
 test eax,eax
 jne .fail3
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],1
 jne .fail4
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_KIND_OFFSET],NEBOC_UNUSED_KIND_PARAMETER
 jne .fail5
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_CODE_OFFSET],NEBOC_UNUSED_WARNING_CALLABLE_INPUT
 jne .fail6
 ; Read receiver.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET],8
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],800
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET],NEBOC_UNUSED_KIND_RECEIVER
 call .lint
 test eax,eax
 jne .fail7
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],0
 jne .fail8
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_READS_OFFSET],1
 jne .fail9
 ; Unread capture.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET],9
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],900
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET],NEBOC_UNUSED_KIND_CAPTURE
 call .lint
 test eax,eax
 jne .fail10
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],1
 jne .fail11
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_KIND_OFFSET],NEBOC_UNUSED_KIND_CAPTURE
 jne .fail12
 ; A callable input cannot have two definitions.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET],10
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],1000
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET],NEBOC_UNUSED_KIND_PARAMETER
 call .lint
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail13
 ; Local kinds cannot enter this owner.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET],11
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],1100
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET],NEBOC_UNUSED_KIND_IMMUTABLE_LOCAL
 call .lint
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail14
 ; Incomplete remains silent.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET],NEBOC_UNUSED_KIND_PARAMETER
 mov qword [rel plan+NEBOC_WARNING_LIVENESS_PLAN_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 call .lint
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail15
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],0
 jne .fail16
 call .build
 test eax,eax
 jne .fail17
 cmp qword [rel events],700
 jne .fail18
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
 call neboc_unused_callable_input
 ret
%assign n 1
%rep 18
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
