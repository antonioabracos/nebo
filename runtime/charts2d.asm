bits 64
default rel
section .text
global nebo_charts_2d_axes_series_e_validacao_numerica_chart_plot_kind_registry_nebo
nebo_charts_2d_axes_series_e_validacao_numerica_chart_plot_kind_registry_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 6
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END CHARTS-2D-AXES-SERIES-E-VALIDACAO-NUMERICA-CHART-PLOT-KIND-REGISTRY-F01

global nebo_charts_2d_axes_series_e_validacao_numerica_line_e_time_series_nebo
nebo_charts_2d_axes_series_e_validacao_numerica_line_e_time_series_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 100000
    jg .invalid
    cmp rsi, 0
    jl .invalid
    cmp rsi, 1
    jg .invalid
    cmp rdx, 1
    jl .invalid
    cmp rdx, 64
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END CHARTS-2D-AXES-SERIES-E-VALIDACAO-NUMERICA-LINE-E-TIME-SERIES-F02

global nebo_charts_2d_axes_series_e_validacao_numerica_bar_nebo
nebo_charts_2d_axes_series_e_validacao_numerica_bar_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 100000
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 1024
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END CHARTS-2D-AXES-SERIES-E-VALIDACAO-NUMERICA-BAR-F03

global nebo_charts_2d_axes_series_e_validacao_numerica_histogram_nebo
nebo_charts_2d_axes_series_e_validacao_numerica_histogram_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 100000
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 4096
    jg .invalid
    cmp rsi, rdi
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END CHARTS-2D-AXES-SERIES-E-VALIDACAO-NUMERICA-HISTOGRAM-F04

global nebo_charts_2d_axes_series_e_validacao_numerica_scatter_points_nebo
nebo_charts_2d_axes_series_e_validacao_numerica_scatter_points_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 100000
    jg .invalid
    cmp rsi, 2
    jne .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END CHARTS-2D-AXES-SERIES-E-VALIDACAO-NUMERICA-SCATTER-POINTS-F05

global nebo_charts_2d_axes_series_e_validacao_numerica_heatmap_matrix_nebo
nebo_charts_2d_axes_series_e_validacao_numerica_heatmap_matrix_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 256
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 256
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END CHARTS-2D-AXES-SERIES-E-VALIDACAO-NUMERICA-HEATMAP-MATRIX-F06

global nebo_charts_2d_axes_series_e_validacao_numerica_x_y_axes_e_labels_nebo
nebo_charts_2d_axes_series_e_validacao_numerica_x_y_axes_e_labels_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 3
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 4096
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END CHARTS-2D-AXES-SERIES-E-VALIDACAO-NUMERICA-X-Y-AXES-E-LABELS-F07

global nebo_charts_2d_axes_series_e_validacao_numerica_bins_legend_labels_colorby_sizeby_nebo
nebo_charts_2d_axes_series_e_validacao_numerica_bins_legend_labels_colorby_sizeby_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 64
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 4096
    jg .invalid
    cmp rdx, 0
    jl .invalid
    cmp rdx, 1
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END CHARTS-2D-AXES-SERIES-E-VALIDACAO-NUMERICA-BINS-LEGEND-LABELS-COLORBY-SIZEBY-F08

global nebo_charts_2d_axes_series_e_validacao_numerica_headless_visual_differential_conformance_nebo
nebo_charts_2d_axes_series_e_validacao_numerica_headless_visual_differential_conformance_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 6
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 100000
    jg .invalid
    cmp rdx, 0
    jl .invalid
    cmp rdx, 1
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END CHARTS-2D-AXES-SERIES-E-VALIDACAO-NUMERICA-HEADLESS-VISUAL-DIFFERENTIAL-CONFORMANCE-F09

global nebo_charts_2d_axes_series_e_validacao_numerica_closeout_nebo
nebo_charts_2d_axes_series_e_validacao_numerica_closeout_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 100000
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 64
    jg .invalid
    cmp rdx, 1
    jl .invalid
    cmp rdx, 6
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END CHARTS-2D-AXES-SERIES-E-VALIDACAO-NUMERICA-CLOSEOUT-F10
