; G156 canonical DocRecordV1 owner.  The request and result use the same
; pointerless 4096-byte layout.  The constructor overwrites framing and hashes,
; validates all bounds, then publishes the complete record in one final copy.
bits 64
default rel

%include "compiler/semantic/docs/doc_record.inc"

global neboc_doc_record
global neboc_doc_record_new
global neboc_doc_record_validate
global neboc_doc_record_reseal
global neboc_doc_record_set_slot
global neboc_doc_record_set_summary
global neboc_doc_record_add_example
global neboc_doc_record_add_law
global neboc_doc_record_signature_hash
global neboc_doc_record_rebind
extern neboc_utf8_validate

section .text

align 16
doc_record_hash:
    mov rax, NEBOC_DOC_FNV_OFFSET
    mov r8, NEBOC_DOC_FNV_PRIME
    xor ecx, ecx
.loop:
    cmp rcx, rsi
    jae .done
    movzx edx, byte [rdi + rcx]
    xor rax, rdx
    imul rax, r8
    inc rcx
    jmp .loop
.done:
    test rax, rax
    jnz .return
    inc rax
.return:
    ret

align 16
neboc_doc_record_validate:
    test rdi, rdi
    jz .argument
    test rdi, 7
    jnz .argument
    mov rax, NEBOC_DOC_RECORD_MAGIC
    cmp qword [rdi + NEBOC_DOC_OFF_MAGIC], rax
    jne .schema
    mov rax, NEBOC_DOC_RECORD_SCHEMA_WORD
    cmp qword [rdi + NEBOC_DOC_OFF_SCHEMA], rax
    jne .schema
    cmp qword [rdi + NEBOC_DOC_OFF_SYMBOL], 0
    je .schema
    mov rax, qword [rdi + NEBOC_DOC_OFF_SPAN_START]
    cmp rax, qword [rdi + NEBOC_DOC_OFF_SPAN_END]
    jae .schema
    cmp qword [rdi + NEBOC_DOC_OFF_SIGNATURE], 0
    je .schema
    mov rax, qword [rdi + NEBOC_DOC_OFF_FIELD_MASK]
    mov rdx, rax
    and rdx, ~NEBOC_DOC_RECORD_FIELD_MASK
    jnz .schema
    test al, 1
    jz .schema
    cmp qword [rdi + NEBOC_DOC_OFF_TITLE], 0
    je .schema
    mov eax, dword [rdi + NEBOC_DOC_OFF_ORIGIN_VIS]
    cmp eax, NEBOC_DOC_RECORD_ORIGIN_BUILTIN
    jb .schema
    cmp eax, NEBOC_DOC_RECORD_ORIGIN_INTERFACE
    ja .schema
    mov eax, dword [rdi + NEBOC_DOC_OFF_ORIGIN_VIS + 4]
    cmp eax, NEBOC_DOC_RECORD_VIS_PUBLIC
    jb .schema
    cmp eax, NEBOC_DOC_RECORD_VIS_PRIVATE
    ja .schema
    mov eax, dword [rdi + NEBOC_DOC_OFF_COUNTS_A]
    cmp al, 4
    ja .limit
    mov edx, eax
    shr edx, 8
    cmp dl, 8
    ja .limit
    shr edx, 8
    cmp dl, 8
    ja .limit
    shr edx, 8
    cmp dl, 8
    ja .limit
    mov eax, dword [rdi + NEBOC_DOC_OFF_COUNTS_B]
    cmp al, 8
    ja .limit
    mov edx, eax
    shr edx, 8
    cmp dl, 1
    ja .limit
    shr edx, 8
    cmp dl, 1
    ja .limit
    mov rax, qword [rdi + NEBOC_DOC_OFF_TEXT_LENGTH]
    cmp rax, NEBOC_DOC_TEXT_CAPACITY
    ja .limit
    test rax, rax
    jz .text_valid
    push rdi
    sub rsp, 16
    mov rsi, rax
    lea rdi, [rdi + NEBOC_DOC_OFF_TEXT]
    mov rdx, rsp
    call neboc_utf8_validate
    add rsp, 16
    pop rdi
    test eax, eax
    jnz .schema
.text_valid:
    mov rcx, qword [rdi + NEBOC_DOC_OFF_TEXT_LENGTH]
    lea r8, [rdi + NEBOC_DOC_OFF_TEXT]
    add r8, rcx
    mov r9, NEBOC_DOC_OFF_CONTENT_HASH - NEBOC_DOC_OFF_TEXT
    sub r9, rcx
.reserved_loop:
    test r9, r9
    jz .reserved_valid
    cmp byte [r8], 0
    jne .schema
    inc r8
    dec r9
    jmp .reserved_loop
.reserved_valid:
    push rdi
    mov esi, NEBOC_DOC_OFF_CONTENT_HASH
    call doc_record_hash
    pop rdi
    cmp rax, qword [rdi + NEBOC_DOC_OFF_CONTENT_HASH]
    jne .schema
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

align 16
neboc_doc_record_reseal:
    push rdi
    mov esi, NEBOC_DOC_OFF_CONTENT_HASH
    call doc_record_hash
    pop rdi
    mov qword [rdi + NEBOC_DOC_OFF_CONTENT_HASH], rax
    xor eax, eax
    xor edx, edx
    ret

