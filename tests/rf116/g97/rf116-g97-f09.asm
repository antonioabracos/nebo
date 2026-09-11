bits 64
default rel
global _start
extern nebo_matrix_tensor_volume_e_comparacao_cientifica_scientific_reference_oracles_nebo
extern nebo_matrix_tensor_volume_e_comparacao_cientifica_large_tensor_bounded_views_nebo
section .text
_start:
    mov rdi, 65536
    mov rsi, 16
    mov rdx, 1
    call nebo_matrix_tensor_volume_e_comparacao_cientifica_large_tensor_bounded_views_nebo
    test rax, rax
    jne .fail
    mov rdi, 1234
    mov rsi, 1234
    mov rdx, 10
    call nebo_matrix_tensor_volume_e_comparacao_cientifica_scientific_reference_oracles_nebo
    test rax, rax
    jne .fail
    mov rdi, 1234
    mov rsi, 1235
    mov rdx, 10
    call nebo_matrix_tensor_volume_e_comparacao_cientifica_scientific_reference_oracles_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
