bits 64
default rel
section .text
global nebo_graph_tree_embeddings_e_projections_graph_renderer_nebo
nebo_graph_tree_embeddings_e_projections_graph_renderer_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 4096
    jg .invalid
    cmp rsi, 0
    jl .invalid
    cmp rsi, 16384
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END GRAPH-TREE-EMBEDDINGS-E-PROJECTIONS-GRAPH-RENDERER-F01

global nebo_graph_tree_embeddings_e_projections_tree_renderer_nebo
nebo_graph_tree_embeddings_e_projections_tree_renderer_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 4096
    jg .invalid
    lea rax, [rdi - 1]
    cmp rsi, rax
    jne .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END GRAPH-TREE-EMBEDDINGS-E-PROJECTIONS-TREE-RENDERER-F02

global nebo_graph_tree_embeddings_e_projections_layouts_nebo
nebo_graph_tree_embeddings_e_projections_layouts_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 4
    jg .invalid
    cmp rsi, 0
    jl .invalid
    cmp rsi, 2147483647
    jg .invalid
    cmp rdx, 1
    jl .invalid
    cmp rdx, 4096
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END GRAPH-TREE-EMBEDDINGS-E-PROJECTIONS-LAYOUTS-F03

global nebo_graph_tree_embeddings_e_projections_highlight_highlightpath_nebo
nebo_graph_tree_embeddings_e_projections_highlight_highlightpath_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 4096
    jg .invalid
    cmp rsi, rdi
    jge .invalid
    cmp rdx, 1
    jl .invalid
    cmp rdx, 4096
    jg .invalid
    cmp rdx, rdi
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END GRAPH-TREE-EMBEDDINGS-E-PROJECTIONS-HIGHLIGHT-HIGHLIGHTPATH-F04

global nebo_graph_tree_embeddings_e_projections_embeddings_nebo
nebo_graph_tree_embeddings_e_projections_embeddings_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 4096
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 1024
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END GRAPH-TREE-EMBEDDINGS-E-PROJECTIONS-EMBEDDINGS-F05

global nebo_graph_tree_embeddings_e_projections_projection_project_dimensions_nebo
nebo_graph_tree_embeddings_e_projections_projection_project_dimensions_nebo:
    cmp rdi, 2
    jl .invalid
    cmp rdi, 1024
    jg .invalid
    cmp rsi, 2
    jl .invalid
    cmp rsi, 3
    jg .invalid
    cmp rsi, rdi
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END GRAPH-TREE-EMBEDDINGS-E-PROJECTIONS-PROJECTION-PROJECT-DIMENSIONS-F06

global nebo_graph_tree_embeddings_e_projections_dependency_computational_graphs_nebo
nebo_graph_tree_embeddings_e_projections_dependency_computational_graphs_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 2
    jg .invalid
    cmp rsi, 1
    jl .invalid
    cmp rsi, 4096
    jg .invalid
    cmp rdx, 0
    jl .invalid
    cmp rdx, 16384
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END GRAPH-TREE-EMBEDDINGS-E-PROJECTIONS-DEPENDENCY-COMPUTATIONAL-GRAPHS-F07

global nebo_graph_tree_embeddings_e_projections_large_graph_limits_nebo
nebo_graph_tree_embeddings_e_projections_large_graph_limits_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 4096
    jg .invalid
    cmp rsi, 0
    jl .invalid
    cmp rsi, 16384
    jg .invalid
    cmp rdx, 1
    jl .invalid
    cmp rdx, 1048576
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END GRAPH-TREE-EMBEDDINGS-E-PROJECTIONS-LARGE-GRAPH-LIMITS-F08

global nebo_graph_tree_embeddings_e_projections_closeout_nebo
nebo_graph_tree_embeddings_e_projections_closeout_nebo:
    cmp rdi, 1
    jl .invalid
    cmp rdi, 4096
    jg .invalid
    cmp rsi, 0
    jl .invalid
    cmp rsi, 16384
    jg .invalid
    cmp rdx, 1
    jl .invalid
    cmp rdx, 4
    jg .invalid
    xor eax, eax
    ret
.invalid:
    mov rax, -1
    ret
; END GRAPH-TREE-EMBEDDINGS-E-PROJECTIONS-CLOSEOUT-F09
