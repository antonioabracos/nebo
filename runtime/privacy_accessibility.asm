bits 64
default rel

%include "runtime/privacy_accessibility.inc"

section .text
global nebo_privacy_classification_validate
nebo_privacy_classification_validate:
    cmp rdi, 1
    jl .invalid_nebo_privacy_classification_validate
    cmp rdi, 32
    jg .invalid_nebo_privacy_classification_validate
    cmp rsi, 0
    jl .invalid_nebo_privacy_classification_validate
    cmp rsi, 15
    jg .invalid_nebo_privacy_classification_validate
    cmp rdx, 0
    jl .invalid_nebo_privacy_classification_validate
    cmp rdx, 3
    jg .invalid_nebo_privacy_classification_validate
    xor eax, eax
    ret
.invalid_nebo_privacy_classification_validate:
    mov eax, -1
    ret


global nebo_redact_mask_validate
nebo_redact_mask_validate:
    cmp rdi, 1
    jl .invalid_nebo_redact_mask_validate
    cmp rdi, 32
    jg .invalid_nebo_redact_mask_validate
    cmp rsi, 0
    jl .invalid_nebo_redact_mask_validate
    cmp rsi, 15
    jg .invalid_nebo_redact_mask_validate
    cmp rdx, 0
    jl .invalid_nebo_redact_mask_validate
    cmp rdx, 3
    jg .invalid_nebo_redact_mask_validate
    xor eax, eax
    ret
.invalid_nebo_redact_mask_validate:
    mov eax, -1
    ret


global nebo_allow_deny_policy_validate
nebo_allow_deny_policy_validate:
    cmp rdi, 1
    jl .invalid_nebo_allow_deny_policy_validate
    cmp rdi, 32
    jg .invalid_nebo_allow_deny_policy_validate
    cmp rsi, 0
    jl .invalid_nebo_allow_deny_policy_validate
    cmp rsi, 15
    jg .invalid_nebo_allow_deny_policy_validate
    cmp rdx, 0
    jl .invalid_nebo_allow_deny_policy_validate
    cmp rdx, 3
    jg .invalid_nebo_allow_deny_policy_validate
    xor eax, eax
    ret
.invalid_nebo_allow_deny_policy_validate:
    mov eax, -1
    ret


global nebo_quality_lineage_validate
nebo_quality_lineage_validate:
    cmp rdi, 1
    jl .invalid_nebo_quality_lineage_validate
    cmp rdi, 32
    jg .invalid_nebo_quality_lineage_validate
    cmp rsi, 0
    jl .invalid_nebo_quality_lineage_validate
    cmp rsi, 15
    jg .invalid_nebo_quality_lineage_validate
    cmp rdx, 0
    jl .invalid_nebo_quality_lineage_validate
    cmp rdx, 3
    jg .invalid_nebo_quality_lineage_validate
    xor eax, eax
    ret
.invalid_nebo_quality_lineage_validate:
    mov eax, -1
    ret


global nebo_trust_zones_validate
nebo_trust_zones_validate:
    cmp rdi, 1
    jl .invalid_nebo_trust_zones_validate
    cmp rdi, 32
    jg .invalid_nebo_trust_zones_validate
    cmp rsi, 0
    jl .invalid_nebo_trust_zones_validate
    cmp rsi, 15
    jg .invalid_nebo_trust_zones_validate
    cmp rdx, 0
    jl .invalid_nebo_trust_zones_validate
    cmp rdx, 3
    jg .invalid_nebo_trust_zones_validate
    xor eax, eax
    ret
.invalid_nebo_trust_zones_validate:
    mov eax, -1
    ret


global nebo_safe_display_validate
nebo_safe_display_validate:
    cmp rdi, 1
    jl .invalid_nebo_safe_display_validate
    cmp rdi, 32
    jg .invalid_nebo_safe_display_validate
    cmp rsi, 0
    jl .invalid_nebo_safe_display_validate
    cmp rsi, 15
    jg .invalid_nebo_safe_display_validate
    cmp rdx, 0
    jl .invalid_nebo_safe_display_validate
    cmp rdx, 3
    jg .invalid_nebo_safe_display_validate
    xor eax, eax
    ret
.invalid_nebo_safe_display_validate:
    mov eax, -1
    ret


global nebo_accessibility_validate
nebo_accessibility_validate:
    cmp rdi, 1
    jl .invalid_nebo_accessibility_validate
    cmp rdi, 32
    jg .invalid_nebo_accessibility_validate
    cmp rsi, 0
    jl .invalid_nebo_accessibility_validate
    cmp rsi, 15
    jg .invalid_nebo_accessibility_validate
    cmp rdx, 0
    jl .invalid_nebo_accessibility_validate
    cmp rdx, 3
    jg .invalid_nebo_accessibility_validate
    xor eax, eax
    ret
.invalid_nebo_accessibility_validate:
    mov eax, -1
    ret


global nebo_contrast_reader_validate
nebo_contrast_reader_validate:
    cmp rdi, 1
    jl .invalid_nebo_contrast_reader_validate
    cmp rdi, 32
    jg .invalid_nebo_contrast_reader_validate
    cmp rsi, 0
    jl .invalid_nebo_contrast_reader_validate
    cmp rsi, 15
    jg .invalid_nebo_contrast_reader_validate
    cmp rdx, 0
    jl .invalid_nebo_contrast_reader_validate
    cmp rdx, 3
    jg .invalid_nebo_contrast_reader_validate
    xor eax, eax
    ret
.invalid_nebo_contrast_reader_validate:
    mov eax, -1
    ret


global nebo_audit_report_validate
nebo_audit_report_validate:
    cmp rdi, 1
    jl .invalid_nebo_audit_report_validate
    cmp rdi, 32
    jg .invalid_nebo_audit_report_validate
    cmp rsi, 0
    jl .invalid_nebo_audit_report_validate
    cmp rsi, 15
    jg .invalid_nebo_audit_report_validate
    cmp rdx, 0
    jl .invalid_nebo_audit_report_validate
    cmp rdx, 3
    jg .invalid_nebo_audit_report_validate
    xor eax, eax
    ret
.invalid_nebo_audit_report_validate:
    mov eax, -1
    ret


global nebo_privacy_trust_quality_lineage_e_acessibilidade_closeout_contract_validate
nebo_privacy_trust_quality_lineage_e_acessibilidade_closeout_contract_validate:
    cmp rdi, 1
    jl privacy_trust_quality_lineage_e_acessibilidade_closeout_.invalid_nebo_contract_validate
    cmp rdi, 32
    jg privacy_trust_quality_lineage_e_acessibilidade_closeout_.invalid_nebo_contract_validate
    cmp rsi, 0
    jl privacy_trust_quality_lineage_e_acessibilidade_closeout_.invalid_nebo_contract_validate
    cmp rsi, 15
    jg privacy_trust_quality_lineage_e_acessibilidade_closeout_.invalid_nebo_contract_validate
    cmp rdx, 0
    jl privacy_trust_quality_lineage_e_acessibilidade_closeout_.invalid_nebo_contract_validate
    cmp rdx, 3
    jg privacy_trust_quality_lineage_e_acessibilidade_closeout_.invalid_nebo_contract_validate
    xor eax, eax
    ret
privacy_trust_quality_lineage_e_acessibilidade_closeout_.invalid_nebo_contract_validate:
    mov eax, -1
    ret
