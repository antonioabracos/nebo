bits 64
default rel
global _start
extern nebo_charts_2d_axes_series_e_validacao_numerica_chart_plot_kind_registry_nebo
section .text
_start:
    mov rdi, 1
    mov rsi, 0
    mov rdx, 0
    call nebo_charts_2d_axes_series_e_validacao_numerica_chart_plot_kind_registry_nebo
    test rax, rax
    jne .fail
    mov rdi, 0
    mov rsi, 0
    mov rdx, 0
    call nebo_charts_2d_axes_series_e_validacao_numerica_chart_plot_kind_registry_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
