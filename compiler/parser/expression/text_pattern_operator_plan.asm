default rel
section .text
global nebo_text_pattern_operator_plan
; edi=operator (0 Text concat, 1 Pattern match, 2 Pattern non-match)
; esi=context (1 Text/Pattern domain). eax=stable plan id, edx=status.
nebo_text_pattern_operator_plan:
    cmp esi, 1
    jne .context
    cmp edi, 2
    ja .operator
    lea eax, [rdi+141001]
    xor edx, edx
    ret
.context:
    xor eax, eax
    mov edx, 1
    ret
.operator:
    xor eax, eax
    mov edx, 2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
