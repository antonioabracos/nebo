default rel
extern nebo_pattern_match
section .text
global nebo_pattern_non_match
; Same ABI as nebo_pattern_match. Inverts only a successful typed result.
nebo_pattern_non_match:
    sub rsp, 8
    call nebo_pattern_match
    add rsp, 8
    test edx, edx
    jnz .return
    xor eax, 1
.return:
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
