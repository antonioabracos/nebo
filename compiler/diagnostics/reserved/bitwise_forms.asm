default rel
section .text
global nebo_reserved_bitwise_form
; rdi=lexeme, rsi=length, rdx=execute intent, rcx=out[id,diagnostic,0].
nebo_reserved_bitwise_form:
    test rdi, rdi
    jz .invalid
    test rcx, rcx
    jz .invalid
    cmp rdx, 1
    ja .invalid
    cmp rsi, 1
    je .single
    cmp rsi, 2
    jne .unknown
    mov al, [rdi]
    cmp al, '<'
    je .left
    cmp al, '>'
    jne .unknown
    cmp byte [rdi+1], '>'
    jne .unknown
    mov r8d, 14
    jmp .publish
.left:
    cmp byte [rdi+1], '<'
    jne .unknown
    mov r8d, 13
    jmp .publish
.single:
    mov al, [rdi]
    cmp al, '&'
    je .and
    cmp al, '|'
    je .or
    cmp al, '~'
    jne .unknown
    mov r8d, 12
    jmp .publish
.and:
    mov r8d, 10
    jmp .publish
.or:
    mov r8d, 11
.publish:
    mov [rcx], r8
    lea rax, [r8+144000]
    mov [rcx+8], rax
    mov qword [rcx+16], 0
    mov eax, 1
    ret
.unknown:
    mov eax, 2
    ret
.invalid:
    mov eax, 3
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
