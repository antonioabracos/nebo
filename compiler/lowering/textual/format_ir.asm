bits 64
default rel
%include "compiler/lowering/textual/format_ir.inc"
section .text
global neboc_format_lower_literal
; rdi=destination node, rsi=bytes, rdx=len; constructs canonical FormatPlan IR.
neboc_format_lower_literal:
    test rdi, rdi
    jz .bad
    test rsi, rsi
    jz .bad
    cmp rdx, FORMAT_MAX_OUTPUT
    ja .bad
    mov qword [rdi + FORMAT_NODE_KIND], FORMAT_NODE_LITERAL
    mov [rdi + FORMAT_NODE_DATA], rsi
    mov [rdi + FORMAT_NODE_LENGTH], rdx
    mov qword [rdi + FORMAT_NODE_PROFILE], 0
    xor eax, eax
    ret
.bad:
    mov eax, FORMAT_E_INVALID
    ret
