; CORRECTNESS-F02 correctness lints over typed, snapshot-bound analysis facts.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lint/correctness.inc"

section .rodata
lint_confidence: db 100,100,100,100,100,95,80,90,80,100,70,90

section .text
lint_correctness_common:
 ; rdi=session, rsi=input, rdx=finding, ecx=rule id
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp ecx,1
 jb .invalid
 cmp ecx,NEBOC_LINT_CORRECTNESS_COUNT
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
 mov r10,rdx
 push rdi
 mov rdi,r10
 xor eax,eax
 mov r11,rcx
 mov ecx,NEBOC_LINT_FINDING_SIZE/8
 rep stosq
 mov rcx,r11
 pop rdi
 mov [r10+NEBOC_LINT_FINDING_RULE_OFFSET],rcx
 mov rax,NEBOC_LINT_CODE_BASE
 add rax,rcx
 mov [r10+NEBOC_LINT_FINDING_CODE_OFFSET],rax
 mov qword [r10+NEBOC_LINT_FINDING_SEVERITY_OFFSET],NEBOC_LINT_SEVERITY_WARNING
 mov qword [r10+NEBOC_LINT_FINDING_GROUP_OFFSET],NEBOC_LINT_GROUP_CORRECTNESS
 mov rax,[rsi+NEBOC_LINT_INPUT_NODE_OFFSET]
 mov [r10+NEBOC_LINT_FINDING_NODE_OFFSET],rax
 mov rax,[rsi+NEBOC_LINT_INPUT_SYMBOL_OFFSET]
 mov [r10+NEBOC_LINT_FINDING_SYMBOL_OFFSET],rax
 mov rax,[rsi+NEBOC_LINT_INPUT_SPAN_START_OFFSET]
 mov [r10+NEBOC_LINT_FINDING_SPAN_START_OFFSET],rax
 mov rax,[rsi+NEBOC_LINT_INPUT_SPAN_END_OFFSET]
 mov [r10+NEBOC_LINT_FINDING_SPAN_END_OFFSET],rax
 mov rax,[rsi+NEBOC_LINT_INPUT_RELATED_OFFSET]
 mov [r10+NEBOC_LINT_FINDING_RELATED_OFFSET],rax
 mov rax,[rsi+NEBOC_LINT_INPUT_SNAPSHOT_OFFSET]
 mov [r10+NEBOC_LINT_FINDING_SNAPSHOT_OFFSET],rax
 cmp qword [rsi+NEBOC_LINT_INPUT_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 jne .incomplete
 mov qword [r10+NEBOC_LINT_FINDING_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 mov rax,1
 dec rcx
 shl rax,cl
 test [rsi+NEBOC_LINT_INPUT_ENABLED_OFFSET],rax
 jz .clean
 test [rsi+NEBOC_LINT_INPUT_FACTS_OFFSET],rax
 jz .clean
 mov qword [r10+NEBOC_LINT_FINDING_PRESENT_OFFSET],1
 lea rax,[rel lint_confidence]
 movzx eax,byte [rax+rcx]
 mov [r10+NEBOC_LINT_FINDING_CONFIDENCE_OFFSET],rax
.clean:
 xor eax,eax
 ret
.incomplete:
 mov qword [r10+NEBOC_LINT_FINDING_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

%macro CORRECTNESS_LINT 2
NEBOC_ABI_FUNCTION %1
 mov ecx,%2
 jmp lint_correctness_common
%endmacro

CORRECTNESS_LINT neboc_lint_unused_binding,NEBOC_LINT_UNUSED_BINDING
CORRECTNESS_LINT neboc_lint_unused_import,NEBOC_LINT_UNUSED_IMPORT
CORRECTNESS_LINT neboc_lint_unreachable_code,NEBOC_LINT_UNREACHABLE_CODE
CORRECTNESS_LINT neboc_lint_ignored_result,NEBOC_LINT_IGNORED_RESULT
CORRECTNESS_LINT neboc_lint_impossible_condition,NEBOC_LINT_IMPOSSIBLE_CONDITION
CORRECTNESS_LINT neboc_lint_partial_match,NEBOC_LINT_PARTIAL_MATCH
CORRECTNESS_LINT neboc_lint_suspicious_shadowing,NEBOC_LINT_SUSPICIOUS_SHADOWING
CORRECTNESS_LINT neboc_lint_resource_may_leak,NEBOC_LINT_RESOURCE_MAY_LEAK
CORRECTNESS_LINT neboc_lint_use_after_move_risk,NEBOC_LINT_USE_AFTER_MOVE_RISK
CORRECTNESS_LINT neboc_lint_constant_overflow,NEBOC_LINT_CONSTANT_OVERFLOW
CORRECTNESS_LINT neboc_lint_float_equality,NEBOC_LINT_FLOAT_EQUALITY
CORRECTNESS_LINT neboc_lint_nonexhaustive_error_handling,NEBOC_LINT_NONEXHAUSTIVE_ERROR

section .note.GNU-stack noalloc noexec nowrite progbits
