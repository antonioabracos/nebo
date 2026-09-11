; C05-F06 imports, aliases and reexports with explicit semantic exemptions.
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/analysis/analysis.inc"
%include "compiler/analysis/warning_liveness.inc"
%include "compiler/lint/unused_bindings.inc"
global _start
extern neboc_analysis_session_new
extern neboc_warning_liveness_build
extern neboc_unused_module_binding
extern neboc_host_process_exit
%define SNAPSHOT 0xC050F0600000001
section .data
compiler_snapshot: dq SNAPSHOT,1,1
options: dq 100,8,4096,query_cache,4
blocks: dq 0,0,7,2
events:
 dq 1200,12,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 1300,13,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 1400,14,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 1401,14,NEBOC_ANALYSIS_EVENT_USE
 dq 1500,15,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 1600,16,NEBOC_ANALYSIS_EVENT_DEFINE
 dq 1700,17,NEBOC_ANALYSIS_EVENT_DEFINE
function: dq SNAPSHOT,92,blocks,1,0,0,events,7,0,0
candidate: dq SNAPSHOT,12,1200,0,NEBOC_UNUSED_KIND_IMPORT,0,0,90,100
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
 ; Plain unused import warns.
 call .lint
 test eax,eax
 jne .fail3
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],1
 jne .fail4
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_CODE_OFFSET],NEBOC_UNUSED_WARNING_MODULE_BINDING
 jne .fail5
 ; Explicit side-effect import is semantically used.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET],13
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],1300
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_FLAGS_OFFSET],NEBOC_UNUSED_FLAG_SIDE_EFFECT_IMPORT
 call .lint
 test eax,eax
 jne .fail6
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],0
 jne .fail7
 ; Resolved alias use is clean.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET],14
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],1400
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET],NEBOC_UNUSED_KIND_ALIAS
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_FLAGS_OFFSET],0
 call .lint
 test eax,eax
 jne .fail8
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],0
 jne .fail9
 ; Unresolved alias warns.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET],15
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],1500
 call .lint
 test eax,eax
 jne .fail10
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],1
 jne .fail11
 ; Public reexport is reachable; private unused reexport warns.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET],16
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],1600
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET],NEBOC_UNUSED_KIND_REEXPORT
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_FLAGS_OFFSET],NEBOC_UNUSED_FLAG_PUBLIC_REEXPORT
 call .lint
 test eax,eax
 jne .fail12
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],0
 jne .fail13
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET],17
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET],1700
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_FLAGS_OFFSET],0
 call .lint
 test eax,eax
 jne .fail14
 cmp qword [rel finding+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],1
 jne .fail15
 ; A side-effect flag cannot be smuggled onto an alias.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET],NEBOC_UNUSED_KIND_ALIAS
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_FLAGS_OFFSET],NEBOC_UNUSED_FLAG_SIDE_EFFECT_IMPORT
 call .lint
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail16
 ; Local kind is outside this owner.
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET],NEBOC_UNUSED_KIND_MUTABLE_LOCAL
 mov qword [rel candidate+NEBOC_UNUSED_CANDIDATE_FLAGS_OFFSET],0
 call .lint
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail17
 cmp qword [rel events],1200
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
 call neboc_unused_module_binding
 ret
%assign n 1
%rep 18
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
