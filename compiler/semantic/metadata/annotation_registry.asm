default rel
section .text
global nebo_annotation_registry_validate
; rdi=descriptor[identity,version,allowed-target mask,visibility].
; rax=stable identity/version key, rdx=status.
nebo_annotation_registry_validate:
    test rdi, rdi
    jz .invalid
    mov rax, [rdi]
    test rax, rax
    jz .invalid
    mov rcx, [rdi+8]
    test rcx, rcx
    jz .invalid
    mov r8, [rdi+16]
    test r8, r8
    jz .targets
    test r8, -64
    jnz .targets
    cmp qword [rdi+24], 2
    ja .invalid
    rol rcx, 17
    xor rax, rcx
    xor edx, edx
    ret
.invalid:
    xor eax, eax
    mov edx, 1
    ret
.targets:
    xor eax, eax
    mov edx, 2
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
