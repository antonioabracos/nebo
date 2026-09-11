; Deterministic, explicit-conflict DocRecord merge.  Equal records merge;
; divergent semantic records never silently win by invocation order.
bits 64
default rel
%include "compiler/semantic/docs/doc_record.inc"
global neboc_doc_merge
global neboc_doc_record_merge
extern neboc_doc_record_validate

section .text
align 16
neboc_doc_merge:
neboc_doc_record_merge:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    mov rbx, rdx
    test rbx, rbx
    jz .argument
    test rbx, 7
    jnz .argument
    call neboc_doc_record_validate
    test eax, eax
    jnz .return
    mov rdi, r13
    call neboc_doc_record_validate
    test eax, eax
    jnz .return
    mov rax, qword [r12 + NEBOC_DOC_OFF_SYMBOL]
    cmp rax, qword [r13 + NEBOC_DOC_OFF_SYMBOL]
    jne .conflict
    mov rax, qword [r12 + NEBOC_DOC_OFF_SIGNATURE]
    cmp rax, qword [r13 + NEBOC_DOC_OFF_SIGNATURE]
    jne .conflict
    mov rax, qword [r12 + NEBOC_DOC_OFF_CONTENT_HASH]
    cmp rax, qword [r13 + NEBOC_DOC_OFF_CONTENT_HASH]
    jne .conflict
    mov rsi, r12
    mov rdi, rbx
    mov ecx, NEBOC_DOC_RECORD_BYTES / 8
    rep movsq
    xor eax, eax
    xor edx, edx
    jmp .return
.argument:
    mov eax, NEBOC_DOC_STATUS_ARGUMENT
    mov edx, 1
    jmp .return
.conflict:
    mov eax, NEBOC_DOC_STATUS_CONFLICT
    mov edx, 4
.return:
    pop r13
    pop r12
    pop rbx
    cld
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
