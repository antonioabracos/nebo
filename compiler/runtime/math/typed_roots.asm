bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

section .text

; rdi=unsigned radicand, esi=degree (2,3,4).
; rax=exact root, edx=status. Non-perfect powers are domain errors.
global nebo_root_exact_u64
nebo_root_exact_u64:
    cmp esi, 2
    je .square
    cmp esi, 3
    je .cube
    cmp esi, 4
    je .fourth
    jmp .domain
.square:
    mov r9, 0x100000001
    jmp .search_init
.cube:
    mov r9, 0x300000
    jmp .search_init
.fourth:
    mov r9, 0x10001
.search_init:
    xor r8d, r8d                 ; inclusive low, exclusive high
.search:
    cmp r8, r9
    jae .domain
    lea r10, [r8 + r9]
    shr r10, 1
    mov eax, 1
    mov ecx, esi
.power:
    mul r10
    test rdx, rdx
    jnz .too_large
    loop .power
    cmp rax, rdi
    je .found
    ja .too_large
    lea r8, [r10 + 1]
    jmp .search
.too_large:
    mov r9, r10
    jmp .search
.found:
    mov rax, r10
    xor edx, edx
    ret
.domain:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
