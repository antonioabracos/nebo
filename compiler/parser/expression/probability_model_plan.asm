default rel
section .text
global nebo_probability_operator_plan
; edi=0 distributed,1 independence,2 conditional separator; esi=model/P context.
nebo_probability_operator_plan:
    cmp edi, 2
    ja .kind
    test esi, esi
    jz .context
    xor eax, eax
    ret
.kind: mov eax, 2
    ret
.context: mov eax, 1
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
