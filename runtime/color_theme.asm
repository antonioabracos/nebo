; Nebo Assembly — PAPEIS-DE-COR-PALETTES-THEMES-COLORMAPS-E-ACESSIBILIDADE immutable semantic theme tokens
bits 64
default rel
%include "runtime/color.inc"
%include "runtime/color_theme.inc"
global nebo_theme_resolve
section .text
; rdi=theme, rsi=semantic token, rdx=out Color.
nebo_theme_resolve:
    test rdi, rdi
    jz .invalid
    test rdx, rdx
    jz .invalid
    cmp qword [rdi + NEBO_THEME_STATE_OFFSET], NEBO_THEME_VALID
    jne .invalid
    cmp rsi, NEBO_THEME_TOKEN_FOREGROUND
    jb .invalid
    cmp rsi, NEBO_THEME_TOKEN_MAX
    ja .invalid
    cmp rsi, NEBO_THEME_TOKEN_ACCENT
    jne .selected
    cmp qword [rdi + NEBO_THEME_ACCENT_PRESENT_OFFSET], 0
    jne .selected
    mov esi, NEBO_THEME_TOKEN_FOREGROUND
.selected:
    dec rsi
    mov eax, [rdi + rsi * 4 + NEBO_THEME_COLORS_OFFSET]
    mov [rdx], eax
    xor eax, eax
    ret
.invalid:
    mov eax, NEBO_COLOR_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
