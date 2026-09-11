bits 64
default rel
global _start
extern nebo_charts_2d_axes_series_e_validacao_numerica_bins_legend_labels_colorby_sizeby_nebo
extern nebo_charts_2d_axes_series_e_validacao_numerica_x_y_axes_e_labels_nebo
section .text
_start:
    mov rdi, 3
    mov rsi, 10
    mov rdx, 0
    call nebo_charts_2d_axes_series_e_validacao_numerica_x_y_axes_e_labels_nebo
    test rax, rax
    jne .fail
    mov rdi, 4
    mov rsi, 10
    mov rdx, 1
    call nebo_charts_2d_axes_series_e_validacao_numerica_bins_legend_labels_colorby_sizeby_nebo
    test rax, rax
    jne .fail
    mov rdi, 65
    mov rsi, 10
    mov rdx, 1
    call nebo_charts_2d_axes_series_e_validacao_numerica_bins_legend_labels_colorby_sizeby_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
