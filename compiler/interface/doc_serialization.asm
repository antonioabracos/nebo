; Native DocRecordV1 <-> compiled-interface adapter.  A public record is one
; authenticated optional section, so V1 readers that predate G156 remain
; forward-compatible.  Private records fail before any output publication.
bits 64
default rel
%include "compiler/semantic/docs/doc_record.inc"
%include "compiler/interface/interface_v1.inc"

%define DOC_NI_BYTES 4192
%define DOC_NI_DIRECTORY 64
%define DOC_NI_PAYLOAD 96
%define DOC_NI_OPTIONAL 1

global neboc_doc_serialize
global neboc_doc_deserialize
global neboc_doc_project_index_key
extern neboc_doc_record_validate

section .text

; rax=state, rdi=bytes, rsi=length -> rax=extended FNV-1a64.
align 16
doc_ni_hash_extend:
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
doc_ni_hash:
    mov rax, NEBOC_DOC_FNV_OFFSET
    jmp doc_ni_hash_extend

; rdi=record, rsi=output, rdx=capacity, rcx=length publication pointer.
align 16
neboc_doc_serialize:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14, rcx
    test r13, r13
    jz .argument
    test r14, r14
    jz .argument
    test r13, 7
    jnz .argument
    test r14, 7
    jnz .argument
    cmp rdx, DOC_NI_BYTES
    jb .limit
    call neboc_doc_record_validate
    test eax, eax
    jnz .return
    cmp dword [r12 + NEBOC_DOC_OFF_ORIGIN_VIS + 4], NEBOC_DOC_RECORD_VIS_PUBLIC
    jne .private

    mov rax, NEBOC_NI_MAGIC
    mov qword [r13], rax
    mov word [r13 + 8], NEBOC_NI_VERSION
    mov word [r13 + 10], NEBOC_NI_HEADER_SIZE
    mov dword [r13 + 12], NEBOC_NI_EDITION
    mov rax, NEBOC_NI_TARGET_X86_64
    mov qword [r13 + 16], rax
    mov rax, qword [r12 + NEBOC_DOC_OFF_SYMBOL]
    mov qword [r13 + 24], rax
    mov rax, NEBOC_DOC_FNV_OFFSET
    mov qword [r13 + 32], rax
    lea rdi, [r13 + 16]
    mov esi, 8
    call doc_ni_hash_extend
    mov qword [r13 + 40], rax
    mov dword [r13 + 48], 1
    mov dword [r13 + 52], DOC_NI_BYTES
    mov qword [r13 + 56], 0

    mov dword [r13 + DOC_NI_DIRECTORY], NEBOC_NI_SECTION_DOC_RECORDS
    mov dword [r13 + DOC_NI_DIRECTORY + 4], DOC_NI_OPTIONAL
    mov qword [r13 + DOC_NI_DIRECTORY + 8], DOC_NI_PAYLOAD
    mov qword [r13 + DOC_NI_DIRECTORY + 16], NEBOC_DOC_RECORD_BYTES
    mov qword [r13 + DOC_NI_DIRECTORY + 24], 0

    lea rdi, [r13 + DOC_NI_PAYLOAD]
    mov rsi, r12
    mov ecx, NEBOC_DOC_RECORD_BYTES / 8
    rep movsq
    lea rdi, [r13 + DOC_NI_PAYLOAD]
    mov esi, NEBOC_DOC_RECORD_BYTES
    call doc_ni_hash
    mov qword [r13 + DOC_NI_DIRECTORY + 24], rax

    mov rdi, r13
    mov esi, 56
    call doc_ni_hash
    lea rdi, [r13 + NEBOC_NI_HEADER_SIZE]
    mov esi, DOC_NI_BYTES - NEBOC_NI_HEADER_SIZE
    call doc_ni_hash_extend
    mov qword [r13 + 56], rax
    mov qword [r14], DOC_NI_BYTES
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
.private:
    mov eax, NEBOC_DOC_STATUS_SCHEMA
    mov edx, 5
.return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret

; rdi=complete interface, rsi=length, rdx=caller-owned record.
align 16
neboc_doc_deserialize:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    test r12, r12
    jz .argument
    test r14, r14
    jz .argument
    test r12, 7
    jnz .argument
    test r14, 7
    jnz .argument
    cmp r13, DOC_NI_BYTES
    jne .schema
    mov rax, NEBOC_NI_MAGIC
    cmp qword [r12], rax
    jne .schema
    cmp word [r12 + 8], NEBOC_NI_VERSION
    jne .schema
    cmp word [r12 + 10], NEBOC_NI_HEADER_SIZE
    jne .schema
    cmp dword [r12 + 12], NEBOC_NI_EDITION
    jne .schema
    cmp dword [r12 + 48], 1
    jne .schema
    cmp dword [r12 + 52], DOC_NI_BYTES
    jne .schema
    cmp dword [r12 + DOC_NI_DIRECTORY], NEBOC_NI_SECTION_DOC_RECORDS
    jne .schema
    cmp dword [r12 + DOC_NI_DIRECTORY + 4], DOC_NI_OPTIONAL
    jne .schema
    cmp qword [r12 + DOC_NI_DIRECTORY + 8], DOC_NI_PAYLOAD
    jne .schema
    cmp qword [r12 + DOC_NI_DIRECTORY + 16], NEBOC_DOC_RECORD_BYTES
    jne .schema
    mov rax, NEBOC_DOC_FNV_OFFSET
    cmp qword [r12 + 32], rax
    jne .schema
    lea rdi, [r12 + 16]
    mov esi, 8
    call doc_ni_hash_extend
    cmp rax, qword [r12 + 40]
    jne .schema
    lea rdi, [r12 + DOC_NI_PAYLOAD]
    mov esi, NEBOC_DOC_RECORD_BYTES
    call doc_ni_hash
    cmp rax, qword [r12 + DOC_NI_DIRECTORY + 24]
    jne .schema
    mov rdi, r12
    mov esi, 56
    call doc_ni_hash
    lea rdi, [r12 + NEBOC_NI_HEADER_SIZE]
    mov esi, DOC_NI_BYTES - NEBOC_NI_HEADER_SIZE
    call doc_ni_hash_extend
    cmp rax, qword [r12 + 56]
    jne .schema
    lea rdi, [r12 + DOC_NI_PAYLOAD]
    call neboc_doc_record_validate
    test eax, eax
    jnz .return
    mov rax, qword [r12 + 24]
    cmp rax, qword [r12 + DOC_NI_PAYLOAD + NEBOC_DOC_OFF_SYMBOL]
    jne .schema
    lea rsi, [r12 + DOC_NI_PAYLOAD]
    mov rdi, r14
    mov ecx, NEBOC_DOC_RECORD_BYTES / 8
    rep movsq
    xor eax, eax
    xor edx, edx
    jmp .return
.argument:
    mov eax, NEBOC_DOC_STATUS_ARGUMENT
    mov edx, 1
    jmp .return
.schema:
    mov eax, NEBOC_DOC_STATUS_SCHEMA
    mov edx, 2
.return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret

; rdi=record, rsi=qword output.  The key is stable across source renames.
align 16
neboc_doc_project_index_key:
    push rsi
    call neboc_doc_record_validate
    pop rsi
    test eax, eax
    jnz .return
    test rsi, rsi
    jz .argument
    mov rax, qword [rdi + NEBOC_DOC_OFF_INDEX_KEY]
    mov qword [rsi], rax
    xor eax, eax
    xor edx, edx
.return:
    ret
.argument:
    mov eax, NEBOC_DOC_STATUS_ARGUMENT
    mov edx, 1
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
