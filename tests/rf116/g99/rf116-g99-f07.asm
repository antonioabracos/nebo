bits 64
default rel
global _start
extern nebo_dashboards_panels_cells_e_composicao_multi_view_cross_widget_interactions_nebo
extern nebo_dashboards_panels_cells_e_composicao_multi_view_dashboard_export_nebo
section .text
_start:
    mov rdi, 1
    mov rsi, 4096
    mov rdx, 1
    call nebo_dashboards_panels_cells_e_composicao_multi_view_dashboard_export_nebo
    test rax, rax
    jne .fail
    mov rdi, 8
    mov rsi, 2
    mov rdx, 3
    call nebo_dashboards_panels_cells_e_composicao_multi_view_cross_widget_interactions_nebo
    test rax, rax
    jne .fail
    mov rdi, 8
    mov rsi, 2
    mov rdx, 2
    call nebo_dashboards_panels_cells_e_composicao_multi_view_cross_widget_interactions_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
