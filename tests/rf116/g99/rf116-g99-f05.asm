bits 64
default rel
global _start
extern nebo_dashboards_panels_cells_e_composicao_multi_view_layout_present_show_nebo
extern nebo_dashboards_panels_cells_e_composicao_multi_view_cell_logpanel_source_nebo
section .text
_start:
    mov rdi, 2
    mov rsi, 3
    mov rdx, 10
    call nebo_dashboards_panels_cells_e_composicao_multi_view_cell_logpanel_source_nebo
    test rax, rax
    jne .fail
    mov rdi, 8
    mov rsi, 2
    mov rdx, 4
    call nebo_dashboards_panels_cells_e_composicao_multi_view_layout_present_show_nebo
    test rax, rax
    jne .fail
    mov rdi, 9
    mov rsi, 2
    mov rdx, 4
    call nebo_dashboards_panels_cells_e_composicao_multi_view_layout_present_show_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
