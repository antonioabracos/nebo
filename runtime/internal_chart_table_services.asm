bits 64
default rel

%include "runtime/internal_chart_table_services.inc"

section .text
global nebo_servicos_internos_visual_chart_e_visual_table_chart_line_bar_contract_validate
nebo_servicos_internos_visual_chart_e_visual_table_chart_line_bar_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_chart_e_visual_table_chart_line_bar_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_chart_e_visual_table_chart_line_bar_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_internos_visual_chart_e_visual_table_chart_line_bar_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_chart_e_visual_table_chart_line_bar_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_chart_e_visual_table_chart_line_bar_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_chart_e_visual_table_chart_line_bar_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_chart_e_visual_table_chart_line_bar_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_chart_e_visual_table_scatter_histogram_contract_validate
nebo_servicos_internos_visual_chart_e_visual_table_scatter_histogram_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_chart_e_visual_table_scatter_histogram_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_chart_e_visual_table_scatter_histogram_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_internos_visual_chart_e_visual_table_scatter_histogram_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_chart_e_visual_table_scatter_histogram_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_chart_e_visual_table_scatter_histogram_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_chart_e_visual_table_scatter_histogram_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_chart_e_visual_table_scatter_histogram_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_chart_e_visual_table_heatmap_matrix_confusion_contract_validate
nebo_servicos_internos_visual_chart_e_visual_table_heatmap_matrix_confusion_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_chart_e_visual_table_heatmap_matrix_confusion_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_chart_e_visual_table_heatmap_matrix_confusion_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_internos_visual_chart_e_visual_table_heatmap_matrix_confusion_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_chart_e_visual_table_heatmap_matrix_confusion_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_chart_e_visual_table_heatmap_matrix_confusion_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_chart_e_visual_table_heatmap_matrix_confusion_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_chart_e_visual_table_heatmap_matrix_confusion_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_chart_e_visual_table_timeseries_aggregate_contract_validate
nebo_servicos_internos_visual_chart_e_visual_table_timeseries_aggregate_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_chart_e_visual_table_timeseries_aggregate_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_chart_e_visual_table_timeseries_aggregate_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_internos_visual_chart_e_visual_table_timeseries_aggregate_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_chart_e_visual_table_timeseries_aggregate_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_chart_e_visual_table_timeseries_aggregate_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_chart_e_visual_table_timeseries_aggregate_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_chart_e_visual_table_timeseries_aggregate_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_chart_e_visual_table_table_preview_schema_profile_contract_validate
nebo_servicos_internos_visual_chart_e_visual_table_table_preview_schema_profile_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_chart_e_visual_table_table_preview_schema_profile_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_chart_e_visual_table_table_preview_schema_profile_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_internos_visual_chart_e_visual_table_table_preview_schema_profile_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_chart_e_visual_table_table_preview_schema_profile_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_chart_e_visual_table_table_preview_schema_profile_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_chart_e_visual_table_table_preview_schema_profile_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_chart_e_visual_table_table_preview_schema_profile_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_chart_e_visual_table_sample_limits_contract_validate
nebo_servicos_internos_visual_chart_e_visual_table_sample_limits_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_chart_e_visual_table_sample_limits_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_chart_e_visual_table_sample_limits_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_internos_visual_chart_e_visual_table_sample_limits_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_chart_e_visual_table_sample_limits_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_chart_e_visual_table_sample_limits_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_chart_e_visual_table_sample_limits_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_chart_e_visual_table_sample_limits_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_chart_e_visual_table_redact_sort_filtersummary_contract_validate
nebo_servicos_internos_visual_chart_e_visual_table_redact_sort_filtersummary_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_chart_e_visual_table_redact_sort_filtersummary_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_chart_e_visual_table_redact_sort_filtersummary_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_internos_visual_chart_e_visual_table_redact_sort_filtersummary_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_chart_e_visual_table_redact_sort_filtersummary_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_chart_e_visual_table_redact_sort_filtersummary_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_chart_e_visual_table_redact_sort_filtersummary_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_chart_e_visual_table_redact_sort_filtersummary_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_chart_e_visual_table_service_to_receiver_migration_contract_validate
nebo_servicos_internos_visual_chart_e_visual_table_service_to_receiver_migration_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_chart_e_visual_table_service_to_receiver_migration_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_chart_e_visual_table_service_to_receiver_migration_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_internos_visual_chart_e_visual_table_service_to_receiver_migration_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_chart_e_visual_table_service_to_receiver_migration_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_chart_e_visual_table_service_to_receiver_migration_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_chart_e_visual_table_service_to_receiver_migration_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_chart_e_visual_table_service_to_receiver_migration_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret

global nebo_servicos_internos_visual_chart_e_visual_table_closeout_contract_validate
nebo_servicos_internos_visual_chart_e_visual_table_closeout_contract_validate:
    test rdx, rdx
    jz servicos_internos_visual_chart_e_visual_table_closeout_.invalid_nebo_contract_validate
    cmp rdi, 1
    jl servicos_internos_visual_chart_e_visual_table_closeout_.invalid_nebo_contract_validate
    cmp rdi, 4096
    jg servicos_internos_visual_chart_e_visual_table_closeout_.bounds_nebo_contract_validate
    cmp rsi, 0
    jl servicos_internos_visual_chart_e_visual_table_closeout_.invalid_nebo_contract_validate
    cmp rsi, 64
    jg servicos_internos_visual_chart_e_visual_table_closeout_.bounds_nebo_contract_validate
    lea rax, [rdi + rsi]
    mov [rdx], rax
    xor eax, eax
    ret
servicos_internos_visual_chart_e_visual_table_closeout_.invalid_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_INVALID
    ret
servicos_internos_visual_chart_e_visual_table_closeout_.bounds_nebo_contract_validate:
    mov eax, NEBO_INTERNAL_ERR_BOUNDS
    ret
