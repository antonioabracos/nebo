; CORRECTNESS-F02 true/false-positive, incomplete and stale lint tests.
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/lint/correctness.inc"
global _start
extern neboc_analysis_session_new
extern neboc_lint_unused_binding
extern neboc_lint_unused_import
extern neboc_lint_unreachable_code
extern neboc_lint_ignored_result
extern neboc_lint_impossible_condition
extern neboc_lint_partial_match
extern neboc_lint_suspicious_shadowing
extern neboc_lint_resource_may_leak
extern neboc_lint_use_after_move_risk
extern neboc_lint_constant_overflow
extern neboc_lint_float_equality
extern neboc_lint_nonexhaustive_error_handling
extern neboc_host_process_exit
%define SNAPSHOT 0x5200480200000001
section .data
compiler_snapshot: dq SNAPSHOT,1,1
options: dq 64,8,4096,cache,2
input: dq SNAPSHOT,42,7,NEBOC_LINT_ALL_CORRECTNESS,NEBOC_LINT_ALL_CORRECTNESS,10,20,99,NEBOC_ANALYSIS_COMPLETE
functions:
 dq neboc_lint_unused_binding,neboc_lint_unused_import,neboc_lint_unreachable_code
 dq neboc_lint_ignored_result,neboc_lint_impossible_condition,neboc_lint_partial_match
 dq neboc_lint_suspicious_shadowing,neboc_lint_resource_may_leak,neboc_lint_use_after_move_risk
 dq neboc_lint_constant_overflow,neboc_lint_float_equality,neboc_lint_nonexhaustive_error_handling
section .bss align=16
session: resb NEBOC_ANALYSIS_SESSION_SIZE
cache: resb NEBOC_ANALYSIS_QUERY_ENTRY_SIZE*2
finding: resb NEBOC_LINT_FINDING_SIZE
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
.positive:
 cmp ebx,NEBOC_LINT_CORRECTNESS_COUNT
 jae .false_setup
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel finding]
 lea rax,[rel functions]
 call [rax+rbx*8]
 test eax,eax
 jne .fail2
 cmp qword [rel finding+NEBOC_LINT_FINDING_PRESENT_OFFSET],1
 jne .fail3
 mov rax,rbx
 inc rax
 cmp [rel finding+NEBOC_LINT_FINDING_RULE_OFFSET],rax
 jne .fail4
 add rax,NEBOC_LINT_CODE_BASE
 cmp [rel finding+NEBOC_LINT_FINDING_CODE_OFFSET],rax
 jne .fail5
 cmp qword [rel finding+NEBOC_LINT_FINDING_SEVERITY_OFFSET],NEBOC_LINT_SEVERITY_WARNING
 jne .fail6
 cmp qword [rel finding+NEBOC_LINT_FINDING_GROUP_OFFSET],NEBOC_LINT_GROUP_CORRECTNESS
 jne .fail7
 cmp qword [rel finding+NEBOC_LINT_FINDING_SPAN_START_OFFSET],10
 jne .fail8
 cmp qword [rel finding+NEBOC_LINT_FINDING_SPAN_END_OFFSET],20
 jne .fail9
 cmp qword [rel finding+NEBOC_LINT_FINDING_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 jne .fail10
 inc ebx
 jmp .positive
.false_setup:
 mov qword [rel input+NEBOC_LINT_INPUT_FACTS_OFFSET],0
 xor ebx,ebx
.negative:
 cmp ebx,NEBOC_LINT_CORRECTNESS_COUNT
 jae .disabled
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel finding]
 lea rax,[rel functions]
 call [rax+rbx*8]
 test eax,eax
 jne .fail11
 cmp qword [rel finding+NEBOC_LINT_FINDING_PRESENT_OFFSET],0
 jne .fail12
 cmp qword [rel finding+NEBOC_LINT_FINDING_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 jne .fail13
 inc ebx
 jmp .negative
.disabled:
 mov qword [rel input+NEBOC_LINT_INPUT_FACTS_OFFSET],NEBOC_LINT_ALL_CORRECTNESS
 mov qword [rel input+NEBOC_LINT_INPUT_ENABLED_OFFSET],0
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel finding]
 call neboc_lint_unused_binding
 test eax,eax
 jne .fail14
 cmp qword [rel finding+NEBOC_LINT_FINDING_PRESENT_OFFSET],0
 jne .fail15
.incomplete:
 mov qword [rel input+NEBOC_LINT_INPUT_ENABLED_OFFSET],NEBOC_LINT_ALL_CORRECTNESS
 mov qword [rel input+NEBOC_LINT_INPUT_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel finding]
 call neboc_lint_unused_binding
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail16
 cmp qword [rel finding+NEBOC_LINT_FINDING_PRESENT_OFFSET],0
 jne .fail17
 cmp qword [rel finding+NEBOC_LINT_FINDING_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 jne .fail18
.stale:
 mov qword [rel input+NEBOC_LINT_INPUT_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 mov qword [rel compiler_snapshot+NEBOC_COMPILER_SNAPSHOT_DIGEST_OFFSET],0xdead
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel finding]
 call neboc_lint_unused_binding
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail19
 mov rax,SNAPSHOT
 mov [rel compiler_snapshot+NEBOC_COMPILER_SNAPSHOT_DIGEST_OFFSET],rax
.atomic_invalid:
 mov qword [rel finding],0x51515151
 mov qword [rel input+NEBOC_LINT_INPUT_SPAN_START_OFFSET],30
 mov qword [rel input+NEBOC_LINT_INPUT_SPAN_END_OFFSET],20
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel finding]
 call neboc_lint_unused_binding
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail20
 cmp qword [rel finding],0x51515151
 jne .fail21
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 21
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
