bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/refactor/source_optimizer.inc"
global _start
extern neboc_fix_plan_new
extern neboc_source_optimizer_new,neboc_source_optimizer_simplify_constants
extern neboc_source_optimizer_simplify_control_flow,neboc_source_optimizer_remove_dead_bindings
extern neboc_source_optimizer_canonicalize_loops,neboc_source_optimizer_merge_equivalent_branches
extern neboc_source_optimizer_rewrite_deprecated_apis,neboc_source_optimizer_upgrade_edition
extern neboc_source_optimizer_preserve_comments,neboc_source_optimizer_report
extern neboc_cli_source_optimize_check,neboc_cli_source_optimize,neboc_cli_modernize
extern neboc_host_process_exit

section .data
s1: db '1 + 1'
s2: db 'old()'
s3: db 'v1api'
b1: times 5 db 0
b2: times 5 db 0
b3: times 5 db 0
r1: db '2    '
r2: db 'new()'
r3: db 'v2api'
sources:
 dq 1,0x81,0x81,s1,5,b1,5
 dq 2,0x82,0x82,s2,5,b2,5
 dq 3,0x83,0x83,s3,5,b3,5
source_set: dq sources,3
edit1: dq 1,0,5,r1,5,0x81,NEBOC_FIXIT_MACHINE_APPLICABLE
edit2: dq 2,0,5,r2,5,0x82,NEBOC_FIXIT_MACHINE_APPLICABLE
edit3: dq 3,0,5,r3,5,0x83,NEBOC_FIXIT_MACHINE_APPLICABLE
unsafe_edit: dq 1,0,5,r1,5,0x81,NEBOC_FIXIT_MACHINE_APPLICABLE
candidates:
 dq NEBOC_SOURCE_PASS_CONSTANTS,0x101,(NEBOC_SOURCE_FACT_SEMANTICS|NEBOC_SOURCE_FACT_DIAGNOSTICS|NEBOC_SOURCE_FACT_TARGET_DEPENDENT),edit1,1
 dq NEBOC_SOURCE_PASS_DEAD_BINDINGS,0x102,NEBOC_SOURCE_FACT_SEMANTICS,unsafe_edit,2
 dq NEBOC_SOURCE_PASS_DEPRECATED_APIS,0x103,(NEBOC_SOURCE_FACT_SEMANTICS|NEBOC_SOURCE_FACT_MIGRATION_VERIFIED|NEBOC_SOURCE_FACT_ATTACHMENTS),edit2,3
 dq NEBOC_SOURCE_PASS_EDITION,0x104,(NEBOC_SOURCE_FACT_SEMANTICS|NEBOC_SOURCE_FACT_EDITION_APPROVED|NEBOC_SOURCE_FACT_ATTACHMENTS),edit3,4
config:
 dq NEBOC_SOURCE_PROFILE_V1,4,0x8080,0x8080,0x8664,plan,candidates,4
 dq 1,2,0x9001,NEBOC_SOURCE_COMMENT_PRESERVE
recheck_fail: dq 1
recheck_ok: dq 0

section .bss align=16
plan: resb NEBOC_FIX_PLAN_SIZE
edits: resb NEBOC_FIX_EDIT_SIZE*4
journal: resb NEBOC_FIX_JOURNAL_SIZE*3
optimizer: resb NEBOC_SOURCE_OPT_SIZE
report: resb NEBOC_SOURCE_REPORT_SIZE
preview: resb NEBOC_FIX_PREVIEW_SIZE
preview_edits: resb NEBOC_FIX_EDIT_SIZE*4

