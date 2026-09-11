; G114 bounded export, record/replay and privacy host services.
bits 64
default rel
%define NEBO_G114_EXPORT_PRIVACY_IMPLEMENTATION 1
%include "runtime/internal_export_privacy_services.inc"

section .text

%macro G114_ENTRY 2
global %1
%1:
    mov edx,%2
    jmp g114_service_build
%endmacro

G114_ENTRY nebo_g114_export_text,NEBO_G114_EXPORT_TEXT
G114_ENTRY nebo_g114_export_html,NEBO_G114_EXPORT_HTML
G114_ENTRY nebo_g114_export_image,NEBO_G114_EXPORT_IMAGE
G114_ENTRY nebo_g114_record,NEBO_G114_RECORD
G114_ENTRY nebo_g114_stop_record,NEBO_G114_STOP_RECORD
G114_ENTRY nebo_g114_replay,NEBO_G114_REPLAY
G114_ENTRY nebo_g114_snapshot,NEBO_G114_SNAPSHOT
G114_ENTRY nebo_g114_redact_fields,NEBO_G114_REDACT_FIELDS
G114_ENTRY nebo_g114_mask,NEBO_G114_MASK
G114_ENTRY nebo_g114_allow,NEBO_G114_ALLOW
G114_ENTRY nebo_g114_deny,NEBO_G114_DENY
G114_ENTRY nebo_g114_policy,NEBO_G114_POLICY
G114_ENTRY nebo_g114_apply,NEBO_G114_APPLY
G114_ENTRY nebo_g114_report,NEBO_G114_REPORT
%undef G114_ENTRY

; RDI=borrowed spec, RSI=caller-owned receipt, EDX=operation.
; All validation and receipt construction finish before publication.
g114_service_build:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,128
    mov r12,rdi
    mov r13,rsi
    mov r14d,edx
    test r12,r12
    jz g114_error_invalid
    test r13,r13
    jz g114_error_invalid
    test r12,7
    jnz g114_error_invalid
    test r13,7
    jnz g114_error_invalid
    cmp qword [r12+NEBO_G114_SPEC_VERSION_OFFSET],NEBO_G114_SPEC_VERSION
    jne g114_error_version
    mov rax,[r12+NEBO_G114_SPEC_TARGET_OFFSET]
    cmp rax,NEBO_G114_TARGET_HEADLESS
    jb g114_error_target
    cmp rax,NEBO_G114_TARGET_LIVE
    ja g114_error_target
    cmp qword [r12+NEBO_G114_SPEC_PATH_DIGEST_OFFSET],0
    je g114_error_path
    cmp qword [r12+NEBO_G114_SPEC_PAYLOAD_DIGEST_OFFSET],0
    je g114_error_integrity
    cmp qword [r12+NEBO_G114_SPEC_PAYLOAD_UNITS_OFFSET],1
    jb g114_error_bounds
    cmp qword [r12+NEBO_G114_SPEC_PAYLOAD_UNITS_OFFSET],NEBO_G114_MAX_PAYLOAD_UNITS
    ja g114_error_bounds
    cmp qword [r12+NEBO_G114_SPEC_GENERATION_OFFSET],1
    jb g114_error_invalid
    mov rax,[r12+NEBO_G114_SPEC_OWNER_GENERATION_OFFSET]
    test rax,rax
    jz g114_error_lifetime
    cmp rax,[r12+NEBO_G114_SPEC_VIEW_GENERATION_OFFSET]
    jne g114_error_lifetime
    mov rax,[r12+NEBO_G114_SPEC_PRIVACY_OFFSET]
    cmp rax,NEBO_G114_PRIVACY_PUBLIC
    jb g114_error_policy
    cmp rax,NEBO_G114_PRIVACY_SECRET
    ja g114_error_policy
    mov rax,[r12+NEBO_G114_SPEC_CAPABILITIES_OFFSET]
    test rax,rax
    jz g114_error_capability
    test rax,~NEBO_G114_CAPABILITY_ALL
    jnz g114_error_capability
    mov rax,[r12+NEBO_G114_SPEC_POLICY_ACTION_OFFSET]
    cmp rax,NEBO_G114_POLICY_ALLOW
    jb g114_error_policy
    cmp rax,NEBO_G114_POLICY_MASK
    ja g114_error_policy
    cmp qword [r12+NEBO_G114_SPEC_RETENTION_OFFSET],1
    jb g114_error_retention
    cmp qword [r12+NEBO_G114_SPEC_RETENTION_OFFSET],NEBO_G114_MAX_RETENTION_TICKS
    ja g114_error_retention
    mov rax,[r12+NEBO_G114_SPEC_PERMISSION_OFFSET]
    test rax,rax
    jz g114_error_permission
    test rax,~NEBO_G114_PERMISSION_ALL
    jnz g114_error_permission
    cmp qword [r12+NEBO_G114_SPEC_SOURCE_DIGEST_OFFSET],0
    je g114_error_integrity

    cmp r14d,NEBO_G114_EXPORT_IMAGE
    jbe .export
    cmp r14d,NEBO_G114_RECORD
    je .record
    cmp r14d,NEBO_G114_STOP_RECORD
    je .stop
    cmp r14d,NEBO_G114_REPLAY
    je .replay
    cmp r14d,NEBO_G114_SNAPSHOT
    je .snapshot
    cmp r14d,NEBO_G114_REDACT_FIELDS
    je .redact
    cmp r14d,NEBO_G114_MASK
    je .mask
    cmp r14d,NEBO_G114_ALLOW
    je .allow
    cmp r14d,NEBO_G114_DENY
    je .deny
    cmp r14d,NEBO_G114_POLICY
    je .policy
    cmp r14d,NEBO_G114_APPLY
    je .apply
    cmp r14d,NEBO_G114_REPORT
    je .report
    jmp g114_error_invalid

