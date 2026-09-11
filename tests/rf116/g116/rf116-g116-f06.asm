bits 64
default rel
global _start
extern nebo_p01_prepare_console_call
extern nebo_p02_render_plan_close
extern nebo_dashboards_panels_cells_e_composicao_multi_view_closeout_nebo
extern nebo_p04_contract_validate
extern nebo_p05_contract_validate
extern nebo_p06_contract_validate
%include "runtime/color_target.inc"
%include "runtime/console_options.inc"
%include "runtime/console_call.inc"
%include "runtime/render_intent.inc"
%include "runtime/p01_integration.inc"
%include "runtime/p02_integration.inc"
section .text
_start:
    lea rdi, [rel p01_request]
    call nebo_p01_prepare_console_call
    test eax, eax
    jne .fail
    cmp qword [rel p01_plan + NEBO_RENDER_PLAN_STATE_OFFSET], NEBO_RENDER_PLAN_READY
    jne .fail
    lea rdi, [rel p02_request]
    lea rsi, [rel p02_receipt]
    call nebo_p02_render_plan_close
    test eax, eax
    jne .fail
    mov rdi, 8
    mov rsi, 2
    mov rdx, 4
    call nebo_dashboards_panels_cells_e_composicao_multi_view_closeout_nebo
    test eax, eax
    jne .fail
    mov rdi, 8
    mov rsi, 4
    mov rdx, 1
    call nebo_p04_contract_validate
    test eax, eax
    jne .fail
    mov rdi, 8
    mov rsi, 4
    mov rdx, 1
    call nebo_p05_contract_validate
    test eax, eax
    jne .fail
    mov rax, 0x1122334455667788
    mov [rel p06_result], rax
    mov rdi, 1
    mov rsi, 4
    lea rdx, [rel p06_result]
    call nebo_p06_contract_validate
    test eax, eax
    jne .fail
    cmp qword [rel p06_result], 5
    jne .fail
    mov rax, 0x1122334455667788
    mov [rel p06_result], rax
    mov rdi, 2
    mov rsi, 4
    lea rdx, [rel p06_result]
    call nebo_p06_contract_validate
    test eax, eax
    jns .fail
    mov rax, 0x1122334455667788
    cmp qword [rel p06_result], rax
    jne .fail
    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov eax, 60
    mov edi, 1
    syscall
section .data
p01_values: dq 3, 0x101820ff, 0
            dq 1, 0xffffffff, 0
p01_request: dq p01_values, 2, p01_scratch, 2
             dq NEBO_COLOR_TARGET_ANSI, NEBO_CONSOLE_EFFECT_WRITE
             dq NEBO_CONSOLE_EFFECT_WRITE, 1
             dq NEBO_CONSOLE_RETURN_RECEIPT, 0, p01_plan, p01_receipt
p02_registry: dq 2, 0x11, 1
p02_document: dq 3, 0x22, NEBO_P02_TARGET_HEADLESS, 1
p02_style: dq 0x33, NEBO_P02_TARGET_HEADLESS, 1, 1
p02_layout: dq 3, 2, 0x44, 1
p02_view: dq 8, 0x55, 1
p02_request: dq p02_registry, p02_document, p02_style, p02_layout, p02_view, 9, NEBO_P02_REQUIRED_FLAGS
section .bss
p01_scratch: resb NEBO_OPTION_VALUE_SIZE * 2
p01_plan: resb NEBO_RENDER_PLAN_SIZE
p01_receipt: resb NEBO_CONSOLE_RECEIPT_SIZE
p02_receipt: resb NEBO_P02_RECEIPT_SIZE
p06_result: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
