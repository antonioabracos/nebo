bits 64
default rel
global _start
extern nebo_matrix_tensor_volume_e_comparacao_cientifica_tensor_slices_axis_index_nebo
extern nebo_matrix_tensor_volume_e_comparacao_cientifica_tensor_base_e_shape_inspector_nebo
section .text
_start:
    mov rdi, 4
    mov rsi, 4096
    mov rdx, 0
    call nebo_matrix_tensor_volume_e_comparacao_cientifica_tensor_base_e_shape_inspector_nebo
    test rax, rax
    jne .fail
    mov rdi, 4
    mov rsi, 2
    mov rdx, 3
    call nebo_matrix_tensor_volume_e_comparacao_cientifica_tensor_slices_axis_index_nebo
    test rax, rax
    jne .fail
    mov rdi, 4
    mov rsi, 4
    mov rdx, 0
    call nebo_matrix_tensor_volume_e_comparacao_cientifica_tensor_slices_axis_index_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
