bits 64
default rel
section .text
global nebo_dashboards_panels_cells_e_composicao_multi_view_dashboard_create_spec_nebo
nebo_dashboards_panels_cells_e_composicao_multi_view_dashboard_create_spec_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 64
    jg .invalid
    cmp rsi, 1
    jne .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END DASHBOARDS-PANELS-CELLS-E-COMPOSICAO-MULTI-VIEW-DASHBOARD-CREATE-SPEC-F01

global nebo_dashboards_panels_cells_e_composicao_multi_view_panel_composition_nebo
nebo_dashboards_panels_cells_e_composicao_multi_view_panel_composition_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 64
    jg .invalid
    cmp rsi, 0
    jl .invalid
    cmp rsi, 64
    jg .invalid
    cmp rsi, rdi
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END DASHBOARDS-PANELS-CELLS-E-COMPOSICAO-MULTI-VIEW-PANEL-COMPOSITION-F02

global nebo_dashboards_panels_cells_e_composicao_multi_view_add_text_chart_table_timeline_nebo
nebo_dashboards_panels_cells_e_composicao_multi_view_add_text_chart_table_timeline_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 4
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 64
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END DASHBOARDS-PANELS-CELLS-E-COMPOSICAO-MULTI-VIEW-ADD-TEXT-CHART-TABLE-TIMELINE-F03

global nebo_dashboards_panels_cells_e_composicao_multi_view_cell_logpanel_source_nebo
nebo_dashboards_panels_cells_e_composicao_multi_view_cell_logpanel_source_nebo:
    cmp rdi, 0
    jl .invalid
    cmp rdi, 63
    jg .invalid
    cmp rsi, 0
    jl .invalid
    cmp rsi, 63
    jg .invalid
    cmp rdx, 0
    jl .invalid
    cmp rdx, 4095
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END DASHBOARDS-PANELS-CELLS-E-COMPOSICAO-MULTI-VIEW-CELL-LOGPANEL-SOURCE-F04

global nebo_dashboards_panels_cells_e_composicao_multi_view_layout_present_show_nebo
nebo_dashboards_panels_cells_e_composicao_multi_view_layout_present_show_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 64
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 8
    jg .invalid
    cmp rdx, 1
    jl .invalid
    cmp rdx, 8
    jg .invalid
    mov rax, rsi
    imul rax, rdx
    cmp rdi, rax
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END DASHBOARDS-PANELS-CELLS-E-COMPOSICAO-MULTI-VIEW-LAYOUT-PRESENT-SHOW-F05

global nebo_dashboards_panels_cells_e_composicao_multi_view_dashboard_export_nebo
nebo_dashboards_panels_cells_e_composicao_multi_view_dashboard_export_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 3
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 1048576
    jg .invalid
    cmp rdx, 1
    jne .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END DASHBOARDS-PANELS-CELLS-E-COMPOSICAO-MULTI-VIEW-DASHBOARD-EXPORT-F06

global nebo_dashboards_panels_cells_e_composicao_multi_view_cross_widget_interactions_nebo
nebo_dashboards_panels_cells_e_composicao_multi_view_cross_widget_interactions_nebo:
    cmp rdi, 2
    jl .invalid
    cmp rdi, 64
    jg .invalid
    cmp rsi, rdi
    jge .invalid
    cmp rdx, rdi
    jge .invalid
    cmp rsi, rdx
    je .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END DASHBOARDS-PANELS-CELLS-E-COMPOSICAO-MULTI-VIEW-CROSS-WIDGET-INTERACTIONS-F07

global nebo_dashboards_panels_cells_e_composicao_multi_view_lifecycle_snapshots_nebo
nebo_dashboards_panels_cells_e_composicao_multi_view_lifecycle_snapshots_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 3
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 1048576
    jg .invalid
    cmp rdx, 1
    jl .invalid
    cmp rdx, 2147483647
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END DASHBOARDS-PANELS-CELLS-E-COMPOSICAO-MULTI-VIEW-LIFECYCLE-SNAPSHOTS-F08

global nebo_dashboards_panels_cells_e_composicao_multi_view_closeout_nebo
nebo_dashboards_panels_cells_e_composicao_multi_view_closeout_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 64
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 8
    jg .invalid
    cmp rdx, 1
    jl .invalid
    cmp rdx, 8
    jg .invalid
    mov rax, rsi
    imul rax, rdx
    cmp rdi, rax
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END DASHBOARDS-PANELS-CELLS-E-COMPOSICAO-MULTI-VIEW-CLOSEOUT-F09
