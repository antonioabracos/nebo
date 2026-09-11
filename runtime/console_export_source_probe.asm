; Source-to-effect bridge for G114 export/privacy internal host services.
bits 64
default rel
%define NEBO_G114_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/console_export_source_probe.inc"

section .note.GNU-stack noalloc noexec nowrite progbits

section .bss align=16
g114_clear_begin:
g114_spec: resb NEBO_G114_SPEC_SIZE
g114_receipts: resb NEBO_G114_OPERATION_COUNT*NEBO_G114_RECEIPT_SIZE
g114_live_receipt: resb NEBO_G114_RECEIPT_SIZE
g114_negative_receipt: resb NEBO_G114_RECEIPT_SIZE
g114_last_mode: resq 1
g114_last_seed: resq 1
g114_clear_end:

section .text
global nebo_g114_source_probe
global nebo_g114_surface_probe
global nebo_g114_negative_probe

g114_probe_clear:
    lea rdi,[rel g114_clear_begin]
    mov ecx,(g114_clear_end-g114_clear_begin)/8
    xor eax,eax
    cld
    rep stosq
    ret

; EDI=subgroup 1..9, ESI=source seed 3401..3409.
nebo_g114_source_probe:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov ebx,edi
    mov ebp,esi
    cmp ebx,1
    jb .invalid
    cmp ebx,NEBO_G114_SOURCE_MAX_MODE
    ja .invalid
    cmp ebp,NEBO_G114_SOURCE_MIN_SEED
    jb .invalid
    cmp ebp,NEBO_G114_SOURCE_MAX_SEED
    ja .invalid
    mov eax,ebp
    sub eax,3400
    cmp eax,ebx
    jne .invalid
    call g114_probe_clear
    mov [rel g114_last_mode],rbx
    mov [rel g114_last_seed],rbp

    mov qword [rel g114_spec+NEBO_G114_SPEC_VERSION_OFFSET],NEBO_G114_SPEC_VERSION
    mov qword [rel g114_spec+NEBO_G114_SPEC_TARGET_OFFSET],NEBO_G114_TARGET_HEADLESS
    mov rax,rbp
    imul rax,rax,17
    mov rdx,0x4731313450415448
    xor rax,rdx
    mov [rel g114_spec+NEBO_G114_SPEC_PATH_DIGEST_OFFSET],rax
    mov rax,rbp
    imul rax,rax,131
    mov rdx,0x473131345041594c
    xor rax,rdx
    mov [rel g114_spec+NEBO_G114_SPEC_PAYLOAD_DIGEST_OFFSET],rax
    lea rax,[rbx+64]
    mov [rel g114_spec+NEBO_G114_SPEC_PAYLOAD_UNITS_OFFSET],rax
    mov [rel g114_spec+NEBO_G114_SPEC_GENERATION_OFFSET],rbp
    mov [rel g114_spec+NEBO_G114_SPEC_OWNER_GENERATION_OFFSET],rbp
    mov [rel g114_spec+NEBO_G114_SPEC_VIEW_GENERATION_OFFSET],rbp
    mov qword [rel g114_spec+NEBO_G114_SPEC_PRIVACY_OFFSET],NEBO_G114_PRIVACY_SENSITIVE
    mov qword [rel g114_spec+NEBO_G114_SPEC_CAPABILITIES_OFFSET],NEBO_G114_CAPABILITY_ALL
    mov qword [rel g114_spec+NEBO_G114_SPEC_POLICY_ACTION_OFFSET],NEBO_G114_POLICY_REDACT
    lea rax,[rbx+30]
    mov [rel g114_spec+NEBO_G114_SPEC_RETENTION_OFFSET],rax
    mov qword [rel g114_spec+NEBO_G114_SPEC_PERMISSION_OFFSET],NEBO_G114_PERMISSION_ALL
    mov qword [rel g114_spec+NEBO_G114_SPEC_RECORD_HANDLE_OFFSET],0
    mov rax,rbp
    imul rax,rax,257
    mov rdx,0x47313134534f5552
    xor rax,rdx
    mov [rel g114_spec+NEBO_G114_SPEC_SOURCE_DIGEST_OFFSET],rax
    mov rax,rbx
    shl rax,32
    or rax,rbp
    mov rdx,NEBO_G114_REQUIRED_FLAGS
    or rax,rdx
    mov [rel g114_spec+NEBO_G114_SPEC_FLAGS_OFFSET],rax

    lea r12,[rel g114_spec]
    lea r13,[rel g114_receipts]
