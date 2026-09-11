bits 64
default rel
%include "runtime/render_model.inc"
extern nebo_render_scalar
global _start
section .text
_start:
    lea rdi, [rel scalar]
    lea rsi, [rel node]
    call nebo_render_scalar
    test eax, eax
    jnz fail
    cmp qword [rel node + NEBO_NODE_KIND_OFFSET], NEBO_NODE_SCALAR
    jne fail
    cmp qword [rel node + NEBO_NODE_DATA_OFFSET], 42
    jne fail
    lea rdi, [rel invalid_bool]
    lea rsi, [rel untouched]
    call nebo_render_scalar
    cmp eax, NEBO_RENDER_INVALID
    jne fail
    mov rax, 0xaaaaaaaaaaaaaaaa
    cmp qword [rel untouched], rax
    jne fail
    lea rdi, [rel private]
    lea rsi, [rel untouched]
    call nebo_render_scalar
    cmp eax, NEBO_RENDER_PRIVACY
    jne fail
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .data
scalar: dq NEBO_TYPE_INT, 42, 0, 0
invalid_bool: dq NEBO_TYPE_BOOL, 2, 0, 0
private: dq nebo_render_model_TYPE_CHAR, 65, 0, NEBO_VALUE_SENSITIVE
untouched: times NEBO_NODE_SIZE db 0xaa
section .bss
node: resb NEBO_NODE_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
