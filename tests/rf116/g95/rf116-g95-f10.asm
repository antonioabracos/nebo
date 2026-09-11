bits 64
default rel
global _start
extern nebo_charts_2d_axes_series_e_validacao_numerica_closeout_nebo
extern nebo_charts_2d_axes_series_e_validacao_numerica_headless_visual_differential_conformance_nebo
section .text
_start:
    mov rdi, 1
    mov rsi, 100
    mov rdx, 0
    call nebo_charts_2d_axes_series_e_validacao_numerica_headless_visual_differential_conformance_nebo
    test rax, rax
    jne .fail
    mov rdi, 1000
    mov rsi, 8
    mov rdx, 2
    call nebo_charts_2d_axes_series_e_validacao_numerica_closeout_nebo
    test rax, rax
    jne .fail
    mov rdi, 1000
    mov rsi, 65
    mov rdx, 2
    call nebo_charts_2d_axes_series_e_validacao_numerica_closeout_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
