; SOURCE-CHANGE-REVIEW-F09 bounded source-change verification and CLI/LSP parity.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/refactor/source_change_review.inc"
extern neboc_fix_plan_validate_current_sources

section .text
change_validate:
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_CHANGE_ACTIVE_OFFSET],1
 jne .invalid
 mov rax,[rdi+NEBOC_CHANGE_SNAPSHOT_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,[rdi+NEBOC_CHANGE_CURRENT_OFFSET]
 jne .stale
 cmp qword [rdi+NEBOC_CHANGE_FIX_PLAN_OFFSET],0
 je .invalid
 xor eax,eax
 ret
.stale:
 mov qword [rdi+NEBOC_CHANGE_DECISION_OFFSET],NEBOC_REVIEW_REJECTED
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

change_reject:
 mov qword [rdi+NEBOC_CHANGE_DECISION_OFFSET],NEBOC_REVIEW_REJECTED
 mov qword [rdi+NEBOC_CHANGE_CONFIDENCE_OFFSET],0
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

NEBOC_ABI_FUNCTION neboc_source_change_verify_parse
 push rdi
 call change_validate
 pop rdi
 test eax,eax
 jnz .done
 cmp qword [rdi+NEBOC_CHANGE_FILE_COUNT_OFFSET],0
 je .invalid
 cmp qword [rdi+NEBOC_CHANGE_FILE_COUNT_OFFSET],NEBOC_CHANGE_MAX_FILES
 ja .limit
 cmp qword [rdi+NEBOC_CHANGE_PARSE_BEFORE_OFFSET],NEBOC_VERIFY_PASS
 jne change_reject
 cmp qword [rdi+NEBOC_CHANGE_PARSE_AFTER_OFFSET],NEBOC_VERIFY_PASS
 jne change_reject
 or qword [rdi+NEBOC_CHANGE_VERIFIED_OFFSET],NEBOC_VERIFY_PARSE
 xor eax,eax
.done:
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret

NEBOC_ABI_FUNCTION neboc_source_change_verify_semantics
 push rdi
 call change_validate
 pop rdi
 test eax,eax
 jnz .done
 mov rax,[rdi+NEBOC_CHANGE_SEM_BEFORE_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,[rdi+NEBOC_CHANGE_SEM_AFTER_OFFSET]
 jne change_reject
 mov rax,[rdi+NEBOC_CHANGE_DIAG_BEFORE_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,[rdi+NEBOC_CHANGE_DIAG_AFTER_OFFSET]
 jne change_reject
 or qword [rdi+NEBOC_CHANGE_VERIFIED_OFFSET],NEBOC_VERIFY_SEMANTICS
 xor eax,eax
.done:
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_source_change_compare_hir
 push rdi
 call change_validate
 pop rdi
 test eax,eax
 jnz .done
 mov rax,[rdi+NEBOC_CHANGE_HIR_POLICY_OFFSET]
 cmp rax,NEBOC_HIR_EQUIVALENCE_REQUIRED
 je .required
 cmp rax,NEBOC_HIR_MANUAL_REVIEW
 jne .invalid
 mov qword [rdi+NEBOC_CHANGE_DECISION_OFFSET],NEBOC_REVIEW_MANUAL_REQUIRED
 jmp .mark
.required:
 mov rax,[rdi+NEBOC_CHANGE_HIR_BEFORE_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,[rdi+NEBOC_CHANGE_HIR_AFTER_OFFSET]
 jne change_reject
.mark:
 or qword [rdi+NEBOC_CHANGE_VERIFIED_OFFSET],NEBOC_VERIFY_HIR
 xor eax,eax
.done:
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_source_change_compare_public_api
 push rdi
 call change_validate
 pop rdi
 test eax,eax
 jnz .done
 mov rax,[rdi+NEBOC_CHANGE_API_IMPACT_OFFSET]
 cmp rax,NEBOC_REFACTOR_API_COMPATIBLE
 jb .invalid
 cmp rax,NEBOC_REFACTOR_API_BREAKING
 ja .invalid
 cmp rax,NEBOC_REFACTOR_API_BREAKING
 jne .mark
 mov qword [rdi+NEBOC_CHANGE_DECISION_OFFSET],NEBOC_REVIEW_MANUAL_REQUIRED
.mark:
 or qword [rdi+NEBOC_CHANGE_VERIFIED_OFFSET],NEBOC_VERIFY_API
 xor eax,eax
.done:
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_source_change_run_selected_tests
 push rdi
 call change_validate
 pop rdi
 test eax,eax
 jnz .done
 cmp qword [rdi+NEBOC_CHANGE_TEST_STATUS_OFFSET],NEBOC_VERIFY_PASS
 jne change_reject
 cmp qword [rdi+NEBOC_CHANGE_TEST_COUNT_OFFSET],0
 je .invalid
 cmp qword [rdi+NEBOC_CHANGE_TEST_COUNT_OFFSET],NEBOC_CHANGE_MAX_SELECTED_TESTS
 ja .limit
 or qword [rdi+NEBOC_CHANGE_VERIFIED_OFFSET],NEBOC_VERIFY_TESTS
 xor eax,eax
.done:
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret

NEBOC_ABI_FUNCTION neboc_source_change_differential_run
 push rdi
 call change_validate
 pop rdi
 test eax,eax
 jnz .done
 cmp qword [rdi+NEBOC_CHANGE_DIFF_STATUS_OFFSET],NEBOC_VERIFY_PASS
 jne change_reject
 cmp qword [rdi+NEBOC_CHANGE_DIFF_RUNS_OFFSET],0
 je .invalid
 cmp qword [rdi+NEBOC_CHANGE_DIFF_RUNS_OFFSET],NEBOC_CHANGE_MAX_DIFFERENTIAL_RUNS
 ja .limit
 mov rax,[rdi+NEBOC_CHANGE_DIFF_BEFORE_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,[rdi+NEBOC_CHANGE_DIFF_AFTER_OFFSET]
 jne change_reject
 or qword [rdi+NEBOC_CHANGE_VERIFIED_OFFSET],NEBOC_VERIFY_DIFFERENTIAL
 xor eax,eax
.done:
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret

NEBOC_ABI_FUNCTION neboc_source_change_review_report
 ; rdi=change, rsi=report.
 test rsi,rsi
 jz .invalid
 push rdi
 push rsi
 sub rsp,8
 call change_validate
 add rsp,8
 pop rsi
 pop rdi
 test eax,eax
 jnz .done
 mov rax,[rdi+NEBOC_CHANGE_VERIFIED_OFFSET]
 cmp rax,NEBOC_VERIFY_ALL
 jne change_reject
 cmp qword [rdi+NEBOC_CHANGE_DECISION_OFFSET],NEBOC_REVIEW_MANUAL_REQUIRED
 je .manual
 mov qword [rdi+NEBOC_CHANGE_DECISION_OFFSET],NEBOC_REVIEW_AUTO_ELIGIBLE
 mov qword [rdi+NEBOC_CHANGE_CONFIDENCE_OFFSET],100
 jmp .copy
.manual:
 mov qword [rdi+NEBOC_CHANGE_CONFIDENCE_OFFSET],70
.copy:
 mov rax,[rdi+NEBOC_CHANGE_VERIFIED_OFFSET]
 mov [rsi+NEBOC_REVIEW_MASK_OFFSET],rax
 mov rax,[rdi+NEBOC_CHANGE_DECISION_OFFSET]
 mov [rsi+NEBOC_REVIEW_DECISION_OFFSET],rax
 mov rax,[rdi+NEBOC_CHANGE_CONFIDENCE_OFFSET]
 mov [rsi+NEBOC_REVIEW_CONFIDENCE_OFFSET],rax
 mov rax,[rdi+NEBOC_CHANGE_API_IMPACT_OFFSET]
 mov [rsi+NEBOC_REVIEW_API_IMPACT_OFFSET],rax
 mov qword [rsi+NEBOC_REVIEW_BOUNDED_OFFSET],1
 xor eax,eax
.done:
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_lsp_code_action_from_fix_or_refactor
 ; rdi=change, rsi=action, rdx=kind.
 test rsi,rsi
 jz .invalid
 push rdi
 push rsi
 push rdx
 call change_validate
 pop rdx
 pop rsi
 pop rdi
 test eax,eax
 jnz .done
 cmp rdx,NEBOC_ACTION_FIX
 je .kind_ok
 cmp rdx,NEBOC_ACTION_REFACTOR
 jne .invalid
 cmp qword [rdi+NEBOC_CHANGE_REFACTOR_OFFSET],0
 je .invalid
.kind_ok:
 mov [rsi+NEBOC_ACTION_KIND_OFFSET],rdx
 mov rax,[rdi+NEBOC_CHANGE_FIX_PLAN_OFFSET]
 mov [rsi+NEBOC_ACTION_FIX_PLAN_OFFSET],rax
 mov rax,[rdi+NEBOC_CHANGE_REFACTOR_OFFSET]
 mov [rsi+NEBOC_ACTION_REFACTOR_OFFSET],rax
 mov rax,[rdi+NEBOC_CHANGE_SNAPSHOT_OFFSET]
 mov [rsi+NEBOC_ACTION_SNAPSHOT_OFFSET],rax
 mov qword [rsi+NEBOC_ACTION_RESOLVED_OFFSET],0
 xor eax,eax
.done:
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_lsp_code_action_resolve
 ; rdi=action, rsi=current snapshot.
 test rdi,rdi
 jz .invalid
 cmp rsi,[rdi+NEBOC_ACTION_SNAPSHOT_OFFSET]
 jne .stale
 mov rax,[rdi+NEBOC_ACTION_FIX_PLAN_OFFSET]
 test rax,rax
 jz .invalid
 push rdi
 mov rdi,rax
 call neboc_fix_plan_validate_current_sources
 pop rdi
 test eax,eax
 jnz .done
 mov qword [rdi+NEBOC_ACTION_RESOLVED_OFFSET],1
.done:
 ret
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_change_review
 jmp neboc_source_change_review_report

NEBOC_ABI_FUNCTION neboc_cli_fix_verify
 ; rdi=change, rsi=level.
 cmp rsi,NEBOC_VERIFY_LEVEL_PARSE
 jb .invalid
 cmp rsi,NEBOC_VERIFY_LEVEL_DIFFERENTIAL
 ja .invalid
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 call neboc_source_change_verify_parse
 test eax,eax
 jnz .done
 cmp r12,NEBOC_VERIFY_LEVEL_PARSE
 je .ok
 mov rdi,rbx
 call neboc_source_change_verify_semantics
 test eax,eax
 jnz .done
 mov rdi,rbx
 call neboc_source_change_compare_hir
 test eax,eax
 jnz .done
 mov rdi,rbx
 call neboc_source_change_compare_public_api
 test eax,eax
 jnz .done
 cmp r12,NEBOC_VERIFY_LEVEL_CHECK
 je .ok
 mov rdi,rbx
 call neboc_source_change_run_selected_tests
 test eax,eax
 jnz .done
 cmp r12,NEBOC_VERIFY_LEVEL_TESTS
 je .ok
 mov rdi,rbx
 call neboc_source_change_differential_run
 test eax,eax
 jnz .done
.ok:
 xor eax,eax
.done:
 pop r13
 pop r12
 pop rbx
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
