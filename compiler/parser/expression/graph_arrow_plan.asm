default rel
section .text
global nebo_graph_arrow_plan
; edi=0 directed/1 bidirectional/2 async/3 transition, esi=matching domain.
nebo_graph_arrow_plan:
    cmp edi, 3
    ja .kind
    cmp esi, edi
    jne .context
    xor eax, eax
    ret
.kind: mov eax, 2
    ret
.context: mov eax, 1
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
