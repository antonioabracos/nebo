bits 64
default rel
global _start
extern nebo_matrix_tensor_volume_e_comparacao_cientifica_compare_with_metric_nebo
extern nebo_matrix_tensor_volume_e_comparacao_cientifica_isosurface_threshold_nebo
section .text
_start:
    mov rdi, 32768
    mov rsi, 4096
    mov rdx, 1
    call nebo_matrix_tensor_volume_e_comparacao_cientifica_isosurface_threshold_nebo
    test rax, rax
    jne .fail
    mov rdi, 4096
    mov rsi, 4096
    mov rdx, 1
    call nebo_matrix_tensor_volume_e_comparacao_cientifica_compare_with_metric_nebo
    test rax, rax
    jne .fail
    mov rdi, 4096
    mov rsi, 2048
    mov rdx, 1
    call nebo_matrix_tensor_volume_e_comparacao_cientifica_compare_with_metric_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
