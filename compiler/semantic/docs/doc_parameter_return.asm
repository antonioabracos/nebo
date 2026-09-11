; Bound parameter and return identities for DocRecordV1.
bits 64
default rel
%include "compiler/semantic/docs/doc_record.inc"
global neboc_doc_parameter_return
global neboc_doc_record_add_parameter
global neboc_doc_record_set_return
extern neboc_doc_record_validate
extern neboc_doc_record_reseal

section .text
align 16
neboc_doc_parameter_return:
neboc_doc_record_add_parameter:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    test r13, r13
    jz .argument
    call neboc_doc_record_validate
    test eax, eax
    jnz .return
    movzx ebx, byte [r12 + NEBOC_DOC_OFF_COUNTS_A]
    cmp ebx, 4
    jae .limit
    xor ecx, ecx
.duplicate_loop:
    cmp ecx, ebx
    jae .publish
    cmp qword [r12 + NEBOC_DOC_OFF_PARAMETERS + rcx * 8], r13
    je .conflict
    inc ecx
    jmp .duplicate_loop
.publish:
    mov qword [r12 + NEBOC_DOC_OFF_PARAMETERS + rbx * 8], r13
    inc byte [r12 + NEBOC_DOC_OFF_COUNTS_A]
    or qword [r12 + NEBOC_DOC_OFF_FIELD_MASK], 1 << 2
    mov rdi, r12
    call neboc_doc_record_reseal
    xor eax, eax
    xor edx, edx
    jmp .return
.argument:
    mov eax, NEBOC_DOC_STATUS_ARGUMENT
    mov edx, 1
    jmp .return
.limit:
    mov eax, NEBOC_DOC_STATUS_LIMIT
    mov edx, 3
    jmp .return
.conflict:
    mov eax, NEBOC_DOC_STATUS_CONFLICT
    mov edx, 4
.return:
    pop r13
    pop r12
    pop rbx
    ret

align 16
neboc_doc_record_set_return:
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    test r13, r13
    jz .argument
    call neboc_doc_record_validate
    test eax, eax
    jnz .return
    mov rax, qword [r12 + NEBOC_DOC_OFF_RETURN_ID]
    test rax, rax
    jz .publish
    cmp rax, r13
    jne .conflict
    cmp qword [r12 + NEBOC_DOC_OFF_RETURN], r13
    jne .conflict
    xor eax, eax
    xor edx, edx
    jmp .return
.publish:
    cmp qword [r12 + NEBOC_DOC_OFF_RETURN], 0
    jne .conflict
    mov qword [r12 + NEBOC_DOC_OFF_RETURN], r13
    mov qword [r12 + NEBOC_DOC_OFF_RETURN_ID], r13
    or qword [r12 + NEBOC_DOC_OFF_FIELD_MASK], 1 << 3
    mov rdi, r12
    call neboc_doc_record_reseal
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
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
