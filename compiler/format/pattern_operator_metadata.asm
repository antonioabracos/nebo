default rel
section .text
global nebo_pattern_operator_metadata
; rdi=operator 0 concat/1 match/2 non-match, rsi=out[5 qwords].
; Emits stable tooling metadata only; it does not activate source syntax.
nebo_pattern_operator_metadata:
    test rsi, rsi
    jz .invalid
    cmp rdi, 2
    ja .invalid
    mov qword [rsi], 2
    mov qword [rsi+8], 1
    cmp rdi, 0
    jne .pattern
    mov qword [rsi+16], 70
    mov qword [rsi+24], 0
    mov qword [rsi+32], 74
    xor eax, eax
    ret
.pattern:
    mov qword [rsi+16], 50
    mov qword [rsi+24], 0
    lea rax, [rdi+74]
    mov [rsi+32], rax
    xor eax, eax
    ret
.invalid:
    mov eax, 1
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
