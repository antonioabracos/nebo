bits 64
default rel
%include "runtime/protocol/codegen.inc"
extern nebo_api_generate_client
section .bss
api resb NEBO_API_SIZE
report resb NEBO_ARTIFACT_SIZE
section .text
global _start
_start:
    mov qword [api+NEBO_API_PROTOCOL],1
    mov qword [api+NEBO_API_SCHEMA_HASH],0x40
    lea rdi,[api]
    mov esi,NEBO_GENERATED_TARGET_X86_64
    lea rdx,[report]
    call nebo_api_generate_client
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
