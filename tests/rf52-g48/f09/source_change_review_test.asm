bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/refactor/source_change_review.inc"
global _start
extern neboc_fix_plan_new
extern neboc_source_change_verify_parse,neboc_source_change_verify_semantics
extern neboc_source_change_compare_hir,neboc_source_change_compare_public_api
extern neboc_source_change_run_selected_tests,neboc_source_change_differential_run
extern neboc_source_change_review_report,neboc_lsp_code_action_from_fix_or_refactor
extern neboc_lsp_code_action_resolve,neboc_cli_change_review,neboc_cli_fix_verify
extern neboc_host_process_exit

%define SNAP 0x48090001
section .data
source: db 'safe'
backup: times 4 db 0
sources: dq 1,0x901,0x901,source,4,backup,4
source_set: dq sources,1
refactor_stub: dq 0x7777
base_change:
 dq SNAP,SNAP,plan,refactor_stub,1
 dq NEBOC_VERIFY_PASS,NEBOC_VERIFY_PASS
 dq 0x1111,0x1111,0x2222,0x2222,0x3333,0x3333
 dq NEBOC_HIR_EQUIVALENCE_REQUIRED,NEBOC_REFACTOR_API_COMPATIBLE
 dq NEBOC_VERIFY_PASS,2,NEBOC_VERIFY_PASS,3,0x4444,0x4444
 dq 0,0,0,1

section .bss align=16
plan: resb NEBOC_FIX_PLAN_SIZE
edits: resb NEBOC_FIX_EDIT_SIZE
journal: resb NEBOC_FIX_JOURNAL_SIZE
change: resb NEBOC_CHANGE_SIZE
breaking: resb NEBOC_CHANGE_SIZE
timeout_change: resb NEBOC_CHANGE_SIZE
mismatch: resb NEBOC_CHANGE_SIZE
report: resb NEBOC_REVIEW_SIZE
action_fix: resb NEBOC_ACTION_SIZE
action_refactor: resb NEBOC_ACTION_SIZE

section .text
_start:
 sub rsp,8
 lea rdi,[rel plan]
 lea rsi,[rel source_set]
 lea rdx,[rel edits]
 mov ecx,1
 lea r8,[rel journal]
 mov r9d,1
 call neboc_fix_plan_new
 test eax,eax
 jne .fail1
 lea rsi,[rel base_change]
 lea rdi,[rel change]
 mov ecx,NEBOC_CHANGE_SIZE/8
 rep movsq
 lea rsi,[rel base_change]
 lea rdi,[rel breaking]
 mov ecx,NEBOC_CHANGE_SIZE/8
 rep movsq
 lea rsi,[rel base_change]
 lea rdi,[rel timeout_change]
 mov ecx,NEBOC_CHANGE_SIZE/8
 rep movsq
 lea rsi,[rel base_change]
 lea rdi,[rel mismatch]
 mov ecx,NEBOC_CHANGE_SIZE/8
 rep movsq

 ; The highest CLI level selects the complete bounded verification chain.
 lea rdi,[rel change]
 mov esi,NEBOC_VERIFY_LEVEL_DIFFERENTIAL
 call neboc_cli_fix_verify
 test eax,eax
 jne .fail2
 cmp qword [rel change+NEBOC_CHANGE_VERIFIED_OFFSET],NEBOC_VERIFY_ALL
 jne .fail3
 lea rdi,[rel change]
 lea rsi,[rel report]
 call neboc_cli_change_review
 test eax,eax
 jne .fail4
 cmp qword [rel report+NEBOC_REVIEW_DECISION_OFFSET],NEBOC_REVIEW_AUTO_ELIGIBLE
 jne .fail5
 cmp qword [rel report+NEBOC_REVIEW_CONFIDENCE_OFFSET],100
 jne .fail6
 cmp qword [rel report+NEBOC_REVIEW_BOUNDED_OFFSET],1
 jne .fail7

 ; LSP fix and refactor actions carry the exact same plan and snapshot.
 lea rdi,[rel change]
 lea rsi,[rel action_fix]
 mov edx,NEBOC_ACTION_FIX
 call neboc_lsp_code_action_from_fix_or_refactor
 test eax,eax
 jne .fail8
 lea rdi,[rel change]
 lea rsi,[rel action_refactor]
 mov edx,NEBOC_ACTION_REFACTOR
 call neboc_lsp_code_action_from_fix_or_refactor
 test eax,eax
 jne .fail9
 mov rax,[rel action_fix+NEBOC_ACTION_FIX_PLAN_OFFSET]
 cmp rax,[rel action_refactor+NEBOC_ACTION_FIX_PLAN_OFFSET]
 jne .fail10
 lea rdi,[rel action_fix]
 mov rsi,SNAP
 call neboc_lsp_code_action_resolve
 test eax,eax
 jne .fail11
 cmp qword [rel action_fix+NEBOC_ACTION_RESOLVED_OFFSET],1
 jne .fail12
 lea rdi,[rel action_refactor]
 mov esi,0xdead
 call neboc_lsp_code_action_resolve
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail13

 ; Breaking API remains reviewable but never auto-eligible.
 mov qword [rel breaking+NEBOC_CHANGE_API_IMPACT_OFFSET],NEBOC_REFACTOR_API_BREAKING
 lea rdi,[rel breaking]
 mov esi,NEBOC_VERIFY_LEVEL_DIFFERENTIAL
 call neboc_cli_fix_verify
 test eax,eax
 jne .fail14
 lea rdi,[rel breaking]
 lea rsi,[rel report]
 call neboc_source_change_review_report
 test eax,eax
 jne .fail15
 cmp qword [rel report+NEBOC_REVIEW_DECISION_OFFSET],NEBOC_REVIEW_MANUAL_REQUIRED
 jne .fail16

 ; Timeout/unknown and semantic mismatch reject bounded auto-apply.
 mov qword [rel timeout_change+NEBOC_CHANGE_DIFF_STATUS_OFFSET],NEBOC_VERIFY_TIMEOUT
 lea rdi,[rel timeout_change]
 call neboc_source_change_differential_run
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail17
 cmp qword [rel timeout_change+NEBOC_CHANGE_DECISION_OFFSET],NEBOC_REVIEW_REJECTED
 jne .fail18
 mov qword [rel mismatch+NEBOC_CHANGE_SEM_AFTER_OFFSET],0x9999
 lea rdi,[rel mismatch]
 call neboc_source_change_verify_semantics
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail19

 ; Individual surfaces remain independently callable and source is untouched.
 lea rdi,[rel change]
 call neboc_source_change_verify_parse
 test eax,eax
 jne .fail20
 lea rdi,[rel change]
 call neboc_source_change_verify_semantics
 test eax,eax
 jne .fail21
 lea rdi,[rel change]
 call neboc_source_change_compare_hir
 test eax,eax
 jne .fail22
 lea rdi,[rel change]
 call neboc_source_change_compare_public_api
 test eax,eax
 jne .fail23
 lea rdi,[rel change]
 call neboc_source_change_run_selected_tests
 test eax,eax
 jne .fail24
 lea rdi,[rel change]
 call neboc_source_change_differential_run
 test eax,eax
 jne .fail25
 cmp dword [rel source],0x65666173
 jne .fail26
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 26
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
