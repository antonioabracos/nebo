; FIX-PLAN-F06 bounded transactional fix engine over caller-owned buffers.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/refactor/fix_plan.inc"

section .text
NEBOC_ABI_FUNCTION neboc_fix_plan_new
 ; rdi=plan, rsi=source set, rdx=edit storage, rcx=edit capacity,
 ; r8=journal storage, r9=journal capacity.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rsi+NEBOC_FIX_SOURCE_SET_COUNT_OFFSET]
 cmp rax,NEBOC_FIX_MAX_FILES
 ja .limit
 test rax,rax
 jz .sources_ok
 cmp qword [rsi+NEBOC_FIX_SOURCE_SET_SOURCES_OFFSET],0
 je .invalid
.sources_ok:
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp rcx,NEBOC_FIX_MAX_EDITS
 ja .limit
 test r8,r8
 jz .invalid
 cmp r9,rax
 jb .limit
 mov r10,[rsi+NEBOC_FIX_SOURCE_SET_SOURCES_OFFSET]
 mov [rdi+NEBOC_FIX_PLAN_SOURCES_OFFSET],r10
 mov [rdi+NEBOC_FIX_PLAN_SOURCE_COUNT_OFFSET],rax
 mov [rdi+NEBOC_FIX_PLAN_EDITS_OFFSET],rdx
 mov [rdi+NEBOC_FIX_PLAN_EDIT_CAPACITY_OFFSET],rcx
 mov qword [rdi+NEBOC_FIX_PLAN_EDIT_COUNT_OFFSET],0
 mov qword [rdi+NEBOC_FIX_PLAN_CONFLICTS_OFFSET],0
 mov qword [rdi+NEBOC_FIX_PLAN_ORDERED_OFFSET],1
 mov qword [rdi+NEBOC_FIX_PLAN_APPLIED_OFFSET],0
 mov qword [rdi+NEBOC_FIX_PLAN_SKIPPED_OFFSET],0
 mov [rdi+NEBOC_FIX_PLAN_JOURNAL_OFFSET],r8
 mov [rdi+NEBOC_FIX_PLAN_JOURNAL_CAPACITY_OFFSET],r9
 mov qword [rdi+NEBOC_FIX_PLAN_JOURNAL_COUNT_OFFSET],0
 mov qword [rdi+NEBOC_FIX_PLAN_FAILURE_AFTER_OFFSET],0
 mov qword [rdi+NEBOC_FIX_PLAN_RECHECK_STATUS_OFFSET],0
 mov qword [rdi+NEBOC_FIX_PLAN_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_fix_plan_add
 ; rdi=plan, rsi=edit.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rdi+NEBOC_FIX_PLAN_ACTIVE_OFFSET],1
 jne .invalid
 cmp qword [rsi+NEBOC_FIX_EDIT_FILE_ID_OFFSET],0
 je .invalid
 mov rax,[rsi+NEBOC_FIX_EDIT_START_OFFSET]
 cmp rax,[rsi+NEBOC_FIX_EDIT_END_OFFSET]
 ja .invalid
 mov rax,[rsi+NEBOC_FIX_EDIT_REPLACEMENT_LENGTH_OFFSET]
 test rax,rax
 jz .replacement_ok
 cmp qword [rsi+NEBOC_FIX_EDIT_REPLACEMENT_OFFSET],0
 je .invalid
.replacement_ok:
 cmp qword [rsi+NEBOC_FIX_EDIT_SNAPSHOT_DIGEST_OFFSET],0
 je .invalid
 mov rax,[rsi+NEBOC_FIX_EDIT_APPLICABILITY_OFFSET]
 cmp rax,NEBOC_FIXIT_MACHINE_APPLICABLE
 jb .invalid
 cmp rax,NEBOC_FIXIT_MANUAL_ONLY
 ja .invalid
 mov r8,[rdi+NEBOC_FIX_PLAN_EDIT_COUNT_OFFSET]
 cmp r8,[rdi+NEBOC_FIX_PLAN_EDIT_CAPACITY_OFFSET]
 jae .limit
 mov r9,[rdi+NEBOC_FIX_PLAN_EDITS_OFFSET]
 xor ecx,ecx
