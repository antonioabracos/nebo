bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/refactor/fix_plan.inc"
global _start
extern neboc_fix_plan_new,neboc_fix_plan_add,neboc_fix_plan_order_canonical
extern neboc_fix_plan_validate_current_sources,neboc_fix_plan_preview
extern neboc_fix_plan_apply,neboc_fix_plan_rollback,neboc_fix_plan_recheck
extern neboc_fix_plan_report,neboc_cli_fix_check,neboc_cli_fix_preview,neboc_cli_fix_apply
extern neboc_host_process_exit
%define DIGEST1 0x1111
%define DIGEST2 0x2222
section .data
source1_bytes: db 'abcd'
source2_bytes: db 'wxyz'
backup1: times 4 db 0
backup2: times 4 db 0
replacement1: db 'Q'
replacement2: db 'R'
sources:
 dq 1,DIGEST1,DIGEST1,source1_bytes,4,backup1,4
 dq 2,DIGEST2,DIGEST2,source2_bytes,4,backup2,4
source_set: dq sources,2
edit2: dq 2,2,3,replacement2,1,DIGEST2,NEBOC_FIXIT_MACHINE_APPLICABLE
edit1: dq 1,1,2,replacement1,1,DIGEST1,NEBOC_FIXIT_MACHINE_APPLICABLE
conflict1: dq 1,0,2,replacement1,2,DIGEST1,NEBOC_FIXIT_MACHINE_APPLICABLE
conflict2: dq 1,1,3,replacement1,2,DIGEST1,NEBOC_FIXIT_MACHINE_APPLICABLE
bad_length: dq 1,0,2,replacement1,1,DIGEST1,NEBOC_FIXIT_MACHINE_APPLICABLE
recheck_fail: dq 1
recheck_ok: dq 0
section .bss align=16
plan: resb NEBOC_FIX_PLAN_SIZE
edits: resb NEBOC_FIX_EDIT_SIZE*4
journal: resb NEBOC_FIX_JOURNAL_SIZE*2
preview: resb NEBOC_FIX_PREVIEW_SIZE
preview_edits: resb NEBOC_FIX_EDIT_SIZE*4
report: resb NEBOC_FIX_REPORT_SIZE
conflict_plan: resb NEBOC_FIX_PLAN_SIZE
conflict_edits: resb NEBOC_FIX_EDIT_SIZE*4
conflict_journal: resb NEBOC_FIX_JOURNAL_SIZE*2
bad_plan: resb NEBOC_FIX_PLAN_SIZE
bad_edits: resb NEBOC_FIX_EDIT_SIZE*2
bad_journal: resb NEBOC_FIX_JOURNAL_SIZE*2
section .text
_start:
 sub rsp,8
 lea rdi,[rel plan]
 lea rsi,[rel source_set]
 lea rdx,[rel edits]
 mov ecx,4
 lea r8,[rel journal]
 mov r9d,2
 call neboc_fix_plan_new
 test eax,eax
 jne .fail1
 lea rdi,[rel plan]
 lea rsi,[rel edit2]
 call neboc_fix_plan_add
 test eax,eax
 jne .fail2
 lea rdi,[rel plan]
 lea rsi,[rel edit1]
 call neboc_fix_plan_add
 test eax,eax
 jne .fail3
 lea rdi,[rel plan]
 call neboc_fix_plan_order_canonical
 test eax,eax
 jne .fail4
 cmp qword [rel edits+NEBOC_FIX_EDIT_FILE_ID_OFFSET],1
 jne .fail5
 lea rdi,[rel plan]
 call neboc_fix_plan_validate_current_sources
 test eax,eax
 jne .fail6
 lea rax,[rel preview_edits]
 mov [rel preview+NEBOC_FIX_PREVIEW_EDITS_OFFSET],rax
 mov qword [rel preview+NEBOC_FIX_PREVIEW_CAPACITY_OFFSET],4
 lea rdi,[rel plan]
 lea rsi,[rel preview]
 call neboc_cli_fix_preview
 test eax,eax
 jne .fail7
 cmp qword [rel preview+NEBOC_FIX_PREVIEW_COUNT_OFFSET],2
 jne .fail8
 lea rdi,[rel plan]
 call neboc_cli_fix_check
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail9
 cmp byte [rel source1_bytes+1],'b'
 jne .fail10
