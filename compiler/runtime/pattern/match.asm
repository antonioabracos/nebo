default rel
section .text
global nebo_pattern_match
; rdi=Text bytes, rsi=Text length, rdx=compiled descriptor,
; rcx=caller capture[2]. eax=matched, edx=status.
nebo_pattern_match:
    push rbx
    push r12
    push r13
    push r14
    test rdx, rdx
    jz .invalid
    test rcx, rcx
    jz .invalid
    test rsi, rsi
    jz .descriptor
    test rdi, rdi
    jz .invalid
.descriptor:
    mov rbx, rdx
    mov r12, [rbx]
    mov r13, [rbx+8]
    mov r14, [rbx+24]
    test r13, r13
    jz .limits
    test r12, r12
    jz .invalid
.limits:
    cmp qword [rbx+16], 1
    ja .invalid
    test r14, r14
    jz .limit
    cmp r14, 1000000
    ja .limit
    cmp r13, rsi
    ja .no_match
    mov r11, rsi
    sub r11, r13
    xor r8d, r8d
    xor r9d, r9d
.candidate:
    cmp r9, r11
    ja .no_match
    xor r10d, r10d
.compare:
    cmp r10, r13
    jae .matched
    inc r8
    cmp r8, r14
    ja .limit
    mov al, [r12+r10]
    cmp qword [rbx+16], 1
    jne .literal
    cmp al, '.'
    je .next_byte
.literal:
    cmp al, [rdi+r9]
    ; The text offset also includes the inner pattern index.
    jne .retry_with_full_offset
.next_byte:
    inc r10
    inc r9
    jmp .compare
.retry_with_full_offset:
    ; r9 was advanced while testing this candidate; recover its start.
    sub r9, r10
    inc r9
    jmp .candidate
.matched:
    sub r9, r10
    mov [rcx], r9
    mov [rcx+8], r13
    mov eax, 1
    xor edx, edx
    jmp .return
.no_match:
    xor eax, eax
    xor edx, edx
    jmp .return
.invalid:
    xor eax, eax
    mov edx, 1
    jmp .return
.limit:
    xor eax, eax
    mov edx, 2
.return:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
