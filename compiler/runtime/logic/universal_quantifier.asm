default rel
section .text
global nebo_forall_bounded
; values: 0 FALSE,1 TRUE,2 UNKNOWN,3 TIMEOUT; rsi=count,rdx=budget.
nebo_forall_bounded:
    test rdi, rdi
    jz .invalid
    cmp rsi, 1000000
    ja .invalid
    cmp rdx, rsi
    jb .budget_timeout
    mov r8d, 1
    xor ecx, ecx
.loop:
    cmp rcx, rsi
    jae .done
    mov eax, [rdi+rcx*4]
    cmp eax, 3
    ja .invalid
    test eax, eax
    jz .mark_false
    cmp eax, 3
    je .mark_timeout
    cmp eax, 2
    jne .next
    cmp r8d, 1
    jne .next
    mov r8d, 2
    jmp .next
.mark_timeout:
    test r8d, r8d
    jz .next
    mov r8d, 3
    jmp .next
.mark_false: xor r8d, r8d
.next: inc rcx
    jmp .loop
.done: mov eax, r8d
    ret
.budget_timeout: mov eax, 3
    ret
.invalid: mov eax, 4
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
