; TRUST-ZONES-PRIVACIDADE-QUALIDADE-CONFIANCA-E-LINEAGE explicit, allocation-free Text metadata primitives.
bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/text_privacy.inc"
global neboc_trust_zone_valid
global neboc_text_as_trusted
global neboc_text_trust_zone
global neboc_quality_score_valid
global neboc_text_with_quality
global neboc_text_with_confidence
global neboc_text_with_lineage
global neboc_text_lineage
global neboc_lineage_merge
global neboc_privacy_label_valid
global neboc_text_with_privacy_label
global neboc_text_privacy_label
global neboc_privacy_join
global neboc_privacy_propagate
global neboc_privacy_redact
global neboc_privacy_declassify
global neboc_sink_policy_accepts
global neboc_privacy_sink_check
global neboc_privacy_error_diagnostic
global neboc_privacy_audit_valid
section .rodata
redacted_bytes: db '[REDACTED]'
align 8
text_privacy_redacted_text: dq redacted_bytes,10,NEBO_TEXT_FLAG_STATIC|NEBO_TEXT_FLAG_VALID_UTF8|NEBO_TEXT_FLAG_ASCII,NEBO_TEXT_STORAGE_STATIC
section .text

; edi=TrustZone, eax=1 when it names a concrete frozen zone.
align 16
neboc_trust_zone_valid:
 xor eax,eax
 cmp edi,NEBO_TRUST_EXTERNAL
 jb .zone_done
 cmp edi,NEBO_TRUST_MAX
 ja .zone_done
 mov eax,1
.zone_done:
 ret

; rdi=Text descriptor, esi=zone, rdx=explicit validator result token,
; rcx=out metadata.  Failed validation leaves the output untouched.
align 16
neboc_text_as_trusted:
 test rdi,rdi
 jz .trusted_null
 test rcx,rcx
 jz .trusted_null
 cmp esi,NEBO_TRUST_EXTERNAL
 jb .trusted_zone
 cmp esi,NEBO_TRUST_MAX
 ja .trusted_zone
 mov r8d,NEBO_TRUST_VALIDATION_TOKEN_BASE
 or r8d,esi
 cmp edx,r8d
 jne .trusted_validation
 mov [rcx+NEBO_PRIVACY_TEXT_OFFSET],rdi
 mov [rcx+NEBO_PRIVACY_TRUST_OFFSET],rsi
 mov qword [rcx+NEBO_PRIVACY_QUALITY_OFFSET],NEBO_SCORE_UNKNOWN
 mov qword [rcx+NEBO_PRIVACY_CONFIDENCE_OFFSET],NEBO_SCORE_UNKNOWN
 mov qword [rcx+NEBO_PRIVACY_LINEAGE_OFFSET],0
 mov qword [rcx+NEBO_PRIVACY_LABEL_OFFSET],0
 mov qword [rcx+NEBO_PRIVACY_FLAGS_OFFSET],NEBO_PRIVACY_FLAG_TRUSTED
 mov qword [rcx+NEBO_PRIVACY_AUDIT_OFFSET],0
 xor eax,eax
 ret
.trusted_null:
 mov eax,NEBO_PRIVACY_ERROR_NULL
 ret
.trusted_zone:
 mov eax,NEBO_PRIVACY_ERROR_TRUST_ZONE
 ret
.trusted_validation:
 mov eax,NEBO_PRIVACY_ERROR_VALIDATION
 ret

; rdi=metadata, eax=TrustZone or negative typed error.
align 16
neboc_text_trust_zone:
 test rdi,rdi
 jz .query_null
 mov rax,[rdi+NEBO_PRIVACY_TRUST_OFFSET]
 ret
.query_null:
 mov rax,-NEBO_PRIVACY_ERROR_NULL
 ret

; edi=score in basis points (0..10000), eax=boolean.
align 16
neboc_quality_score_valid:
 xor eax,eax
 cmp edi,NEBO_SCORE_MAX
 ja .score_done
 mov eax,1
.score_done:
 ret

