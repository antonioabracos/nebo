; Nebo Assembly — RF116 P01 atomic Console Color-option integration
bits 64
default rel
%include "runtime/console_options.inc"
%include "runtime/render_intent.inc"
%include "runtime/console_call.inc"
%include "runtime/p01_integration.inc"
extern nebo_console_options_normalize
extern nebo_render_intent_build
extern nebo_console_call_finalize
global nebo_p01_prepare_console_call
section .text
; rdi=P01 request. Scratch may change on failure; public plan/receipt remain atomic.
nebo_p01_prepare_console_call:
    test rdi, rdi
    jz .pre_invalid
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, NEBO_P01_STACK_SIZE
    mov rbx, rdi
    mov r12, [rbx + NEBO_P01_REQUEST_PLAN_OFFSET]
    mov r13, [rbx + NEBO_P01_REQUEST_RECEIPT_OFFSET]
    mov r14, [rbx + NEBO_P01_REQUEST_SCRATCH_OFFSET]
    mov r15, [rbx + NEBO_P01_REQUEST_COUNT_OFFSET]
    test r12, r12
    jz .invalid
    test r13, r13
    jz .invalid
    test r15, r15
    jz .scratch_ready
    test r14, r14
    jz .invalid
.scratch_ready:
    mov rax, [rbx + NEBO_P01_REQUEST_VALUES_OFFSET]
    mov [rsp + NEBO_P01_STACK_NORMALIZE_OFFSET + NEBO_OPTIONS_NORMALIZE_VALUES_OFFSET], rax
    mov [rsp + NEBO_P01_STACK_NORMALIZE_OFFSET + NEBO_OPTIONS_NORMALIZE_COUNT_OFFSET], r15
    mov [rsp + NEBO_P01_STACK_NORMALIZE_OFFSET + NEBO_OPTIONS_NORMALIZE_DESTINATION_OFFSET], r14
    mov rax, [rbx + NEBO_P01_REQUEST_SCRATCH_CAPACITY_OFFSET]
    mov [rsp + NEBO_P01_STACK_NORMALIZE_OFFSET + NEBO_OPTIONS_NORMALIZE_CAPACITY_OFFSET], rax
    lea rax, [rsp + NEBO_P01_STACK_NORMALIZE_RECEIPT_OFFSET]
    mov [rsp + NEBO_P01_STACK_NORMALIZE_OFFSET + NEBO_OPTIONS_NORMALIZE_RECEIPT_OFFSET], rax
    lea rdi, [rsp + NEBO_P01_STACK_NORMALIZE_OFFSET]
    call nebo_console_options_normalize
    test eax, eax
    jnz .done
    mov [rsp + NEBO_P01_STACK_INTENT_OFFSET + NEBO_RENDER_INTENT_OPTIONS_OFFSET], r14
    mov [rsp + NEBO_P01_STACK_INTENT_OFFSET + NEBO_RENDER_INTENT_COUNT_OFFSET], r15
    mov rax, [rbx + NEBO_P01_REQUEST_TARGET_OFFSET]
    mov [rsp + NEBO_P01_STACK_INTENT_OFFSET + NEBO_RENDER_INTENT_TARGET_OFFSET], rax
    mov rax, [rbx + NEBO_P01_REQUEST_CAPABILITIES_OFFSET]
    mov [rsp + NEBO_P01_STACK_INTENT_OFFSET + NEBO_RENDER_INTENT_CAPABILITIES_OFFSET], rax
    mov rax, [rbx + NEBO_P01_REQUEST_EFFECTS_OFFSET]
    mov [rsp + NEBO_P01_STACK_INTENT_OFFSET + NEBO_RENDER_INTENT_EFFECTS_OFFSET], rax
    lea rdi, [rsp + NEBO_P01_STACK_INTENT_OFFSET]
    lea rsi, [rsp + NEBO_P01_STACK_PLAN_OFFSET]
    call nebo_render_intent_build
    test eax, eax
    jnz .done
    mov rax, [rbx + NEBO_P01_REQUEST_METHOD_OFFSET]
    mov [rsp + NEBO_P01_STACK_CALL_OFFSET + NEBO_CONSOLE_CALL_METHOD_OFFSET], rax
    mov rax, [rbx + NEBO_P01_REQUEST_EFFECTS_OFFSET]
    mov [rsp + NEBO_P01_STACK_CALL_OFFSET + NEBO_CONSOLE_CALL_EFFECTS_OFFSET], rax
    mov rax, [rbx + NEBO_P01_REQUEST_CAPABILITIES_OFFSET]
    mov [rsp + NEBO_P01_STACK_CALL_OFFSET + NEBO_CONSOLE_CALL_CAPABILITIES_OFFSET], rax
    mov rax, [rbx + NEBO_P01_REQUEST_RETURN_KIND_OFFSET]
    mov [rsp + NEBO_P01_STACK_CALL_OFFSET + NEBO_CONSOLE_CALL_RETURN_KIND_OFFSET], rax
    lea rax, [rsp + NEBO_P01_STACK_PLAN_OFFSET]
    mov [rsp + NEBO_P01_STACK_CALL_OFFSET + NEBO_CONSOLE_CALL_RENDER_PLAN_OFFSET], rax
    mov rax, [rbx + NEBO_P01_REQUEST_HANDLE_OFFSET]
    mov [rsp + NEBO_P01_STACK_CALL_OFFSET + NEBO_CONSOLE_CALL_HANDLE_OFFSET], rax
    lea rdi, [rsp + NEBO_P01_STACK_CALL_OFFSET]
    lea rsi, [rsp + NEBO_P01_STACK_RECEIPT_OFFSET]
    call nebo_console_call_finalize
    test eax, eax
    jnz .done
    mov [rsp + NEBO_P01_STACK_RECEIPT_OFFSET + NEBO_CONSOLE_RECEIPT_RENDER_PLAN_OFFSET], r12
    lea rsi, [rsp + NEBO_P01_STACK_PLAN_OFFSET]
    mov rdi, r12
    mov ecx, NEBO_RENDER_PLAN_SIZE / 8
    rep movsq
    lea rsi, [rsp + NEBO_P01_STACK_RECEIPT_OFFSET]
    mov rdi, r13
    mov ecx, NEBO_CONSOLE_RECEIPT_SIZE / 8
    rep movsq
    xor eax, eax
    jmp .done
.invalid:
    mov eax, NEBO_OPTIONS_INVALID
.done:
    add rsp, NEBO_P01_STACK_SIZE
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.pre_invalid:
    mov eax, NEBO_OPTIONS_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
