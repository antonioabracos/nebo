default rel
section .text
global nebo_logic_nand, nebo_logic_nor
; Both already-evaluated Boolean operands are consumed; no short circuit.
nebo_logic_nand:
    cmp edi, 1
    ja .invalid
    cmp esi, 1
    ja .invalid
    mov eax, edi
    and eax, esi
    xor eax, 1
    ret
.invalid: mov eax, 4
    ret
nebo_logic_nor:
    cmp edi, 1
    ja .invalid2
    cmp esi, 1
    ja .invalid2
    mov eax, edi
    or eax, esi
    xor eax, 1
    ret
.invalid2: mov eax, 4
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