.export:
    test qword [r12+NEBO_G114_SPEC_CAPABILITIES_OFFSET],NEBO_G114_CAPABILITY_EXPORT
    jz g114_error_capability
    test qword [r12+NEBO_G114_SPEC_PERMISSION_OFFSET],NEBO_G114_PERMISSION_WRITE
    jz g114_error_permission
    cmp qword [r12+NEBO_G114_SPEC_POLICY_ACTION_OFFSET],NEBO_G114_POLICY_DENY
    je g114_error_policy
    cmp qword [r12+NEBO_G114_SPEC_PRIVACY_OFFSET],NEBO_G114_PRIVACY_SECRET
    jne .export_size
    mov rax,[r12+NEBO_G114_SPEC_POLICY_ACTION_OFFSET]
    cmp rax,NEBO_G114_POLICY_REDACT
    je .export_size
    cmp rax,NEBO_G114_POLICY_MASK
    jne g114_error_policy
.export_size:
    cmp r14d,NEBO_G114_EXPORT_HTML
    jne .export_image_size
    mov rax,NEBO_G114_FLAG_HTML_SANITIZED
    test qword [r12+NEBO_G114_SPEC_FLAGS_OFFSET],rax
    jz g114_error_integrity
.export_image_size:
    cmp r14d,NEBO_G114_EXPORT_IMAGE
    jne .export_state
    cmp qword [r12+NEBO_G114_SPEC_PAYLOAD_UNITS_OFFSET],NEBO_G114_MAX_IMAGE_UNITS
    ja g114_error_bounds
.export_state:
    mov r15d,NEBO_G114_STATE_CLOSED
    jmp .stage

.record:
    test qword [r12+NEBO_G114_SPEC_CAPABILITIES_OFFSET],NEBO_G114_CAPABILITY_RECORD
    jz g114_error_capability
    test qword [r12+NEBO_G114_SPEC_PERMISSION_OFFSET],NEBO_G114_PERMISSION_WRITE
    jz g114_error_permission
    cmp qword [r12+NEBO_G114_SPEC_RECORD_HANDLE_OFFSET],0
    jne g114_error_state
    call g114_require_secret_transform
    test eax,eax
    jnz g114_error_policy
    mov r15d,NEBO_G114_STATE_OPEN
    jmp .stage

