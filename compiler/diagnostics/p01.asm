; Nebo Assembly — RF116 P01 stable typed diagnostics
bits 64
default rel

%include "compiler/semantic/const_binding.inc"
%include "compiler/diagnostics/p01.inc"
%include "runtime/color.inc"
%include "runtime/console_options.inc"
%include "runtime/console_option_registry.inc"
%include "runtime/render_intent.inc"

global neboc_diag_from_const_status
global neboc_diag_from_color_status
global neboc_diag_from_option_status
global neboc_diag_from_render_intent_status

section .text
; rdi=semantic status, rsi=start, rdx=end, rcx=out diagnostic
neboc_diag_from_const_status:
    test rcx, rcx
    jz .invalid
    cmp rsi, rdx
    ja .invalid
    cmp edi, NEBOC_CONST_NAME_NOT_ALL_CAPS
    je .name
    cmp edi, NEBOC_CONST_WRITE_FORBIDDEN
    je .write
    cmp edi, NEBOC_CONST_SHADOW_FORBIDDEN
    je .shadow
    jmp .invalid
.name:
    mov eax, NEBOC_DIAG_CONST_INVALID_NAME
    jmp .commit
.write:
    mov eax, NEBOC_DIAG_CONST_WRITE
    jmp .commit
.shadow:
    mov eax, NEBOC_DIAG_CONST_SHADOW
.commit:
    mov [rcx + NEBOC_DIAG_CODE_OFFSET], rax
    mov [rcx + NEBOC_DIAG_START_OFFSET], rsi
    mov [rcx + NEBOC_DIAG_END_OFFSET], rdx
    mov qword [rcx + NEBOC_DIAG_SEVERITY_OFFSET], NEBOC_DIAG_SEVERITY_ERROR
    xor eax, eax
    ret
.invalid:
    mov eax, NEBOC_CONST_INVALID_ARGUMENT
    ret

; rdi=Color status, rsi=parse error index, rdx=span start, rcx=span end,
; r8=out diagnostic. The error index is added to the literal start for hex.
neboc_diag_from_color_status:
    test r8, r8
    jz .color_invalid
    cmp rdx, rcx
    ja .color_invalid
    cmp edi, NEBO_COLOR_CHANNEL_RANGE
    je .color_channel
    cmp edi, NEBO_COLOR_HEX_INVALID
    je .color_hex
    cmp edi, NEBO_COLOR_ALPHA_UNSUPPORTED
    je .color_alpha
    jmp .color_invalid
.color_channel:
    mov eax, NEBOC_DIAG_COLOR_CHANNEL
    jmp .color_commit
.color_hex:
    mov eax, NEBOC_DIAG_COLOR_HEX
    add rdx, rsi
    cmp rdx, rcx
    cmova rdx, rcx
    jmp .color_commit
.color_alpha:
    mov eax, NEBOC_DIAG_COLOR_ALPHA
.color_commit:
    mov [r8 + NEBOC_DIAG_CODE_OFFSET], rax
    mov [r8 + NEBOC_DIAG_START_OFFSET], rdx
    mov [r8 + NEBOC_DIAG_END_OFFSET], rcx
    mov qword [r8 + NEBOC_DIAG_SEVERITY_OFFSET], NEBOC_DIAG_SEVERITY_ERROR
    xor eax, eax
    ret
.color_invalid:
    mov eax, NEBO_COLOR_INVALID
    ret

; rdi=option status, rsi=start, rdx=end, rcx=out diagnostic.
neboc_diag_from_option_status:
    test rcx, rcx
    jz .option_invalid
    cmp rsi, rdx
    ja .option_invalid
    cmp edi, NEBO_OPTIONS_DUPLICATE
    je .option_duplicate
    cmp edi, NEBO_OPTIONS_CONFLICT
    je .option_conflict
    cmp edi, NEBO_OPTIONS_BUDGET
    je .option_budget
    cmp edi, NEBO_OPTIONS_BUDGET_OPTIONS
    jb .option_registry_range
    cmp edi, NEBO_OPTIONS_BUDGET_STEPS
    jbe .option_budget
.option_registry_range:
    cmp edi, NEBO_OPTION_REGISTRY_NOT_FOUND
    jb .option_invalid
    cmp edi, NEBO_OPTION_REGISTRY_NAME_DUPLICATE
    ja .option_invalid
    mov eax, NEBOC_DIAG_OPTION_REGISTRY
    jmp .option_commit
.option_duplicate:
    mov eax, NEBOC_DIAG_OPTION_DUPLICATE
    jmp .option_commit
.option_conflict:
    mov eax, NEBOC_DIAG_OPTION_CONFLICT
    jmp .option_commit
.option_budget:
    mov eax, NEBOC_DIAG_OPTION_BUDGET
.option_commit:
    mov [rcx + NEBOC_DIAG_CODE_OFFSET], rax
    mov [rcx + NEBOC_DIAG_START_OFFSET], rsi
    mov [rcx + NEBOC_DIAG_END_OFFSET], rdx
    mov qword [rcx + NEBOC_DIAG_SEVERITY_OFFSET], NEBOC_DIAG_SEVERITY_ERROR
    xor eax, eax
    ret
.option_invalid:
    mov eax, NEBO_OPTIONS_INVALID
    ret

; rdi=RenderIntent status, rsi=start, rdx=end, rcx=out diagnostic.
neboc_diag_from_render_intent_status:
    test rcx, rcx
    jz .intent_invalid
    cmp rsi, rdx
    ja .intent_invalid
    cmp edi, NEBO_RENDER_INTENT_ORDER
    je .intent_commit
    cmp edi, NEBO_RENDER_INTENT_EFFECT
    jne .intent_invalid
.intent_commit:
    mov qword [rcx + NEBOC_DIAG_CODE_OFFSET], NEBOC_DIAG_RENDER_INTENT
    mov [rcx + NEBOC_DIAG_START_OFFSET], rsi
    mov [rcx + NEBOC_DIAG_END_OFFSET], rdx
    mov qword [rcx + NEBOC_DIAG_SEVERITY_OFFSET], NEBOC_DIAG_SEVERITY_ERROR
    xor eax, eax
    ret
.intent_invalid:
    mov eax, NEBO_OPTIONS_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
