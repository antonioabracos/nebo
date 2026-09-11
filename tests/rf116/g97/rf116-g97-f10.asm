bits 64
default rel
global _start
extern nebo_matrix_tensor_volume_e_comparacao_cientifica_closeout_nebo
extern nebo_matrix_tensor_volume_e_comparacao_cientifica_scientific_reference_oracles_nebo
section .text
_start:
    mov rdi, 1234
    mov rsi, 1234
    mov rdx, 10
    call nebo_matrix_tensor_volume_e_comparacao_cientifica_scientific_reference_oracles_nebo
    test rax, rax
    jne .fail
    mov rdi, 4
    mov rsi, 4096
    mov rdx, 2
    call nebo_matrix_tensor_volume_e_comparacao_cientifica_closeout_nebo
    test rax, rax
    jne .fail
    mov rdi, 17
    mov rsi, 4096
    mov rdx, 2
    call nebo_matrix_tensor_volume_e_comparacao_cientifica_closeout_nebo
    cmp rax, -1
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
