default rel
section .text
global nebo_reserved_index_slice_form
; rdi=lexeme, rsi=length, rdx=execute intent, rcx=out[id,diagnostic,0].
nebo_reserved_index_slice_form:
    test rdi, rdi
    jz .invalid
    test rcx, rcx
    jz .invalid
    cmp rdx, 1
    ja .invalid
    cmp rsi, 3
    jb .unknown
    mov r8, rsi
    dec r8
    cmp byte [rdi+r8], ']'
    je .index_scan
    xor r8d, r8d
    mov r9, -1
.slice_scan:
    cmp r8, rsi
    jae .slice_done
    cmp byte [rdi+r8], ':'
    jne .slice_next
    cmp r8, 0
    je .unknown
    mov r10, rsi
    dec r10
    cmp r8, r10
    je .unknown
    cmp r9, -1
    jne .unknown
    mov r9, r8
.slice_next:
    inc r8
    jmp .slice_scan
.slice_done:
    cmp r9, -1
    je .unknown
    mov r8d, 16
    jmp .publish
.index_scan:
    mov r8d, 1
    mov r9, rsi
    sub r9, 2
.index_loop:
    cmp r8, r9
    ja .unknown
    cmp byte [rdi+r8], '['
    je .index
    inc r8
    jmp .index_loop
.index:
    cmp r8, r9
    je .unknown
    mov r8d, 15
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