.failure_injection:
 mov qword [rel plan+NEBOC_FIX_PLAN_FAILURE_AFTER_OFFSET],1
 lea rdi,[rel plan]
 mov esi,NEBOC_FIX_CAPABILITY_APPLY
 mov edx,NEBOC_FIX_POLICY_APPLY_CONFIRMED
 call neboc_cli_fix_apply
 cmp eax,NEBOC_STATUS_IO_ERROR
 jne .fail11
 cmp dword [rel source1_bytes],0x64636261
 jne .fail12
 cmp dword [rel source2_bytes],0x7a797877
 jne .fail13
.apply_success:
 mov qword [rel plan+NEBOC_FIX_PLAN_FAILURE_AFTER_OFFSET],0
 lea rdi,[rel plan]
 mov esi,NEBOC_FIX_CAPABILITY_APPLY
 mov edx,NEBOC_FIX_POLICY_APPLY_CONFIRMED
 call neboc_fix_plan_apply
 test eax,eax
 jne .fail14
 cmp byte [rel source1_bytes+1],'Q'
 jne .fail15
 cmp byte [rel source2_bytes+2],'R'
 jne .fail16
 lea rdi,[rel plan]
 lea rsi,[rel recheck_fail]
 call neboc_fix_plan_recheck
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail17
 cmp qword [rel plan+NEBOC_FIX_PLAN_JOURNAL_COUNT_OFFSET],2
 jne .fail18
 lea rdi,[rel plan]
 call neboc_fix_plan_rollback
 test eax,eax
 jne .fail19
 cmp dword [rel source1_bytes],0x64636261
 jne .fail20
.apply_and_finalize:
 lea rdi,[rel plan]
 mov esi,NEBOC_FIX_CAPABILITY_APPLY
 mov edx,NEBOC_FIX_POLICY_APPLY_CONFIRMED
 call neboc_fix_plan_apply
 test eax,eax
 jne .fail21
 lea rdi,[rel plan]
 lea rsi,[rel recheck_ok]
 call neboc_fix_plan_recheck
 test eax,eax
 jne .fail22
 lea rdi,[rel plan]
 lea rsi,[rel report]
 call neboc_fix_plan_report
 test eax,eax
 jne .fail23
 cmp qword [rel report+NEBOC_FIX_REPORT_APPLIED_OFFSET],2
 jne .fail24
 cmp qword [rel report+NEBOC_FIX_REPORT_JOURNAL_OFFSET],0
 jne .fail25
.conflicts:
 lea rdi,[rel conflict_plan]
 lea rsi,[rel source_set]
 lea rdx,[rel conflict_edits]
 mov ecx,4
 lea r8,[rel conflict_journal]
 mov r9d,2
 call neboc_fix_plan_new
 test eax,eax
 jne .fail26
 lea rdi,[rel conflict_plan]
 lea rsi,[rel conflict1]
 call neboc_fix_plan_add
 test eax,eax
 jne .fail27
 lea rdi,[rel conflict_plan]
 lea rsi,[rel conflict2]
 call neboc_fix_plan_add
 test eax,eax
 jne .fail28
 cmp qword [rel conflict_plan+NEBOC_FIX_PLAN_CONFLICTS_OFFSET],1
 jne .fail29
 lea rdi,[rel conflict_plan]
 call neboc_fix_plan_order_canonical
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail30
.unsupported_length:
 ; Restore source digests for a separate preflight-only plan.
 mov qword [rel sources+NEBOC_FIX_SOURCE_CURRENT_DIGEST_OFFSET],DIGEST1
 mov qword [rel sources+NEBOC_FIX_SOURCE_SIZE+NEBOC_FIX_SOURCE_CURRENT_DIGEST_OFFSET],DIGEST2
 lea rdi,[rel bad_plan]
 lea rsi,[rel source_set]
 lea rdx,[rel bad_edits]
 mov ecx,2
 lea r8,[rel bad_journal]
 mov r9d,2
 call neboc_fix_plan_new
 test eax,eax
 jne .fail31
 lea rdi,[rel bad_plan]
 lea rsi,[rel bad_length]
 call neboc_fix_plan_add
 test eax,eax
 jne .fail32
 lea rdi,[rel bad_plan]
 call neboc_fix_plan_order_canonical
 test eax,eax
 jne .fail33
 lea rdi,[rel bad_plan]
 call neboc_fix_plan_validate_current_sources
 cmp eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 jne .fail34
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 34
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