.stop:
    test qword [r12+NEBO_G114_SPEC_CAPABILITIES_OFFSET],NEBO_G114_CAPABILITY_RECORD
    jz g114_error_capability
    test qword [r12+NEBO_G114_SPEC_PERMISSION_OFFSET],NEBO_G114_PERMISSION_WRITE
    jz g114_error_permission
    call g114_validate_record_handle
    test eax,eax
    jnz g114_error_state
    mov r15d,NEBO_G114_STATE_CLOSED
    jmp .stage

.replay:
    test qword [r12+NEBO_G114_SPEC_CAPABILITIES_OFFSET],NEBO_G114_CAPABILITY_RECORD
    jz g114_error_capability
    test qword [r12+NEBO_G114_SPEC_PERMISSION_OFFSET],NEBO_G114_PERMISSION_READ
    jz g114_error_permission
    call g114_validate_record_handle
    test eax,eax
    jnz g114_error_state
    call g114_require_secret_transform
    test eax,eax
    jnz g114_error_policy
    mov r15d,NEBO_G114_STATE_REPLAYED
    jmp .stage

.snapshot:
    mov rax,[r12+NEBO_G114_SPEC_CAPABILITIES_OFFSET]
    and eax,NEBO_G114_CAPABILITY_EXPORT|NEBO_G114_CAPABILITY_RECORD
    cmp eax,NEBO_G114_CAPABILITY_EXPORT|NEBO_G114_CAPABILITY_RECORD
    jne g114_error_capability
    test qword [r12+NEBO_G114_SPEC_PERMISSION_OFFSET],NEBO_G114_PERMISSION_WRITE
    jz g114_error_permission
    call g114_validate_record_handle
    test eax,eax
    jnz g114_error_state
    call g114_require_secret_transform
    test eax,eax
    jnz g114_error_policy
    mov r15d,NEBO_G114_STATE_SNAPSHOT
    jmp .stage

.redact:
    call g114_require_privacy_capability
    test eax,eax
    jnz g114_error_capability
    cmp qword [r12+NEBO_G114_SPEC_POLICY_ACTION_OFFSET],NEBO_G114_POLICY_REDACT
    jne g114_error_policy
    mov rax,NEBO_G114_FLAG_FIELDS_SELECTED
    test qword [r12+NEBO_G114_SPEC_FLAGS_OFFSET],rax
    jz g114_error_integrity
    mov r15d,NEBO_G114_STATE_REDACTED
    jmp .stage
.mask:
    call g114_require_privacy_capability
    test eax,eax
    jnz g114_error_capability
    cmp qword [r12+NEBO_G114_SPEC_POLICY_ACTION_OFFSET],NEBO_G114_POLICY_MASK
    jne g114_error_policy
    mov r15d,NEBO_G114_STATE_MASKED
    jmp .stage
.allow:
    call g114_require_privacy_capability
    test eax,eax
    jnz g114_error_capability
    cmp qword [r12+NEBO_G114_SPEC_POLICY_ACTION_OFFSET],NEBO_G114_POLICY_ALLOW
    jne g114_error_policy
    cmp qword [r12+NEBO_G114_SPEC_PRIVACY_OFFSET],NEBO_G114_PRIVACY_SECRET
    je g114_error_policy
    mov r15d,NEBO_G114_STATE_ALLOWED
    jmp .stage
.deny:
    call g114_require_privacy_capability
    test eax,eax
    jnz g114_error_capability
    cmp qword [r12+NEBO_G114_SPEC_POLICY_ACTION_OFFSET],NEBO_G114_POLICY_DENY
    jne g114_error_policy
    mov r15d,NEBO_G114_STATE_DENIED
    jmp .stage
