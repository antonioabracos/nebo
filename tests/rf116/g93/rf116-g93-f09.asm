bits 64
default rel
%include "runtime/layout_model.inc"
extern nebo_layout_hash
global _start
section .text
_start:
    lea rdi, [rel request]
    lea rsi, [rel first]
    call nebo_layout_hash
    test eax, eax
    jnz fail
    lea rdi, [rel request]
    lea rsi, [rel second]
    call nebo_layout_hash
    test eax, eax
    jnz fail
    mov rax, [rel first + NEBO_LAYOUT_HASH_RECEIPT_DIGEST_OFFSET]
    cmp rax, [rel second + NEBO_LAYOUT_HASH_RECEIPT_DIGEST_OFFSET]
    jne fail
    lea rdi, [rel changed_request]
    lea rsi, [rel changed]
    call nebo_layout_hash
    test eax, eax
    jnz fail
    mov rax, [rel first + NEBO_LAYOUT_HASH_RECEIPT_DIGEST_OFFSET]
    cmp rax, [rel changed + NEBO_LAYOUT_HASH_RECEIPT_DIGEST_OFFSET]
    je fail
    lea rdi, [rel bad_request]
    lea rsi, [rel untouched]
    call nebo_layout_hash
    cmp eax, NEBO_LAYOUT_CONFLICT
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
nodes:
    dq NEBO_LAYOUT_GRID, 1, 0, 1, 80, 24, 3, NEBO_LAYOUT_NODE_READY
    dq NEBO_LAYOUT_ROW, 2, 0, 0, 80, 12, 1, NEBO_LAYOUT_NODE_READY
changed_nodes:
    dq NEBO_LAYOUT_GRID, 1, 0, 1, 81, 24, 3, NEBO_LAYOUT_NODE_READY
    dq NEBO_LAYOUT_ROW, 2, 0, 0, 80, 12, 1, NEBO_LAYOUT_NODE_READY
bad_nodes:
    dq NEBO_LAYOUT_GRID, 2, 0, 1, 80, 24, 3, NEBO_LAYOUT_NODE_READY
    dq NEBO_LAYOUT_ROW, 1, 0, 0, 80, 12, 1, NEBO_LAYOUT_NODE_READY
request: dq nodes, 2
changed_request: dq changed_nodes, 2
bad_request: dq bad_nodes, 2
untouched: times NEBO_LAYOUT_HASH_RECEIPT_SIZE db 0xaa
section .bss
first: resb NEBO_LAYOUT_HASH_RECEIPT_SIZE
second: resb NEBO_LAYOUT_HASH_RECEIPT_SIZE
changed: resb NEBO_LAYOUT_HASH_RECEIPT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
