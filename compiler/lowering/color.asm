; Nebo Assembly — TIPO-PUBLICO-COLOR-CONSTRUCTORS-PARSING-E-ABI Color(...) sugar lowering to canonical constructors
bits 64
default rel
%include "runtime/color.inc"
%include "compiler/lowering/color.inc"
extern nebo_color_rgb_lowering
extern nebo_color_rgba_lowering
extern nebo_color_hex_literal
global neboc_color_sugar_lower
section .text
; rdi=sugar request, rsi=out Color. Reuses canonical constructor engines.
neboc_color_sugar_lower:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    mov rax, [rdi + NEBOC_COLOR_SUGAR_FORM_OFFSET]
    cmp eax, NEBOC_COLOR_SUGAR_RGB
    je .rgb
    cmp eax, NEBOC_COLOR_SUGAR_RGBA
    je .rgba
    cmp eax, NEBOC_COLOR_SUGAR_HEX
    je .hex
    jmp .invalid
.rgb:
    cmp qword [rdi + NEBOC_COLOR_SUGAR_ARGUMENT_COUNT_OFFSET], 3
    jne .invalid
    mov r8, [rdi + NEBOC_COLOR_SUGAR_ARGUMENTS_OFFSET]
    test r8, r8
    jz .invalid
    mov rcx, rsi
    mov rdx, [r8 + 16]
    mov rsi, [r8 + 8]
    mov rdi, [r8]
    sub rsp, 8
    call nebo_color_rgb_lowering
    add rsp, 8
    ret
.rgba:
    cmp qword [rdi + NEBOC_COLOR_SUGAR_ARGUMENT_COUNT_OFFSET], 4
    jne .invalid
    mov r9, [rdi + NEBOC_COLOR_SUGAR_ARGUMENTS_OFFSET]
    test r9, r9
    jz .invalid
    mov r8, rsi
    mov rcx, [r9 + 24]
    mov rdx, [r9 + 16]
    mov rsi, [r9 + 8]
    mov rdi, [r9]
    sub rsp, 8
    call nebo_color_rgba_lowering
    add rsp, 8
    ret
.hex:
    cmp qword [rdi + NEBOC_COLOR_SUGAR_ARGUMENT_COUNT_OFFSET], 1
    jne .invalid
    mov rdx, rsi
    mov rsi, [rdi + NEBOC_COLOR_SUGAR_TEXT_LENGTH_OFFSET]
    mov rdi, [rdi + NEBOC_COLOR_SUGAR_TEXT_OFFSET]
    sub rsp, 8
    call nebo_color_hex_literal
    add rsp, 8
    ret
.invalid:
    mov eax, NEBO_COLOR_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
