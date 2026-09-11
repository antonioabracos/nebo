bits 64
default rel
global _start
extern nebo_graph_tree_embeddings_e_projections_dependency_computational_graphs_nebo
extern nebo_graph_tree_embeddings_e_projections_projection_project_dimensions_nebo
section .text
_start:
    mov rdi, 64
    mov rsi, 2
    mov rdx, 0
    call nebo_graph_tree_embeddings_e_projections_projection_project_dimensions_nebo
    test rax, rax
    jne .fail
    mov rdi, 1
    mov rsi, 100
    mov rdx, 200
    call nebo_graph_tree_embeddings_e_projections_dependency_computational_graphs_nebo
    test rax, rax
    jne .fail
    mov rdi, 3
    mov rsi, 100
    mov rdx, 200
    call nebo_graph_tree_embeddings_e_projections_dependency_computational_graphs_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
