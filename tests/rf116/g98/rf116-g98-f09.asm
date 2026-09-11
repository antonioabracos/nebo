bits 64
default rel
global _start
extern nebo_graph_tree_embeddings_e_projections_closeout_nebo
extern nebo_graph_tree_embeddings_e_projections_large_graph_limits_nebo
section .text
_start:
    mov rdi, 4096
    mov rsi, 16384
    mov rdx, 1048576
    call nebo_graph_tree_embeddings_e_projections_large_graph_limits_nebo
    test rax, rax
    jne .fail
    mov rdi, 100
    mov rsi, 200
    mov rdx, 2
    call nebo_graph_tree_embeddings_e_projections_closeout_nebo
    test rax, rax
    jne .fail
    mov rdi, 100
    mov rsi, 200
    mov rdx, 5
    call nebo_graph_tree_embeddings_e_projections_closeout_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