%macro G114_CALL 2
    mov rdi,r12
    lea rsi,[r13+(%2-1)*NEBO_G114_RECEIPT_SIZE]
    call %1
    test eax,eax
    jnz .effect
    cmp qword [r13+(%2-1)*NEBO_G114_RECEIPT_SIZE+NEBO_G114_RECEIPT_OPERATION_OFFSET],%2
    jne .effect
    cmp qword [r13+(%2-1)*NEBO_G114_RECEIPT_SIZE+NEBO_G114_RECEIPT_MATURITY_OFFSET],NEBO_G114_MATURITY_INTERNAL_EXPORT_PRIVACY_SERVICES_GREEN
    jne .effect
    cmp qword [r13+(%2-1)*NEBO_G114_RECEIPT_SIZE+NEBO_G114_RECEIPT_ARTIFACT_DIGEST_OFFSET],0
    je .effect
    cmp qword [r13+(%2-1)*NEBO_G114_RECEIPT_SIZE+NEBO_G114_RECEIPT_AUDIT_DIGEST_OFFSET],0
    je .effect
%endmacro
    G114_CALL nebo_g114_export_text,NEBO_G114_EXPORT_TEXT
    G114_CALL nebo_g114_export_html,NEBO_G114_EXPORT_HTML
    G114_CALL nebo_g114_export_image,NEBO_G114_EXPORT_IMAGE
    G114_CALL nebo_g114_record,NEBO_G114_RECORD
    mov rax,[r13+(NEBO_G114_RECORD-1)*NEBO_G114_RECEIPT_SIZE+NEBO_G114_RECEIPT_RECORD_HANDLE_OFFSET]
    test rax,rax
    jz .effect
    mov [rel g114_spec+NEBO_G114_SPEC_RECORD_HANDLE_OFFSET],rax
    G114_CALL nebo_g114_stop_record,NEBO_G114_STOP_RECORD
    G114_CALL nebo_g114_replay,NEBO_G114_REPLAY
    G114_CALL nebo_g114_snapshot,NEBO_G114_SNAPSHOT
    mov qword [rel g114_spec+NEBO_G114_SPEC_POLICY_ACTION_OFFSET],NEBO_G114_POLICY_REDACT
    G114_CALL nebo_g114_redact_fields,NEBO_G114_REDACT_FIELDS
    mov qword [rel g114_spec+NEBO_G114_SPEC_POLICY_ACTION_OFFSET],NEBO_G114_POLICY_MASK
    G114_CALL nebo_g114_mask,NEBO_G114_MASK
    mov qword [rel g114_spec+NEBO_G114_SPEC_POLICY_ACTION_OFFSET],NEBO_G114_POLICY_ALLOW
    G114_CALL nebo_g114_allow,NEBO_G114_ALLOW
    mov qword [rel g114_spec+NEBO_G114_SPEC_POLICY_ACTION_OFFSET],NEBO_G114_POLICY_DENY
    G114_CALL nebo_g114_deny,NEBO_G114_DENY
    mov qword [rel g114_spec+NEBO_G114_SPEC_POLICY_ACTION_OFFSET],NEBO_G114_POLICY_REDACT
    G114_CALL nebo_g114_policy,NEBO_G114_POLICY
    G114_CALL nebo_g114_apply,NEBO_G114_APPLY
    G114_CALL nebo_g114_report,NEBO_G114_REPORT
%undef G114_CALL

    ; Live and headless adapters must preserve both logical digests.
    mov qword [rel g114_spec+NEBO_G114_SPEC_TARGET_OFFSET],NEBO_G114_TARGET_LIVE
    mov qword [rel g114_spec+NEBO_G114_SPEC_RECORD_HANDLE_OFFSET],0
    mov rdi,r12
    lea rsi,[rel g114_live_receipt]
    call nebo_g114_export_text
    test eax,eax
    jnz .effect
    mov rax,[rel g114_live_receipt+NEBO_G114_RECEIPT_ARTIFACT_DIGEST_OFFSET]
    cmp rax,[r13+NEBO_G114_RECEIPT_ARTIFACT_DIGEST_OFFSET]
    jne .effect
    mov rax,[rel g114_live_receipt+NEBO_G114_RECEIPT_AUDIT_DIGEST_OFFSET]
    cmp rax,[r13+NEBO_G114_RECEIPT_AUDIT_DIGEST_OFFSET]
    jne .effect

    mov eax,ebp
    jmp .done
