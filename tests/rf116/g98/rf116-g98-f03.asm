bits 64
default rel
global _start
extern nebo_graph_tree_embeddings_e_projections_layouts_nebo
extern nebo_graph_tree_embeddings_e_projections_tree_renderer_nebo
section .text
_start:
    mov rdi, 10
    mov rsi, 9
    mov rdx, 0
    call nebo_graph_tree_embeddings_e_projections_tree_renderer_nebo
    test rax, rax
    jne .fail
    mov rdi, 1
    mov rsi, 42
    mov rdx, 100
    call nebo_graph_tree_embeddings_e_projections_layouts_nebo
    test rax, rax
    jne .fail
    mov rdi, 5
    mov rsi, 42
    mov rdx, 100
    call nebo_graph_tree_embeddings_e_projections_layouts_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
