default rel
section .text
global nebo_annotation_plan
; rdi=name, rsi=name length, rdx=declaration context flag,
; rcx=argument count, r8=out[registry id,name length,args,phase].
nebo_annotation_plan:
    test rdi, rdi
    jz .invalid
    test r8, r8
    jz .invalid
    cmp rdx, 1
    jne .context
    test rsi, rsi
    jz .invalid
    cmp rsi, 64
    ja .limit
    cmp rcx, 32
    ja .limit
    xor r9d, r9d
.name:
    movzx eax, byte [rdi+r9]
    cmp al, '_'
    je .accepted
    cmp al, 'A'
    jb .digit
    cmp al, 'Z'
    jbe .accepted
    cmp al, 'a'
    jb .digit
    cmp al, 'z'
    jbe .accepted
.digit:
    test r9, r9
    jz .invalid
    cmp al, '0'
    jb .invalid
    cmp al, '9'
    ja .invalid
.accepted:
    inc r9
    cmp r9, rsi
    jb .name
    mov qword [r8], 80
    mov [r8+8], rsi
    mov [r8+16], rcx
    mov qword [r8+24], 1
    xor eax, eax
    ret
.invalid:
    mov eax, 1
    ret
.context:
    mov eax, 2
    ret
.limit:
    mov eax, 3
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