.conflict_loop:
 cmp rcx,r8
 jae .copy
 mov r10,rcx
 imul r10,NEBOC_FIX_EDIT_SIZE
 add r10,r9
 mov rax,[r10+NEBOC_FIX_EDIT_FILE_ID_OFFSET]
 cmp rax,[rsi+NEBOC_FIX_EDIT_FILE_ID_OFFSET]
 jne .next
 mov rax,[r10+NEBOC_FIX_EDIT_START_OFFSET]
 cmp rax,[rsi+NEBOC_FIX_EDIT_END_OFFSET]
 jae .next
 mov rax,[rsi+NEBOC_FIX_EDIT_START_OFFSET]
 cmp rax,[r10+NEBOC_FIX_EDIT_END_OFFSET]
 jae .next
 inc qword [rdi+NEBOC_FIX_PLAN_CONFLICTS_OFFSET]
.next:
 inc rcx
 jmp .conflict_loop
.copy:
 imul r8,NEBOC_FIX_EDIT_SIZE
 add r8,r9
 mov rcx,NEBOC_FIX_EDIT_SIZE/8
.copy_loop:
 mov rax,[rsi]
 mov [r8],rax
 add rsi,8
 add r8,8
 dec rcx
 jnz .copy_loop
 inc qword [rdi+NEBOC_FIX_PLAN_EDIT_COUNT_OFFSET]
 mov qword [rdi+NEBOC_FIX_PLAN_ORDERED_OFFSET],0
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_fix_plan_order_canonical
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_FIX_PLAN_ACTIVE_OFFSET],1
 jne .invalid
 cmp qword [rdi+NEBOC_FIX_PLAN_CONFLICTS_OFFSET],0
 jne .conflict
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,[r12+NEBOC_FIX_PLAN_EDITS_OFFSET]
 mov r14,[r12+NEBOC_FIX_PLAN_EDIT_COUNT_OFFSET]
 cmp r14,1
 jbe .ordered
 dec r14
.outer:
 xor ebx,ebx
.inner:
 cmp rbx,r14
 jae .next_outer
 mov r8,rbx
 imul r8,NEBOC_FIX_EDIT_SIZE
 add r8,r13
 lea r9,[r8+NEBOC_FIX_EDIT_SIZE]
 mov rax,[r8+NEBOC_FIX_EDIT_FILE_ID_OFFSET]
 mov rcx,[r9+NEBOC_FIX_EDIT_FILE_ID_OFFSET]
 cmp rax,rcx
 ja .swap
 jb .next_inner
 mov rax,[r8+NEBOC_FIX_EDIT_START_OFFSET]
 cmp rax,[r9+NEBOC_FIX_EDIT_START_OFFSET]
 jae .next_inner
.swap:
 xor ecx,ecx
.swap_loop:
 mov rax,[r8+rcx]
 mov rdx,[r9+rcx]
 mov [r8+rcx],rdx
 mov [r9+rcx],rax
 add rcx,8
 cmp rcx,NEBOC_FIX_EDIT_SIZE
 jb .swap_loop
.next_inner:
 inc rbx
 jmp .inner
.next_outer:
 dec r14
 jnz .outer
.ordered:
 mov qword [r12+NEBOC_FIX_PLAN_ORDERED_OFFSET],1
 xor eax,eax
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.conflict:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

fix_validate_common:
 cmp qword [rdi+NEBOC_FIX_PLAN_ACTIVE_OFFSET],1
 jne .invalid
 mov r8,[rdi+NEBOC_FIX_PLAN_SOURCES_OFFSET]
 xor ecx,ecx
