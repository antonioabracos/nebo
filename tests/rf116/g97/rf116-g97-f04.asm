bits 64
default rel
global _start
extern nebo_matrix_tensor_volume_e_comparacao_cientifica_volume_slices_nebo
extern nebo_matrix_tensor_volume_e_comparacao_cientifica_tensor_slices_axis_index_nebo
section .text
_start:
    mov rdi, 4
    mov rsi, 2
    mov rdx, 3
    call nebo_matrix_tensor_volume_e_comparacao_cientifica_tensor_slices_axis_index_nebo
    test rax, rax
    jne .fail
    mov rdi, 64
    mov rsi, 2
    mov rdx, 10
    call nebo_matrix_tensor_volume_e_comparacao_cientifica_volume_slices_nebo
    test rax, rax
    jne .fail
    mov rdi, 64
    mov rsi, 3
    mov rdx, 0
    call nebo_matrix_tensor_volume_e_comparacao_cientifica_volume_slices_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
