; C04-F07 bounded warning exit, cap-lints and exact-baseline policy.
; This owner never mutates the canonical Diagnostic or source semantics.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/driver/cli/linux-x86_64/cli_driver.inc"
%include "compiler/diagnostics/warning_policy.inc"
%include "compiler/diagnostics/warning_cli_policy.inc"

section .text

; warning_baseline_new(baseline*, entries*, capacity, snapshot_digest)
NEBOC_ABI_FUNCTION neboc_warning_baseline_new
 test rdi,rdi
 jz .new_invalid
 test rsi,rsi
 jz .new_invalid
 test rdx,rdx
 jz .new_invalid
 cmp rdx,NEBOC_WARNING_BASELINE_MAX_ENTRIES
 ja .new_limit
 test rcx,rcx
 jz .new_invalid
 push rdi
 push rcx
 mov rdi,rsi
 mov rcx,rdx
 xor eax,eax
 rep stosq
 pop rcx
 pop rdi
 mov [rdi+NEBOC_WARNING_BASELINE_ENTRIES_OFFSET],rsi
 mov [rdi+NEBOC_WARNING_BASELINE_CAPACITY_OFFSET],rdx
 mov qword [rdi+NEBOC_WARNING_BASELINE_COUNT_OFFSET],0
 mov [rdi+NEBOC_WARNING_BASELINE_SNAPSHOT_DIGEST_OFFSET],rcx
 mov qword [rdi+NEBOC_WARNING_BASELINE_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.new_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.new_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; warning_baseline_add(baseline*, canonical_identity_digest)
; Duplicate and zero identities fail closed.
NEBOC_ABI_FUNCTION neboc_warning_baseline_add
 test rdi,rdi
 jz .add_invalid
 test rsi,rsi
 jz .add_invalid
 cmp qword [rdi+NEBOC_WARNING_BASELINE_ACTIVE_OFFSET],1
 jne .add_invalid
 mov rdx,[rdi+NEBOC_WARNING_BASELINE_ENTRIES_OFFSET]
 test rdx,rdx
 jz .add_invalid
 xor ecx,ecx
.add_scan:
 cmp rcx,[rdi+NEBOC_WARNING_BASELINE_COUNT_OFFSET]
 jae .add_append
 cmp [rdx+rcx*8],rsi
 je .add_invalid
 inc rcx
 jmp .add_scan
.add_append:
 cmp rcx,[rdi+NEBOC_WARNING_BASELINE_CAPACITY_OFFSET]
 jae .add_limit
 mov [rdx+rcx*8],rsi
 inc qword [rdi+NEBOC_WARNING_BASELINE_COUNT_OFFSET]
 xor eax,eax
 ret
.add_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.add_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; warning_baseline_classify(baseline*, identity_digest, current_snapshot_digest,
;                           out_class*)
; Snapshot mismatch is STALE and cannot suppress any warning.
NEBOC_ABI_FUNCTION neboc_warning_baseline_classify
 test rdi,rdi
 jz .class_invalid
 test rsi,rsi
 jz .class_invalid
 test rdx,rdx
 jz .class_invalid
 test rcx,rcx
 jz .class_invalid
 cmp qword [rdi+NEBOC_WARNING_BASELINE_ACTIVE_OFFSET],1
 jne .class_invalid
 mov r8,[rdi+NEBOC_WARNING_BASELINE_ENTRIES_OFFSET]
 test r8,r8
 jz .class_invalid
 cmp rdx,[rdi+NEBOC_WARNING_BASELINE_SNAPSHOT_DIGEST_OFFSET]
 jne .class_stale
 xor r9d,r9d
.class_scan:
 cmp r9,[rdi+NEBOC_WARNING_BASELINE_COUNT_OFFSET]
 jae .class_new
 cmp [r8+r9*8],rsi
 je .class_matched
 inc r9
 jmp .class_scan
.class_new:
 mov qword [rcx],NEBOC_WARNING_BASELINE_NEW
 xor eax,eax
 ret
.class_matched:
 mov qword [rcx],NEBOC_WARNING_BASELINE_MATCHED
 xor eax,eax
 ret
.class_stale:
 mov qword [rcx],NEBOC_WARNING_BASELINE_STALE
 xor eax,eax
 ret
.class_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; warning_cli_decide(request*, decision*)
; Order is explicit: warnings-as-errors promotion, then cap-lints. Forbid is
; never lowered. An exact baseline match suppresses only a final WARN; DENY and
; FORBID remain build failures. The original diagnostic level is retained.
NEBOC_ABI_FUNCTION neboc_warning_cli_decide
 test rdi,rdi
 jz .decide_invalid
 test rsi,rsi
 jz .decide_invalid
 mov rax,[rdi+NEBOC_WARNING_CLI_REQUEST_LEVEL_OFFSET]
 cmp rax,NEBOC_WARNING_LEVEL_ALLOW
 jb .decide_invalid
 cmp rax,NEBOC_WARNING_LEVEL_FORBID
 ja .decide_invalid
 mov r8,[rdi+NEBOC_WARNING_CLI_REQUEST_WARNINGS_AS_ERRORS_OFFSET]
 cmp r8,1
 ja .decide_invalid
 mov r9,[rdi+NEBOC_WARNING_CLI_REQUEST_CAP_LINTS_OFFSET]
 cmp r9,NEBOC_WARNING_LEVEL_FORBID
 ja .decide_invalid
 mov r10,[rdi+NEBOC_WARNING_CLI_REQUEST_BASELINE_CLASS_OFFSET]
 cmp r10,NEBOC_WARNING_BASELINE_STALE
 ja .decide_invalid

 mov [rsi+NEBOC_WARNING_CLI_DECISION_ORIGINAL_LEVEL_OFFSET],rax
 mov [rsi+NEBOC_WARNING_CLI_DECISION_BASELINE_CLASS_OFFSET],r10
 mov qword [rsi+NEBOC_WARNING_CLI_DECISION_FLAGS_OFFSET],0
 cmp r10,NEBOC_WARNING_BASELINE_STALE
 jne .decide_promote
 or qword [rsi+NEBOC_WARNING_CLI_DECISION_FLAGS_OFFSET],NEBOC_WARNING_CLI_FLAG_BASELINE_STALE
.decide_promote:
 cmp r8,1
 jne .decide_cap
 cmp rax,NEBOC_WARNING_LEVEL_WARN
 jne .decide_cap
 mov eax,NEBOC_WARNING_LEVEL_DENY
 or qword [rsi+NEBOC_WARNING_CLI_DECISION_FLAGS_OFFSET],NEBOC_WARNING_CLI_FLAG_PROMOTED
.decide_cap:
 test r9,r9
 jz .decide_store_level
 cmp rax,NEBOC_WARNING_LEVEL_FORBID
 je .decide_store_level
 cmp rax,r9
 jbe .decide_store_level
 mov rax,r9
 or qword [rsi+NEBOC_WARNING_CLI_DECISION_FLAGS_OFFSET],NEBOC_WARNING_CLI_FLAG_CAPPED
.decide_store_level:
 mov [rsi+NEBOC_WARNING_CLI_DECISION_EFFECTIVE_LEVEL_OFFSET],rax
 mov qword [rsi+NEBOC_WARNING_CLI_DECISION_EMIT_OFFSET],0
 mov qword [rsi+NEBOC_WARNING_CLI_DECISION_FAIL_OFFSET],0
 mov qword [rsi+NEBOC_WARNING_CLI_DECISION_EXIT_CODE_OFFSET],NEBOC_CLI_EXIT_SUCCESS
 cmp rax,NEBOC_WARNING_LEVEL_ALLOW
 je .decide_ok
 cmp rax,NEBOC_WARNING_LEVEL_WARN
 jne .decide_failure
 cmp r10,NEBOC_WARNING_BASELINE_MATCHED
 jne .decide_visible
 or qword [rsi+NEBOC_WARNING_CLI_DECISION_FLAGS_OFFSET],NEBOC_WARNING_CLI_FLAG_BASELINE_SUPPRESSED
 jmp .decide_ok
.decide_visible:
 mov qword [rsi+NEBOC_WARNING_CLI_DECISION_EMIT_OFFSET],1
 jmp .decide_ok
.decide_failure:
 mov qword [rsi+NEBOC_WARNING_CLI_DECISION_EMIT_OFFSET],1
 mov qword [rsi+NEBOC_WARNING_CLI_DECISION_FAIL_OFFSET],1
 mov qword [rsi+NEBOC_WARNING_CLI_DECISION_EXIT_CODE_OFFSET],NEBOC_CLI_EXIT_SOURCE_ERROR
.decide_ok:
 xor eax,eax
 ret
.decide_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
