bits 64
default rel

%include "runtime/scan_console.inc"

section .text
global nebo_scan_console_adapter_validate
nebo_scan_console_adapter_validate:
    cmp rdi, 1
    jl .invalid_nebo_scan_console_adapter_validate
    cmp rdi, 64
    jg .invalid_nebo_scan_console_adapter_validate
    cmp rsi, 0
    jl .invalid_nebo_scan_console_adapter_validate
    cmp rsi, 4
    jg .invalid_nebo_scan_console_adapter_validate
    cmp rdx, 0
    jl .invalid_nebo_scan_console_adapter_validate
    cmp rdx, 3
    jg .invalid_nebo_scan_console_adapter_validate
    xor eax, eax
    ret
.invalid_nebo_scan_console_adapter_validate:
    mov eax, -1
    ret


global nebo_form_metadata_validate
nebo_form_metadata_validate:
    cmp rdi, 1
    jl .invalid_nebo_form_metadata_validate
    cmp rdi, 64
    jg .invalid_nebo_form_metadata_validate
    cmp rsi, 0
    jl .invalid_nebo_form_metadata_validate
    cmp rsi, 4
    jg .invalid_nebo_form_metadata_validate
    cmp rdx, 0
    jl .invalid_nebo_form_metadata_validate
    cmp rdx, 3
    jg .invalid_nebo_form_metadata_validate
    xor eax, eax
    ret
.invalid_nebo_form_metadata_validate:
    mov eax, -1
    ret


global nebo_feedback_style_validate
nebo_feedback_style_validate:
    cmp rdi, 1
    jl .invalid_nebo_feedback_style_validate
    cmp rdi, 64
    jg .invalid_nebo_feedback_style_validate
    cmp rsi, 0
    jl .invalid_nebo_feedback_style_validate
    cmp rsi, 4
    jg .invalid_nebo_feedback_style_validate
    cmp rdx, 0
    jl .invalid_nebo_feedback_style_validate
    cmp rdx, 3
    jg .invalid_nebo_feedback_style_validate
    xor eax, eax
    ret
.invalid_nebo_feedback_style_validate:
    mov eax, -1
    ret


global nebo_multiline_input_validate
nebo_multiline_input_validate:
    cmp rdi, 1
    jl .invalid_nebo_multiline_input_validate
    cmp rdi, 64
    jg .invalid_nebo_multiline_input_validate
    cmp rsi, 0
    jl .invalid_nebo_multiline_input_validate
    cmp rsi, 4
    jg .invalid_nebo_multiline_input_validate
    cmp rdx, 0
    jl .invalid_nebo_multiline_input_validate
    cmp rdx, 3
    jg .invalid_nebo_multiline_input_validate
    xor eax, eax
    ret
.invalid_nebo_multiline_input_validate:
    mov eax, -1
    ret


global nebo_choice_model_validate
nebo_choice_model_validate:
    cmp rdi, 1
    jl .invalid_nebo_choice_model_validate
    cmp rdi, 64
    jg .invalid_nebo_choice_model_validate
    cmp rsi, 0
    jl .invalid_nebo_choice_model_validate
    cmp rsi, 4
    jg .invalid_nebo_choice_model_validate
    cmp rdx, 0
    jl .invalid_nebo_choice_model_validate
    cmp rdx, 3
    jg .invalid_nebo_choice_model_validate
    xor eax, eax
    ret
.invalid_nebo_choice_model_validate:
    mov eax, -1
    ret


global nebo_security_policy_validate
nebo_security_policy_validate:
    cmp rdi, 1
    jl .invalid_nebo_security_policy_validate
    cmp rdi, 64
    jg .invalid_nebo_security_policy_validate
    cmp rsi, 0
    jl .invalid_nebo_security_policy_validate
    cmp rsi, 4
    jg .invalid_nebo_security_policy_validate
    cmp rdx, 0
    jl .invalid_nebo_security_policy_validate
    cmp rdx, 3
    jg .invalid_nebo_security_policy_validate
    xor eax, eax
    ret
.invalid_nebo_security_policy_validate:
    mov eax, -1
    ret


global nebo_request_response_validate
nebo_request_response_validate:
    cmp rdi, 1
    jl .invalid_nebo_request_response_validate
    cmp rdi, 64
    jg .invalid_nebo_request_response_validate
    cmp rsi, 0
    jl .invalid_nebo_request_response_validate
    cmp rsi, 4
    jg .invalid_nebo_request_response_validate
    cmp rdx, 0
    jl .invalid_nebo_request_response_validate
    cmp rdx, 3
    jg .invalid_nebo_request_response_validate
    xor eax, eax
    ret
.invalid_nebo_request_response_validate:
    mov eax, -1
    ret


global nebo_validation_retry_validate
nebo_validation_retry_validate:
    cmp rdi, 1
    jl .invalid_nebo_validation_retry_validate
    cmp rdi, 64
    jg .invalid_nebo_validation_retry_validate
    cmp rsi, 0
    jl .invalid_nebo_validation_retry_validate
    cmp rsi, 4
    jg .invalid_nebo_validation_retry_validate
    cmp rdx, 0
    jl .invalid_nebo_validation_retry_validate
    cmp rdx, 3
    jg .invalid_nebo_validation_retry_validate
    xor eax, eax
    ret
.invalid_nebo_validation_retry_validate:
    mov eax, -1
    ret


global nebo_live_fallback_replay_validate
nebo_live_fallback_replay_validate:
    cmp rdi, 1
    jl .invalid_nebo_live_fallback_replay_validate
    cmp rdi, 64
    jg .invalid_nebo_live_fallback_replay_validate
    cmp rsi, 0
    jl .invalid_nebo_live_fallback_replay_validate
    cmp rsi, 4
    jg .invalid_nebo_live_fallback_replay_validate
    cmp rdx, 0
    jl .invalid_nebo_live_fallback_replay_validate
    cmp rdx, 3
    jg .invalid_nebo_live_fallback_replay_validate
    xor eax, eax
    ret
.invalid_nebo_live_fallback_replay_validate:
    mov eax, -1
    ret


global nebo_scan_console_forms_choices_e_input_visual_closeout_contract_validate
nebo_scan_console_forms_choices_e_input_visual_closeout_contract_validate:
    cmp rdi, 1
    jl scan_console_forms_choices_e_input_visual_closeout_.invalid_nebo_contract_validate
    cmp rdi, 64
    jg scan_console_forms_choices_e_input_visual_closeout_.invalid_nebo_contract_validate
    cmp rsi, 0
    jl scan_console_forms_choices_e_input_visual_closeout_.invalid_nebo_contract_validate
    cmp rsi, 4
    jg scan_console_forms_choices_e_input_visual_closeout_.invalid_nebo_contract_validate
    cmp rdx, 0
    jl scan_console_forms_choices_e_input_visual_closeout_.invalid_nebo_contract_validate
    cmp rdx, 3
    jg scan_console_forms_choices_e_input_visual_closeout_.invalid_nebo_contract_validate
    xor eax, eax
    ret
scan_console_forms_choices_e_input_visual_closeout_.invalid_nebo_contract_validate:
    mov eax, -1
    ret
