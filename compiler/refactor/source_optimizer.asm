; SOURCE-OPTIMIZER-F08 explicit bounded source optimizer and edition modernizer.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/refactor/source_optimizer.inc"

extern neboc_fix_plan_add,neboc_fix_plan_order_canonical
extern neboc_fix_plan_validate_current_sources,neboc_fix_plan_preview
extern neboc_fix_plan_apply,neboc_fix_plan_recheck,neboc_fix_plan_rollback

section .text
NEBOC_ABI_FUNCTION neboc_source_optimizer_new
 ; rdi=optimizer, rsi=config.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rsi+NEBOC_SOURCE_CONFIG_PROFILE_OFFSET],NEBOC_SOURCE_PROFILE_V1
 jne .invalid
 mov rax,[rsi+NEBOC_SOURCE_CONFIG_LIMIT_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,NEBOC_SOURCE_MAX_CANDIDATES
 ja .limit
 mov rdx,[rsi+NEBOC_SOURCE_CONFIG_COUNT_OFFSET]
 cmp rdx,rax
 ja .limit
 test rdx,rdx
 jz .candidates_ok
 cmp qword [rsi+NEBOC_SOURCE_CONFIG_CANDIDATES_OFFSET],0
 je .invalid
.candidates_ok:
 mov rax,[rsi+NEBOC_SOURCE_CONFIG_SNAPSHOT_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,[rsi+NEBOC_SOURCE_CONFIG_CURRENT_OFFSET]
 jne .stale
 cmp qword [rsi+NEBOC_SOURCE_CONFIG_FIX_PLAN_OFFSET],0
 je .invalid
 mov rax,[rsi+NEBOC_SOURCE_CONFIG_PROFILE_OFFSET]
 mov [rdi+NEBOC_SOURCE_OPT_PROFILE_OFFSET],rax
 mov rax,[rsi+NEBOC_SOURCE_CONFIG_LIMIT_OFFSET]
 mov [rdi+NEBOC_SOURCE_OPT_LIMIT_OFFSET],rax
 mov rax,[rsi+NEBOC_SOURCE_CONFIG_SNAPSHOT_OFFSET]
 mov [rdi+NEBOC_SOURCE_OPT_SNAPSHOT_OFFSET],rax
 mov rax,[rsi+NEBOC_SOURCE_CONFIG_CURRENT_OFFSET]
 mov [rdi+NEBOC_SOURCE_OPT_CURRENT_OFFSET],rax
 mov rax,[rsi+NEBOC_SOURCE_CONFIG_TARGET_OFFSET]
 mov [rdi+NEBOC_SOURCE_OPT_TARGET_OFFSET],rax
 mov rax,[rsi+NEBOC_SOURCE_CONFIG_FIX_PLAN_OFFSET]
 mov [rdi+NEBOC_SOURCE_OPT_FIX_PLAN_OFFSET],rax
 mov rax,[rsi+NEBOC_SOURCE_CONFIG_CANDIDATES_OFFSET]
 mov [rdi+NEBOC_SOURCE_OPT_CANDIDATES_OFFSET],rax
 mov rax,[rsi+NEBOC_SOURCE_CONFIG_COUNT_OFFSET]
 mov [rdi+NEBOC_SOURCE_OPT_COUNT_OFFSET],rax
 mov qword [rdi+NEBOC_SOURCE_OPT_EXECUTED_OFFSET],0
 mov qword [rdi+NEBOC_SOURCE_OPT_SELECTED_OFFSET],0
 mov qword [rdi+NEBOC_SOURCE_OPT_SKIPPED_OFFSET],0
 mov rax,[rsi+NEBOC_SOURCE_CONFIG_COMMENT_POLICY_OFFSET]
 mov [rdi+NEBOC_SOURCE_OPT_COMMENT_POLICY_OFFSET],rax
 mov rax,[rsi+NEBOC_SOURCE_CONFIG_FROM_EDITION_OFFSET]
 mov [rdi+NEBOC_SOURCE_OPT_FROM_EDITION_OFFSET],rax
 mov rax,[rsi+NEBOC_SOURCE_CONFIG_TO_EDITION_OFFSET]
 mov [rdi+NEBOC_SOURCE_OPT_TO_EDITION_OFFSET],rax
 mov rax,[rsi+NEBOC_SOURCE_CONFIG_MIGRATION_SET_OFFSET]
 mov [rdi+NEBOC_SOURCE_OPT_MIGRATION_SET_OFFSET],rax
 mov qword [rdi+NEBOC_SOURCE_OPT_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

source_pass_common:
 ; rdi=optimizer, ecx=pass, edx=required fact mask.
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_SOURCE_OPT_ACTIVE_OFFSET],1
 jne .invalid
 mov rax,[rdi+NEBOC_SOURCE_OPT_SNAPSHOT_OFFSET]
 cmp rax,[rdi+NEBOC_SOURCE_OPT_CURRENT_OFFSET]
 jne .stale
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rcx
 mov r13,rdx
 mov rax,1
 mov rcx,r12
 dec rcx
 shl rax,cl
 test [rbx+NEBOC_SOURCE_OPT_EXECUTED_OFFSET],rax
 jnz .invalid_saved
 mov r14,[rbx+NEBOC_SOURCE_OPT_CANDIDATES_OFFSET]
 xor r15d,r15d
.loop:
 cmp r15,[rbx+NEBOC_SOURCE_OPT_COUNT_OFFSET]
 jae .complete
 mov r10,r15
 imul r10,NEBOC_SOURCE_CANDIDATE_SIZE
 add r10,r14
 cmp [r10+NEBOC_SOURCE_CANDIDATE_PASS_OFFSET],r12
 jne .next
 cmp qword [r10+NEBOC_SOURCE_CANDIDATE_NODE_OFFSET],0
 je .invalid_saved
 mov rax,[r10+NEBOC_SOURCE_CANDIDATE_FACTS_OFFSET]
 mov r11,rax
 and r11,r13
 cmp r11,r13
 jne .skip
 test rax,NEBOC_SOURCE_FACT_TARGET_DEPENDENT
 jz .target_ok
 cmp qword [rbx+NEBOC_SOURCE_OPT_TARGET_OFFSET],0
 je .skip
.target_ok:
 mov rsi,[r10+NEBOC_SOURCE_CANDIDATE_EDIT_OFFSET]
 test rsi,rsi
 jz .invalid_saved
 mov rdi,[rbx+NEBOC_SOURCE_OPT_FIX_PLAN_OFFSET]
 call neboc_fix_plan_add
 test eax,eax
 jnz .done
 inc qword [rbx+NEBOC_SOURCE_OPT_SELECTED_OFFSET]
 jmp .next
.skip:
 inc qword [rbx+NEBOC_SOURCE_OPT_SKIPPED_OFFSET]
.next:
 inc r15
 jmp .loop
.complete:
 mov rax,1
 mov rcx,r12
 dec rcx
 shl rax,cl
 or [rbx+NEBOC_SOURCE_OPT_EXECUTED_OFFSET],rax
 xor eax,eax
 jmp .done
.invalid_saved:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

%macro SOURCE_PASS 3
NEBOC_ABI_FUNCTION %1
 mov ecx,%2
 mov edx,%3
 jmp source_pass_common
%endmacro
SOURCE_PASS neboc_source_optimizer_simplify_constants,NEBOC_SOURCE_PASS_CONSTANTS,(NEBOC_SOURCE_FACT_SEMANTICS|NEBOC_SOURCE_FACT_DIAGNOSTICS)
SOURCE_PASS neboc_source_optimizer_simplify_control_flow,NEBOC_SOURCE_PASS_CONTROL_FLOW,(NEBOC_SOURCE_FACT_SEMANTICS|NEBOC_SOURCE_FACT_DIAGNOSTICS|NEBOC_SOURCE_FACT_EFFECTS|NEBOC_SOURCE_FACT_EVALUATION_ORDER|NEBOC_SOURCE_FACT_CLEANUP)
SOURCE_PASS neboc_source_optimizer_remove_dead_bindings,NEBOC_SOURCE_PASS_DEAD_BINDINGS,(NEBOC_SOURCE_FACT_SEMANTICS|NEBOC_SOURCE_FACT_EFFECTS|NEBOC_SOURCE_FACT_OWNERSHIP|NEBOC_SOURCE_FACT_CLEANUP|NEBOC_SOURCE_FACT_DEAD_PRIVATE)
SOURCE_PASS neboc_source_optimizer_canonicalize_loops,NEBOC_SOURCE_PASS_LOOPS,(NEBOC_SOURCE_FACT_SEMANTICS|NEBOC_SOURCE_FACT_EVALUATION_ORDER|NEBOC_SOURCE_FACT_CLEANUP|NEBOC_SOURCE_FACT_BOUNDS)
SOURCE_PASS neboc_source_optimizer_merge_equivalent_branches,NEBOC_SOURCE_PASS_EQUIVALENT_BRANCHES,(NEBOC_SOURCE_FACT_SEMANTICS|NEBOC_SOURCE_FACT_EFFECTS|NEBOC_SOURCE_FACT_EVALUATION_ORDER|NEBOC_SOURCE_FACT_CLEANUP|NEBOC_SOURCE_FACT_BRANCH_EQUIVALENCE)

NEBOC_ABI_FUNCTION neboc_source_optimizer_rewrite_deprecated_apis
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_SOURCE_OPT_MIGRATION_SET_OFFSET],0
 je .invalid
 mov ecx,NEBOC_SOURCE_PASS_DEPRECATED_APIS
 mov edx,(NEBOC_SOURCE_FACT_SEMANTICS|NEBOC_SOURCE_FACT_MIGRATION_VERIFIED|NEBOC_SOURCE_FACT_ATTACHMENTS)
 jmp source_pass_common
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_source_optimizer_upgrade_edition
 test rdi,rdi
 jz .invalid
 mov rax,[rdi+NEBOC_SOURCE_OPT_FROM_EDITION_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,[rdi+NEBOC_SOURCE_OPT_TO_EDITION_OFFSET]
 jae .invalid
 mov ecx,NEBOC_SOURCE_PASS_EDITION
 mov edx,(NEBOC_SOURCE_FACT_SEMANTICS|NEBOC_SOURCE_FACT_EDITION_APPROVED|NEBOC_SOURCE_FACT_ATTACHMENTS)
 jmp source_pass_common
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_source_optimizer_preserve_comments
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_SOURCE_OPT_ACTIVE_OFFSET],1
 jne .invalid
 cmp qword [rdi+NEBOC_SOURCE_OPT_COMMENT_POLICY_OFFSET],NEBOC_SOURCE_COMMENT_PRESERVE
 jne .invalid
 or qword [rdi+NEBOC_SOURCE_OPT_EXECUTED_OFFSET],(1 << (NEBOC_SOURCE_PASS_COMMENTS-1))
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_source_optimizer_report
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_SOURCE_OPT_EXECUTED_OFFSET]
 mov [rsi+NEBOC_SOURCE_REPORT_EXECUTED_OFFSET],rax
 mov rax,[rdi+NEBOC_SOURCE_OPT_SELECTED_OFFSET]
 mov [rsi+NEBOC_SOURCE_REPORT_SELECTED_OFFSET],rax
 mov rax,[rdi+NEBOC_SOURCE_OPT_SKIPPED_OFFSET]
 mov [rsi+NEBOC_SOURCE_REPORT_SKIPPED_OFFSET],rax
 mov rax,[rdi+NEBOC_SOURCE_OPT_TARGET_OFFSET]
 mov [rsi+NEBOC_SOURCE_REPORT_TARGET_OFFSET],rax
 mov rax,[rdi+NEBOC_SOURCE_OPT_FROM_EDITION_OFFSET]
 mov [rsi+NEBOC_SOURCE_REPORT_FROM_EDITION_OFFSET],rax
 mov rax,[rdi+NEBOC_SOURCE_OPT_TO_EDITION_OFFSET]
 mov [rsi+NEBOC_SOURCE_REPORT_TO_EDITION_OFFSET],rax
 mov rax,[rdi+NEBOC_SOURCE_OPT_COMMENT_POLICY_OFFSET]
 mov [rsi+NEBOC_SOURCE_REPORT_COMMENT_POLICY_OFFSET],rax
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

source_optimizer_prepare_plan:
 mov rdi,[rdi+NEBOC_SOURCE_OPT_FIX_PLAN_OFFSET]
 push rdi
 call neboc_fix_plan_order_canonical
 pop rdi
 test eax,eax
 jnz .done
 call neboc_fix_plan_validate_current_sources
.done:
 ret

NEBOC_ABI_FUNCTION neboc_cli_source_optimize_check
 test rdi,rdi
 jz .invalid
 push rdi
 call source_optimizer_prepare_plan
 pop rdi
 test eax,eax
 jnz .done
 mov rdi,[rdi+NEBOC_SOURCE_OPT_FIX_PLAN_OFFSET]
 cmp qword [rdi+NEBOC_FIX_PLAN_EDIT_COUNT_OFFSET],0
 je .done
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_source_optimize
 ; rdi=optimizer,rsi=mode,rdx=preview,rcx=capability,r8=policy,r9=recheck status.
 test rdi,rdi
 jz .invalid
 cmp rsi,NEBOC_SOURCE_CLI_APPLY
 ja .invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 mov [rsp],r9
 call source_optimizer_prepare_plan
 test eax,eax
 jnz .done
 cmp r12,NEBOC_SOURCE_CLI_APPLY
 je .apply
 mov rdi,[rbx+NEBOC_SOURCE_OPT_FIX_PLAN_OFFSET]
 mov rsi,r13
 call neboc_fix_plan_preview
 jmp .done
.apply:
 cmp r14,NEBOC_FIX_CAPABILITY_APPLY
 jne .invalid_saved
 cmp r15,NEBOC_FIX_POLICY_APPLY_CONFIRMED
 jne .invalid_saved
 cmp qword [rsp],0
 je .invalid_saved
 mov rdi,[rbx+NEBOC_SOURCE_OPT_FIX_PLAN_OFFSET]
 mov rsi,r14
 mov rdx,r15
 call neboc_fix_plan_apply
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_SOURCE_OPT_FIX_PLAN_OFFSET]
 mov rsi,[rsp]
 call neboc_fix_plan_recheck
 test eax,eax
 jz .done
 mov rdi,[rbx+NEBOC_SOURCE_OPT_FIX_PLAN_OFFSET]
 call neboc_fix_plan_rollback
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid_saved:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_modernize
 test rdi,rdi
 jz .invalid
 mov rax,[rdi+NEBOC_SOURCE_OPT_FROM_EDITION_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,[rdi+NEBOC_SOURCE_OPT_TO_EDITION_OFFSET]
 jae .invalid
 cmp qword [rdi+NEBOC_SOURCE_OPT_MIGRATION_SET_OFFSET],0
 je .invalid
 jmp neboc_cli_source_optimize
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
