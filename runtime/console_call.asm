; Nebo Assembly — CONSOLECALL-CONSOLEOPTION-REGISTRY-E-NORMALIZACAO terminal Console effect/receipt/handle contract
bits 64
default rel
%include "runtime/console_options.inc"
%include "runtime/console_call.inc"
global nebo_console_call_finalize
section .text
; rdi=validated call request, rsi=out receipt. Atomic on contract failure.
nebo_console_call_finalize:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp qword [rdi + NEBO_CONSOLE_CALL_METHOD_OFFSET], 0
    je .invalid
    cmp qword [rdi + NEBO_CONSOLE_CALL_RENDER_PLAN_OFFSET], 0
    je .invalid
    mov rax, [rdi + NEBO_CONSOLE_CALL_EFFECTS_OFFSET]
    mov rcx, rax
    and rcx, ~NEBO_CONSOLE_EFFECT_ALL
    jnz .invalid
    mov rdx, [rdi + NEBO_CONSOLE_CALL_CAPABILITIES_OFFSET]
    not rdx
    test rax, rdx
    jnz .effect_denied
    mov rcx, [rdi + NEBO_CONSOLE_CALL_RETURN_KIND_OFFSET]
    cmp rcx, NEBO_CONSOLE_RETURN_UNIT
    jb .return_invalid
    cmp rcx, NEBO_CONSOLE_RETURN_MAX
    ja .return_invalid
    cmp rcx, NEBO_CONSOLE_RETURN_HANDLE
    jne .no_handle
    cmp qword [rdi + NEBO_CONSOLE_CALL_HANDLE_OFFSET], 0
    je .return_invalid
    jmp .commit
.no_handle:
    cmp qword [rdi + NEBO_CONSOLE_CALL_HANDLE_OFFSET], 0
    jne .return_invalid
.commit:
    mov rdx, [rdi + NEBO_CONSOLE_CALL_METHOD_OFFSET]
    mov [rsi + NEBO_CONSOLE_RECEIPT_METHOD_OFFSET], rdx
    mov [rsi + NEBO_CONSOLE_RECEIPT_EFFECTS_OFFSET], rax
    mov [rsi + NEBO_CONSOLE_RECEIPT_RETURN_KIND_OFFSET], rcx
    mov rdx, [rdi + NEBO_CONSOLE_CALL_RENDER_PLAN_OFFSET]
    mov [rsi + NEBO_CONSOLE_RECEIPT_RENDER_PLAN_OFFSET], rdx
    mov rdx, [rdi + NEBO_CONSOLE_CALL_HANDLE_OFFSET]
    mov [rsi + NEBO_CONSOLE_RECEIPT_HANDLE_OFFSET], rdx
    mov qword [rsi + NEBO_CONSOLE_RECEIPT_STATE_OFFSET], NEBO_CONSOLE_RECEIPT_READY
    xor eax, eax
    ret
.effect_denied:
    mov eax, NEBO_CONSOLE_CALL_EFFECT_DENIED
    ret
.return_invalid:
    mov eax, NEBO_CONSOLE_CALL_RETURN_INVALID
    ret
.invalid:
    mov eax, NEBO_OPTIONS_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
