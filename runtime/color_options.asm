; Nebo Assembly — PAPEIS-DE-COR-PALETTES-THEMES-COLORMAPS-E-ACESSIBILIDADE runtime representation of typed Color roles
bits 64
default rel
%include "compiler/semantic/color_options.inc"
%include "runtime/color_options.inc"
global nebo_color_option_materialize
section .text
; rdi=typed semantic option, rsi=out runtime option.
nebo_color_option_materialize:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp qword [rdi + NEBOC_COLOR_OPTION_STATE_OFFSET], NEBOC_COLOR_OPTION_VALID
    jne .invalid
    mov rax, [rdi + NEBOC_COLOR_OPTION_ROLE_OFFSET]
    mov [rsi + NEBO_COLOR_RUNTIME_OPTION_ROLE_OFFSET], rax
    mov eax, [rdi + NEBOC_COLOR_OPTION_VALUE_OFFSET]
    mov [rsi + NEBO_COLOR_RUNTIME_OPTION_VALUE_OFFSET], rax
    mov qword [rsi + NEBO_COLOR_RUNTIME_OPTION_STATE_OFFSET], NEBO_COLOR_RUNTIME_OPTION_READY
    xor eax, eax
    ret
.invalid:
    mov eax, NEBOC_COLOR_OPTION_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
