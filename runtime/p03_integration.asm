bits 64
default rel
section .text
global nebo_dashboards_panels_cells_e_composicao_multi_view_closeout_nebo
nebo_dashboards_panels_cells_e_composicao_multi_view_closeout_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 64
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 6
    jg .invalid
    cmp rdx, 1
    jl .invalid
    cmp rdx, 16
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END DASHBOARDS-PANELS-CELLS-E-COMPOSICAO-MULTI-VIEW-CLOSEOUT-F09
