default rel
section .text
global nebo_reserved_raw_comment_form
; rdi=lexeme, rsi=length, rdx=execute intent, rcx=out[id,diagnostic,0].
nebo_reserved_raw_comment_form:
    test rdi, rdi
    jz .invalid
    test rcx, rcx
    jz .invalid
    cmp rdx, 1
    ja .invalid
    cmp rsi, 2
    jb .unknown
    cmp byte [rdi], 060h
    je .backtick
    cmp rsi, 4
    jb .unknown
    cmp byte [rdi], '/'
    jne .unknown
    cmp byte [rdi+1], '*'
    jne .unknown
    mov r8, rsi
    sub r8, 2
    cmp byte [rdi+r8], '*'
    jne .unknown
    cmp byte [rdi+r8+1], '/'
    jne .unknown
    mov r8d, 9
    jmp .publish
.backtick:
    mov r8, rsi
    dec r8
    cmp byte [rdi+r8], 060h
    jne .unknown
    mov r8d, 8
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
