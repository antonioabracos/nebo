bits 64
default rel
global _start
extern nebo_charts_2d_axes_series_e_validacao_numerica_scatter_points_nebo
extern nebo_charts_2d_axes_series_e_validacao_numerica_histogram_nebo
section .text
_start:
    mov rdi, 100
    mov rsi, 10
    mov rdx, 0
    call nebo_charts_2d_axes_series_e_validacao_numerica_histogram_nebo
    test rax, rax
    jne .fail
    mov rdi, 10
    mov rsi, 2
    mov rdx, 0
    call nebo_charts_2d_axes_series_e_validacao_numerica_scatter_points_nebo
    test rax, rax
    jne .fail
    mov rdi, 10
    mov rsi, 3
    mov rdx, 0
    call nebo_charts_2d_axes_series_e_validacao_numerica_scatter_points_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
