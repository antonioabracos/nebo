bits 64
default rel

%include "runtime/p05_integration.inc"

extern nebo_scan_console_forms_choices_e_input_visual_closeout_contract_validate
extern nebo_privacy_trust_quality_lineage_e_acessibilidade_closeout_contract_validate
extern nebo_sinks_routing_files_mirroring_e_fallback_closeout_contract_validate
extern nebo_capture_mock_snapshot_golden_record_e_replay_closeout_contract_validate
extern nebo_diagnostics_explain_inspection_e_renderer_profiler_closeout_contract_validate

section .text
global nebo_p05_contract_validate
nebo_p05_contract_validate:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rsp], rdi
    mov [rsp + 8], rsi
    call nebo_scan_console_forms_choices_e_input_visual_closeout_contract_validate
    test eax, eax
    jne .done
    mov rdi, [rsp]
    mov rsi, [rsp + 8]
    call nebo_privacy_trust_quality_lineage_e_acessibilidade_closeout_contract_validate
    test eax, eax
    jne .done
    mov rdi, [rsp]
    mov rsi, [rsp + 8]
    call nebo_sinks_routing_files_mirroring_e_fallback_closeout_contract_validate
    test eax, eax
    jne .done
    mov rdi, [rsp]
    mov rsi, [rsp + 8]
    call nebo_capture_mock_snapshot_golden_record_e_replay_closeout_contract_validate
    test eax, eax
    jne .done
    mov rdi, [rsp]
    mov rsi, [rsp + 8]
    call nebo_diagnostics_explain_inspection_e_renderer_profiler_closeout_contract_validate
.done:
    leave
    ret
