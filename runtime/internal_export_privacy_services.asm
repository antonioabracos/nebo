bits 64
default rel

%include "runtime/internal_export_privacy_services.inc"

section .text
global nebo_servicos_visual_export_e_visual_privacy_record_replay_export_text_html_image_contract_validate
nebo_servicos_visual_export_e_visual_privacy_record_replay_export_text_html_image_contract_validate:
    test rdx, rdx
    jz servicos_visual_export_e_visual_privacy_record_replay_export_text_html_image_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_visual_export_e_visual_privacy_record_replay_export_text_html_image_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_visual_export_e_visual_privacy_record_replay_export_text_html_image_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_visual_export_e_visual_privacy_record_replay_export_text_html_image_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_visual_export_e_visual_privacy_record_replay_export_text_html_image_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_visual_export_e_visual_privacy_record_replay_export_text_html_image_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_visual_export_e_visual_privacy_record_replay_export_text_html_image_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_visual_export_e_visual_privacy_record_replay_record_stoprecord_contract_validate
nebo_servicos_visual_export_e_visual_privacy_record_replay_record_stoprecord_contract_validate:
    test rdx, rdx
    jz servicos_visual_export_e_visual_privacy_record_replay_record_stoprecord_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_visual_export_e_visual_privacy_record_replay_record_stoprecord_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_visual_export_e_visual_privacy_record_replay_record_stoprecord_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_visual_export_e_visual_privacy_record_replay_record_stoprecord_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_visual_export_e_visual_privacy_record_replay_record_stoprecord_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_visual_export_e_visual_privacy_record_replay_record_stoprecord_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_visual_export_e_visual_privacy_record_replay_record_stoprecord_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_visual_export_e_visual_privacy_record_replay_replay_snapshot_contract_validate
nebo_servicos_visual_export_e_visual_privacy_record_replay_replay_snapshot_contract_validate:
    test rdx, rdx
    jz servicos_visual_export_e_visual_privacy_record_replay_replay_snapshot_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_visual_export_e_visual_privacy_record_replay_replay_snapshot_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_visual_export_e_visual_privacy_record_replay_replay_snapshot_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_visual_export_e_visual_privacy_record_replay_replay_snapshot_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_visual_export_e_visual_privacy_record_replay_replay_snapshot_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_visual_export_e_visual_privacy_record_replay_replay_snapshot_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_visual_export_e_visual_privacy_record_replay_replay_snapshot_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_visual_export_e_visual_privacy_record_replay_redactfields_mask_contract_validate
nebo_servicos_visual_export_e_visual_privacy_record_replay_redactfields_mask_contract_validate:
    test rdx, rdx
    jz servicos_visual_export_e_visual_privacy_record_replay_redactfields_mask_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_visual_export_e_visual_privacy_record_replay_redactfields_mask_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_visual_export_e_visual_privacy_record_replay_redactfields_mask_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_visual_export_e_visual_privacy_record_replay_redactfields_mask_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_visual_export_e_visual_privacy_record_replay_redactfields_mask_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_visual_export_e_visual_privacy_record_replay_redactfields_mask_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_visual_export_e_visual_privacy_record_replay_redactfields_mask_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_visual_export_e_visual_privacy_record_replay_allow_deny_contract_validate
nebo_servicos_visual_export_e_visual_privacy_record_replay_allow_deny_contract_validate:
    test rdx, rdx
    jz servicos_visual_export_e_visual_privacy_record_replay_allow_deny_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_visual_export_e_visual_privacy_record_replay_allow_deny_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_visual_export_e_visual_privacy_record_replay_allow_deny_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_visual_export_e_visual_privacy_record_replay_allow_deny_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_visual_export_e_visual_privacy_record_replay_allow_deny_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_visual_export_e_visual_privacy_record_replay_allow_deny_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_visual_export_e_visual_privacy_record_replay_allow_deny_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_visual_export_e_visual_privacy_record_replay_policy_apply_report_contract_validate
nebo_servicos_visual_export_e_visual_privacy_record_replay_policy_apply_report_contract_validate:
    test rdx, rdx
    jz servicos_visual_export_e_visual_privacy_record_replay_policy_apply_report_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_visual_export_e_visual_privacy_record_replay_policy_apply_report_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_visual_export_e_visual_privacy_record_replay_policy_apply_report_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_visual_export_e_visual_privacy_record_replay_policy_apply_report_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_visual_export_e_visual_privacy_record_replay_policy_apply_report_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_visual_export_e_visual_privacy_record_replay_policy_apply_report_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_visual_export_e_visual_privacy_record_replay_policy_apply_report_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_visual_export_e_visual_privacy_record_replay_migration_to_receiver_host_service_contract_validate
nebo_servicos_visual_export_e_visual_privacy_record_replay_migration_to_receiver_host_service_contract_validate:
    test rdx, rdx
    jz servicos_visual_export_e_visual_privacy_record_replay_migration_to_receiver_host_service_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_visual_export_e_visual_privacy_record_replay_migration_to_receiver_host_service_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_visual_export_e_visual_privacy_record_replay_migration_to_receiver_host_service_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_visual_export_e_visual_privacy_record_replay_migration_to_receiver_host_service_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_visual_export_e_visual_privacy_record_replay_migration_to_receiver_host_service_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_visual_export_e_visual_privacy_record_replay_migration_to_receiver_host_service_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_visual_export_e_visual_privacy_record_replay_migration_to_receiver_host_service_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_visual_export_e_visual_privacy_record_replay_retention_permissions_audit_contract_validate
nebo_servicos_visual_export_e_visual_privacy_record_replay_retention_permissions_audit_contract_validate:
    test rdx, rdx
    jz servicos_visual_export_e_visual_privacy_record_replay_retention_permissions_audit_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_visual_export_e_visual_privacy_record_replay_retention_permissions_audit_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_visual_export_e_visual_privacy_record_replay_retention_permissions_audit_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_visual_export_e_visual_privacy_record_replay_retention_permissions_audit_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_visual_export_e_visual_privacy_record_replay_retention_permissions_audit_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_visual_export_e_visual_privacy_record_replay_retention_permissions_audit_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_visual_export_e_visual_privacy_record_replay_retention_permissions_audit_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_visual_export_e_visual_privacy_record_replay_closeout_contract_validate
nebo_servicos_visual_export_e_visual_privacy_record_replay_closeout_contract_validate:
    test rdx, rdx
    jz servicos_visual_export_e_visual_privacy_record_replay_closeout_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_visual_export_e_visual_privacy_record_replay_closeout_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_visual_export_e_visual_privacy_record_replay_closeout_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_visual_export_e_visual_privacy_record_replay_closeout_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_visual_export_e_visual_privacy_record_replay_closeout_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_visual_export_e_visual_privacy_record_replay_closeout_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_visual_export_e_visual_privacy_record_replay_closeout_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret
