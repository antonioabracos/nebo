default rel
section .text
global nebo_utf8_pattern_boundaries
; rdi=UTF-8 bytes, rsi=byte length, rdx=caller out[codepoints, graphemes].
; Canonical UTF-8 only; U+0300..U+036F extend the preceding grapheme.
nebo_utf8_pattern_boundaries:
    test rdx, rdx
    jz .invalid
    test rsi, rsi
    jz .publish_zero
    test rdi, rdi
    jz .invalid
    xor r8d, r8d
    xor r9d, r9d
    xor r10d, r10d
.next:
    cmp r8, rsi
    jae .publish
    movzx eax, byte [rdi+r8]
    test al, al
    js .multibyte
    inc r8
    inc r9
    inc r10
    jmp .next
.multibyte:
    cmp al, 0c2h
    jb .invalid
    cmp al, 0dfh
    jbe .two
    cmp al, 0efh
    jbe .three
    cmp al, 0f4h
    jbe .four
    jmp .invalid
.two:
    lea r11, [r8+1]
    cmp r11, rsi
    jae .invalid
    movzx ecx, byte [rdi+r11]
    mov r11d, ecx
    and r11d, 0c0h
    cmp r11d, 080h
    jne .invalid
    inc r9
    cmp al, 0cch
    je .combining
    cmp al, 0cdh
    jne .two_base
    cmp cl, 0afh
    jbe .combining
.two_base:
    inc r10
    add r8, 2
    jmp .next
.combining:
    test r10, r10
    jz .invalid
    add r8, 2
    jmp .next
.three:
    lea r11, [r8+2]
    cmp r11, rsi
    jae .invalid
    movzx ecx, byte [rdi+r8+1]
    mov r11d, ecx
    and r11d, 0c0h
    cmp r11d, 080h
    jne .invalid
    cmp al, 0e0h
    jne .three_surrogate
    cmp cl, 0a0h
    jb .invalid
.three_surrogate:
    cmp al, 0edh
    jne .three_tail
    cmp cl, 09fh
    ja .invalid
.three_tail:
    movzx ecx, byte [rdi+r8+2]
    and ecx, 0c0h
    cmp ecx, 080h
    jne .invalid
    add r8, 3
    inc r9
    inc r10
    jmp .next
.four:
    lea r11, [r8+3]
    cmp r11, rsi
    jae .invalid
    movzx ecx, byte [rdi+r8+1]
    mov r11d, ecx
    and r11d, 0c0h
    cmp r11d, 080h
    jne .invalid
    cmp al, 0f0h
    jne .four_max
    cmp cl, 090h
    jb .invalid
.four_max:
    cmp al, 0f4h
    jne .four_tail
    cmp cl, 08fh
    ja .invalid
.four_tail:
    movzx ecx, byte [rdi+r8+2]
    and ecx, 0c0h
    cmp ecx, 080h
    jne .invalid
    movzx ecx, byte [rdi+r8+3]
    and ecx, 0c0h
    cmp ecx, 080h
    jne .invalid
    add r8, 4
    inc r9
    inc r10
    jmp .next
.publish_zero:
    xor r9d, r9d
    xor r10d, r10d
.publish:
    mov [rdx], r9
    mov [rdx+8], r10
    xor eax, eax
    ret
.invalid:
    mov eax, 1
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