.sources:
 cmp rcx,[rdi+NEBOC_FIX_PLAN_SOURCE_COUNT_OFFSET]
 jae .edits_begin
 mov r9,rcx
 imul r9,NEBOC_FIX_SOURCE_SIZE
 add r9,r8
 mov rax,[r9+NEBOC_FIX_SOURCE_ID_OFFSET]
 test rax,rax
 jz .invalid
 mov rax,[r9+NEBOC_FIX_SOURCE_SNAPSHOT_DIGEST_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,[r9+NEBOC_FIX_SOURCE_CURRENT_DIGEST_OFFSET]
 jne .stale
 mov rax,[r9+NEBOC_FIX_SOURCE_LENGTH_OFFSET]
 test rax,rax
 jz .source_next
 cmp qword [r9+NEBOC_FIX_SOURCE_BYTES_OFFSET],0
 je .invalid
.source_next:
 inc rcx
 jmp .sources
.edits_begin:
 mov r10,[rdi+NEBOC_FIX_PLAN_EDITS_OFFSET]
 xor ecx,ecx
.edits:
 cmp rcx,[rdi+NEBOC_FIX_PLAN_EDIT_COUNT_OFFSET]
 jae .ok
 mov r11,rcx
 imul r11,NEBOC_FIX_EDIT_SIZE
 add r11,r10
 xor edx,edx
.find_source:
 cmp rdx,[rdi+NEBOC_FIX_PLAN_SOURCE_COUNT_OFFSET]
 jae .invalid
 mov r9,rdx
 imul r9,NEBOC_FIX_SOURCE_SIZE
 add r9,r8
 mov rax,[r9+NEBOC_FIX_SOURCE_ID_OFFSET]
 cmp rax,[r11+NEBOC_FIX_EDIT_FILE_ID_OFFSET]
 je .found
 inc rdx
 jmp .find_source
.found:
 mov rax,[r11+NEBOC_FIX_EDIT_SNAPSHOT_DIGEST_OFFSET]
 cmp rax,[r9+NEBOC_FIX_SOURCE_SNAPSHOT_DIGEST_OFFSET]
 jne .stale
 mov rax,[r11+NEBOC_FIX_EDIT_END_OFFSET]
 cmp rax,[r9+NEBOC_FIX_SOURCE_LENGTH_OFFSET]
 ja .invalid
 sub rax,[r11+NEBOC_FIX_EDIT_START_OFFSET]
 cmp rax,[r11+NEBOC_FIX_EDIT_REPLACEMENT_LENGTH_OFFSET]
 jne .unsupported
 inc rcx
 jmp .edits
.ok:
 xor eax,eax
 ret
.unsupported:
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_fix_plan_validate_current_sources
 test rdi,rdi
 jz .invalid
 jmp fix_validate_common
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_fix_plan_preview
 ; rdi=plan, rsi=structured preview descriptor.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rdi+NEBOC_FIX_PLAN_ORDERED_OFFSET],1
 jne .invalid
 mov rax,[rdi+NEBOC_FIX_PLAN_EDIT_COUNT_OFFSET]
 cmp rax,[rsi+NEBOC_FIX_PREVIEW_CAPACITY_OFFSET]
 ja .limit
 test rax,rax
 jz .empty
 cmp qword [rsi+NEBOC_FIX_PREVIEW_EDITS_OFFSET],0
 je .invalid
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rsi,[r12+NEBOC_FIX_PLAN_EDITS_OFFSET]
 mov rdi,[r13+NEBOC_FIX_PREVIEW_EDITS_OFFSET]
 mov rcx,[r12+NEBOC_FIX_PLAN_EDIT_COUNT_OFFSET]
 imul rcx,NEBOC_FIX_EDIT_SIZE/8
 rep movsq
 mov rax,[r12+NEBOC_FIX_PLAN_EDIT_COUNT_OFFSET]
 mov [r13+NEBOC_FIX_PREVIEW_COUNT_OFFSET],rax
 pop r13
 pop r12
 xor eax,eax
 ret
.empty:
 mov qword [rsi+NEBOC_FIX_PREVIEW_COUNT_OFFSET],0
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_fix_plan_apply
 ; rdi=plan, rsi=capability, rdx=policy.
 test rdi,rdi
 jz .invalid
 cmp rsi,NEBOC_FIX_CAPABILITY_APPLY
 jne .invalid
 cmp rdx,NEBOC_FIX_POLICY_APPLY_CONFIRMED
 jne .invalid
 cmp qword [rdi+NEBOC_FIX_PLAN_ORDERED_OFFSET],1
 jne .invalid
 cmp qword [rdi+NEBOC_FIX_PLAN_CONFLICTS_OFFSET],0
 jne .invalid_source
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov r12,rdi
 call fix_validate_common
 test eax,eax
 jnz .done
 mov rax,[r12+NEBOC_FIX_PLAN_SOURCE_COUNT_OFFSET]
 cmp rax,[r12+NEBOC_FIX_PLAN_JOURNAL_CAPACITY_OFFSET]
 ja .limit
 mov r13,[r12+NEBOC_FIX_PLAN_SOURCES_OFFSET]
 mov r14,[r12+NEBOC_FIX_PLAN_JOURNAL_OFFSET]
 xor r15d,r15d