.policy:
    call g114_require_privacy_capability
    test eax,eax
    jnz g114_error_capability
    mov r15d,NEBO_G114_STATE_POLICY
    jmp .stage
.apply:
    call g114_require_privacy_capability
    test eax,eax
    jnz g114_error_capability
    cmp qword [r12+NEBO_G114_SPEC_POLICY_ACTION_OFFSET],NEBO_G114_POLICY_DENY
    je .apply_deny
    mov r15d,NEBO_G114_STATE_APPLIED
    jmp .stage
.apply_deny:
    mov r15d,NEBO_G114_STATE_DENIED
    jmp .stage
.report:
    mov rax,[r12+NEBO_G114_SPEC_CAPABILITIES_OFFSET]
    and eax,NEBO_G114_CAPABILITY_PRIVACY|NEBO_G114_CAPABILITY_AUDIT
    cmp eax,NEBO_G114_CAPABILITY_PRIVACY|NEBO_G114_CAPABILITY_AUDIT
    jne g114_error_capability
    test qword [r12+NEBO_G114_SPEC_PERMISSION_OFFSET],NEBO_G114_PERMISSION_AUDIT
    jz g114_error_permission
    mov r15d,NEBO_G114_STATE_REPORT

.stage:
    lea rdi,[rsp]
    mov ecx,NEBO_G114_RECEIPT_SIZE/8
    xor eax,eax
    cld
    rep stosq
    mov [rsp+NEBO_G114_RECEIPT_OPERATION_OFFSET],r14
    mov rax,[r12+NEBO_G114_SPEC_TARGET_OFFSET]
    mov [rsp+NEBO_G114_RECEIPT_TARGET_OFFSET],rax
    mov [rsp+NEBO_G114_RECEIPT_STATE_OFFSET],r15
    mov rax,[r12+NEBO_G114_SPEC_PAYLOAD_UNITS_OFFSET]
    mov [rsp+NEBO_G114_RECEIPT_PAYLOAD_UNITS_OFFSET],rax
    mov rax,[r12+NEBO_G114_SPEC_GENERATION_OFFSET]
    mov [rsp+NEBO_G114_RECEIPT_GENERATION_OFFSET],rax
    mov rax,[r12+NEBO_G114_SPEC_PRIVACY_OFFSET]
    cmp r14d,NEBO_G114_REDACT_FIELDS
    je .published_public
    cmp r14d,NEBO_G114_APPLY
    jne .privacy_mask
    cmp qword [r12+NEBO_G114_SPEC_POLICY_ACTION_OFFSET],NEBO_G114_POLICY_REDACT
    je .published_public
.privacy_mask:
    cmp r14d,NEBO_G114_MASK
    je .published_sensitive
    cmp r14d,NEBO_G114_APPLY
    jne .privacy_export
    cmp qword [r12+NEBO_G114_SPEC_POLICY_ACTION_OFFSET],NEBO_G114_POLICY_MASK
    je .published_sensitive
.privacy_export:
    cmp r14d,NEBO_G114_EXPORT_IMAGE
    ja .privacy_ready
    cmp qword [r12+NEBO_G114_SPEC_POLICY_ACTION_OFFSET],NEBO_G114_POLICY_REDACT
    je .published_public
    cmp qword [r12+NEBO_G114_SPEC_POLICY_ACTION_OFFSET],NEBO_G114_POLICY_MASK
    je .published_sensitive
    jmp .privacy_ready
.published_public:
    mov eax,NEBO_G114_PRIVACY_PUBLIC
    jmp .privacy_ready
.published_sensitive:
    mov eax,NEBO_G114_PRIVACY_SENSITIVE
