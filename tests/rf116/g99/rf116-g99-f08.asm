bits 64
default rel
global _start
extern nebo_dashboards_panels_cells_e_composicao_multi_view_lifecycle_snapshots_nebo
extern nebo_dashboards_panels_cells_e_composicao_multi_view_cross_widget_interactions_nebo
section .text
_start:
    mov rdi, 8
    mov rsi, 2
    mov rdx, 3
    call nebo_dashboards_panels_cells_e_composicao_multi_view_cross_widget_interactions_nebo
    test rax, rax
    jne .fail
    mov rdi, 2
    mov rsi, 4096
    mov rdx, 1
    call nebo_dashboards_panels_cells_e_composicao_multi_view_lifecycle_snapshots_nebo
    test rax, rax
    jne .fail
    mov rdi, 4
    mov rsi, 4096
    mov rdx, 1
    call nebo_dashboards_panels_cells_e_composicao_multi_view_lifecycle_snapshots_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
