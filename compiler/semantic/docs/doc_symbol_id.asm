; Stable attachment SymbolId owner.  This is byte-for-byte the FNV-1a owner
; used by the native G155 DocParser for declaration names.
bits 64
default rel
%include "compiler/semantic/docs/doc_record.inc"
global neboc_doc_symbol_id
section .text
align 16
neboc_doc_symbol_id:
    test rdi, rdi
    jz .argument
    test rdx, rdx
    jz .argument
    test rdx, 7
    jnz .argument
    test rsi, rsi
    jz .argument
    cmp rsi, 4096
    ja .limit
    mov rax, NEBOC_DOC_FNV_OFFSET
    mov r8, NEBOC_DOC_FNV_PRIME
    xor ecx, ecx
.loop:
    cmp rcx, rsi
    jae .publish
    movzx r9d, byte [rdi + rcx]
    test r9b, r9b
    jz .schema
    xor rax, r9
    imul rax, r8
    inc rcx
    jmp .loop
.publish:
    test rax, rax
    jnz .nonzero
    inc rax
.nonzero:
    mov qword [rdx], rax
    xor eax, eax
    xor edx, edx
    ret
.argument:
    mov eax, NEBOC_DOC_STATUS_ARGUMENT
    mov edx, 1
    ret
.schema:
    mov eax, NEBOC_DOC_STATUS_SCHEMA
    mov edx, 2
    ret
.limit:
    mov eax, NEBOC_DOC_STATUS_LIMIT
    mov edx, 3
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
