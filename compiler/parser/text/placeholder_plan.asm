default rel
section .text
global nebo_placeholder_plan
; dil=placeholder s/d/f/b, rsi=argument type 1..4, rdx=profile flags <=15,
; rcx=out[registry id, type, flags]. eax=typed status.
nebo_placeholder_plan:
    test rcx, rcx
    jz .invalid
    cmp rdx, 15
    ja .invalid
    movzx eax, dil
    cmp al, 's'
    je .text
    cmp al, 'd'
    je .integer
    cmp al, 'f'
    je .float
    cmp al, 'b'
    je .boolean
    jmp .invalid
.text:
    mov r8d, 1
    jmp .typed
.integer:
    mov r8d, 2
    jmp .typed
.float:
    mov r8d, 3
    jmp .typed
.boolean:
    mov r8d, 4
.typed:
    cmp rsi, r8
    jne .mismatch
    mov qword [rcx], 78
    mov [rcx+8], r8
    mov [rcx+16], rdx
    xor eax, eax
    ret
.invalid:
    mov eax, 1
    ret
.mismatch:
    mov eax, 2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
