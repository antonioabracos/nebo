; C05-F02 exact resolved-identity oracle for unused immutable locals.
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/analysis/analysis.inc"
%include "compiler/analysis/warning_liveness.inc"
%include "compiler/lint/unused_bindings.inc"
global _start
extern neboc_analysis_session_new
extern neboc_warning_liveness_build
extern neboc_unused_immutable_local
extern neboc_host_process_exit

%define SNAPSHOT 0xC050F0200000001
section .data
compiler_snapshot: dq SNAPSHOT,1,1
options: dq 100,8,4096,query_cache,4
blocks: dq 0,0,4,2
events:
 dq 100,1,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 200,2,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 201,2,NEBOC_ANALYSIS_EVENT_USE
 dq 300,3,NEBOC_ANALYSIS_EVENT_DEFINE
function: dq SNAPSHOT,88,blocks,1,0,0,events,4,0,0
candidate: dq SNAPSHOT,1,100,0,NEBOC_UNUSED_KIND_IMMUTABLE_LOCAL,0,0x55,10,20

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

 call .lint
 test eax,eax
 jne .fail3
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],1
 jne .fail4
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_CODE_OFFSET],NEBOC_UNUSED_WARNING_IMMUTABLE_LOCAL
 jne .fail5
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_READS_OFFSET],0
 jne .fail6
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_DEFINITIONS_OFFSET],1
 jne .fail7
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_INITIALIZER_EFFECTS_OFFSET],0x55
 jne .fail8
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_REASON_OFFSET],NEBOC_UNUSED_REASON_NO_READS
 jne .fail9

 ; A read of the same resolved identity suppresses the warning.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET],2
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],200
 call .lint
 test eax,eax
 jne .fail10
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],0
 jne .fail11
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_READS_OFFSET],1
 jne .fail12

 ; A distinct identity with an identical spelling is independent.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET],3
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],300
 call .lint
 test eax,eax
 jne .fail13
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],1
 jne .fail14

 ; Incomplete analysis must never be reported as unused.
 mov qword [rel plan+NEBOC_WARNING_LIVENESS_PLAN_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 call .lint
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail15
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],0
 jne .fail16
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 jne .fail17
 call .build
 test eax,eax
 jne .fail18

 ; Candidate kind and a fabricated declaration identity fail closed.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET],NEBOC_UNUSED_KIND_MUTABLE_LOCAL
 call .lint
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail19
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET],NEBOC_UNUSED_KIND_IMMUTABLE_LOCAL
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET],4
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],400
 call .lint
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail20

 ; Snapshot invalidation rejects the fact set.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET],1
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],100
 mov qword [rel compiler_snapshot],0xdead
 call .lint
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail21
 mov rax,SNAPSHOT
 mov [rel compiler_snapshot],rax

 ; Spans and analysis inputs are not mutated.
 cmp qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SPAN_START_OFFSET],10
 jne .fail22
 cmp qword [rel events+NEBOC_ANALYSIS_EVENT_NODE_OFFSET],100
 jne .fail23
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
 call neboc_unused_immutable_local
 ret

%assign n 1
%rep 23
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
