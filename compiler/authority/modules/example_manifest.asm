; G149 immutable public-example identity manifest.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/authority/modules/foundation.inc"

section .text

; examples_freeze(hashes*, count, report).  Every hash is nonzero and unique.
NEBOC_ABI_FUNCTION neboc_rf166_example_manifest_freeze
    test rdi,rdi
    jz .argument
    test rdx,rdx
    jz .argument
    test rdi,7
    jnz .argument
    test rdx,7
    jnz .argument
    cmp rdi,rdx
    je .argument
    cmp rsi,NEBOC_RF166_EXAMPLE_COUNT
    jne .source
    NEBOC_RF166_REJECT_OVERLAP rdi,(NEBOC_RF166_EXAMPLE_COUNT*8),rdx,NEBOC_RF166_EXAMPLE_SIZE,.argument,rax
    xor ecx,ecx
    xor r8d,r8d
.outer:
    cmp rcx,rsi
    jae .publish
    mov rax,[rdi+rcx*8]
    test rax,rax
    jz .source
    lea r9,[rcx+1]
.inner:
    cmp r9,rsi
    jae .reduce
    cmp rax,[rdi+r9*8]
    je .source
    inc r9
    jmp .inner
.reduce:
    rol r8,9
    xor r8,rax
    lea rax,[rcx+1]
    xor r8,rax
    inc ecx
    jmp .outer
.publish:
    mov qword [rdx+NEBOC_RF166_EXAMPLE_SCHEMA_OFFSET],NEBOC_RF166_FOUNDATION_SCHEMA
    mov qword [rdx+NEBOC_RF166_EXAMPLE_COUNT_OFFSET],NEBOC_RF166_EXAMPLE_COUNT
    mov qword [rdx+NEBOC_RF166_EXAMPLE_UNIQUE_OFFSET],NEBOC_RF166_EXAMPLE_COUNT
    mov [rdx+NEBOC_RF166_EXAMPLE_DIGEST_OFFSET],r8
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.source:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.argument:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