section .text
_start:
 sub rsp,8
 lea rdi,[rel plan]
 lea rsi,[rel source_set]
 lea rdx,[rel edits]
 mov ecx,4
 lea r8,[rel journal]
 mov r9d,3
 call neboc_fix_plan_new
 test eax,eax
 jne .fail1
 lea rdi,[rel optimizer]
 lea rsi,[rel config]
 call neboc_source_optimizer_new
 test eax,eax
 jne .fail2
 lea rdi,[rel optimizer]
 call neboc_source_optimizer_simplify_constants
 test eax,eax
 jne .fail3
 lea rdi,[rel optimizer]
 call neboc_source_optimizer_simplify_control_flow
 test eax,eax
 jne .fail4
 lea rdi,[rel optimizer]
 call neboc_source_optimizer_remove_dead_bindings
 test eax,eax
 jne .fail5
 lea rdi,[rel optimizer]
 call neboc_source_optimizer_canonicalize_loops
 test eax,eax
 jne .fail6
 lea rdi,[rel optimizer]
 call neboc_source_optimizer_merge_equivalent_branches
 test eax,eax
 jne .fail7
 lea rdi,[rel optimizer]
 call neboc_source_optimizer_rewrite_deprecated_apis
 test eax,eax
 jne .fail8
 lea rdi,[rel optimizer]
 call neboc_source_optimizer_upgrade_edition
 test eax,eax
 jne .fail9
 lea rdi,[rel optimizer]
 call neboc_source_optimizer_preserve_comments
 test eax,eax
 jne .fail10
 lea rdi,[rel optimizer]
 lea rsi,[rel report]
 call neboc_source_optimizer_report
 test eax,eax
 jne .fail11
 cmp qword [rel report+NEBOC_SOURCE_REPORT_EXECUTED_OFFSET],0xff
 jne .fail12
 cmp qword [rel report+NEBOC_SOURCE_REPORT_SELECTED_OFFSET],3
 jne .fail13
 cmp qword [rel report+NEBOC_SOURCE_REPORT_SKIPPED_OFFSET],1
 jne .fail14
 cmp qword [rel report+NEBOC_SOURCE_REPORT_TARGET_OFFSET],0x8664
 jne .fail15
 lea rdi,[rel optimizer]
 call neboc_cli_source_optimize_check
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail16
 lea rax,[rel preview_edits]
 mov [rel preview+NEBOC_FIX_PREVIEW_EDITS_OFFSET],rax
 mov qword [rel preview+NEBOC_FIX_PREVIEW_CAPACITY_OFFSET],4
 lea rdi,[rel optimizer]
 mov esi,NEBOC_SOURCE_CLI_PREVIEW
 lea rdx,[rel preview]
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 call neboc_cli_source_optimize
 test eax,eax
 jne .fail17
 cmp qword [rel preview+NEBOC_FIX_PREVIEW_COUNT_OFFSET],3
 jne .fail18
 cmp dword [rel s1],0x202b2031
 jne .fail19
 lea rdi,[rel optimizer]
 mov esi,NEBOC_SOURCE_CLI_PREVIEW
 lea rdx,[rel preview]
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 call neboc_cli_modernize
 test eax,eax
 jne .fail20
 ; Failed formatter/check/test status rolls the whole caller-buffer set back.
 lea rdi,[rel optimizer]
 mov esi,NEBOC_SOURCE_CLI_APPLY
 xor edx,edx
 mov ecx,NEBOC_FIX_CAPABILITY_APPLY
 mov r8d,NEBOC_FIX_POLICY_APPLY_CONFIRMED
 lea r9,[rel recheck_fail]
 call neboc_cli_source_optimize
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail21
 cmp dword [rel s1],0x202b2031
 jne .fail22
 cmp dword [rel s2],0x28646c6f
 jne .fail23
 cmp dword [rel s3],0x70613176
 jne .fail24
 ; Successful status finalizes all selected transformations.
 lea rdi,[rel optimizer]
 mov esi,NEBOC_SOURCE_CLI_APPLY
 xor edx,edx
 mov ecx,NEBOC_FIX_CAPABILITY_APPLY
 mov r8d,NEBOC_FIX_POLICY_APPLY_CONFIRMED
 lea r9,[rel recheck_ok]
 call neboc_cli_source_optimize
 test eax,eax
 jne .fail25
 cmp dword [rel s1],0x20202032
 jne .fail26
 cmp dword [rel s2],0x2877656e
 jne .fail27
 cmp dword [rel s3],0x70613276
 jne .fail28
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 28
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
