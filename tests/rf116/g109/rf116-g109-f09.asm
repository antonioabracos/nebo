bits 64
default rel
global _start
extern nebo_diagnostics_explain_inspection_e_renderer_profiler_closeout_contract_validate
extern nebo_p05_contract_validate

section .text
_start:
    mov rdi, 8
    mov rsi, 4
    mov rdx, 1
    call nebo_diagnostics_explain_inspection_e_renderer_profiler_closeout_contract_validate
    test eax, eax
    jne .fail
    mov rdi, 0
    mov rsi, 4
    mov rdx, 1
    call nebo_diagnostics_explain_inspection_e_renderer_profiler_closeout_contract_validate
    cmp eax, -1
    jne .fail
    mov rdi, 8
    mov rsi, 4
    mov rdx, 9
    call nebo_diagnostics_explain_inspection_e_renderer_profiler_closeout_contract_validate
    cmp eax, -1
    jne .fail
    mov rdi, 8
    mov rsi, 4
    mov rdx, 1
    call nebo_diagnostics_explain_inspection_e_renderer_profiler_closeout_contract_validate
    test eax, eax
    jne .fail

    mov rdi, 8
    mov rsi, 4
    mov rdx, 1
    call nebo_p05_contract_validate
    test eax, eax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
