bits 64
default rel
%include "runtime/render_model.inc"
extern nebo_render_buffer
global _start
section .text
_start:
    lea rdi, [rel text_value]
    lea rsi, [rel node]
    call nebo_render_buffer
    test eax, eax
    jnz fail
    cmp qword [rel node + NEBO_NODE_KIND_OFFSET], NEBO_NODE_BUFFER
    jne fail
    cmp qword [rel node + NEBO_NODE_COUNT_OFFSET], 4
    jne fail
    lea rdi, [rel too_large]
    lea rsi, [rel untouched]
    call nebo_render_buffer
    cmp eax, NEBO_RENDER_LIMIT
    jne fail
    mov rax, 0xaaaaaaaaaaaaaaaa
    cmp qword [rel untouched], rax
    jne fail
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .rodata
text: db "Nebo"
section .data
text_value: dq nebo_render_model_TYPE_TEXT, text, 4, 0
too_large: dq nebo_render_model_TYPE_BYTES, text, NEBO_MAX_RENDER_PAYLOAD + 1, 0
untouched: times NEBO_NODE_SIZE db 0xaa
section .bss
node: resb NEBO_NODE_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
