bits 64
default rel
section .text
global nebo_matrix_tensor_volume_e_comparacao_cientifica_matrix_views_nebo
nebo_matrix_tensor_volume_e_comparacao_cientifica_matrix_views_nebo:
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
; END MATRIX-TENSOR-VOLUME-E-COMPARACAO-CIENTIFICA-MATRIX-VIEWS-F01

global nebo_matrix_tensor_volume_e_comparacao_cientifica_tensor_base_e_shape_inspector_nebo
nebo_matrix_tensor_volume_e_comparacao_cientifica_tensor_base_e_shape_inspector_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 16
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 65536
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END MATRIX-TENSOR-VOLUME-E-COMPARACAO-CIENTIFICA-TENSOR-BASE-E-SHAPE-INSPECTOR-F02

global nebo_matrix_tensor_volume_e_comparacao_cientifica_tensor_slices_axis_index_nebo
nebo_matrix_tensor_volume_e_comparacao_cientifica_tensor_slices_axis_index_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 16
    jg .invalid
    cmp rsi, 0
    jl .invalid
    cmp rsi, 15
    jg .invalid
    cmp rsi, rdi
    jge .invalid
    cmp rdx, 0
    jl .invalid
    cmp rdx, 65535
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END MATRIX-TENSOR-VOLUME-E-COMPARACAO-CIENTIFICA-TENSOR-SLICES-AXIS-INDEX-F03

global nebo_matrix_tensor_volume_e_comparacao_cientifica_volume_slices_nebo
nebo_matrix_tensor_volume_e_comparacao_cientifica_volume_slices_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 256
    jg .invalid
    cmp rsi, 0
    jl .invalid
    cmp rsi, 2
    jg .invalid
    cmp rdx, rdi
    jge .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END MATRIX-TENSOR-VOLUME-E-COMPARACAO-CIENTIFICA-VOLUME-SLICES-F04

global nebo_matrix_tensor_volume_e_comparacao_cientifica_isosurface_threshold_nebo
nebo_matrix_tensor_volume_e_comparacao_cientifica_isosurface_threshold_nebo:
    cmp rdi, 0
    jl .invalid
    cmp rdi, 65535
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 65536
    jg .invalid
    cmp rdx, 1
    jl .invalid
    cmp rdx, 3
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END MATRIX-TENSOR-VOLUME-E-COMPARACAO-CIENTIFICA-ISOSURFACE-THRESHOLD-F05

global nebo_matrix_tensor_volume_e_comparacao_cientifica_compare_with_metric_nebo
nebo_matrix_tensor_volume_e_comparacao_cientifica_compare_with_metric_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 65536
    jg .invalid
    cmp rdi, rsi
    jne .invalid
    cmp rdx, 1
    jl .invalid
    cmp rdx, 4
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END MATRIX-TENSOR-VOLUME-E-COMPARACAO-CIENTIFICA-COMPARE-WITH-METRIC-F06

global nebo_matrix_tensor_volume_e_comparacao_cientifica_colormap_quality_nebo
nebo_matrix_tensor_volume_e_comparacao_cientifica_colormap_quality_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 8
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 3
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END MATRIX-TENSOR-VOLUME-E-COMPARACAO-CIENTIFICA-COLORMAP-QUALITY-F07

global nebo_matrix_tensor_volume_e_comparacao_cientifica_large_tensor_bounded_views_nebo
nebo_matrix_tensor_volume_e_comparacao_cientifica_large_tensor_bounded_views_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 65536
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 16
    jg .invalid
    cmp rdx, 1
    jl .invalid
    cmp rdx, 3
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END MATRIX-TENSOR-VOLUME-E-COMPARACAO-CIENTIFICA-LARGE-TENSOR-BOUNDED-VIEWS-F08

global nebo_matrix_tensor_volume_e_comparacao_cientifica_scientific_reference_oracles_nebo
nebo_matrix_tensor_volume_e_comparacao_cientifica_scientific_reference_oracles_nebo:
    cmp rdi, rsi
    jne .invalid
    cmp rdx, 0
    jl .invalid
    cmp rdx, 1000
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END MATRIX-TENSOR-VOLUME-E-COMPARACAO-CIENTIFICA-SCIENTIFIC-REFERENCE-ORACLES-F09

global nebo_matrix_tensor_volume_e_comparacao_cientifica_closeout_nebo
nebo_matrix_tensor_volume_e_comparacao_cientifica_closeout_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 16
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 65536
    jg .invalid
    cmp rdx, 1
    jl .invalid
    cmp rdx, 3
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END MATRIX-TENSOR-VOLUME-E-COMPARACAO-CIENTIFICA-CLOSEOUT-F10