.invalid:
    mov eax,NEBO_G114_ERROR_INVALID
    jmp .done
.effect:
    mov eax,-99
.done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

; EDI=field 1..44. Fields 3..16 are artifact digests and 17..30 audit
; digests, making every public service independently observable.
nebo_g114_surface_probe:
    cmp edi,1
    je .mode
    cmp edi,2
    je .seed
    cmp edi,3
    jb .zero
    cmp edi,16
    jbe .artifact
    cmp edi,30
    jbe .audit
    cmp edi,31
    je .first_operation
    cmp edi,32
    je .last_operation
    cmp edi,33
    je .maturity
    cmp edi,34
    je .privacy
    cmp edi,35
    je .capabilities
    cmp edi,36
    je .policy
    cmp edi,37
    je .retention
    cmp edi,38
    je .permission
    cmp edi,39
    je .source
    cmp edi,40
    je .target
    cmp edi,41
    je .units
    cmp edi,42
    je .record_handle
    cmp edi,43
    je .replay_state
    cmp edi,44
    je .report_state
.zero:
    xor eax,eax
    ret
.mode: mov rax,[rel g114_last_mode]
    ret
.seed: mov rax,[rel g114_last_seed]
    ret
.artifact:
    sub edi,3
    imul edi,NEBO_G114_RECEIPT_SIZE
    lea rdx,[rel g114_receipts]
    mov rax,[rdx+rdi+NEBO_G114_RECEIPT_ARTIFACT_DIGEST_OFFSET]
    ret
.audit:
    sub edi,17
    imul edi,NEBO_G114_RECEIPT_SIZE
    lea rdx,[rel g114_receipts]
    mov rax,[rdx+rdi+NEBO_G114_RECEIPT_AUDIT_DIGEST_OFFSET]
    ret
.first_operation: mov rax,[rel g114_receipts+NEBO_G114_RECEIPT_OPERATION_OFFSET]
    ret
.last_operation: mov rax,[rel g114_receipts+(NEBO_G114_OPERATION_COUNT-1)*NEBO_G114_RECEIPT_SIZE+NEBO_G114_RECEIPT_OPERATION_OFFSET]
    ret
.maturity: mov rax,[rel g114_receipts+(NEBO_G114_OPERATION_COUNT-1)*NEBO_G114_RECEIPT_SIZE+NEBO_G114_RECEIPT_MATURITY_OFFSET]
    ret
.privacy: mov rax,[rel g114_receipts+NEBO_G114_RECEIPT_PRIVACY_OFFSET]
    ret
.capabilities: mov rax,[rel g114_receipts+NEBO_G114_RECEIPT_CAPABILITIES_OFFSET]
    ret
.policy: mov rax,[rel g114_receipts+NEBO_G114_RECEIPT_POLICY_ACTION_OFFSET]
    ret
.retention: mov rax,[rel g114_receipts+NEBO_G114_RECEIPT_RETENTION_OFFSET]
    ret
.permission: mov rax,[rel g114_receipts+NEBO_G114_RECEIPT_PERMISSION_OFFSET]
    ret
.source: mov rax,[rel g114_receipts+NEBO_G114_RECEIPT_SOURCE_DIGEST_OFFSET]
    ret
.target: mov rax,[rel g114_receipts+NEBO_G114_RECEIPT_TARGET_OFFSET]
    ret
.units: mov rax,[rel g114_receipts+NEBO_G114_RECEIPT_PAYLOAD_UNITS_OFFSET]
    ret
.record_handle: mov rax,[rel g114_receipts+(NEBO_G114_RECORD-1)*NEBO_G114_RECEIPT_SIZE+NEBO_G114_RECEIPT_RECORD_HANDLE_OFFSET]
    ret