align 16
neboc_doc_record:
neboc_doc_record_new:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, NEBOC_DOC_RECORD_BYTES
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .argument
    test r13, r13
    jz .argument
    test r12, 7
    jnz .argument
    test r13, 7
    jnz .argument
    mov r14, qword [r12 + NEBOC_DOC_OFF_TEXT_LENGTH]
    cmp r14, NEBOC_DOC_TEXT_CAPACITY
    ja .limit
    mov rdi, rsp
    xor eax, eax
    mov ecx, NEBOC_DOC_RECORD_BYTES / 8
    rep stosq
    mov rsi, r12
    mov rdi, rsp
    mov ecx, NEBOC_DOC_OFF_TEXT / 8
    rep movsq
    test r14, r14
    jz .request_copied
    lea rsi, [r12 + NEBOC_DOC_OFF_TEXT]
    lea rdi, [rsp + NEBOC_DOC_OFF_TEXT]
    mov rcx, r14
    rep movsb
.request_copied:
    mov rax, NEBOC_DOC_RECORD_MAGIC
    mov qword [rsp + NEBOC_DOC_OFF_MAGIC], rax
    mov rax, NEBOC_DOC_RECORD_SCHEMA_WORD
    mov qword [rsp + NEBOC_DOC_OFF_SCHEMA], rax
    mov qword [rsp + NEBOC_DOC_OFF_CONTENT_HASH], 0
    cmp qword [rsp + NEBOC_DOC_OFF_INDEX_KEY], 0
    jne .index_ready
    mov rax, qword [rsp + NEBOC_DOC_OFF_SYMBOL]
    xor rax, qword [rsp + NEBOC_DOC_OFF_SIGNATURE]
    rol rax, 17
    test rax, rax
    jnz .store_index
    inc rax
.store_index:
    mov qword [rsp + NEBOC_DOC_OFF_INDEX_KEY], rax
.index_ready:
    mov rdi, rsp
    mov esi, NEBOC_DOC_OFF_CONTENT_HASH
    call doc_record_hash
    mov qword [rsp + NEBOC_DOC_OFF_CONTENT_HASH], rax
    mov rdi, rsp
    call neboc_doc_record_validate
    test eax, eax
    jnz .return
    mov rsi, rsp
    mov rdi, r13
    mov ecx, NEBOC_DOC_RECORD_BYTES / 8
    rep movsq
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
.return:
    add rsp, NEBOC_DOC_RECORD_BYTES
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret

align 16
neboc_doc_record_set_slot:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov rbx, rcx
    test r13, r13
    jz .argument
    test r14, 7
    jnz .argument
    cmp r14, NEBOC_DOC_OFF_TITLE
    jb .argument
    cmp r14, NEBOC_DOC_OFF_INDEX_KEY
    ja .argument
    call neboc_doc_record_validate
    test eax, eax
    jnz .return
    mov rax, qword [r12 + r14]
    test rax, rax
    jz .publish
    cmp rax, r13
    je .success
    mov eax, NEBOC_DOC_STATUS_CONFLICT
    mov edx, 4
    jmp .return
.publish:
    mov qword [r12 + r14], r13
    or qword [r12 + NEBOC_DOC_OFF_FIELD_MASK], rbx
    mov rdi, r12
    call neboc_doc_record_reseal
.success:
    xor eax, eax
    xor edx, edx
    jmp .return
.argument:
    mov eax, NEBOC_DOC_STATUS_ARGUMENT
    mov edx, 1
.return:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

align 16
neboc_doc_record_set_summary:
    mov edx, NEBOC_DOC_OFF_SUMMARY
    mov ecx, 1 << 1
    jmp neboc_doc_record_set_slot

align 16
neboc_doc_record_add_example:
    mov edx, NEBOC_DOC_OFF_EXAMPLES
    mov ecx, 1 << 12
    jmp neboc_doc_record_set_slot

align 16
neboc_doc_record_add_law:
    mov edx, NEBOC_DOC_OFF_LAWS
    mov ecx, 1 << 13
    jmp neboc_doc_record_set_slot

align 16
neboc_doc_record_signature_hash:
    push rsi
    call neboc_doc_record_validate
    pop rsi
    test eax, eax
    jnz .return
    test rsi, rsi
    jz .argument
    test rsi, 7
    jnz .argument
    mov rax, qword [rdi + NEBOC_DOC_OFF_SIGNATURE]
    mov qword [rsi], rax
    xor eax, eax
    xor edx, edx
.return:
    ret
.argument:
    mov eax, NEBOC_DOC_STATUS_ARGUMENT
    mov edx, 1
    ret

; rdi=validated record, rsi=new resolver SymbolId, rdx=output.  A refactor can
; move the same semantic record to its new identity without name-based lookup.
align 16
neboc_doc_record_rebind:
    push rbx
    push r12
    push r13
    mov r12, rsi
    mov r13, rdx
    test r12, r12
    jz .argument
    test r13, r13
    jz .argument
    test r13, 7
    jnz .argument
    call neboc_doc_record_validate
    test eax, eax
    jnz .return
    mov rsi, rdi
    mov rdi, r13
    mov ecx, NEBOC_DOC_RECORD_BYTES / 8
    rep movsq
    mov qword [r13 + NEBOC_DOC_OFF_SYMBOL], r12
    mov rax, r12
    xor rax, qword [r13 + NEBOC_DOC_OFF_SIGNATURE]
    rol rax, 17
    test rax, rax
    jnz .index
    inc rax
.index:
    mov qword [r13 + NEBOC_DOC_OFF_INDEX_KEY], rax
    mov rdi, r13
    call neboc_doc_record_reseal
    xor eax, eax
    xor edx, edx
    jmp .return
.argument:
    mov eax, NEBOC_DOC_STATUS_ARGUMENT
    mov edx, 1
.return:
    pop r13
    pop r12
    pop rbx
    cld
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
