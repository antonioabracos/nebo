default rel
section .text
global nebo_exists_bounded, nebo_not_exists_bounded
; finite bounded domain, same four truth states as universal quantification.
nebo_exists_bounded:
    test rdi, rdi
    jz .invalid
    cmp rsi, 1000000
    ja .invalid
    cmp rdx, rsi
    jb .timeout
    xor r8d, r8d
    xor r9d, r9d
    xor ecx, ecx
.loop:
    cmp rcx, rsi
    jae .done
    mov eax, [rdi+rcx*4]
    cmp eax, 3
    ja .invalid
    cmp eax, 1
    je .witness
    cmp eax, r9d
    jbe .next
    mov r9d, eax
    jmp .next
.witness: mov r8d, 1
.next: inc rcx
    jmp .loop
.done:
    test r8d, r8d
    jnz .true
    mov eax, r9d
    ret
.true: mov eax, 1
    ret
.timeout: mov eax, 3
    ret
.invalid: mov eax, 4
    ret
nebo_not_exists_bounded:
    call nebo_exists_bounded
    cmp eax, 1
    je .false
    test eax, eax
    jne .unchanged
    mov eax, 1
    ret
.false: xor eax, eax
.unchanged: ret
section .note.GNU-stack noalloc noexec nowrite progbits