.privacy_ready:
    mov [rsp+NEBO_G114_RECEIPT_PRIVACY_OFFSET],rax
    mov rax,[r12+NEBO_G114_SPEC_CAPABILITIES_OFFSET]
    mov [rsp+NEBO_G114_RECEIPT_CAPABILITIES_OFFSET],rax
    mov rax,[r12+NEBO_G114_SPEC_POLICY_ACTION_OFFSET]
    mov [rsp+NEBO_G114_RECEIPT_POLICY_ACTION_OFFSET],rax
    mov rax,[r12+NEBO_G114_SPEC_RETENTION_OFFSET]
    mov [rsp+NEBO_G114_RECEIPT_RETENTION_OFFSET],rax
    mov rax,[r12+NEBO_G114_SPEC_PERMISSION_OFFSET]
    mov [rsp+NEBO_G114_RECEIPT_PERMISSION_OFFSET],rax
    mov rax,[r12+NEBO_G114_SPEC_RECORD_HANDLE_OFFSET]
    cmp r14d,NEBO_G114_RECORD
    jne .record_ready
    call g114_record_handle
.record_ready:
    mov [rsp+NEBO_G114_RECEIPT_RECORD_HANDLE_OFFSET],rax
    mov rax,[r12+NEBO_G114_SPEC_SOURCE_DIGEST_OFFSET]
    mov [rsp+NEBO_G114_RECEIPT_SOURCE_DIGEST_OFFSET],rax
    mov qword [rsp+NEBO_G114_RECEIPT_MATURITY_OFFSET],NEBO_G114_MATURITY_INTERNAL_EXPORT_PRIVACY_SERVICES_GREEN
    mov rax,[r12+NEBO_G114_SPEC_FLAGS_OFFSET]
    mov [rsp+NEBO_G114_RECEIPT_FLAGS_OFFSET],rax

    ; Target is excluded: live and headless adapters share logical artifacts.
    mov rbx,0x6731313461727431
    xor rbx,r14
    rol rbx,7
    xor rbx,r15
    rol rbx,11
    xor rbx,[r12+NEBO_G114_SPEC_PATH_DIGEST_OFFSET]
    rol rbx,13
    xor rbx,[r12+NEBO_G114_SPEC_PAYLOAD_DIGEST_OFFSET]
    rol rbx,17
    xor rbx,[r12+NEBO_G114_SPEC_PAYLOAD_UNITS_OFFSET]
    rol rbx,19
    xor rbx,[r12+NEBO_G114_SPEC_GENERATION_OFFSET]
    rol rbx,23
    xor rbx,[rsp+NEBO_G114_RECEIPT_PRIVACY_OFFSET]
    rol rbx,29
    xor rbx,[r12+NEBO_G114_SPEC_POLICY_ACTION_OFFSET]
    rol rbx,31
    xor rbx,[rsp+NEBO_G114_RECEIPT_RECORD_HANDLE_OFFSET]
    rol rbx,37
    xor rbx,[r12+NEBO_G114_SPEC_SOURCE_DIGEST_OFFSET]
    rol rbx,41
    xor rbx,[r12+NEBO_G114_SPEC_FLAGS_OFFSET]
    mov [rsp+NEBO_G114_RECEIPT_ARTIFACT_DIGEST_OFFSET],rbx

    mov rax,0x6731313461756431
    xor rax,rbx
    rol rax,9
    xor rax,[r12+NEBO_G114_SPEC_CAPABILITIES_OFFSET]
    rol rax,15
    xor rax,[rsp+NEBO_G114_RECEIPT_PRIVACY_OFFSET]
    rol rax,21
    xor rax,[r12+NEBO_G114_SPEC_POLICY_ACTION_OFFSET]
    rol rax,27
    xor rax,[r12+NEBO_G114_SPEC_RETENTION_OFFSET]
    rol rax,33
    xor rax,[r12+NEBO_G114_SPEC_PERMISSION_OFFSET]
    rol rax,39
    xor rax,[r12+NEBO_G114_SPEC_SOURCE_DIGEST_OFFSET]
    mov [rsp+NEBO_G114_RECEIPT_AUDIT_DIGEST_OFFSET],rax

    mov rdi,r13
    lea rsi,[rsp]
    mov ecx,NEBO_G114_RECEIPT_SIZE/8
    cld
    rep movsq
    xor eax,eax
    jmp g114_service_done

