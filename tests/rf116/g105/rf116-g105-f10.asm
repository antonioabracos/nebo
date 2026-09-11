bits 64
default rel
global _start
extern nebo_scan_console_forms_choices_e_input_visual_closeout_contract_validate

section .text
_start:
    mov rdi, 8
    mov rsi, 4
    mov rdx, 1
    call nebo_scan_console_forms_choices_e_input_visual_closeout_contract_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 4
    mov rdx, 1
    call nebo_scan_console_forms_choices_e_input_visual_closeout_contract_validate
    cmp eax, -1
    jne .fail
    mov rdi, 8
    mov rsi, 4
    mov rdx, 4
    call nebo_scan_console_forms_choices_e_input_visual_closeout_contract_validate
    cmp eax, -1
    jne .fail
    mov rdi, 8
    mov rsi, 4
    mov rdx, 1
    call nebo_scan_console_forms_choices_e_input_visual_closeout_contract_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
