default rel
section .text
global nebo_reserved_path_form
; rdi=lexeme, rsi=length, rdx=execute intent, rcx=out[id,diagnostic,0].
nebo_reserved_path_form:
    test rdi, rdi
    jz .invalid
    test rcx, rcx
    jz .invalid
    cmp rdx, 1
    ja .invalid
    cmp rsi, 3
    je .ellipsis
    cmp rsi, 2
    jne .unknown
    cmp byte [rdi], ':'
    jne .unknown
    cmp byte [rdi+1], ':'
    jne .unknown
    mov r8d, 4
    jmp .publish
.ellipsis:
    cmp byte [rdi], '.'
    jne .unknown
    cmp byte [rdi+1], '.'
    jne .unknown
    cmp byte [rdi+2], '.'
    jne .unknown
    mov r8d, 3
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
