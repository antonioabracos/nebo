; C04-F08 registry-bound suppressions, explanations and nonmutating fix preview.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/warning_policy.inc"
%include "compiler/diagnostics/warning_registry.inc"
%include "compiler/diagnostics/explain.inc"
%include "compiler/diagnostics/warning_guidance.inc"

extern neboc_warning_registry_lookup
extern neboc_diagnostic_explanation_load
extern neboc_fix_it_preview

section .text

; warning_suppression_record(out*, diagnostic*, policy_explanation*, reason*,
;                            reason_len, canonical_identity_digest)
; Only an explicit allow rule may suppress a warning. Reasons are bounded and
; single-line so the audit record cannot be forged by control bytes.
NEBOC_ABI_FUNCTION neboc_warning_suppression_record
 test rdi,rdi
 jz .record_invalid
 test rsi,rsi
 jz .record_invalid
 test rdx,rdx
 jz .record_invalid
 test rcx,rcx
 jz .record_invalid
 test r8,r8
 jz .record_invalid
 cmp r8,NEBOC_WARNING_SUPPRESSION_MAX_REASON_BYTES
 ja .record_limit
 test r9,r9
 jz .record_invalid
 cmp qword [rsi+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET],NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 jne .record_invalid
 cmp qword [rdx+NEBOC_WARNING_EXPLANATION_LEVEL_OFFSET],NEBOC_WARNING_LEVEL_ALLOW
 jne .record_invalid
 cmp qword [rdx+NEBOC_WARNING_EXPLANATION_RULE_OFFSET],0
 je .record_invalid
 cmp qword [rdx+NEBOC_WARNING_EXPLANATION_RULE_LENGTH_OFFSET],0
 je .record_invalid
 mov rax,[rdx+NEBOC_WARNING_EXPLANATION_SOURCE_OFFSET]
 cmp rax,NEBOC_WARNING_SOURCE_POLICY
 je .record_reason
 cmp rax,NEBOC_WARNING_SOURCE_SCOPE
 jne .record_invalid
.record_reason:
 xor eax,eax
 xor r10d,r10d
.record_reason_loop:
 cmp rax,r8
 jae .record_reason_done
 mov r11b,[rcx+rax]
 cmp r11b,0x20
 jb .record_invalid
 cmp r11b,0x7f
 je .record_invalid
 cmp r11b,0x20
 je .record_reason_next
 mov r10d,1
.record_reason_next:
 inc rax
 jmp .record_reason_loop
.record_reason_done:
 test r10d,r10d
 jz .record_invalid

 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,128
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 mov [rsp+120],r9
 mov rdi,[r12+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov rsi,[r12+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 lea rdx,[rsp]
 call neboc_warning_registry_lookup
 test eax,eax
 jnz .record_finish
 mov rax,[r12+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov [rbx+NEBOC_WARNING_SUPPRESSION_CODE_OFFSET],rax
 mov rax,[r12+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 mov [rbx+NEBOC_WARNING_SUPPRESSION_CODE_LENGTH_OFFSET],rax
 mov [rbx+NEBOC_WARNING_SUPPRESSION_REASON_OFFSET],r14
 mov [rbx+NEBOC_WARNING_SUPPRESSION_REASON_LENGTH_OFFSET],r15
 mov rax,[r13+NEBOC_WARNING_EXPLANATION_RULE_OFFSET]
 mov [rbx+NEBOC_WARNING_SUPPRESSION_RULE_OFFSET],rax
 mov rax,[r13+NEBOC_WARNING_EXPLANATION_RULE_LENGTH_OFFSET]
 mov [rbx+NEBOC_WARNING_SUPPRESSION_RULE_LENGTH_OFFSET],rax
 mov rax,[r13+NEBOC_WARNING_EXPLANATION_SOURCE_OFFSET]
 mov [rbx+NEBOC_WARNING_SUPPRESSION_SOURCE_OFFSET],rax
 mov rax,[rsp+120]
 mov [rbx+NEBOC_WARNING_SUPPRESSION_IDENTITY_DIGEST_OFFSET],rax
 mov qword [rbx+NEBOC_WARNING_SUPPRESSION_ACTIVE_OFFSET],1
 xor eax,eax
.record_finish:
 add rsp,128
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.record_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.record_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; warning_explanation_load(diagnostic*, out_explanation*)
; The WarningId must be present in both the warning registry and offline catalog.
NEBOC_ABI_FUNCTION neboc_warning_explanation_load
 test rdi,rdi
 jz .explain_invalid
 test rsi,rsi
 jz .explain_invalid
 cmp qword [rdi+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET],NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 jne .explain_invalid
 push rbx
 push r12
 sub rsp,120
 mov rbx,rdi
 mov r12,rsi
 mov rdi,[rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov rsi,[rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 lea rdx,[rsp]
 call neboc_warning_registry_lookup
 test eax,eax
 jnz .explain_finish
 mov rdi,[rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov rsi,[rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 mov rdx,r12
 call neboc_diagnostic_explanation_load
.explain_finish:
 add rsp,120
 pop r12
 pop rbx
 ret
.explain_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; warning_fixit_preview(diagnostic*, fix*, source_map*, writer*)
; Registry applicability is authoritative; preview never applies an edit.
NEBOC_ABI_FUNCTION neboc_warning_fixit_preview
 test rdi,rdi
 jz .preview_invalid
 test rsi,rsi
 jz .preview_invalid
 test rdx,rdx
 jz .preview_invalid
 test rcx,rcx
 jz .preview_invalid
 cmp qword [rdi+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET],NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 jne .preview_invalid
 cmp qword [rsi+NEBOC_FIXIT_ACTIVE_OFFSET],1
 jne .preview_invalid
 push rbx
 push r12
 push r13
 push r14
 sub rsp,120
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov rdi,[rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov rsi,[rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 lea rdx,[rsp]
 call neboc_warning_registry_lookup
 test eax,eax
 jnz .preview_finish
 mov rax,[rsp+NEBOC_WARNING_ENTRY_FIXIT_APPLICABILITY_OFFSET]
 cmp rax,[r12+NEBOC_FIXIT_APPLICABILITY_OFFSET]
 jne .preview_mismatch
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 call neboc_fix_it_preview
 jmp .preview_finish
.preview_mismatch:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.preview_finish:
 add rsp,120
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.preview_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
