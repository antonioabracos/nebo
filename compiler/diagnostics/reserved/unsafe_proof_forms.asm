default rel
section .text
global nebo_reserved_unsafe_proof_form
; rdi=UTF-8 lexeme, rsi=length, rdx=execute intent, rcx=out[id,diagnostic,0].
nebo_reserved_unsafe_proof_form:
    test rdi, rdi
    jz .invalid
    test rcx, rcx
    jz .invalid
    cmp rdx, 1
    ja .invalid
    cmp rsi, 2
    jb .unknown
    mov al, [rdi]
    cmp al, '&'
    je .address
    cmp al, '*'
    je .deref
    cmp rsi, 2
    jne .three_or_abs
    cmp al, 0ceh
    jne .unknown
    cmp byte [rdi+1], 0bbh
    jne .unknown
    mov r8d, 19
    jmp .publish
.three_or_abs:
    cmp al, '|'
    je .absolute
    cmp rsi, 3
    jne .unknown
    cmp al, 0e2h
    jne .unknown
    mov al, [rdi+1]
    cmp al, 086h
    je .map_arrow
    cmp al, 089h
    je .define
    cmp al, 088h
    jne .unknown
    mov al, [rdi+2]
    cmp al, 0b4h
    je .proof
    cmp al, 0b5h
    jne .unknown
.proof:
    mov r8d, 23
    jmp .publish
.map_arrow:
    cmp byte [rdi+2], 0a6h
    jne .unknown
    mov r8d, 20
    jmp .publish
.define:
    cmp byte [rdi+2], 094h
    jne .unknown
    mov r8d, 22
    jmp .publish
.absolute:
    cmp rsi, 3
    jb .unknown
    mov r8, rsi
    dec r8
    cmp byte [rdi+r8], '|'
    jne .unknown
    mov r8d, 21
    jmp .publish
.address:
    mov r8d, 17
    jmp .publish
.deref:
    mov r8d, 18
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
