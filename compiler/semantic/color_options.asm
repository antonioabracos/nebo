; Nebo Assembly — PAPEIS-DE-COR-PALETTES-THEMES-COLORMAPS-E-ACESSIBILIDADE typed foreground/background Color options
bits 64
default rel
%include "compiler/semantic/color.inc"
%include "compiler/semantic/color_options.inc"
global neboc_color_option_typecheck
section .text
; rdi=role, rsi=argument type id, edx=Color, rcx=out typed option.
neboc_color_option_typecheck:
    test rcx, rcx
    jz .invalid
    test rdi, rdi
    jz .bare
    cmp rdi, NEBOC_COLOR_ROLE_FOREGROUND
    je .role_ok
    cmp rdi, NEBOC_COLOR_ROLE_BACKGROUND
    jne .invalid
.role_ok:
    cmp rsi, NEBOC_COLOR_TYPE_ID
    jne .type
    mov [rcx + NEBOC_COLOR_OPTION_ROLE_OFFSET], rdi
    mov eax, edx
    mov [rcx + NEBOC_COLOR_OPTION_VALUE_OFFSET], rax
    mov [rcx + NEBOC_COLOR_OPTION_TYPE_ID_OFFSET], rsi
    mov qword [rcx + NEBOC_COLOR_OPTION_STATE_OFFSET], NEBOC_COLOR_OPTION_VALID
    xor eax, eax
    ret
.bare:
    mov eax, NEBOC_COLOR_OPTION_BARE_COLOR
    ret
.type:
    mov eax, NEBOC_COLOR_OPTION_TYPE_MISMATCH
    ret
.invalid:
    mov eax, NEBOC_COLOR_OPTION_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