; rdi=input metadata, rsi=score, rdx=out metadata.
align 16
neboc_text_with_quality:
 mov ecx,NEBO_PRIVACY_QUALITY_OFFSET
 jmp with_score

align 16
neboc_text_with_confidence:
 mov ecx,NEBO_PRIVACY_CONFIDENCE_OFFSET
with_score:
 test rdi,rdi
 jz .with_score_null
 test rdx,rdx
 jz .with_score_null
 cmp rsi,NEBO_SCORE_MAX
 ja .with_score_invalid
 xor r8d,r8d
.with_score_copy:
 mov rax,[rdi+r8]
 mov [rdx+r8],rax
 add r8,8
 cmp r8,NEBO_PRIVACY_METADATA_SIZE
 jb .with_score_copy
 mov [rdx+rcx],rsi
 xor eax,eax
 ret
.with_score_null:
 mov eax,NEBO_PRIVACY_ERROR_NULL
 ret
.with_score_invalid:
 mov eax,NEBO_PRIVACY_ERROR_SCORE
 ret

; rdi=input metadata, rsi=non-zero stable source id, rdx=out metadata.
align 16
neboc_text_with_lineage:
 test rdi,rdi
 jz .with_lineage_null
 test rdx,rdx
 jz .with_lineage_null
 test rsi,rsi
 jz .with_lineage_invalid
 xor ecx,ecx
.with_lineage_copy:
 mov rax,[rdi+rcx]
 mov [rdx+rcx],rax
 add rcx,8
 cmp rcx,NEBO_PRIVACY_METADATA_SIZE
 jb .with_lineage_copy
 mov [rdx+NEBO_PRIVACY_LINEAGE_OFFSET],rsi
 xor eax,eax
 ret
.with_lineage_null:
 mov eax,NEBO_PRIVACY_ERROR_NULL
 ret
.with_lineage_invalid:
 mov eax,NEBO_PRIVACY_ERROR_LINEAGE
 ret

align 16
neboc_text_lineage:
 test rdi,rdi
 jz .lineage_query_null
 mov rax,[rdi+NEBO_PRIVACY_LINEAGE_OFFSET]
 ret
.lineage_query_null:
 mov rax,-NEBO_PRIVACY_ERROR_NULL
 ret

; rdi=left lineage, rsi=right lineage, rdx=out digest.  Order is preserved.
align 16
neboc_lineage_merge:
 test rdx,rdx
 jz .merge_null
 test rdi,rdi
 jz .merge_invalid
 test rsi,rsi
 jz .merge_invalid
 mov rax,NEBO_LINEAGE_FNV1A64_OFFSET
 mov r8,NEBO_LINEAGE_FNV1A64_PRIME
 mov r9,rdi
 mov r10,rsi
 mov ecx,16
.merge_hash:
 mov r11,r9
 and r11d,0xff
 xor rax,r11
 imul rax,r8
 shr r9,8
 dec ecx
 cmp ecx,8
 jne .merge_next
 mov r9,r10
.merge_next:
 test ecx,ecx
 jnz .merge_hash
 test rax,rax
 jnz .merge_commit
 mov rax,1
.merge_commit:
 mov [rdx],rax
 xor eax,eax
 ret
.merge_null:
 mov eax,NEBO_PRIVACY_ERROR_NULL
 ret
.merge_invalid:
 mov eax,NEBO_PRIVACY_ERROR_LINEAGE
 ret

; edi=label, eax=boolean.  All wrappers have a unique frozen label.
align 16
neboc_privacy_label_valid:
 xor eax,eax
 cmp edi,NEBO_PRIVACY_LABEL_MAX
 ja .label_valid_done
 mov eax,1
.label_valid_done:
 ret

; rdi=input metadata, rsi=label, rdx=out.  Ordinary wrapping may only
; preserve or increase restriction; declassification has a separate ABI.
align 16
neboc_text_with_privacy_label:
 test rdi,rdi
 jz .with_label_null
 test rdx,rdx
 jz .with_label_null
 cmp rsi,NEBO_PRIVACY_LABEL_MAX
 ja .with_label_invalid
 cmp rsi,[rdi+NEBO_PRIVACY_LABEL_OFFSET]
 jb .with_label_policy
 xor ecx,ecx
