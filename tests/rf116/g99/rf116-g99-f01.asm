bits 64
default rel
global _start
extern nebo_dashboards_panels_cells_e_composicao_multi_view_dashboard_create_spec_nebo
section .text
_start:
    mov rdi, 8
    mov rsi, 1
    mov rdx, 0
    call nebo_dashboards_panels_cells_e_composicao_multi_view_dashboard_create_spec_nebo
    test rax, rax
    jne .fail
    mov rdi, 65
    mov rsi, 1
    mov rdx, 0
    call nebo_dashboards_panels_cells_e_composicao_multi_view_dashboard_create_spec_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