; Helpers preserve the service inputs in r12/r14/r15.
g114_require_privacy_capability:
    mov rax,[r12+NEBO_G114_SPEC_CAPABILITIES_OFFSET]
    and eax,NEBO_G114_CAPABILITY_PRIVACY
    cmp eax,NEBO_G114_CAPABILITY_PRIVACY
    setne al
    movzx eax,al
    ret
g114_require_secret_transform:
    cmp qword [r12+NEBO_G114_SPEC_PRIVACY_OFFSET],NEBO_G114_PRIVACY_SECRET
    jne .secret_ok
    mov rax,[r12+NEBO_G114_SPEC_POLICY_ACTION_OFFSET]
    cmp rax,NEBO_G114_POLICY_REDACT
    je .secret_ok
    cmp rax,NEBO_G114_POLICY_MASK
    je .secret_ok
    mov eax,1
    ret
.secret_ok:
    xor eax,eax
    ret
g114_record_handle:
    mov rax,[r12+NEBO_G114_SPEC_PATH_DIGEST_OFFSET]
    xor rax,[r12+NEBO_G114_SPEC_PAYLOAD_DIGEST_OFFSET]
    rol rax,17
    xor rax,[r12+NEBO_G114_SPEC_GENERATION_OFFSET]
    mov rdx,0x6731313472656331
    xor rax,rdx
    ret
g114_validate_record_handle:
    call g114_record_handle
    cmp rax,[r12+NEBO_G114_SPEC_RECORD_HANDLE_OFFSET]
    setne al
    movzx eax,al
    ret

g114_error_invalid: mov eax,NEBO_G114_ERROR_INVALID
    jmp g114_service_done
g114_error_bounds: mov eax,NEBO_G114_ERROR_BOUNDS
    jmp g114_service_done
g114_error_version: mov eax,NEBO_G114_ERROR_VERSION
    jmp g114_service_done
g114_error_target: mov eax,NEBO_G114_ERROR_TARGET
    jmp g114_service_done
g114_error_policy: mov eax,NEBO_G114_ERROR_POLICY
    jmp g114_service_done
g114_error_lifetime: mov eax,NEBO_G114_ERROR_LIFETIME
    jmp g114_service_done
g114_error_path: mov eax,NEBO_G114_ERROR_PATH
    jmp g114_service_done
g114_error_capability: mov eax,NEBO_G114_ERROR_CAPABILITY
    jmp g114_service_done
g114_error_state: mov eax,NEBO_G114_ERROR_STATE
    jmp g114_service_done
g114_error_retention: mov eax,NEBO_G114_ERROR_RETENTION
    jmp g114_service_done
g114_error_permission: mov eax,NEBO_G114_ERROR_PERMISSION
    jmp g114_service_done
g114_error_integrity: mov eax,NEBO_G114_ERROR_INTEGRITY
g114_service_done:
    add rsp,128
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Compatibility hook used by the P06 closeout aggregator. It is not a G114
; surface implementation and remains a bounded scalar readiness gate.
global nebo_servicos_visual_export_e_visual_privacy_record_replay_closeout_contract_validate
nebo_servicos_visual_export_e_visual_privacy_record_replay_closeout_contract_validate:
    test rdx,rdx
    jz .compat_invalid
    cmp rdi,1
    jb .compat_invalid
    cmp rdi,100000
    ja .compat_bounds
    cmp rsi,64
    ja .compat_bounds
    lea rax,[rdi+rsi]
    mov [rdx],rax
    xor eax,eax
    ret
.compat_invalid:
    mov eax,NEBO_G114_ERROR_INVALID
    ret
.compat_bounds:
    mov eax,NEBO_G114_ERROR_BOUNDS
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