.with_label_copy:
 mov rax,[rdi+rcx]
 mov [rdx+rcx],rax
 add rcx,8
 cmp rcx,NEBO_PRIVACY_METADATA_SIZE
 jb .with_label_copy
 mov [rdx+NEBO_PRIVACY_LABEL_OFFSET],rsi
 or qword [rdx+NEBO_PRIVACY_FLAGS_OFFSET],NEBO_PRIVACY_FLAG_CLASSIFIED
 xor eax,eax
 ret
.with_label_null:
 mov eax,NEBO_PRIVACY_ERROR_NULL
 ret
.with_label_invalid:
 mov eax,NEBO_PRIVACY_ERROR_LABEL
 ret
.with_label_policy:
 mov eax,NEBO_PRIVACY_ERROR_POLICY
 ret

align 16
neboc_text_privacy_label:
 test rdi,rdi
 jz .label_query_null
 mov rax,[rdi+NEBO_PRIVACY_LABEL_OFFSET]
 ret
.label_query_null:
 mov rax,-NEBO_PRIVACY_ERROR_NULL
 ret

; edi=left label, esi=right label, eax=conservative join or negative error.
align 16
neboc_privacy_join:
 cmp edi,NEBO_PRIVACY_LABEL_MAX
 ja .join_label_invalid
 cmp esi,NEBO_PRIVACY_LABEL_MAX
 ja .join_label_invalid
 mov eax,edi
 cmp eax,esi
 jae .join_label_done
 mov eax,esi
.join_label_done:
 ret
.join_label_invalid:
 mov eax,-NEBO_PRIVACY_ERROR_LABEL
 ret

; rdi=left metadata, rsi=right metadata, rdx=result carrier pointer,
; rcx=out metadata.  This ABI is shared by Text and future plan/collection
; carriers; it does not activate formatting, interpolation, or rendering.
align 16
neboc_privacy_propagate:
 test rdi,rdi
 jz .propagate_null
 test rsi,rsi
 jz .propagate_null
 test rcx,rcx
 jz .propagate_null
 cmp qword [rdi+NEBO_PRIVACY_LABEL_OFFSET],NEBO_PRIVACY_LABEL_MAX
 ja .propagate_label
 cmp qword [rsi+NEBO_PRIVACY_LABEL_OFFSET],NEBO_PRIVACY_LABEL_MAX
 ja .propagate_label
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rdi,[r12+NEBO_PRIVACY_LINEAGE_OFFSET]
 mov rsi,[r13+NEBO_PRIVACY_LINEAGE_OFFSET]
 test rdi,rdi
 jz .propagate_left_lineage_empty
 test rsi,rsi
 jz .propagate_right_lineage_empty
 lea rdx,[rsp]
 call neboc_lineage_merge
 test eax,eax
 jnz .propagate_saved_error
 jmp .propagate_lineage_ready
.propagate_left_lineage_empty:
 mov [rsp],rsi
 jmp .propagate_lineage_ready
.propagate_right_lineage_empty:
 mov [rsp],rdi
.propagate_lineage_ready:
 mov rax,[r12+NEBO_PRIVACY_TRUST_OFFSET]
 cmp rax,[r13+NEBO_PRIVACY_TRUST_OFFSET]
 jbe .propagate_trust_ready
 mov rax,[r13+NEBO_PRIVACY_TRUST_OFFSET]
.propagate_trust_ready:
 mov [rsp+8],rax
 mov r8,[r12+NEBO_PRIVACY_QUALITY_OFFSET]
 mov r9,[r13+NEBO_PRIVACY_QUALITY_OFFSET]
 cmp r8,NEBO_SCORE_UNKNOWN
 je .propagate_quality_ready
 cmp r9,NEBO_SCORE_UNKNOWN
 je .propagate_quality_unknown
 cmp r8,r9
 jbe .propagate_quality_ready
 mov r8,r9
 jmp .propagate_quality_ready
