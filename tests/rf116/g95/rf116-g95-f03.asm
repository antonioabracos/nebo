bits 64
default rel
global _start
extern nebo_charts_2d_axes_series_e_validacao_numerica_bar_nebo
extern nebo_charts_2d_axes_series_e_validacao_numerica_line_e_time_series_nebo
section .text
_start:
    mov rdi, 128
    mov rsi, 1
    mov rdx, 1
    call nebo_charts_2d_axes_series_e_validacao_numerica_line_e_time_series_nebo
    test rax, rax
    jne .fail
    mov rdi, 10
    mov rsi, 20
    mov rdx, 0
    call nebo_charts_2d_axes_series_e_validacao_numerica_bar_nebo
    test rax, rax
    jne .fail
    mov rdi, 0
    mov rsi, 20
    mov rdx, 0
    call nebo_charts_2d_axes_series_e_validacao_numerica_bar_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
