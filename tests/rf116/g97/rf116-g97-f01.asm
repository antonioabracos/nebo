bits 64
default rel
global _start
extern nebo_matrix_tensor_volume_e_comparacao_cientifica_matrix_views_nebo
section .text
_start:
    mov rdi, 16
    mov rsi, 16
    mov rdx, 0
    call nebo_matrix_tensor_volume_e_comparacao_cientifica_matrix_views_nebo
    test rax, rax
    jne .fail
    mov rdi, 257
    mov rsi, 1
    mov rdx, 0
    call nebo_matrix_tensor_volume_e_comparacao_cientifica_matrix_views_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
