; Nebo Assembly — TIPO-PUBLICO-COLOR-CONSTRUCTORS-PARSING-E-ABI public Color type identity and ABI descriptor
bits 64
default rel
%include "runtime/color.inc"
%include "compiler/semantic/color.inc"
global neboc_color_type_descriptor
section .text
neboc_color_type_descriptor:
    test rdi, rdi
    jz .invalid
    mov qword [rdi + NEBOC_COLOR_DESC_TYPE_ID_OFFSET], NEBOC_COLOR_TYPE_ID
    mov qword [rdi + NEBOC_COLOR_DESC_SIZE_OFFSET], NEBO_COLOR_SIZE
    mov qword [rdi + NEBOC_COLOR_DESC_ALIGN_OFFSET], NEBO_COLOR_ALIGN
    mov qword [rdi + NEBOC_COLOR_DESC_FLAGS_OFFSET], \
        NEBOC_COLOR_FLAG_IMMUTABLE | NEBOC_COLOR_FLAG_COPY | \
        NEBOC_COLOR_FLAG_SRGB | NEBOC_COLOR_FLAG_UNPREMULTIPLIED
    xor eax, eax
    ret
.invalid:
    mov eax, NEBO_COLOR_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