.propagate_quality_unknown:
 mov r8,NEBO_SCORE_UNKNOWN
.propagate_quality_ready:
 mov r9,[r12+NEBO_PRIVACY_CONFIDENCE_OFFSET]
 mov r10,[r13+NEBO_PRIVACY_CONFIDENCE_OFFSET]
 cmp r9,NEBO_SCORE_UNKNOWN
 je .propagate_confidence_ready
 cmp r10,NEBO_SCORE_UNKNOWN
 je .propagate_confidence_unknown
 cmp r9,r10
 jbe .propagate_confidence_ready
 mov r9,r10
 jmp .propagate_confidence_ready
.propagate_confidence_unknown:
 mov r9,NEBO_SCORE_UNKNOWN
.propagate_confidence_ready:
 mov r10,[r12+NEBO_PRIVACY_LABEL_OFFSET]
 cmp r10,[r13+NEBO_PRIVACY_LABEL_OFFSET]
 jae .propagate_label_ready
 mov r10,[r13+NEBO_PRIVACY_LABEL_OFFSET]
.propagate_label_ready:
 mov r11,[r12+NEBO_PRIVACY_FLAGS_OFFSET]
 or r11,[r13+NEBO_PRIVACY_FLAGS_OFFSET]
 mov rbx,[r12+NEBO_PRIVACY_AUDIT_OFFSET]
 cmp rbx,[r13+NEBO_PRIVACY_AUDIT_OFFSET]
 jae .propagate_audit_ready
 mov rbx,[r13+NEBO_PRIVACY_AUDIT_OFFSET]
.propagate_audit_ready:
 mov [r15+NEBO_PRIVACY_TEXT_OFFSET],r14
 mov rax,[rsp+8]
 mov [r15+NEBO_PRIVACY_TRUST_OFFSET],rax
 mov [r15+NEBO_PRIVACY_QUALITY_OFFSET],r8
 mov [r15+NEBO_PRIVACY_CONFIDENCE_OFFSET],r9
 mov rax,[rsp]
 mov [r15+NEBO_PRIVACY_LINEAGE_OFFSET],rax
 mov [r15+NEBO_PRIVACY_LABEL_OFFSET],r10
 mov [r15+NEBO_PRIVACY_FLAGS_OFFSET],r11
 mov [r15+NEBO_PRIVACY_AUDIT_OFFSET],rbx
 xor eax,eax
.propagate_saved_error:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.propagate_null:
 mov eax,NEBO_PRIVACY_ERROR_NULL
 ret
.propagate_label:
 mov eax,NEBO_PRIVACY_ERROR_LABEL
 ret

; Internal deterministic audit event. rdi=metadata, rsi=event, rdx=out id.
align 16
privacy_audit_event:
 mov rdi,[rdi+NEBO_PRIVACY_LINEAGE_OFFSET]
 test rdi,rdi
 jnz .audit_has_parent
 mov edi,0x52463834
.audit_has_parent:
 jmp neboc_lineage_merge

; rdi=input metadata, rsi=redaction policy, rdx=out metadata.
align 16
neboc_privacy_redact:
 test rdi,rdi
 jz .redact_null
 test rdx,rdx
 jz .redact_null
 cmp rsi,NEBO_REDACTION_POLICY_FULL
 jne .redact_policy
 push r12
 push r13
 push r14
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rsi,NEBO_AUDIT_ACTION_REDACT
 xor rsi,r13
 lea rdx,[rsp]
 call privacy_audit_event
 test eax,eax
 jnz .redact_restore
 xor ecx,ecx
