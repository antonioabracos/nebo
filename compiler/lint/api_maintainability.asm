; API-MAINTAINABILITY-F05 semantic API and configurable maintainability lints.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lint/api_maintainability.inc"

section .text
maint_lint_common:
 ; rdi=session, rsi=typed input, rdx=finding, ecx=rule id.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp ecx,1
 jb .invalid
 cmp ecx,NEBOC_MAINT_LINT_COUNT
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
 mov rax,NEBOC_MAINT_CODE_BASE
 add rax,r14
 mov [r13+NEBOC_LINT_FINDING_CODE_OFFSET],rax
 mov qword [r13+NEBOC_LINT_FINDING_SEVERITY_OFFSET],NEBOC_LINT_SEVERITY_WARNING
 mov qword [r13+NEBOC_LINT_FINDING_GROUP_OFFSET],NEBOC_LINT_GROUP_API_MAINTAINABILITY
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

%macro MAINT_LINT 2
NEBOC_ABI_FUNCTION %1
 mov ecx,%2
 jmp maint_lint_common
%endmacro
MAINT_LINT neboc_lint_public_api_break,NEBOC_MAINT_PUBLIC_API_BREAK
MAINT_LINT neboc_lint_deprecated_api_use,NEBOC_MAINT_DEPRECATED_API_USE
MAINT_LINT neboc_lint_duplicate_branch_body,NEBOC_MAINT_DUPLICATE_BRANCH_BODY
MAINT_LINT neboc_lint_excessive_cyclomatic_complexity,NEBOC_MAINT_CYCLOMATIC_COMPLEXITY
MAINT_LINT neboc_lint_deep_nesting,NEBOC_MAINT_DEEP_NESTING
MAINT_LINT neboc_lint_long_function,NEBOC_MAINT_LONG_FUNCTION
MAINT_LINT neboc_lint_inconsistent_error_context,NEBOC_MAINT_ERROR_CONTEXT
MAINT_LINT neboc_lint_unstable_public_layout,NEBOC_MAINT_UNSTABLE_LAYOUT
MAINT_LINT neboc_lint_module_cycle_risk,NEBOC_MAINT_MODULE_CYCLE_RISK
MAINT_LINT neboc_lint_naming_policy,NEBOC_MAINT_NAMING_POLICY

NEBOC_ABI_FUNCTION neboc_api_baseline_capture
 ; rdi=current semantic API set, rsi=destination set with items/capacity.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,[r12+NEBOC_API_SET_COUNT_OFFSET]
 cmp r14,NEBOC_API_MAX_ITEMS
 ja .limit
 cmp r14,[r13+NEBOC_API_SET_CAPACITY_OFFSET]
 ja .limit
 test r14,r14
 jz .validated
 mov r15,[r12+NEBOC_API_SET_ITEMS_OFFSET]
 test r15,r15
 jz .invalid_saved
 mov rax,[r13+NEBOC_API_SET_ITEMS_OFFSET]
 test rax,rax
 jz .invalid_saved
 xor ecx,ecx
 xor r8d,r8d
.validate_items:
 mov rax,[r15+rcx]
 test rax,rax
 jz .invalid_saved
 cmp rax,r8
 jbe .invalid_saved
 mov r8,rax
 add rcx,NEBOC_API_ITEM_SIZE
 sub r14,1
 jnz .validate_items
 mov r14,[r12+NEBOC_API_SET_COUNT_OFFSET]
.validated:
 mov rax,[r12+NEBOC_API_SET_SNAPSHOT_OFFSET]
 test rax,rax
 jz .invalid_saved
 mov [r13+NEBOC_API_SET_SNAPSHOT_OFFSET],rax
 mov [r13+NEBOC_API_SET_COUNT_OFFSET],r14
 test r14,r14
 jz .ok
 mov rsi,[r12+NEBOC_API_SET_ITEMS_OFFSET]
 mov rdi,[r13+NEBOC_API_SET_ITEMS_OFFSET]
 mov rcx,r14
 shl rcx,3
 rep movsq
.ok:
 xor eax,eax
 jmp .capture_done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .capture_done
.invalid_saved:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.capture_done:
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_api_diff
 ; rdi=canonical baseline set, rsi=canonical current set, rdx=result.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rax,[r12+NEBOC_API_SET_COUNT_OFFSET]
 cmp rax,NEBOC_API_MAX_ITEMS
 ja .limit
 mov rax,[r13+NEBOC_API_SET_COUNT_OFFSET]
 cmp rax,NEBOC_API_MAX_ITEMS
 ja .limit
 xor r15d,r15d
.validate_set:
 cmp r15d,0
 jne .current_set
 mov r10,r12
 jmp .set_selected
.current_set:
 mov r10,r13
.set_selected:
 mov rcx,[r10+NEBOC_API_SET_COUNT_OFFSET]
 test rcx,rcx
 jz .set_valid
 mov r11,[r10+NEBOC_API_SET_ITEMS_OFFSET]
 test r11,r11
 jz .invalid_saved
 xor r8d,r8d