.replay_state: mov rax,[rel g114_receipts+(NEBO_G114_REPLAY-1)*NEBO_G114_RECEIPT_SIZE+NEBO_G114_RECEIPT_STATE_OFFSET]
    ret
.report_state: mov rax,[rel g114_receipts+(NEBO_G114_REPORT-1)*NEBO_G114_RECEIPT_SIZE+NEBO_G114_RECEIPT_STATE_OFFSET]
    ret

; EDI=case 1..20. A failed service call never publishes a receipt.
nebo_g114_negative_probe:
    push rbx
    push r12
    push r13
    sub rsp,8
    mov ebx,edi
    cmp ebx,1
    jb .bad
    cmp ebx,NEBO_G114_SOURCE_NEGATIVE_COUNT
    ja .bad
    mov edi,1
    mov esi,3401
    call nebo_g114_source_probe
    cmp eax,3401
    jne .bad
    cmp ebx,1
    je .bad_mode
    cmp ebx,2
    je .bad_seed
    mov rax,0x6e65676174697665
    mov [rel g114_negative_receipt+NEBO_G114_RECEIPT_ARTIFACT_DIGEST_OFFSET],rax
    cmp ebx,3
    je .null_spec
    cmp ebx,4
    je .null_receipt
    lea rdi,[rel g114_spec]
    lea rsi,[rel g114_negative_receipt]
    cmp ebx,5
    je .version
    cmp ebx,6
    je .target
    cmp ebx,7
    je .path
    cmp ebx,8
    je .payload
    cmp ebx,9
    je .units
    cmp ebx,10
    je .privacy
    cmp ebx,11
    je .capabilities
    cmp ebx,12
    je .lifetime
    cmp ebx,13
    je .retention
    cmp ebx,14
    je .permission
    cmp ebx,15
    je .secret_export
    cmp ebx,16
    je .missing_export
    cmp ebx,17
    je .record_state
    cmp ebx,18
    je .stop_state
    cmp ebx,19
    je .redact_policy
    cmp ebx,20
    je .report_capability
    cmp ebx,21
    je .html_sanitized
    jmp .fields_selected
.bad_mode:
    xor edi,edi
    mov esi,3401
    call nebo_g114_source_probe
    cmp eax,NEBO_G114_ERROR_INVALID
    jne .bad
    jmp .ok
.bad_seed:
    mov edi,1
    mov esi,3402
    call nebo_g114_source_probe
    cmp eax,NEBO_G114_ERROR_INVALID
    jne .bad
    jmp .ok
.null_spec:
    xor edi,edi
    lea rsi,[rel g114_negative_receipt]
    mov r12d,NEBO_G114_ERROR_INVALID
    jmp .run_export
.null_receipt:
    lea rdi,[rel g114_spec]
    xor esi,esi
    call nebo_g114_export_text
    cmp eax,NEBO_G114_ERROR_INVALID
    jne .bad
    jmp .ok
.version:
    mov qword [rel g114_spec+NEBO_G114_SPEC_VERSION_OFFSET],2
    mov r12d,NEBO_G114_ERROR_VERSION
    jmp .run_export
.target:
    mov qword [rel g114_spec+NEBO_G114_SPEC_TARGET_OFFSET],3
    mov r12d,NEBO_G114_ERROR_TARGET
    jmp .run_export
.path:
    mov qword [rel g114_spec+NEBO_G114_SPEC_PATH_DIGEST_OFFSET],0
    mov r12d,NEBO_G114_ERROR_PATH
    jmp .run_export
.payload:
    mov qword [rel g114_spec+NEBO_G114_SPEC_PAYLOAD_DIGEST_OFFSET],0
    mov r12d,NEBO_G114_ERROR_INTEGRITY
    jmp .run_export
.units:
    mov qword [rel g114_spec+NEBO_G114_SPEC_PAYLOAD_UNITS_OFFSET],NEBO_G114_MAX_PAYLOAD_UNITS+1
    mov r12d,NEBO_G114_ERROR_BOUNDS
    jmp .run_export
.privacy:
    mov qword [rel g114_spec+NEBO_G114_SPEC_PRIVACY_OFFSET],4
    mov r12d,NEBO_G114_ERROR_POLICY
    jmp .run_export