.redact_copy:
 mov rax,[r12+rcx]
 mov [r14+rcx],rax
 add rcx,8
 cmp rcx,NEBO_PRIVACY_METADATA_SIZE
 jb .redact_copy
 lea rax,[rel text_privacy_redacted_text]
 mov [r14+NEBO_PRIVACY_TEXT_OFFSET],rax
 mov qword [r14+NEBO_PRIVACY_LABEL_OFFSET],NEBO_PRIVACY_REDACTED
 or qword [r14+NEBO_PRIVACY_FLAGS_OFFSET],NEBO_PRIVACY_FLAG_CLASSIFIED|NEBO_PRIVACY_FLAG_REDACTED
 mov rax,[rsp]
 mov [r14+NEBO_PRIVACY_AUDIT_OFFSET],rax
 xor eax,eax
.redact_restore:
 add rsp,16
 pop r14
 pop r13
 pop r12
 ret
.redact_null:
 mov eax,NEBO_PRIVACY_ERROR_NULL
 ret
.redact_policy:
 mov eax,NEBO_PRIVACY_ERROR_POLICY
 ret

; rdi=input, esi=target label, rdx=policy id, rcx=capability, r8=out.
align 16
neboc_privacy_declassify:
 test rdi,rdi
 jz .declass_null
 test r8,r8
 jz .declass_null
 cmp esi,NEBO_PRIVACY_LABEL_MAX
 ja .declass_label
 cmp rsi,[rdi+NEBO_PRIVACY_LABEL_OFFSET]
 ja .declass_policy
 test rdx,rdx
 jz .declass_policy
 mov rax,NEBO_DECLASSIFY_CAPABILITY_V1
 cmp rcx,rax
 jne .declass_capability
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,r8
 mov rsi,NEBO_AUDIT_ACTION_DECLASSIFY
 xor rsi,r14
 lea rdx,[rsp]
 call privacy_audit_event
 test eax,eax
 jnz .declass_restore
 xor ebx,ebx
.declass_copy:
 mov rax,[r12+rbx]
 mov [r15+rbx],rax
 add rbx,8
 cmp rbx,NEBO_PRIVACY_METADATA_SIZE
 jb .declass_copy
 mov [r15+NEBO_PRIVACY_LABEL_OFFSET],r13
 or qword [r15+NEBO_PRIVACY_FLAGS_OFFSET],NEBO_PRIVACY_FLAG_CLASSIFIED|NEBO_PRIVACY_FLAG_DECLASSIFIED
 mov rax,[rsp]
 mov [r15+NEBO_PRIVACY_AUDIT_OFFSET],rax
 xor eax,eax
.declass_restore:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.declass_null:
 mov eax,NEBO_PRIVACY_ERROR_NULL
 ret
.declass_label:
 mov eax,NEBO_PRIVACY_ERROR_LABEL
 ret
.declass_policy:
 mov eax,NEBO_PRIVACY_ERROR_POLICY
 ret
.declass_capability:
 mov eax,NEBO_PRIVACY_ERROR_CAPABILITY
 ret

; edi=label, esi=maximum accepted restriction, eax=boolean or negative error.
align 16
neboc_sink_policy_accepts:
 cmp edi,NEBO_PRIVACY_LABEL_MAX
 ja .sink_accept_invalid
 cmp esi,NEBO_PRIVACY_LABEL_MAX
 ja .sink_accept_invalid
 xor eax,eax
 cmp edi,esi
 ja .sink_accept_done
 mov eax,1
.sink_accept_done:
 ret
.sink_accept_invalid:
 mov eax,-NEBO_PRIVACY_ERROR_LABEL
 ret

; rdi=metadata, esi=sink maximum, rdx=structured violation output.
align 16
neboc_privacy_sink_check:
 test rdi,rdi
 jz .sink_check_null
 test rdx,rdx
 jz .sink_check_null
 mov r8,[rdi+NEBO_PRIVACY_LABEL_OFFSET]
 cmp r8,NEBO_PRIVACY_LABEL_MAX
 ja .sink_check_label
 cmp esi,NEBO_PRIVACY_LABEL_MAX
 ja .sink_check_label
 cmp r8,rsi
 ja .sink_check_violation
 mov qword [rdx+NEBO_VIOLATION_LABEL_OFFSET],0
 mov qword [rdx+NEBO_VIOLATION_SINK_MAX_OFFSET],0
 mov qword [rdx+NEBO_VIOLATION_DIAGNOSTIC_OFFSET],0
 mov qword [rdx+NEBO_VIOLATION_AUDIT_OFFSET],0
 xor eax,eax
 ret
