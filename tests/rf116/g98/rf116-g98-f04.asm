bits 64
default rel
global _start
extern nebo_graph_tree_embeddings_e_projections_highlight_highlightpath_nebo
extern nebo_graph_tree_embeddings_e_projections_layouts_nebo
section .text
_start:
    mov rdi, 1
    mov rsi, 42
    mov rdx, 100
    call nebo_graph_tree_embeddings_e_projections_layouts_nebo
    test rax, rax
    jne .fail
    mov rdi, 100
    mov rsi, 10
    mov rdx, 5
    call nebo_graph_tree_embeddings_e_projections_highlight_highlightpath_nebo
    test rax, rax
    jne .fail
    mov rdi, 100
    mov rsi, 100
    mov rdx, 5
    call nebo_graph_tree_embeddings_e_projections_highlight_highlightpath_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