.backup:
 cmp r15,[r12+NEBOC_FIX_PLAN_SOURCE_COUNT_OFFSET]
 jae .apply_begin
 mov r8,r15
 imul r8,NEBOC_FIX_SOURCE_SIZE
 add r8,r13
 mov rax,[r8+NEBOC_FIX_SOURCE_LENGTH_OFFSET]
 cmp rax,[r8+NEBOC_FIX_SOURCE_BACKUP_CAPACITY_OFFSET]
 ja .limit
 test rax,rax
 jz .backup_record
 cmp qword [r8+NEBOC_FIX_SOURCE_BACKUP_OFFSET],0
 je .invalid_local
 mov rsi,[r8+NEBOC_FIX_SOURCE_BYTES_OFFSET]
 mov rdi,[r8+NEBOC_FIX_SOURCE_BACKUP_OFFSET]
 mov rcx,rax
 rep movsb
.backup_record:
 mov r9,r15
 imul r9,NEBOC_FIX_JOURNAL_SIZE
 add r9,r14
 mov [r9+NEBOC_FIX_JOURNAL_SOURCE_OFFSET],r8
 mov rax,[r8+NEBOC_FIX_SOURCE_LENGTH_OFFSET]
 mov [r9+NEBOC_FIX_JOURNAL_LENGTH_OFFSET],rax
 mov qword [r9+NEBOC_FIX_JOURNAL_ACTIVE_OFFSET],1
 inc r15
 jmp .backup
.apply_begin:
 mov rax,[r12+NEBOC_FIX_PLAN_SOURCE_COUNT_OFFSET]
 mov [r12+NEBOC_FIX_PLAN_JOURNAL_COUNT_OFFSET],rax
 mov qword [r12+NEBOC_FIX_PLAN_APPLIED_OFFSET],0
 mov qword [r12+NEBOC_FIX_PLAN_SKIPPED_OFFSET],0
 xor r15d,r15d
.apply_loop:
 cmp r15,[r12+NEBOC_FIX_PLAN_EDIT_COUNT_OFFSET]
 jae .mark_digests
 mov r10,r15
 imul r10,NEBOC_FIX_EDIT_SIZE
 add r10,[r12+NEBOC_FIX_PLAN_EDITS_OFFSET]
 cmp qword [r10+NEBOC_FIX_EDIT_APPLICABILITY_OFFSET],NEBOC_FIXIT_MACHINE_APPLICABLE
 jne .skip
 xor ecx,ecx
.locate:
 mov r8,rcx
 imul r8,NEBOC_FIX_SOURCE_SIZE
 add r8,r13
 mov rax,[r8+NEBOC_FIX_SOURCE_ID_OFFSET]
 cmp rax,[r10+NEBOC_FIX_EDIT_FILE_ID_OFFSET]
 je .write
 inc rcx
 jmp .locate
.write:
 mov rdi,[r8+NEBOC_FIX_SOURCE_BYTES_OFFSET]
 add rdi,[r10+NEBOC_FIX_EDIT_START_OFFSET]
 mov rsi,[r10+NEBOC_FIX_EDIT_REPLACEMENT_OFFSET]
 mov rcx,[r10+NEBOC_FIX_EDIT_REPLACEMENT_LENGTH_OFFSET]
 rep movsb
 inc qword [r12+NEBOC_FIX_PLAN_APPLIED_OFFSET]
 mov rax,[r12+NEBOC_FIX_PLAN_FAILURE_AFTER_OFFSET]
 test rax,rax
 jz .next_edit
 cmp rax,[r12+NEBOC_FIX_PLAN_APPLIED_OFFSET]
 jne .next_edit
 mov rdi,r12
 call neboc_fix_plan_rollback
 mov eax,NEBOC_STATUS_IO_ERROR
 jmp .done
.skip:
 inc qword [r12+NEBOC_FIX_PLAN_SKIPPED_OFFSET]
.next_edit:
 inc r15
 jmp .apply_loop
.mark_digests:
 xor r15d,r15d
.digest_loop:
 cmp r15,[r12+NEBOC_FIX_PLAN_SOURCE_COUNT_OFFSET]
 jae .ok
 mov r8,r15
 imul r8,NEBOC_FIX_SOURCE_SIZE
 add r8,r13
 mov rax,[r8+NEBOC_FIX_SOURCE_SNAPSHOT_DIGEST_OFFSET]
 xor rax,0x52463532
 mov [r8+NEBOC_FIX_SOURCE_CURRENT_DIGEST_OFFSET],rax
 inc r15
 jmp .digest_loop
.ok:
 xor eax,eax
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid_local:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.invalid_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_fix_plan_rollback
 test rdi,rdi
 jz .invalid
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,[r12+NEBOC_FIX_PLAN_JOURNAL_OFFSET]
 xor r14d,r14d
