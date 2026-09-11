bits 64
default rel
global _start
extern nebo_charts_2d_axes_series_e_validacao_numerica_heatmap_matrix_nebo
extern nebo_charts_2d_axes_series_e_validacao_numerica_scatter_points_nebo
section .text
_start:
    mov rdi, 10
    mov rsi, 2
    mov rdx, 0
    call nebo_charts_2d_axes_series_e_validacao_numerica_scatter_points_nebo
    test rax, rax
    jne .fail
    mov rdi, 16
    mov rsi, 16
    mov rdx, 0
    call nebo_charts_2d_axes_series_e_validacao_numerica_heatmap_matrix_nebo
    test rax, rax
    jne .fail
    mov rdi, 257
    mov rsi, 1
    mov rdx, 0
    call nebo_charts_2d_axes_series_e_validacao_numerica_heatmap_matrix_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
