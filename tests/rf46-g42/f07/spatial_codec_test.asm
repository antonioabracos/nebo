; CLI-NEBOC-BUILD-REPL-E-FERRAMENTAS-F07 positive, negative, max-bound and failure-atomic tests.
bits 64
default rel
%include "runtime/spatial/spatial_codec.inc"
extern nebo_spatial_codec_evaluate
section .data
records dq 28,56,84,112
invalid_record dq 1110593
section .bss
report resb NEBO_SPATIAL_CODEC_REPORT_SIZE
max_records resq NEBO_SPATIAL_CODEC_MAX_RECORDS
section .text
global _start
_start:
    lea rdi,[records]
    mov esi,4
    lea rdx,[report]
    call nebo_spatial_codec_evaluate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_SPATIAL_CODEC_REPORT_COUNT],4
    jne fail
    cmp qword [report+NEBO_SPATIAL_CODEC_REPORT_SUM],280
    jne fail
    mov rax,0xca4ffeda31289212
    cmp [report+NEBO_SPATIAL_CODEC_REPORT_HASH],rax
    jne fail
    cmp qword [report+NEBO_SPATIAL_CODEC_REPORT_MIN],28
    jne fail
    cmp qword [report+NEBO_SPATIAL_CODEC_REPORT_MAX],112
    jne fail
    mov rax,0x1122334455667788
    mov [report],rax
    lea rdi,[invalid_record]
    mov esi,1
    lea rdx,[report]
    call nebo_spatial_codec_evaluate
    cmp eax,NEBO_SPATIAL_CODEC_STATUS_INVALID
    jne fail
    mov rax,0x1122334455667788
    cmp [report],rax
    jne fail
    xor edi,edi
    mov esi,1
    lea rdx,[report]
    call nebo_spatial_codec_evaluate
    cmp eax,NEBO_SPATIAL_CODEC_STATUS_INVALID
    jne fail
    lea rdi,[records]
    xor esi,esi
    lea rdx,[report]
    call nebo_spatial_codec_evaluate
    cmp eax,NEBO_SPATIAL_CODEC_STATUS_INVALID
    jne fail
    lea rdi,[records]
    mov esi,NEBO_SPATIAL_CODEC_MAX_RECORDS+1
    lea rdx,[report]
    call nebo_spatial_codec_evaluate
    cmp eax,NEBO_SPATIAL_CODEC_STATUS_LIMIT
    jne fail
    lea rdi,[max_records]
    mov esi,NEBO_SPATIAL_CODEC_MAX_RECORDS
    lea rdx,[report]
    call nebo_spatial_codec_evaluate
    test eax,eax
    jnz fail
    xor edi,edi
    jmp exit
fail:
    mov edi,1
exit:
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
