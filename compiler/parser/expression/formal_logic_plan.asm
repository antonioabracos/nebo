default rel
section .text
global nebo_formal_logic_operator_plan
; edi=operator kind 0..8, esi=formal domain gate.
nebo_formal_logic_operator_plan:
    test esi, esi
    jz .gate
    cmp edi, 8
    ja .kind
    xor eax, eax
    ret
.gate: mov eax, 1
    ret
.kind: mov eax, 2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
