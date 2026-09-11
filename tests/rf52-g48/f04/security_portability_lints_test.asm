bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/lint/security_portability.inc"
global _start
extern neboc_analysis_session_new
extern neboc_lint_excessive_capability,neboc_lint_secret_in_diagnostic
extern neboc_lint_path_traversal_construction,neboc_lint_nondeterministic_build_input
extern neboc_lint_target_specific_syscall,neboc_lint_pointer_width_assumption
extern neboc_lint_endianness_assumption,neboc_lint_unchecked_narrowing
extern neboc_lint_host_path_embedded,neboc_lint_unbounded_external_input
extern neboc_lint_environment_dependent_branch,neboc_lint_nonportable_api
extern neboc_host_process_exit
%define SNAPSHOT 0x5200480400000001
section .data
compiler_snapshot: dq SNAPSHOT,1,1
options: dq 64,8,4096,cache,2
input: dq SNAPSHOT,42,7,NEBOC_SEC_ALL,NEBOC_SEC_ALL,10,20,0x55,NEBOC_ANALYSIS_COMPLETE
functions:
 dq neboc_lint_excessive_capability,neboc_lint_secret_in_diagnostic
 dq neboc_lint_path_traversal_construction,neboc_lint_nondeterministic_build_input
 dq neboc_lint_target_specific_syscall,neboc_lint_pointer_width_assumption
 dq neboc_lint_endianness_assumption,neboc_lint_unchecked_narrowing
 dq neboc_lint_host_path_embedded,neboc_lint_unbounded_external_input
 dq neboc_lint_environment_dependent_branch,neboc_lint_nonportable_api
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
 cmp ebx,NEBOC_SEC_COUNT
 jae .negative_setup
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel finding]
 lea rax,[rel functions]
 call [rax+rbx*8]
 test eax,eax
 jne .fail2
 cmp qword [rel finding+NEBOC_LINT_FINDING_PRESENT_OFFSET],1
 jne .fail3
 cmp qword [rel finding+NEBOC_LINT_FINDING_GROUP_OFFSET],NEBOC_LINT_GROUP_SECURITY_PORTABILITY
 jne .fail4
 mov rax,rbx
 inc rax
 add rax,NEBOC_SEC_CODE_BASE
 cmp [rel finding+NEBOC_LINT_FINDING_CODE_OFFSET],rax
 jne .fail5
 inc ebx
 jmp .positive
.negative_setup:
 mov qword [rel input+NEBOC_LINT_INPUT_FACTS_OFFSET],0
 xor ebx,ebx
.negative:
 cmp ebx,NEBOC_SEC_COUNT
 jae .incomplete
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel finding]
 lea rax,[rel functions]
 call [rax+rbx*8]
 test eax,eax
 jne .fail6
 cmp qword [rel finding+NEBOC_LINT_FINDING_PRESENT_OFFSET],0
 jne .fail7
 inc ebx
 jmp .negative
.incomplete:
 mov qword [rel input+NEBOC_LINT_INPUT_FACTS_OFFSET],NEBOC_SEC_ALL
 mov qword [rel input+NEBOC_LINT_INPUT_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel finding]
 call neboc_lint_unbounded_external_input
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail8
 cmp qword [rel finding+NEBOC_LINT_FINDING_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 jne .fail9
.stale:
 mov qword [rel input+NEBOC_LINT_INPUT_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 mov qword [rel compiler_snapshot],0xdead
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel finding]
 call neboc_lint_secret_in_diagnostic
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail10
 mov rax,SNAPSHOT
 mov [rel compiler_snapshot],rax
.invalid_atomic:
 mov qword [rel finding],0x51515151
 mov qword [rel input+NEBOC_LINT_INPUT_SPAN_START_OFFSET],30
 mov qword [rel input+NEBOC_LINT_INPUT_SPAN_END_OFFSET],20
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel finding]
 call neboc_lint_nonportable_api
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail11
 cmp qword [rel finding],0x51515151
 jne .fail12
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 12
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