.validate_order:
 mov rax,[r11+NEBOC_API_ITEM_IDENTITY_OFFSET]
 test rax,rax
 jz .invalid_saved
 cmp rax,r8
 jbe .invalid_saved
 mov r8,rax
 add r11,NEBOC_API_ITEM_SIZE
 dec rcx
 jnz .validate_order
.set_valid:
 inc r15d
 cmp r15d,2
 jb .validate_set
 mov rdi,r14
 xor eax,eax
 mov ecx,NEBOC_API_DIFF_SIZE/8
 rep stosq
 xor r8d,r8d
 xor r9d,r9d
.merge:
 cmp r8,[r12+NEBOC_API_SET_COUNT_OFFSET]
 jae .baseline_done
 cmp r9,[r13+NEBOC_API_SET_COUNT_OFFSET]
 jae .current_done
 mov r10,[r12+NEBOC_API_SET_ITEMS_OFFSET]
 mov rax,r8
 shl rax,6
 add r10,rax
 mov r11,[r13+NEBOC_API_SET_ITEMS_OFFSET]
 mov rax,r9
 shl rax,6
 add r11,rax
 mov rax,[r10+NEBOC_API_ITEM_IDENTITY_OFFSET]
 mov rbx,[r11+NEBOC_API_ITEM_IDENTITY_OFFSET]
 cmp rax,rbx
 jb .removed
 ja .added
 inc qword [r14+NEBOC_API_DIFF_MATCHED_OFFSET]
 mov rcx,NEBOC_API_ITEM_SIGNATURE_OFFSET
.compare_contract:
 mov rax,[r10+rcx]
 cmp rax,[r11+rcx]
 jne .changed
 add rcx,8
 cmp rcx,NEBOC_API_ITEM_DEPRECATED_OFFSET
 jb .compare_contract
 inc qword [r14+NEBOC_API_DIFF_COMPATIBLE_OFFSET]
 jmp .advance_both
.changed:
 mov rax,[r10+NEBOC_API_ITEM_IDENTITY_OFFSET]
 inc qword [r14+NEBOC_API_DIFF_BREAKING_OFFSET]
 cmp qword [r14+NEBOC_API_DIFF_FIRST_BREAKING_OFFSET],0
 jne .advance_both
 mov [r14+NEBOC_API_DIFF_FIRST_BREAKING_OFFSET],rax
.advance_both:
 inc r8
 inc r9
 jmp .merge
.removed:
 mov rax,[r10+NEBOC_API_ITEM_IDENTITY_OFFSET]
 inc qword [r14+NEBOC_API_DIFF_BREAKING_OFFSET]
 cmp qword [r14+NEBOC_API_DIFF_FIRST_BREAKING_OFFSET],0
 jne .removed_advance
 mov [r14+NEBOC_API_DIFF_FIRST_BREAKING_OFFSET],rax
.removed_advance:
 inc r8
 jmp .merge
.added:
 mov rax,[r11+NEBOC_API_ITEM_IDENTITY_OFFSET]
 inc qword [r14+NEBOC_API_DIFF_ADDITIVE_OFFSET]
 cmp qword [r14+NEBOC_API_DIFF_FIRST_ADDITIVE_OFFSET],0
 jne .added_advance
 mov [r14+NEBOC_API_DIFF_FIRST_ADDITIVE_OFFSET],rax
.added_advance:
 inc r9
 jmp .merge
.baseline_done:
 cmp r9,[r13+NEBOC_API_SET_COUNT_OFFSET]
 jae .complete
 mov r11,[r13+NEBOC_API_SET_ITEMS_OFFSET]
 mov rax,r9
 shl rax,6
 mov rax,[r11+rax+NEBOC_API_ITEM_IDENTITY_OFFSET]
 inc qword [r14+NEBOC_API_DIFF_ADDITIVE_OFFSET]
 cmp qword [r14+NEBOC_API_DIFF_FIRST_ADDITIVE_OFFSET],0
 jne .baseline_advance
 mov [r14+NEBOC_API_DIFF_FIRST_ADDITIVE_OFFSET],rax
.baseline_advance:
 inc r9
 jmp .baseline_done
.current_done:
 cmp r8,[r12+NEBOC_API_SET_COUNT_OFFSET]
 jae .complete
 mov r10,[r12+NEBOC_API_SET_ITEMS_OFFSET]
 mov rax,r8
 shl rax,6
 mov rax,[r10+rax+NEBOC_API_ITEM_IDENTITY_OFFSET]
 inc qword [r14+NEBOC_API_DIFF_BREAKING_OFFSET]
 cmp qword [r14+NEBOC_API_DIFF_FIRST_BREAKING_OFFSET],0
 jne .current_advance
 mov [r14+NEBOC_API_DIFF_FIRST_BREAKING_OFFSET],rax
.current_advance:
 inc r8
 jmp .current_done
.complete:
 mov qword [r14+NEBOC_API_DIFF_COMPLETE_OFFSET],1
 xor eax,eax
 jmp .diff_done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .diff_done
.invalid_saved:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.diff_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_api_diff
 ; Bounded local CLI backend. Parsing/filesystem integration is outside this ABI.
 jmp neboc_api_diff

section .note.GNU-stack noalloc noexec nowrite progbits
