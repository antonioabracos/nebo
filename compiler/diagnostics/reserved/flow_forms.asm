default rel
section .text
global nebo_reserved_flow_form
; rdi=lexeme, rsi=length, rdx=execute intent 0/1, rcx=out[id,diagnostic,executable].
; Recognized forms always return eax=1 (RESERVED), never executable semantics.
nebo_reserved_flow_form:
    test rdi, rdi
    jz .invalid
    test rcx, rcx
    jz .invalid
    cmp rdx, 1
    ja .invalid
    cmp rsi, 2
    je .short
    cmp rsi, 3
    jne .unknown
    cmp byte [rdi], '<'
    jne .unknown
    cmp byte [rdi+1], '.'
    jne .unknown
    cmp byte [rdi+2], '>'
    jne .unknown
    mov r8d, 2
    jmp .publish
.short:
    cmp byte [rdi], '<'
    jne .unknown
    cmp byte [rdi+1], '.'
    jne .unknown
    mov r8d, 1
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
