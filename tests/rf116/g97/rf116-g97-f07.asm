bits 64
default rel
global _start
extern nebo_matrix_tensor_volume_e_comparacao_cientifica_colormap_quality_nebo
extern nebo_matrix_tensor_volume_e_comparacao_cientifica_compare_with_metric_nebo
section .text
_start:
    mov rdi, 4096
    mov rsi, 4096
    mov rdx, 1
    call nebo_matrix_tensor_volume_e_comparacao_cientifica_compare_with_metric_nebo
    test rax, rax
    jne .fail
    mov rdi, 1
    mov rsi, 2
    mov rdx, 0
    call nebo_matrix_tensor_volume_e_comparacao_cientifica_colormap_quality_nebo
    test rax, rax
    jne .fail
    mov rdi, 9
    mov rsi, 2
    mov rdx, 0
    call nebo_matrix_tensor_volume_e_comparacao_cientifica_colormap_quality_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
