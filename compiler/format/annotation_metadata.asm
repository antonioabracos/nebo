default rel
section .text
global nebo_annotation_tooling_metadata
; rdi=reflection 0 none/1 compile-time/2 generated-runtime,
; rsi=macro hygiene, rdx=formatter preservation, rcx=source activation,
; r8=out[5]. Source activation must remain zero.
nebo_annotation_tooling_metadata:
    test r8, r8
    jz .invalid
    cmp rdi, 2
    ja .invalid
    cmp rsi, 1
    jne .hygiene
    cmp rdx, 1
    jne .hygiene
    test rcx, rcx
    jnz .overclaim
    mov [r8], rdi
    mov qword [r8+8], 1
    mov qword [r8+16], 1
    mov qword [r8+24], 0
    mov qword [r8+32], 80
    xor eax, eax
    ret
.invalid:
    mov eax, 1
    ret
.hygiene:
    mov eax, 2
    ret
.overclaim:
    mov eax, 3
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
