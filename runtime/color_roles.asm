; Nebo Assembly — PAPEIS-DE-COR-PALETTES-THEMES-COLORMAPS-E-ACESSIBILIDADE semantic Color role values
bits 64
default rel
%include "runtime/color.inc"
%include "runtime/color_roles.inc"
global nebo_color_role_define
section .text
; rdi=role kind, esi=Color value, rdx=out descriptor.
nebo_color_role_define:
    test rdx, rdx
    jz .invalid
    cmp rdi, NEBO_ROLE_FOREGROUND
    jb .invalid
    cmp rdi, NEBO_ROLE_MAX
    ja .invalid
    mov [rdx + NEBO_ROLE_DESC_KIND_OFFSET], rdi
    mov eax, esi
    mov [rdx + NEBO_ROLE_DESC_COLOR_OFFSET], rax
    mov qword [rdx + NEBO_ROLE_DESC_STATE_OFFSET], NEBO_ROLE_VALID
    xor eax, eax
    ret
.invalid:
    mov eax, NEBO_COLOR_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