.capabilities:
    mov qword [rel g114_spec+NEBO_G114_SPEC_CAPABILITIES_OFFSET],16
    mov r12d,NEBO_G114_ERROR_CAPABILITY
    jmp .run_export
.lifetime:
    inc qword [rel g114_spec+NEBO_G114_SPEC_VIEW_GENERATION_OFFSET]
    mov r12d,NEBO_G114_ERROR_LIFETIME
    jmp .run_export
.retention:
    mov qword [rel g114_spec+NEBO_G114_SPEC_RETENTION_OFFSET],NEBO_G114_MAX_RETENTION_TICKS+1
    mov r12d,NEBO_G114_ERROR_RETENTION
    jmp .run_export
.permission:
    mov qword [rel g114_spec+NEBO_G114_SPEC_PERMISSION_OFFSET],8
    mov r12d,NEBO_G114_ERROR_PERMISSION
    jmp .run_export
.secret_export:
    mov qword [rel g114_spec+NEBO_G114_SPEC_PRIVACY_OFFSET],NEBO_G114_PRIVACY_SECRET
    mov qword [rel g114_spec+NEBO_G114_SPEC_POLICY_ACTION_OFFSET],NEBO_G114_POLICY_ALLOW
    mov r12d,NEBO_G114_ERROR_POLICY
    jmp .run_export
.missing_export:
    mov qword [rel g114_spec+NEBO_G114_SPEC_CAPABILITIES_OFFSET],NEBO_G114_CAPABILITY_ALL-NEBO_G114_CAPABILITY_EXPORT
    mov r12d,NEBO_G114_ERROR_CAPABILITY
    jmp .run_export
.record_state:
    mov rax,0x6731313833696e78
    mov [rel g114_spec+NEBO_G114_SPEC_RECORD_HANDLE_OFFSET],rax
    mov r12d,NEBO_G114_ERROR_STATE
    jmp .run_record
.stop_state:
    mov qword [rel g114_spec+NEBO_G114_SPEC_RECORD_HANDLE_OFFSET],0
    mov r12d,NEBO_G114_ERROR_STATE
    jmp .run_stop
.redact_policy:
    mov qword [rel g114_spec+NEBO_G114_SPEC_POLICY_ACTION_OFFSET],NEBO_G114_POLICY_ALLOW
    mov r12d,NEBO_G114_ERROR_POLICY
    jmp .run_redact
.report_capability:
    mov qword [rel g114_spec+NEBO_G114_SPEC_CAPABILITIES_OFFSET],NEBO_G114_CAPABILITY_EXPORT|NEBO_G114_CAPABILITY_RECORD|NEBO_G114_CAPABILITY_PRIVACY
    mov r12d,NEBO_G114_ERROR_CAPABILITY
    jmp .run_report
.html_sanitized:
    mov rax,~NEBO_G114_FLAG_HTML_SANITIZED
    and [rel g114_spec+NEBO_G114_SPEC_FLAGS_OFFSET],rax
    mov r12d,NEBO_G114_ERROR_INTEGRITY
    jmp .run_html
.fields_selected:
    mov rax,~NEBO_G114_FLAG_FIELDS_SELECTED
    and [rel g114_spec+NEBO_G114_SPEC_FLAGS_OFFSET],rax
    mov qword [rel g114_spec+NEBO_G114_SPEC_POLICY_ACTION_OFFSET],NEBO_G114_POLICY_REDACT
    mov r12d,NEBO_G114_ERROR_INTEGRITY
    jmp .run_redact
.run_export:
    call nebo_g114_export_text
    jmp .verify
.run_html:
    call nebo_g114_export_html
    jmp .verify
.run_record:
    call nebo_g114_record
    jmp .verify
.run_stop:
    call nebo_g114_stop_record
    jmp .verify
.run_redact:
    call nebo_g114_redact_fields
    jmp .verify
.run_report:
    call nebo_g114_report
.verify:
    cmp eax,r12d
    jne .bad
    mov r13,0x6e65676174697665
    cmp [rel g114_negative_receipt+NEBO_G114_RECEIPT_ARTIFACT_DIGEST_OFFSET],r13
    jne .bad
.ok:
    xor eax,eax
    jmp .done
.bad:
    mov eax,1
.done:
    add rsp,8
    pop r13
    pop r12
    pop rbx
    ret
