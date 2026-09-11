bits 64
default rel
global _start
extern nebo_dashboards_panels_cells_e_composicao_multi_view_add_text_chart_table_timeline_nebo
extern nebo_dashboards_panels_cells_e_composicao_multi_view_panel_composition_nebo
section .text
_start:
    mov rdi, 8
    mov rsi, 4
    mov rdx, 0
    call nebo_dashboards_panels_cells_e_composicao_multi_view_panel_composition_nebo
    test rax, rax
    jne .fail
    mov rdi, 1
    mov rsi, 8
    mov rdx, 0
    call nebo_dashboards_panels_cells_e_composicao_multi_view_add_text_chart_table_timeline_nebo
    test rax, rax
    jne .fail
    mov rdi, 5
    mov rsi, 8
    mov rdx, 0
    call nebo_dashboards_panels_cells_e_composicao_multi_view_add_text_chart_table_timeline_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
