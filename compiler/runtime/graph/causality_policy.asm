default rel
section .text
global nebo_graph_policy_validate
; edge records: source,dest,capacity,backpressure; count<=64; allow_cycles bool.
nebo_graph_policy_validate:
    test rdi, rdi
    jz .invalid
    cmp rsi, 64
    ja .limit
    cmp rdx, 1
    ja .invalid
    xor ecx, ecx
.loop:
    cmp rcx, rsi
    jae .ok
    mov r8, rcx
    shl r8, 5
    cmp qword [rdi+r8+16], 0
    jle .capacity
    cmp qword [rdi+r8+24], 2
    ja .invalid
    test rdx, rdx
    jnz .next
    mov r9, [rdi+r8]
    cmp r9, [rdi+r8+8]
    je .cycle
.next: inc rcx
    jmp .loop
.ok: xor eax, eax
    ret
.invalid: mov eax, 1
    ret
.limit: mov eax, 2
    ret
.capacity: mov eax, 3
    ret
.cycle: mov eax, 4
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
