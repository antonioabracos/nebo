default rel
section .rodata
align 8
quick_fixes:
    dq 146001,146002,146003,0,146005,146006,146007,146008
    dq 146009,0,146011,146012,146013,146014,146015,146016,146017,146018
    dq 146019,146020,0,0,146023,0,0,146026
section .text
global nebo_rejected_migration
; edi=Registry ordinal 1..26, rsi=out[diagnostic,quick-fix].
; eax: 1 automatic fix, 2 manual migration, 3 invalid; invalid is atomic.
nebo_rejected_migration:
    test rsi, rsi
    jz .invalid
    test edi, edi
    jz .invalid
    cmp edi, 26
    ja .invalid
    mov eax, edi
    add rax, 145000
    mov [rsi], rax
    lea r8, [quick_fixes]
    mov eax, edi
    dec eax
    mov rax, [r8+rax*8]
    mov [rsi+8], rax
    test rax, rax
    jz .manual
    mov eax, 1
    ret
.manual:
    mov eax, 2
    ret
.invalid:
    mov eax, 3
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
