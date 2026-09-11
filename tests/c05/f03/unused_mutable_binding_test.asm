; C05-F03 unused mutable binding oracle: writes are not reads.
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/analysis/analysis.inc"
%include "compiler/analysis/warning_liveness.inc"
%include "compiler/lint/unused_bindings.inc"
global _start
extern neboc_analysis_session_new
extern neboc_warning_liveness_build
extern neboc_unused_mutable_binding
extern neboc_host_process_exit
%define SNAPSHOT 0xC050F0300000001

section .data
compiler_snapshot: dq SNAPSHOT,1,1
options: dq 100,8,4096,query_cache,4
blocks: dq 0,0,6,2
events:
 dq 400,4,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 401,4,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 500,5,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 501,5,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 502,5,NEBOC_ANALYSIS_EVENT_USE
 dq 600,6,NEBOC_ANALYSIS_EVENT_DEFINE
function: dq SNAPSHOT,89,blocks,1,0,0,events,6,0,0
candidate: dq SNAPSHOT,4,400,0,NEBOC_UNUSED_KIND_MUTABLE_LOCAL,0,0x77,30,40

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

 ; Declaration plus assignment and zero reads is unused-mutable.
 call .lint
 test eax,eax
 jne .fail3
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],1
 jne .fail4
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_KIND_OFFSET],NEBOC_UNUSED_KIND_MUTABLE_LOCAL
 jne .fail5
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_CODE_OFFSET],NEBOC_UNUSED_WARNING_MUTABLE_BINDING
 jne .fail6
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_DEFINITIONS_OFFSET],2
 jne .fail7
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_READS_OFFSET],0
 jne .fail8
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_INITIALIZER_EFFECTS_OFFSET],0x77
 jne .fail9

 ; Any read of the same identity makes the binding used.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET],5
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],500
 call .lint
 test eax,eax
 jne .fail10
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],0
 jne .fail11
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_DEFINITIONS_OFFSET],2
 jne .fail12
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_READS_OFFSET],1
 jne .fail13

 ; One-definition mutable declarations are valid and still classified.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET],6
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],600
 call .lint
 test eax,eax
 jne .fail14
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],1
 jne .fail15
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_DEFINITIONS_OFFSET],1
 jne .fail16

 ; Immutable candidates cannot enter this owner.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET],NEBOC_UNUSED_KIND_IMMUTABLE_LOCAL
 call .lint
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail17
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET],NEBOC_UNUSED_KIND_MUTABLE_LOCAL

 ; Incomplete analysis is explicit and silent.
 mov qword [rel plan+NEBOC_WARNING_LIVENESS_PLAN_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 call .lint
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail18
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],0
 jne .fail19
 call .build
 test eax,eax
 jne .fail20

 ; Declaration identity must match an actual defining event.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],601
 call .lint
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail21
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],600
 cmp qword [rel events+NEBOC_ANALYSIS_EVENT_NODE_OFFSET],400
 jne .fail22
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
 call neboc_unused_mutable_binding
 ret
%assign n 1
%rep 22
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
