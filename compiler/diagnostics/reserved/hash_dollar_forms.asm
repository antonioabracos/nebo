default rel
section .text
global nebo_reserved_hash_dollar_form
; rdi=lexeme, rsi=length, rdx=execute intent, rcx=out[id,diagnostic,0].
nebo_reserved_hash_dollar_form:
    test rdi, rdi
    jz .invalid
    test rcx, rcx
    jz .invalid
    cmp rdx, 1
    ja .invalid
    cmp rsi, 1
    je .single
    cmp rsi, 7
    jne .unknown
    cmp byte [rdi], '#'
    jne .unknown
    mov r8d, 1
.hex:
    movzx eax, byte [rdi+r8]
    cmp al, '0'
    jb .upper
    cmp al, '9'
    jbe .hex_ok
.upper:
    cmp al, 'A'
    jb .lower
    cmp al, 'F'
    jbe .hex_ok
.lower:
    cmp al, 'a'
    jb .unknown
    cmp al, 'f'
    ja .unknown
.hex_ok:
    inc r8
    cmp r8, 7
    jb .hex
    mov r8d, 6
    jmp .publish
.single:
    cmp byte [rdi], '#'
    je .hash
    cmp byte [rdi], '$'
    jne .unknown
    mov r8d, 7
    jmp .publish
.hash:
    mov r8d, 5
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
