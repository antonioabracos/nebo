default rel
section .text
global nebo_pattern_compile
; rdi=pattern bytes, rsi=length (<=4096), rdx=mode (0 literal, 1 dot),
; rcx=step budget (1..1000000), r8=caller-owned descriptor[4 qwords].
; eax=status: 0 OK, 1 invalid, 2 limit, 3 unsupported syntax.
nebo_pattern_compile:
    test r8, r8
    jz .invalid
    test rsi, rsi
    jz .pointer_ok
    test rdi, rdi
    jz .invalid
.pointer_ok:
    cmp rdx, 1
    ja .invalid
    test rcx, rcx
    jz .limit
    cmp rcx, 1000000
    ja .limit
    cmp rsi, 4096
    ja .limit
    cmp rsi, rcx
    ja .limit
    xor r9d, r9d
.scan:
    cmp r9, rsi
    jae .publish
    mov al, [rdi+r9]
    test al, al
    jz .invalid
    cmp al, '*'
    je .unsupported
    cmp al, '+'
    je .unsupported
    cmp al, '['
    je .unsupported
    cmp al, '('
    je .unsupported
    cmp al, 92
    je .unsupported
    inc r9
    jmp .scan
.publish:
    mov [r8], rdi
    mov [r8+8], rsi
    mov [r8+16], rdx
    mov [r8+24], rcx
    xor eax, eax
    ret
.invalid:
    mov eax, 1
    ret
.limit:
    mov eax, 2
    ret
.unsupported:
    mov eax, 3
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
