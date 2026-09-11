bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/lint/api_maintainability.inc"
global _start
extern neboc_analysis_session_new
extern neboc_lint_public_api_break,neboc_lint_deprecated_api_use
extern neboc_lint_duplicate_branch_body,neboc_lint_excessive_cyclomatic_complexity
extern neboc_lint_deep_nesting,neboc_lint_long_function
extern neboc_lint_inconsistent_error_context,neboc_lint_unstable_public_layout
extern neboc_lint_module_cycle_risk,neboc_lint_naming_policy
extern neboc_api_baseline_capture,neboc_api_diff,neboc_cli_api_diff
extern neboc_host_process_exit
%define SNAPSHOT 0x5200480500000001
section .data
compiler_snapshot: dq SNAPSHOT,1,1
options: dq 64,8,4096,cache,2
input: dq SNAPSHOT,42,7,NEBOC_MAINT_ALL,NEBOC_MAINT_ALL,10,20,0x55,NEBOC_ANALYSIS_COMPLETE
lint_functions:
 dq neboc_lint_public_api_break,neboc_lint_deprecated_api_use
 dq neboc_lint_duplicate_branch_body,neboc_lint_excessive_cyclomatic_complexity
 dq neboc_lint_deep_nesting,neboc_lint_long_function
 dq neboc_lint_inconsistent_error_context,neboc_lint_unstable_public_layout
 dq neboc_lint_module_cycle_risk,neboc_lint_naming_policy
source_items:
 dq 1,10,20,30,40,1,0,0
 dq 2,11,21,31,41,1,1,99
source_set: dq SNAPSHOT,source_items,2,2
baseline_set: dq 0,baseline_items,0,2
current_items:
 dq 1,999,20,30,40,1,0,0
 dq 3,12,22,32,42,1,0,0
current_set: dq SNAPSHOT,current_items,2,2
unsorted_items:
 dq 3,1,1,1,1,1,0,0
 dq 1,1,1,1,1,1,0,0
unsorted_set: dq SNAPSHOT,unsorted_items,2,2
section .bss align=16
session: resb NEBOC_ANALYSIS_SESSION_SIZE
cache: resb NEBOC_ANALYSIS_QUERY_ENTRY_SIZE*2
finding: resb NEBOC_LINT_FINDING_SIZE
baseline_items: resb NEBOC_API_ITEM_SIZE*2
diff_result: resb NEBOC_API_DIFF_SIZE
section .text
_start:
 sub rsp,8
 lea rdi,[rel session]
 lea rsi,[rel compiler_snapshot]
 lea rdx,[rel options]
 call neboc_analysis_session_new
 test eax,eax
 jne .fail1
 xor ebx,ebx
.lint_positive:
 cmp ebx,NEBOC_MAINT_LINT_COUNT
 jae .lint_negative_setup
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel finding]
 lea rax,[rel lint_functions]
 call [rax+rbx*8]
 test eax,eax
 jne .fail2
 cmp qword [rel finding+NEBOC_LINT_FINDING_PRESENT_OFFSET],1
 jne .fail3
 cmp qword [rel finding+NEBOC_LINT_FINDING_GROUP_OFFSET],NEBOC_LINT_GROUP_API_MAINTAINABILITY
 jne .fail4
 inc ebx
 jmp .lint_positive
.lint_negative_setup:
 mov qword [rel input+NEBOC_LINT_INPUT_FACTS_OFFSET],0
 xor ebx,ebx
.lint_negative:
 cmp ebx,NEBOC_MAINT_LINT_COUNT
 jae .incomplete
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel finding]
 lea rax,[rel lint_functions]
 call [rax+rbx*8]
 test eax,eax
 jne .fail5
 cmp qword [rel finding+NEBOC_LINT_FINDING_PRESENT_OFFSET],0
 jne .fail6
 inc ebx
 jmp .lint_negative
.incomplete:
 mov qword [rel input+NEBOC_LINT_INPUT_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel finding]
 call neboc_lint_long_function
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail7
.stale:
 mov qword [rel input+NEBOC_LINT_INPUT_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 mov qword [rel compiler_snapshot],0xdead
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel finding]
 call neboc_lint_public_api_break
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail8
 mov rax,SNAPSHOT
 mov [rel compiler_snapshot],rax
.capture:
 lea rdi,[rel source_set]
 lea rsi,[rel baseline_set]
 call neboc_api_baseline_capture
 test eax,eax
 jne .fail9
 mov rax,SNAPSHOT
 cmp [rel baseline_set+NEBOC_API_SET_SNAPSHOT_OFFSET],rax
 jne .fail10
 cmp qword [rel baseline_set+NEBOC_API_SET_COUNT_OFFSET],2
 jne .fail11
 cmp qword [rel baseline_items+NEBOC_API_ITEM_IDENTITY_OFFSET],1
 jne .fail12
.diff_changed:
 lea rdi,[rel baseline_set]
 lea rsi,[rel current_set]
 lea rdx,[rel diff_result]
 call neboc_api_diff
 test eax,eax
 jne .fail13
 cmp qword [rel diff_result+NEBOC_API_DIFF_BREAKING_OFFSET],2
 jne .fail14
 cmp qword [rel diff_result+NEBOC_API_DIFF_ADDITIVE_OFFSET],1
 jne .fail15
 cmp qword [rel diff_result+NEBOC_API_DIFF_COMPLETE_OFFSET],1
 jne .fail16
.diff_compatible:
 lea rdi,[rel baseline_set]
 lea rsi,[rel baseline_set]
 lea rdx,[rel diff_result]
 call neboc_cli_api_diff
 test eax,eax
 jne .fail17
 cmp qword [rel diff_result+NEBOC_API_DIFF_COMPATIBLE_OFFSET],2
 jne .fail18
 cmp qword [rel diff_result+NEBOC_API_DIFF_BREAKING_OFFSET],0
 jne .fail19
.invalid_atomic:
 mov qword [rel diff_result],0x51515151
 lea rdi,[rel baseline_set]
 lea rsi,[rel unsorted_set]
 lea rdx,[rel diff_result]
 call neboc_api_diff
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail20
 cmp qword [rel diff_result],0x51515151
 jne .fail21
.bounded_atomic:
 mov qword [rel diff_result],0x62626262
 mov qword [rel current_set+NEBOC_API_SET_COUNT_OFFSET],NEBOC_API_MAX_ITEMS+1
 lea rdi,[rel baseline_set]
 lea rsi,[rel current_set]
 lea rdx,[rel diff_result]
 call neboc_api_diff
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail22
 cmp qword [rel diff_result],0x62626262
 jne .fail23
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 23
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
