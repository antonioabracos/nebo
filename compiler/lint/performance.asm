; PERFORMANCE-F03 opt-in performance lints; estimates are never measurements.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lint/performance.inc"
section .text
perf_validate:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rdi+NEBOC_ANALYSIS_SESSION_ACTIVE_OFFSET],1
 jne .invalid
 mov rax,[rdi+NEBOC_ANALYSIS_SESSION_COMPILER_OFFSET]
 test rax,rax
 jz .invalid
 cmp qword [rax+NEBOC_COMPILER_SNAPSHOT_VALID_OFFSET],1
 jne .stale
 mov r8,[rdi+NEBOC_ANALYSIS_SESSION_SNAPSHOT_OFFSET]
 cmp [rax+NEBOC_COMPILER_SNAPSHOT_DIGEST_OFFSET],r8
 jne .stale
 cmp [rsi+NEBOC_PERF_INPUT_SNAPSHOT_OFFSET],r8
 jne .stale
 cmp qword [rsi+NEBOC_PERF_INPUT_CONFIDENCE_OFFSET],100
 ja .invalid
 mov rax,[rsi+NEBOC_PERF_INPUT_SPAN_END_OFFSET]
 cmp rax,[rsi+NEBOC_PERF_INPUT_SPAN_START_OFFSET]
 jb .invalid
 xor eax,eax
 ret
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

perf_lint_common:
 ; rdi=session, rsi=input, rdx=finding, ecx=rule
 test rdx,rdx
 jz .invalid
 cmp ecx,1
 jb .invalid
 cmp ecx,NEBOC_PERF_COUNT
 ja .invalid
 push r12
 push r13
 push r14
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 call perf_validate
 test eax,eax
 jnz .done
 mov rdi,r13
 xor eax,eax
 mov ecx,NEBOC_LINT_FINDING_SIZE/8
 rep stosq
 mov [r13+NEBOC_LINT_FINDING_RULE_OFFSET],r14
 mov rax,NEBOC_PERF_CODE_BASE
 add rax,r14
 mov [r13+NEBOC_LINT_FINDING_CODE_OFFSET],rax
 mov qword [r13+NEBOC_LINT_FINDING_SEVERITY_OFFSET],NEBOC_LINT_SEVERITY_WARNING
 mov qword [r13+NEBOC_LINT_FINDING_GROUP_OFFSET],NEBOC_LINT_GROUP_PERFORMANCE
 mov rax,[r12+NEBOC_PERF_INPUT_NODE_OFFSET]
 mov [r13+NEBOC_LINT_FINDING_NODE_OFFSET],rax
 mov rax,[r12+NEBOC_PERF_INPUT_CONFIDENCE_OFFSET]
 mov [r13+NEBOC_LINT_FINDING_CONFIDENCE_OFFSET],rax
 mov rax,[r12+NEBOC_PERF_INPUT_SPAN_START_OFFSET]
 mov [r13+NEBOC_LINT_FINDING_SPAN_START_OFFSET],rax
 mov rax,[r12+NEBOC_PERF_INPUT_SPAN_END_OFFSET]
 mov [r13+NEBOC_LINT_FINDING_SPAN_END_OFFSET],rax
 mov rax,[r12+NEBOC_PERF_INPUT_COST_OFFSET]
 mov [r13+NEBOC_LINT_FINDING_RELATED_OFFSET],rax
 mov rax,[r12+NEBOC_PERF_INPUT_SNAPSHOT_OFFSET]
 mov [r13+NEBOC_LINT_FINDING_SNAPSHOT_OFFSET],rax
 cmp qword [r12+NEBOC_PERF_INPUT_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 jne .incomplete
 mov qword [r13+NEBOC_LINT_FINDING_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 mov rax,1
 mov rcx,r14
 dec rcx
 shl rax,cl
 test [r12+NEBOC_PERF_INPUT_ENABLED_OFFSET],rax
 jz .clean
 test [r12+NEBOC_PERF_INPUT_FACTS_OFFSET],rax
 jz .clean
 mov qword [r13+NEBOC_LINT_FINDING_PRESENT_OFFSET],1
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
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

%macro PERF_LINT 2
NEBOC_ABI_FUNCTION %1
 mov ecx,%2
 jmp perf_lint_common
%endmacro
PERF_LINT neboc_lint_unnecessary_clone,NEBOC_PERF_UNNECESSARY_CLONE
PERF_LINT neboc_lint_unnecessary_allocation,NEBOC_PERF_UNNECESSARY_ALLOCATION
PERF_LINT neboc_lint_redundant_materialization,NEBOC_PERF_REDUNDANT_MATERIALIZATION
PERF_LINT neboc_lint_repeated_computation,NEBOC_PERF_REPEATED_COMPUTATION
PERF_LINT neboc_lint_bounds_check_barrier,NEBOC_PERF_BOUNDS_CHECK_BARRIER
PERF_LINT neboc_lint_vectorization_blocker,NEBOC_PERF_VECTORIZATION_BLOCKER
PERF_LINT neboc_lint_noncontiguous_tensor_hot_path,NEBOC_PERF_NONCONTIGUOUS_TENSOR
PERF_LINT neboc_lint_blocking_in_async_context,NEBOC_PERF_BLOCKING_ASYNC
PERF_LINT neboc_lint_excessive_synchronization,NEBOC_PERF_EXCESSIVE_SYNC
PERF_LINT neboc_lint_repeated_serialization,NEBOC_PERF_REPEATED_SERIALIZATION
PERF_LINT neboc_lint_large_value_by_copy,NEBOC_PERF_LARGE_VALUE_COPY

NEBOC_ABI_FUNCTION neboc_lint_estimated_impact
 ; rdi=session, rsi=input, rdx=impact
 test rdx,rdx
 jz .invalid
 push r12
 push r13
 sub rsp,8
 mov r12,rsi
 mov r13,rdx
 call perf_validate
 test eax,eax
 jnz .done
 mov rdi,r13
 xor eax,eax
 mov ecx,NEBOC_PERF_IMPACT_SIZE/8
 rep stosq
 cmp qword [r12+NEBOC_PERF_INPUT_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 jne .incomplete
 mov rax,[r12+NEBOC_PERF_INPUT_COST_OFFSET]
 mov [r13+NEBOC_PERF_IMPACT_COST_OFFSET],rax
 mov rcx,NEBOC_PERF_COST_LOW
 cmp rax,10
 jb .class
 mov ecx,NEBOC_PERF_COST_MEDIUM
 cmp rax,100
 jb .class
 mov ecx,NEBOC_PERF_COST_HIGH
.class:
 mov [r13+NEBOC_PERF_IMPACT_CLASS_OFFSET],rcx
 mov rax,[r12+NEBOC_PERF_INPUT_CONFIDENCE_OFFSET]
 mov [r13+NEBOC_PERF_IMPACT_CONFIDENCE_OFFSET],rax
 mov qword [r13+NEBOC_PERF_IMPACT_REQUIRES_BENCHMARK_OFFSET],1
 mov qword [r13+NEBOC_PERF_IMPACT_MEASURED_OFFSET],0
 mov rax,[r12+NEBOC_PERF_INPUT_SNAPSHOT_OFFSET]
 mov [r13+NEBOC_PERF_IMPACT_SNAPSHOT_OFFSET],rax
 mov qword [r13+NEBOC_PERF_IMPACT_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 xor eax,eax
 jmp .done
.incomplete:
 mov qword [r13+NEBOC_PERF_IMPACT_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.done:
 add rsp,8
 pop r13
 pop r12
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
