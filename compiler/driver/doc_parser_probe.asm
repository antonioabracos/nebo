; RF166-G155 no-libc transport for the canonical semantic-doc parser.
bits 64
default rel

%include "compiler/parser/doc.inc"

global _start
extern neboc_doc_parse

section .text
_start:
    xor r12d,r12d
.read:
    xor eax,eax
    xor edi,edi
    lea rsi,[rel source]
    add rsi,r12
    mov edx,NEBOC_DOC_MAX_SOURCE_BYTES+1
    sub rdx,r12
    syscall
    test rax,rax
    js .io
    jz .parse
    add r12,rax
    cmp r12,NEBOC_DOC_MAX_SOURCE_BYTES
    ja .limit
    jmp .read
.parse:
    lea rdi,[rel source]
    mov rsi,r12
    lea rdx,[rel result]
    call neboc_doc_parse
    test eax,eax
    jnz .diagnostic
    mov edi,1
    lea rsi,[rel result]
    mov edx,NEBOC_DOC_RESULT_BYTES
    call write_all
    test eax,eax
    jnz .io
    xor edi,edi
    jmp .exit
.diagnostic:
    mov [rel error_record],rdx
    mov [rel error_record+8],rcx
    mov edi,2
    lea rsi,[rel error_record]
    mov edx,16
    call write_all
    mov edi,1
    jmp .exit
.limit:
    mov qword [rel error_record],NEBOC_DOC_DIAG_LIMIT
    mov qword [rel error_record+8],0
    mov edi,2
    lea rsi,[rel error_record]
    mov edx,16
    call write_all
    mov edi,1
    jmp .exit
.io:
    mov edi,3
.exit:
    mov eax,60
    syscall

; write_all(fd, bytes, length) -> eax status.
write_all:
    test rdx,rdx
    jz .ok
.loop:
    mov eax,1
    syscall
    test rax,rax
    jle .bad
    add rsi,rax
    sub rdx,rax
    jnz .loop
.ok:
    xor eax,eax
    ret
.bad:
    mov eax,1
    ret

section .bss
source: resb NEBOC_DOC_MAX_SOURCE_BYTES+8
result: resb NEBOC_DOC_RESULT_BYTES
error_record: resq 2

section .note.GNU-stack noalloc noexec nowrite progbits
