default rel
section .text
global nebo_percent_escape
; rdi=template bytes, rsi=length, rdx=caller output, rcx=capacity.
; Collapses only %% to %, rejects every unmatched percent atomically.
nebo_percent_escape:
    test rdx, rdx
    jz .invalid
    test rsi, rsi
    jz .publish_zero
    test rdi, rdi
    jz .invalid
    mov r10, rdx
    xor r8d, r8d
    xor r9d, r9d
.preflight:
    cmp r9, rsi
    jae .capacity
    mov al, [rdi+r9]
    cmp al, '%'
    jne .plain_preflight
    inc r9
    cmp r9, rsi
    jae .unmatched
    cmp byte [rdi+r9], '%'
    jne .unmatched
.plain_preflight:
    inc r9
    inc r8
    jmp .preflight
.capacity:
    cmp rcx, r8
    jb .small
    xor r9d, r9d
    xor edx, edx
.copy:
    cmp r9, rsi
    jae .ok
    mov al, [rdi+r9]
    cmp al, '%'
    jne .store
    inc r9
.store:
    mov [r10+rdx], al
    inc rdx
    inc r9
    jmp .copy
.ok:
    mov rax, r8
    xor edx, edx
    ret
.publish_zero:
    xor eax, eax
    xor edx, edx
    ret
.invalid:
    xor eax, eax
    mov edx, 1
    ret
.unmatched:
    xor eax, eax
    mov edx, 2
    ret
.small:
    xor eax, eax
    mov edx, 3
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
