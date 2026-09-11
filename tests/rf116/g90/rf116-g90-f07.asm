bits 64
default rel
%include "runtime/render_model.inc"
extern nebo_render_media_metadata
global _start
section .text
_start:
    lea rdi, [rel image]
    lea rsi, [rel node]
    call nebo_render_media_metadata
    test eax, eax
    jnz fail
    cmp qword [rel node + NEBO_NODE_KIND_OFFSET], NEBO_NODE_MEDIA_METADATA
    jne fail
    cmp qword [rel node + NEBO_NODE_COUNT_OFFSET], 640
    jne fail
    lea rdi, [rel oversized]
    lea rsi, [rel untouched]
    call nebo_render_media_metadata
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
section .data
metadata: dq 0x52474241
image: dq metadata, NEBO_TYPE_IMAGE, 640, 480, 8, 0
oversized: dq metadata, NEBO_TYPE_VIDEO, 2048, 2048, 8, 0
untouched: times NEBO_NODE_SIZE db 0xaa
section .bss
node: resb NEBO_NODE_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
