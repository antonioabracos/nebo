default rel
section .text
global nebo_graph_provenance_hash
; edge qwords,count<=64 (four qwords each),format version=1.
nebo_graph_provenance_hash:
    test rdi, rdi
    jz .invalid
    cmp rsi, 64
    ja .limit
    cmp rdx, 1
    jne .version
    mov rax, 1469598103934665603
    mov r9, 1099511628211
    mov r8, rsi
    shl r8, 2
    xor ecx, ecx
.loop:
    cmp rcx, r8
    jae .done
    xor rax, [rdi+rcx*8]
    imul rax, r9
    inc rcx
    jmp .loop
.done: xor edx, edx
    ret
.invalid: xor eax, eax
    mov edx, 1
    ret
.limit: xor eax, eax
    mov edx, 2
    ret
.version: xor eax, eax
    mov edx, 3
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
