; Nebo Assembly — CHAMADAS-ANINHADAS-EM-CONSOLE-E-AVALIACAO-EXACTLY-ONCE option effect/capability validation
bits 64
default rel
%include "compiler/semantic/console_calls.inc"
%include "compiler/semantic/console_effects.inc"
global neboc_console_option_effect_check
section .text
; rdi=option expression, rsi=explicitly granted capabilities, rdx=out proof
neboc_console_option_effect_check:
    test rdi, rdi
    jz .invalid
    test rdx, rdx
    jz .invalid
    mov rax, [rdi + NEBOC_OPTION_EXPR_EFFECTS_OFFSET]
    test rax, ~NEBOC_EFFECT_ALL
    jnz .invalid
    mov rcx, rax
    not rsi
    test rcx, rsi
    jnz .forbidden
    not rsi
    mov [rdx + NEBOC_EFFECT_REQUIRED_OFFSET], rax
    mov [rdx + NEBOC_EFFECT_GRANTED_OFFSET], rsi
    mov qword [rdx + NEBOC_EFFECT_STATE_OFFSET], NEBOC_EFFECT_VALID
    xor eax, eax
    ret
.forbidden:
    mov eax, NEBOC_OPTION_EFFECT_FORBIDDEN
    ret
.invalid:
    mov eax, NEBOC_OPTION_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
