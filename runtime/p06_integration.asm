bits 64
default rel

%include "runtime/p06_integration.inc"
%include "runtime/internal_console_abi.inc"

extern nebo_servicos_internos_visual_console_e_visual_panel_closeout_contract_validate
extern nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_closeout_contract_validate
extern nebo_servicos_internos_visual_chart_e_visual_table_closeout_contract_validate
extern nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_closeout_contract_validate
extern nebo_servicos_visual_export_e_visual_privacy_record_replay_closeout_contract_validate
extern nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_closeout_contract_validate

section .text
global nebo_p06_contract_validate
nebo_p06_contract_validate:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    mov [rsp], rdi
    mov [rsp + 8], rsi
    mov [rsp + 16], rdx
    test rdx, rdx
    jz .invalid
    mov rdi, [rsp]
    mov rsi, [rsp + 8]
    lea rdx, [rsp + 24]
    call nebo_servicos_internos_visual_console_e_visual_panel_closeout_contract_validate
    test eax, eax
    jne .done
    mov rdi, [rsp]
    mov rsi, [rsp + 8]
    lea rdx, [rsp + 24]
    call nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_closeout_contract_validate
    test eax, eax
    jne .done
    mov rdi, [rsp]
    mov rsi, [rsp + 8]
    lea rdx, [rsp + 24]
    call nebo_servicos_internos_visual_chart_e_visual_table_closeout_contract_validate
    test eax, eax
    jne .done
    mov rdi, [rsp]
    mov rsi, [rsp + 8]
    lea rdx, [rsp + 24]
    call nebo_servicos_visual_dashboard_visual_ml_visual_media_e_visual_graph_closeout_contract_validate
    test eax, eax
    jne .done
    mov rdi, [rsp]
    mov rsi, [rsp + 8]
    lea rdx, [rsp + 24]
    call nebo_servicos_visual_export_e_visual_privacy_record_replay_closeout_contract_validate
    test eax, eax
    jne .done
    mov rdi, [rsp]
    mov rsi, [rsp + 8]
    lea rdx, [rsp + 24]
    call nebo_abi_interno_runtime_assembly_capabilities_e_renderer_plugins_closeout_contract_validate
    test eax, eax
    jne .done
    mov rdx, [rsp + 16]
    mov rcx, [rsp + 24]
    mov [rdx], rcx
    xor eax, eax
    jmp .done
.invalid:
    mov eax, NEBO_INTERNAL_ERR_INVALID
.done:
    leave
    ret
