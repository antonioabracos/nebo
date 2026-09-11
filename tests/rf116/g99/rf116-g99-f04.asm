bits 64
default rel
global _start
extern nebo_dashboards_panels_cells_e_composicao_multi_view_cell_logpanel_source_nebo
extern nebo_dashboards_panels_cells_e_composicao_multi_view_add_text_chart_table_timeline_nebo
section .text
_start:
    mov rdi, 1
    mov rsi, 8
    mov rdx, 0
    call nebo_dashboards_panels_cells_e_composicao_multi_view_add_text_chart_table_timeline_nebo
    test rax, rax
    jne .fail
    mov rdi, 2
    mov rsi, 3
    mov rdx, 10
    call nebo_dashboards_panels_cells_e_composicao_multi_view_cell_logpanel_source_nebo
    test rax, rax
    jne .fail
    mov rdi, 64
    mov rsi, 3
    mov rdx, 10
    call nebo_dashboards_panels_cells_e_composicao_multi_view_cell_logpanel_source_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
