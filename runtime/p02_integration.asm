; Nebo Assembly — RF116 P02 single RenderPlan integration boundary
bits 64
default rel
%include "runtime/p02_integration.inc"
global nebo_p02_render_plan_close
section .text
; Joins five already-validated receipts without retaining source pointers.
nebo_p02_render_plan_close:
    test rdi, rdi
    jz .p02_invalid
    test rsi, rsi
    jz .p02_invalid
    cmp qword [rdi + NEBO_P02_REQUEST_GENERATION_OFFSET], 0
    je .p02_invalid
    cmp qword [rdi + NEBO_P02_REQUEST_FLAGS_OFFSET], NEBO_P02_REQUIRED_FLAGS
    jne .p02_privacy
    mov rdx, [rdi + NEBO_P02_REQUEST_REGISTRY_OFFSET]
    test rdx, rdx
    jz .p02_invalid
    cmp qword [rdx + NEBO_P02_REGISTRY_STATE_OFFSET], NEBO_P02_COMPONENT_READY
    jne .p02_conflict
    mov rax, [rdx + NEBO_P02_REGISTRY_DIGEST_OFFSET]
    mov rdx, [rdi + NEBO_P02_REQUEST_DOCUMENT_OFFSET]
    test rdx, rdx
    jz .p02_invalid
    cmp qword [rdx + NEBO_P02_DOCUMENT_STATE_OFFSET], NEBO_P02_COMPONENT_READY
    jne .p02_conflict
    cmp qword [rdx + NEBO_P02_DOCUMENT_TARGET_OFFSET], NEBO_P02_TARGET_HEADLESS
    jne .p02_target
    rol rax, 11
    xor rax, [rdx + NEBO_P02_DOCUMENT_DIGEST_OFFSET]
    mov rdx, [rdi + NEBO_P02_REQUEST_STYLE_OFFSET]
    test rdx, rdx
    jz .p02_invalid
    cmp qword [rdx + NEBO_P02_STYLE_STATE_OFFSET], NEBO_P02_COMPONENT_READY
    jne .p02_conflict
    cmp qword [rdx + NEBO_P02_STYLE_TARGET_OFFSET], NEBO_P02_TARGET_HEADLESS
    jne .p02_target
    rol rax, 13
    xor rax, [rdx + NEBO_P02_STYLE_DIGEST_OFFSET]
    mov rdx, [rdi + NEBO_P02_REQUEST_LAYOUT_OFFSET]
    test rdx, rdx
    jz .p02_invalid
    cmp qword [rdx + NEBO_P02_LAYOUT_STATE_OFFSET], NEBO_P02_COMPONENT_READY
    jne .p02_conflict
    rol rax, 17
    xor rax, [rdx + NEBO_P02_LAYOUT_DIGEST_OFFSET]
    mov rdx, [rdi + NEBO_P02_REQUEST_VIEW_OFFSET]
    test rdx, rdx
    jz .p02_invalid
    cmp qword [rdx + NEBO_P02_VIEW_STATE_OFFSET], NEBO_P02_COMPONENT_READY
    jne .p02_conflict
    rol rax, 19
    xor rax, [rdx + NEBO_P02_VIEW_DIGEST_OFFSET]
    rol rax, 23
    xor rax, [rdi + NEBO_P02_REQUEST_GENERATION_OFFSET]
    mov [rsi + NEBO_P02_RECEIPT_DIGEST_OFFSET], rax
    mov rax, [rdi + NEBO_P02_REQUEST_GENERATION_OFFSET]
    mov [rsi + NEBO_P02_RECEIPT_GENERATION_OFFSET], rax
    mov qword [rsi + NEBO_P02_RECEIPT_COMPONENTS_OFFSET], 5
    mov qword [rsi + NEBO_P02_RECEIPT_TARGET_OFFSET], NEBO_P02_TARGET_HEADLESS
    mov qword [rsi + NEBO_P02_RECEIPT_STATE_OFFSET], NEBO_P02_READY
    xor eax, eax
    ret
.p02_privacy:
    mov eax, NEBO_P02_PRIVACY
    ret
.p02_target:
    mov eax, NEBO_P02_TARGET
    ret
.p02_conflict:
    mov eax, NEBO_P02_CONFLICT
    ret
.p02_invalid:
    mov eax, NEBO_P02_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
