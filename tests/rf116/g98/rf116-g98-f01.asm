bits 64
default rel
global _start
extern nebo_graph_tree_embeddings_e_projections_graph_renderer_nebo
section .text
_start:
    mov rdi, 100
    mov rsi, 200
    mov rdx, 0
    call nebo_graph_tree_embeddings_e_projections_graph_renderer_nebo
    test rax, rax
    jne .fail
    mov rdi, 4097
    mov rsi, 200
    mov rdx, 0
    call nebo_graph_tree_embeddings_e_projections_graph_renderer_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
