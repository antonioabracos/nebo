default rel
section .text
global nebo_conditional_probability_i64
; joint_num/joint_den divided by condition_num/condition_den.
; rax=result numerator,rdx=result denominator,rcx=status.
nebo_conditional_probability_i64:
    test rdi, rdi
    js .invalid
    test rsi, rsi
    jle .invalid
    test rdx, rdx
    jle .zero_condition
    test rcx, rcx
    jle .invalid
    cmp rdi, rsi
    ja .invalid
    cmp rdx, rcx
    ja .invalid
    mov r8, rdi
    imul r8, rcx
    jo .overflow
    mov r9, rsi
    imul r9, rdx
    jo .overflow
    mov r10, r8
    mov r11, r9
.gcd:
    test r11, r11
    jz .reduce
    mov rax, r10
    xor edx, edx
    div r11
    mov r10, r11
    mov r11, rdx
    jmp .gcd
.reduce:
    mov rax, r8
    xor edx, edx
    div r10
    mov r8, rax
    mov rax, r9
    xor edx, edx
    div r10
    mov rdx, rax
    mov rax, r8
    xor ecx, ecx
    ret
.invalid: xor eax, eax
    xor edx, edx
    mov ecx, 1
    ret
.zero_condition: xor eax, eax
    xor edx, edx
    mov ecx, 2
    ret
.overflow: xor eax, eax
    xor edx, edx
    mov ecx, 3
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