.loop:
 cmp r14,[r12+NEBOC_FIX_PLAN_JOURNAL_COUNT_OFFSET]
 jae .done
 mov r8,r14
 imul r8,NEBOC_FIX_JOURNAL_SIZE
 add r8,r13
 cmp qword [r8+NEBOC_FIX_JOURNAL_ACTIVE_OFFSET],1
 jne .next
 mov r9,[r8+NEBOC_FIX_JOURNAL_SOURCE_OFFSET]
 mov rsi,[r9+NEBOC_FIX_SOURCE_BACKUP_OFFSET]
 mov rdi,[r9+NEBOC_FIX_SOURCE_BYTES_OFFSET]
 mov rcx,[r8+NEBOC_FIX_JOURNAL_LENGTH_OFFSET]
 rep movsb
 mov rax,[r9+NEBOC_FIX_SOURCE_SNAPSHOT_DIGEST_OFFSET]
 mov [r9+NEBOC_FIX_SOURCE_CURRENT_DIGEST_OFFSET],rax
 mov qword [r8+NEBOC_FIX_JOURNAL_ACTIVE_OFFSET],0
.next:
 inc r14
 jmp .loop
.done:
 mov qword [r12+NEBOC_FIX_PLAN_JOURNAL_COUNT_OFFSET],0
 mov qword [r12+NEBOC_FIX_PLAN_APPLIED_OFFSET],0
 xor eax,eax
 pop r14
 pop r13
 pop r12
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_fix_plan_recheck
 ; rdi=plan, rsi=caller-provided formatter/parse/check/lint status.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rdi+NEBOC_FIX_PLAN_JOURNAL_COUNT_OFFSET],0
 je .invalid
 mov rax,[rsi]
 mov [rdi+NEBOC_FIX_PLAN_RECHECK_STATUS_OFFSET],rax
 test rax,rax
 jnz .failed
 mov r8,[rdi+NEBOC_FIX_PLAN_JOURNAL_OFFSET]
 xor ecx,ecx
.finalize:
 cmp rcx,[rdi+NEBOC_FIX_PLAN_JOURNAL_COUNT_OFFSET]
 jae .ok
 mov r9,rcx
 imul r9,NEBOC_FIX_JOURNAL_SIZE
 mov qword [r8+r9+NEBOC_FIX_JOURNAL_ACTIVE_OFFSET],0
 inc rcx
 jmp .finalize
.ok:
 mov qword [rdi+NEBOC_FIX_PLAN_JOURNAL_COUNT_OFFSET],0
 xor eax,eax
 ret
.failed:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_fix_plan_report
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_FIX_PLAN_EDIT_COUNT_OFFSET]
 mov [rsi+NEBOC_FIX_REPORT_EDITS_OFFSET],rax
 mov rax,[rdi+NEBOC_FIX_PLAN_APPLIED_OFFSET]
 mov [rsi+NEBOC_FIX_REPORT_APPLIED_OFFSET],rax
 mov rax,[rdi+NEBOC_FIX_PLAN_SKIPPED_OFFSET]
 mov [rsi+NEBOC_FIX_REPORT_SKIPPED_OFFSET],rax
 mov rax,[rdi+NEBOC_FIX_PLAN_CONFLICTS_OFFSET]
 mov [rsi+NEBOC_FIX_REPORT_CONFLICTS_OFFSET],rax
 mov rax,[rdi+NEBOC_FIX_PLAN_JOURNAL_COUNT_OFFSET]
 mov [rsi+NEBOC_FIX_REPORT_JOURNAL_OFFSET],rax
 mov rax,[rdi+NEBOC_FIX_PLAN_RECHECK_STATUS_OFFSET]
 mov [rsi+NEBOC_FIX_REPORT_RECHECK_OFFSET],rax
 mov rax,[rdi+NEBOC_FIX_PLAN_ORDERED_OFFSET]
 mov [rsi+NEBOC_FIX_REPORT_ORDERED_OFFSET],rax
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_fix_check
 test rdi,rdi
 jz .invalid
 push rdi
 call fix_validate_common
 pop rdi
 test eax,eax
 jnz .done
 cmp qword [rdi+NEBOC_FIX_PLAN_EDIT_COUNT_OFFSET],0
 je .done
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_fix_preview
 jmp neboc_fix_plan_preview

NEBOC_ABI_FUNCTION neboc_cli_fix_apply
 jmp neboc_fix_plan_apply

section .note.GNU-stack noalloc noexec nowrite progbits
