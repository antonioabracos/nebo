; Nebo Assembly — PAPEIS-DE-COR-PALETTES-THEMES-COLORMAPS-E-ACESSIBILIDADE bounded additional Color-space ingress
bits 64
default rel
%include "runtime/color.inc"
%include "runtime/color_space.inc"
global nebo_color_space_normalize
section .text
; rdi=space, rsi=c1, rdx=c2, rcx=c3, r8=alpha, r9=out descriptor.
nebo_color_space_normalize:
    test r9, r9
    jz .invalid
    cmp rdi, NEBO_SPACE_SRGB8
    jb .invalid
    cmp rdi, NEBO_SPACE_MAX
    ja .invalid
    cmp rdi, NEBO_SPACE_LINEAR_SRGB16
    je .wide
    cmp rsi, 255
    ja .boundary
    cmp rdx, 255
    ja .boundary
    cmp rcx, 255
    ja .boundary
    cmp r8, 255
    ja .boundary
    cmp rdi, NEBO_SPACE_GRAY8
    jne .commit
    test rdx, rdx
    jnz .boundary
    test rcx, rcx
    jnz .boundary
    jmp .commit
.wide:
    cmp rsi, 65535
    ja .boundary
    cmp rdx, 65535
    ja .boundary
    cmp rcx, 65535
    ja .boundary
    cmp r8, 65535
    ja .boundary
.commit:
    mov [r9 + NEBO_SPACE_DESC_KIND_OFFSET], rdi
    mov [r9 + NEBO_SPACE_DESC_C1_OFFSET], rsi
    mov [r9 + NEBO_SPACE_DESC_C2_OFFSET], rdx
    mov [r9 + NEBO_SPACE_DESC_C3_OFFSET], rcx
    mov [r9 + NEBO_SPACE_DESC_ALPHA_OFFSET], r8
    mov qword [r9 + NEBO_SPACE_DESC_STATE_OFFSET], NEBO_SPACE_READY
    xor eax, eax
    ret
.boundary:
    mov eax, NEBO_SPACE_BOUNDARY
    ret
.invalid:
    mov eax, NEBO_COLOR_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
