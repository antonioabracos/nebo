default rel
section .text
global nebo_text_concat_checked
; rdi=left, rsi=left bytes, rdx=right, rcx=right bytes,
; r8=caller output, r9=capacity. rax=written bytes, rdx=status.
nebo_text_concat_checked:
    test r8, r8
    jz .invalid
    test rsi, rsi
    jz .right_pointer
    test rdi, rdi
    jz .invalid
.right_pointer:
    test rcx, rcx
    jz .size
    test rdx, rdx
    jz .invalid
.size:
    mov r10, rdx
    mov rax, rsi
    add rax, rcx
    jc .overflow
    cmp r9, rax
    jb .capacity
    xor r9d, r9d
.copy_left:
    cmp r9, rsi
    jae .right_start
    mov dl, [rdi+r9]
    mov [r8+r9], dl
    inc r9
    jmp .copy_left
.right_start:
    lea rdi, [r8+rsi]
    xor r9d, r9d
.copy_right:
    cmp r9, rcx
    jae .ok
    mov dl, [r10+r9]
    mov [rdi+r9], dl
    inc r9
    jmp .copy_right
.ok:
    xor edx, edx
    ret
.invalid:
    xor eax, eax
    mov edx, 1
    ret
.overflow:
    xor eax, eax
    mov edx, 2
    ret
.capacity:
    xor eax, eax
    mov edx, 3
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
