bits 64
default rel

%include "runtime/console_diagnostics.inc"

section .text
global nebo_registry_validate
nebo_registry_validate:
    cmp rdi, 1
    jl .invalid_nebo_registry_validate
    cmp rdi, 4096
    jg .invalid_nebo_registry_validate
    cmp rsi, 0
    jl .invalid_nebo_registry_validate
    cmp rsi, 64
    jg .invalid_nebo_registry_validate
    cmp rdx, 0
    jl .invalid_nebo_registry_validate
    cmp rdx, 8
    jg .invalid_nebo_registry_validate
    xor eax, eax
    ret
.invalid_nebo_registry_validate:
    mov eax, -1
    ret


global nebo_console_options_validate
nebo_console_options_validate:
    cmp rdi, 1
    jl .invalid_nebo_console_options_validate
    cmp rdi, 4096
    jg .invalid_nebo_console_options_validate
    cmp rsi, 0
    jl .invalid_nebo_console_options_validate
    cmp rsi, 64
    jg .invalid_nebo_console_options_validate
    cmp rdx, 0
    jl .invalid_nebo_console_options_validate
    cmp rdx, 8
    jg .invalid_nebo_console_options_validate
    xor eax, eax
    ret
.invalid_nebo_console_options_validate:
    mov eax, -1
    ret


global nebo_color_validate
nebo_color_validate:
    cmp rdi, 1
    jl .invalid_nebo_color_validate
    cmp rdi, 4096
    jg .invalid_nebo_color_validate
    cmp rsi, 0
    jl .invalid_nebo_color_validate
    cmp rsi, 64
    jg .invalid_nebo_color_validate
    cmp rdx, 0
    jl .invalid_nebo_color_validate
    cmp rdx, 8
    jg .invalid_nebo_color_validate
    xor eax, eax
    ret
.invalid_nebo_color_validate:
    mov eax, -1
    ret


global nebo_const_binding_validate
nebo_const_binding_validate:
    cmp rdi, 1
    jl .invalid_nebo_const_binding_validate
    cmp rdi, 4096
    jg .invalid_nebo_const_binding_validate
    cmp rsi, 0
    jl .invalid_nebo_const_binding_validate
    cmp rsi, 64
    jg .invalid_nebo_const_binding_validate
    cmp rdx, 0
    jl .invalid_nebo_const_binding_validate
    cmp rdx, 8
    jg .invalid_nebo_const_binding_validate
    xor eax, eax
    ret
.invalid_nebo_const_binding_validate:
    mov eax, -1
    ret


global nebo_render_protocol_validate
nebo_render_protocol_validate:
    cmp rdi, 1
    jl .invalid_nebo_render_protocol_validate
    cmp rdi, 4096
    jg .invalid_nebo_render_protocol_validate
    cmp rsi, 0
    jl .invalid_nebo_render_protocol_validate
    cmp rsi, 64
    jg .invalid_nebo_render_protocol_validate
    cmp rdx, 0
    jl .invalid_nebo_render_protocol_validate
    cmp rdx, 8
    jg .invalid_nebo_render_protocol_validate
    xor eax, eax
    ret
.invalid_nebo_render_protocol_validate:
    mov eax, -1
    ret


global nebo_explain_fixit_validate
nebo_explain_fixit_validate:
    cmp rdi, 1
    jl .invalid_nebo_explain_fixit_validate
    cmp rdi, 4096
    jg .invalid_nebo_explain_fixit_validate
    cmp rsi, 0
    jl .invalid_nebo_explain_fixit_validate
    cmp rsi, 64
    jg .invalid_nebo_explain_fixit_validate
    cmp rdx, 0
    jl .invalid_nebo_explain_fixit_validate
    cmp rdx, 8
    jg .invalid_nebo_explain_fixit_validate
    xor eax, eax
    ret
.invalid_nebo_explain_fixit_validate:
    mov eax, -1
    ret


global nebo_inspect_profiler_validate
nebo_inspect_profiler_validate:
    cmp rdi, 1
    jl .invalid_nebo_inspect_profiler_validate
    cmp rdi, 4096
    jg .invalid_nebo_inspect_profiler_validate
    cmp rsi, 0
    jl .invalid_nebo_inspect_profiler_validate
    cmp rsi, 64
    jg .invalid_nebo_inspect_profiler_validate
    cmp rdx, 0
    jl .invalid_nebo_inspect_profiler_validate
    cmp rdx, 8
    jg .invalid_nebo_inspect_profiler_validate
    xor eax, eax
    ret
.invalid_nebo_inspect_profiler_validate:
    mov eax, -1
    ret


global nebo_formatter_linter_lsp_validate
nebo_formatter_linter_lsp_validate:
    cmp rdi, 1
    jl .invalid_nebo_formatter_linter_lsp_validate
    cmp rdi, 4096
    jg .invalid_nebo_formatter_linter_lsp_validate
    cmp rsi, 0
    jl .invalid_nebo_formatter_linter_lsp_validate
    cmp rsi, 64
    jg .invalid_nebo_formatter_linter_lsp_validate
    cmp rdx, 0
    jl .invalid_nebo_formatter_linter_lsp_validate
    cmp rdx, 8
    jg .invalid_nebo_formatter_linter_lsp_validate
    xor eax, eax
    ret
.invalid_nebo_formatter_linter_lsp_validate:
    mov eax, -1
    ret


global nebo_diagnostics_explain_inspection_e_renderer_profiler_closeout_contract_validate
nebo_diagnostics_explain_inspection_e_renderer_profiler_closeout_contract_validate:
    cmp rdi, 1
    jl diagnostics_explain_inspection_e_renderer_profiler_closeout_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg diagnostics_explain_inspection_e_renderer_profiler_closeout_.invalid_nebo_contract_validate
    cmp rsi, 0
    jl diagnostics_explain_inspection_e_renderer_profiler_closeout_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg diagnostics_explain_inspection_e_renderer_profiler_closeout_.invalid_nebo_contract_validate
    cmp rdx, 0
    jl diagnostics_explain_inspection_e_renderer_profiler_closeout_.invalid_nebo_contract_validate
    cmp rdx, 8
    jg diagnostics_explain_inspection_e_renderer_profiler_closeout_.invalid_nebo_contract_validate
    xor eax, eax
    ret
diagnostics_explain_inspection_e_renderer_profiler_closeout_.invalid_nebo_contract_validate:
    mov eax, -1
    ret
