default rel
section .text
global nebo_format_plan_evaluate_once
; rdi=nodes[kind,expr_id], rsi=node count, rdx=declared expressions,
; rcx=step budget, r8=out[visited mask,node count].
; kind 0 is literal and kind 1 is a pure expression slot.
nebo_format_plan_evaluate_once:
    test r8, r8
    jz .invalid
    test rsi, rsi
    jz .empty_pointer
    test rdi, rdi
    jz .invalid
.empty_pointer:
    cmp rsi, 256
    ja .limit
    cmp rdx, 64
    ja .limit
    cmp rcx, rsi
    jb .limit
    cmp rcx, 4096
    ja .limit
    xor r9d, r9d
    xor r10d, r10d
.node:
    cmp r10, rsi
    jae .coverage
    mov r11, r10
    shl r11, 4
    mov rax, [rdi+r11]
    test rax, rax
    jz .next
    cmp rax, 1
    jne .invalid
    mov rax, [rdi+r11+8]
    cmp rax, rdx
    jae .invalid
    bts r9, rax
    jc .duplicate
.next:
    inc r10
    jmp .node
.coverage:
    test rdx, rdx
    jz .expect_zero
    cmp rdx, 64
    je .expect_all
    mov r11, 1
    mov rcx, rdx
    shl r11, cl
    dec r11
    jmp .compare
.expect_all:
    mov r11, -1
    jmp .compare
.expect_zero:
    xor r11d, r11d
.compare:
    cmp r9, r11
    jne .missing
    mov [r8], r9
    mov [r8+8], rsi
    xor eax, eax
    ret
.invalid:
    mov eax, 1
    ret
.limit:
    mov eax, 2
    ret
.duplicate:
    mov eax, 3
    ret
.missing:
    mov eax, 4
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
