; SECURITY-PORTABILITY-F04 classification-only security/determinism/portability lints.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lint/security_portability.inc"
section .text
sec_lint_common:
 ; Reuses the F02 snapshot-bound typed fact input and finding schema.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp ecx,1
 jb .invalid
 cmp ecx,NEBOC_SEC_COUNT
 ja .invalid
 cmp qword [rdi+NEBOC_ANALYSIS_SESSION_ACTIVE_OFFSET],1
 jne .invalid
 mov r8,[rdi+NEBOC_ANALYSIS_SESSION_COMPILER_OFFSET]
 test r8,r8
 jz .invalid
 cmp qword [r8+NEBOC_COMPILER_SNAPSHOT_VALID_OFFSET],1
 jne .stale
 mov r9,[rdi+NEBOC_ANALYSIS_SESSION_SNAPSHOT_OFFSET]
 cmp [r8+NEBOC_COMPILER_SNAPSHOT_DIGEST_OFFSET],r9
 jne .stale
 cmp [rsi+NEBOC_LINT_INPUT_SNAPSHOT_OFFSET],r9
 jne .stale
 mov rax,[rsi+NEBOC_LINT_INPUT_SPAN_END_OFFSET]
 cmp rax,[rsi+NEBOC_LINT_INPUT_SPAN_START_OFFSET]
 jb .invalid
 push r12
 push r13
 push r14
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov rdi,r13
 xor eax,eax
 mov ecx,NEBOC_LINT_FINDING_SIZE/8
 rep stosq
 mov [r13+NEBOC_LINT_FINDING_RULE_OFFSET],r14
 mov rax,NEBOC_SEC_CODE_BASE
 add rax,r14
 mov [r13+NEBOC_LINT_FINDING_CODE_OFFSET],rax
 mov qword [r13+NEBOC_LINT_FINDING_SEVERITY_OFFSET],NEBOC_LINT_SEVERITY_WARNING
 mov qword [r13+NEBOC_LINT_FINDING_GROUP_OFFSET],NEBOC_LINT_GROUP_SECURITY_PORTABILITY
 mov rax,[r12+NEBOC_LINT_INPUT_NODE_OFFSET]
 mov [r13+NEBOC_LINT_FINDING_NODE_OFFSET],rax
 mov rax,[r12+NEBOC_LINT_INPUT_SYMBOL_OFFSET]
 mov [r13+NEBOC_LINT_FINDING_SYMBOL_OFFSET],rax
 mov rax,[r12+NEBOC_LINT_INPUT_SPAN_START_OFFSET]
 mov [r13+NEBOC_LINT_FINDING_SPAN_START_OFFSET],rax
 mov rax,[r12+NEBOC_LINT_INPUT_SPAN_END_OFFSET]
 mov [r13+NEBOC_LINT_FINDING_SPAN_END_OFFSET],rax
 mov rax,[r12+NEBOC_LINT_INPUT_RELATED_OFFSET]
 mov [r13+NEBOC_LINT_FINDING_RELATED_OFFSET],rax
 mov rax,[r12+NEBOC_LINT_INPUT_SNAPSHOT_OFFSET]
 mov [r13+NEBOC_LINT_FINDING_SNAPSHOT_OFFSET],rax
 cmp qword [r12+NEBOC_LINT_INPUT_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 jne .incomplete
 mov qword [r13+NEBOC_LINT_FINDING_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 mov rax,1
 mov rcx,r14
 dec rcx
 shl rax,cl
 test [r12+NEBOC_LINT_INPUT_ENABLED_OFFSET],rax
 jz .clean
 test [r12+NEBOC_LINT_INPUT_FACTS_OFFSET],rax
 jz .clean
 mov qword [r13+NEBOC_LINT_FINDING_PRESENT_OFFSET],1
 mov qword [r13+NEBOC_LINT_FINDING_CONFIDENCE_OFFSET],100
.clean:
 xor eax,eax
 jmp .done
.incomplete:
 mov qword [r13+NEBOC_LINT_FINDING_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.done:
 pop r14
 pop r13
 pop r12
 ret
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
%macro SEC_LINT 2
NEBOC_ABI_FUNCTION %1
 mov ecx,%2
 jmp sec_lint_common
%endmacro
SEC_LINT neboc_lint_excessive_capability,NEBOC_SEC_EXCESSIVE_CAPABILITY
SEC_LINT neboc_lint_secret_in_diagnostic,NEBOC_SEC_SECRET_DIAGNOSTIC
SEC_LINT neboc_lint_path_traversal_construction,NEBOC_SEC_PATH_TRAVERSAL
SEC_LINT neboc_lint_nondeterministic_build_input,NEBOC_SEC_NONDETERMINISTIC_BUILD
SEC_LINT neboc_lint_target_specific_syscall,NEBOC_SEC_TARGET_SYSCALL
SEC_LINT neboc_lint_pointer_width_assumption,NEBOC_SEC_POINTER_WIDTH
SEC_LINT neboc_lint_endianness_assumption,NEBOC_SEC_ENDIANNESS
SEC_LINT neboc_lint_unchecked_narrowing,NEBOC_SEC_UNCHECKED_NARROWING
SEC_LINT neboc_lint_host_path_embedded,NEBOC_SEC_HOST_PATH
SEC_LINT neboc_lint_unbounded_external_input,NEBOC_SEC_UNBOUNDED_INPUT
SEC_LINT neboc_lint_environment_dependent_branch,NEBOC_SEC_ENVIRONMENT_BRANCH
SEC_LINT neboc_lint_nonportable_api,NEBOC_SEC_NONPORTABLE_API
section .note.GNU-stack noalloc noexec nowrite progbits