.sink_check_violation:
 mov [rdx+NEBO_VIOLATION_LABEL_OFFSET],r8
 mov [rdx+NEBO_VIOLATION_SINK_MAX_OFFSET],rsi
 mov qword [rdx+NEBO_VIOLATION_DIAGNOSTIC_OFFSET],NEBO_DIAG_PRIVACY_SINK
 mov rcx,[rdi+NEBO_PRIVACY_AUDIT_OFFSET]
 mov [rdx+NEBO_VIOLATION_AUDIT_OFFSET],rcx
 mov eax,NEBO_PRIVACY_ERROR_SINK
 ret
.sink_check_null:
 mov eax,NEBO_PRIVACY_ERROR_NULL
 ret
.sink_check_label:
 mov eax,NEBO_PRIVACY_ERROR_LABEL
 ret

; edi=typed privacy status, eax=stable diagnostic code or zero for success.
align 16
neboc_privacy_error_diagnostic:
 xor eax,eax
 test edi,edi
 jz .diagnostic_done
 cmp edi,NEBO_PRIVACY_ERROR_NULL
 je .diagnostic_null
 cmp edi,NEBO_PRIVACY_ERROR_TRUST_ZONE
 je .diagnostic_trust
 cmp edi,NEBO_PRIVACY_ERROR_VALIDATION
 je .diagnostic_validation
 cmp edi,NEBO_PRIVACY_ERROR_SCORE
 je .diagnostic_score
 cmp edi,NEBO_PRIVACY_ERROR_LINEAGE
 je .diagnostic_lineage
 cmp edi,NEBO_PRIVACY_ERROR_LABEL
 je .diagnostic_label
 cmp edi,NEBO_PRIVACY_ERROR_CAPABILITY
 je .diagnostic_capability
 cmp edi,NEBO_PRIVACY_ERROR_SINK
 je .diagnostic_sink
 cmp edi,NEBO_PRIVACY_ERROR_POLICY
 je .diagnostic_policy
 mov eax,-NEBO_PRIVACY_ERROR_POLICY
 ret
.diagnostic_null:
 mov eax,NEBO_DIAG_PRIVACY_NULL
 ret
.diagnostic_trust:
 mov eax,NEBO_DIAG_PRIVACY_TRUST_ZONE
 ret
.diagnostic_validation:
 mov eax,NEBO_DIAG_PRIVACY_VALIDATION
 ret
.diagnostic_score:
 mov eax,NEBO_DIAG_PRIVACY_SCORE
 ret
.diagnostic_lineage:
 mov eax,NEBO_DIAG_PRIVACY_LINEAGE
 ret
.diagnostic_label:
 mov eax,NEBO_DIAG_PRIVACY_LABEL
 ret
.diagnostic_capability:
 mov eax,NEBO_DIAG_PRIVACY_CAPABILITY
 ret
.diagnostic_sink:
 mov eax,NEBO_DIAG_PRIVACY_SINK
 ret
.diagnostic_policy:
 mov eax,NEBO_DIAG_PRIVACY_POLICY
.diagnostic_done:
 ret

; rdi=metadata, eax=1 when security-changing flags have an audit id.
align 16
neboc_privacy_audit_valid:
 xor eax,eax
 test rdi,rdi
 jz .audit_valid_done
 mov rcx,[rdi+NEBO_PRIVACY_FLAGS_OFFSET]
 and ecx,NEBO_PRIVACY_FLAG_REDACTED|NEBO_PRIVACY_FLAG_DECLASSIFIED
 jz .audit_valid_yes
 cmp qword [rdi+NEBO_PRIVACY_AUDIT_OFFSET],0
 je .audit_valid_done
.audit_valid_yes:
 mov eax,1
.audit_valid_done:
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
