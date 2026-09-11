bits 64
default rel
global _start
extern nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_log_levels_contract_validate

%include "runtime/internal_observability_services.inc"

section .note.GNU-stack noalloc noexec nowrite progbits

section .bss
result_value: resq 1

section .text
_start:
    mov rax, 0x1122334455667788
    mov [result_value], rax
    mov rdi, 5
    mov rsi, 4
    lea rdx, [result_value]
    call nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_log_levels_contract_validate
    test eax, eax
    jne .fail
    cmp qword [result_value], 9
    jne .fail

    mov rax, 0x1122334455667788
    mov [result_value], rax
    mov rdi, 4097
    mov rsi, 4
    lea rdx, [result_value]
    call nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_log_levels_contract_validate
    cmp eax, NEBO_INTERNAL_ERR_BOUNDS
    jne .fail
    mov rax, 0x1122334455667788
    cmp [result_value], rax
    jne .fail

    mov rdi, 0
    mov rsi, 4
    lea rdx, [result_value]
    call nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_log_levels_contract_validate
    cmp eax, NEBO_INTERNAL_ERR_INVALID
    jne .fail
    mov rax, 0x1122334455667788
    cmp [result_value], rax
    jne .fail

    mov rdi, 5
    mov rsi, 4
    xor edx, edx
    call nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_log_levels_contract_validate
    cmp eax, NEBO_INTERNAL_ERR_INVALID
    jne .fail

    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
