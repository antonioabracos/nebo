default rel
section .text
global nebo_annotation_arguments_validate
; rdi=args[name id,expected type,actual type,flags], rsi=count,
; rdx=declared count, rcx=out named-argument mask.
; flags: exactly one of PROVIDED=1 or DEFAULTED=2.
nebo_annotation_arguments_validate:
    test rcx, rcx
    jz .invalid
    cmp rsi, 32
    ja .invalid
    cmp rsi, rdx
    jne .missing
    test rsi, rsi
    jz .publish_zero
    test rdi, rdi
    jz .invalid
    xor r8d, r8d
    xor r9d, r9d
.argument:
    mov r10, r9
    shl r10, 5
    mov rax, [rdi+r10]
    cmp rax, 63
    ja .invalid
    bts r8, rax
    jc .duplicate
    mov r11, [rdi+r10+8]
    test r11, r11
    jz .invalid
    cmp r11, [rdi+r10+16]
    jne .type
    mov rax, [rdi+r10+24]
    cmp rax, 1
    je .next
    cmp rax, 2
    jne .invalid
.next:
    inc r9
    cmp r9, rsi
    jb .argument
    mov [rcx], r8
    xor eax, eax
    ret
.publish_zero:
    mov qword [rcx], 0
    xor eax, eax
    ret
.invalid:
    mov eax, 1
    ret
.type:
    mov eax, 2
    ret
.duplicate:
    mov eax, 3
    ret
.missing:
    mov eax, 4
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
