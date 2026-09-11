; G164 fixed native comment-trivia probe. Reads at most 1 MiB from stdin and
; writes the canonical binary projection; errors are a 24-byte fixed record.
bits 64
default rel
%include "compiler/parser/block_comment.inc"
global _start
extern neboc_comment_scan

%define RESULT_CAPACITY (NEBOC_COMMENT_SCAN_HEADER_SIZE + NEBOC_COMMENT_MAX_RECORDS * NEBOC_COMMENT_RECORD_SIZE)

section .text
_start:
    xor r12d,r12d
.read:
    xor eax,eax
    xor edi,edi
    lea rsi,[rel source]
    add rsi,r12
    mov edx,NEBOC_COMMENT_MAX_SOURCE_BYTES+1
    sub rdx,r12
    syscall
    test rax,rax
    js .io_error
    jz .scan
    add r12,rax
    cmp r12,NEBOC_COMMENT_MAX_SOURCE_BYTES
    jbe .read
    mov eax,NEBOC_COMMENT_STATUS_LENGTH
    mov edx,NEBOC_COMMENT_MAX_SOURCE_BYTES
    jmp .error
.scan:
    lea rdi,[rel source]
    mov rsi,r12
    lea rdx,[rel result]
    mov ecx,RESULT_CAPACITY
    call neboc_comment_scan
    test eax,eax
    jnz .error
    mov r12,[rel result+NEBOC_COMMENT_SCAN_OUTPUT_BYTES_OFFSET]
    lea r13,[rel result]
.write:
    test r12,r12
    jz .ok
    mov eax,1
    mov edi,1
    mov rsi,r13
    mov rdx,r12
    syscall
    test rax,rax
    jle .io_error
    add r13,rax
    sub r12,rax
    jmp .write
.ok:
    xor edi,edi
    jmp .exit
.io_error:
    mov eax,NEBOC_COMMENT_STATUS_ARGUMENT
    xor edx,edx
.error:
    mov r8d,eax
    mov r9d,edx
    mov rax,0x2152524534363147       ; "G164ERR!"
    mov [rel error_record],rax
    mov [rel error_record+8],r8
    mov [rel error_record+16],r9
    mov eax,1
    mov edi,1
    lea rsi,[rel error_record]
    mov edx,24
    syscall
    mov edi,2
.exit:
    mov eax,60
    syscall

section .bss align=16
source: resb NEBOC_COMMENT_MAX_SOURCE_BYTES+1
resb 15
result: resb RESULT_CAPACITY
error_record: resb 24
section .note.GNU-stack noalloc noexec nowrite progbits
