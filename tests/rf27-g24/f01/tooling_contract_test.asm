bits 64
default rel
%include "compiler/tooling/tooling_contract.inc"

section .bss
align 16
contract resb NEBO_TOOLING_CONTRACT_SIZE
workspace resb 4096

section .text
global _start
_start:
    lea rdi,[contract]
    call nebo_tooling_contract_init
    test eax,eax
    jnz .fail1
    lea rdi,[contract]
    call nebo_tooling_contract_validate
    test eax,eax
    jnz .fail2
    cmp qword [contract+NEBO_TOOLING_CONTRACT_FLAGS],NEBO_TOOLING_REQUIRED_FLAGS
    jne .fail3
    cmp qword [contract+NEBO_TOOLING_CONTRACT_MAX_SOURCE],NEBO_TOOLING_MAX_SOURCE_BYTES
    jne .fail4
    cmp qword [contract+NEBO_TOOLING_CONTRACT_MAX_DOCUMENTS],NEBO_TOOLING_MAX_DOCUMENTS
    jne .fail5
    cmp qword [contract+NEBO_TOOLING_CONTRACT_MAX_SYMBOLS],NEBO_TOOLING_MAX_SYMBOLS
    jne .fail6
    cmp qword [contract+NEBO_TOOLING_CONTRACT_MAX_DIAGNOSTICS],NEBO_TOOLING_MAX_DIAGNOSTICS
    jne .fail7
    cmp qword [contract+NEBO_TOOLING_CONTRACT_MAX_WORKSPACE],NEBO_TOOLING_MAX_WORKSPACE_BYTES
    jne .fail8
    cmp qword [contract+NEBO_TOOLING_CONTRACT_MAX_OUTPUT],NEBO_TOOLING_MAX_OUTPUT_BYTES
    jne .fail9
    lea rdi,[contract]
    call nebo_tooling_contract_fingerprint
    cmp rax,[contract+NEBO_TOOLING_CONTRACT_CATALOG_ID]
    jne .fail10

    lea rdi,[contract]
    mov esi,100
    mov edx,10
    mov ecx,20
    call nebo_tooling_span_validate
    test eax,eax
    jnz .fail11
    lea rdi,[contract]
    mov esi,100
    mov edx,20
    mov ecx,10
    call nebo_tooling_span_validate
    cmp eax,NEBO_TOOLING_ERROR_SPAN
    jne .fail12
    lea rdi,[contract]
    mov esi,100
    mov edx,90
    mov ecx,101
    call nebo_tooling_span_validate
    cmp eax,NEBO_TOOLING_ERROR_SPAN
    jne .fail13
    lea rdi,[contract]
    mov esi,NEBO_TOOLING_MAX_SOURCE_BYTES+1
    xor edx,edx
    xor ecx,ecx
    call nebo_tooling_span_validate
    cmp eax,NEBO_TOOLING_ERROR_LIMIT
    jne .fail14

    lea rdi,[contract]
    lea rsi,[workspace]
    mov edx,4096
    call nebo_tooling_workspace_validate
    test eax,eax
    jnz .fail15
    lea rdi,[contract]
    xor esi,esi
    mov edx,4096
    call nebo_tooling_workspace_validate
    cmp eax,NEBO_TOOLING_ERROR_WORKSPACE
    jne .fail16
    lea rdi,[contract]
    lea rsi,[workspace+1]
    mov edx,4096
    call nebo_tooling_workspace_validate
    cmp eax,NEBO_TOOLING_ERROR_WORKSPACE
    jne .fail17
    lea rdi,[contract]
    lea rsi,[workspace]
    mov edx,NEBO_TOOLING_MAX_WORKSPACE_BYTES+1
    call nebo_tooling_workspace_validate
    cmp eax,NEBO_TOOLING_ERROR_LIMIT
    jne .fail18

    ; A forged parallel parser identity must not become a second source of truth.
    inc qword [contract+NEBO_TOOLING_CONTRACT_PARSER]
    lea rdi,[contract]
    call nebo_tooling_contract_validate
    cmp eax,NEBO_TOOLING_ERROR_CONTRACT
    jne .fail19
    dec qword [contract+NEBO_TOOLING_CONTRACT_PARSER]

    ; Every immutable qword, including the catalog identity, is authenticated.
    xor ebx,ebx
.mutate:
    lea r12,[contract]
    xor qword [r12+rbx*8],1
    mov rdi,r12
    call nebo_tooling_contract_validate
    cmp eax,NEBO_TOOLING_ERROR_CONTRACT
    jne .fail20
    xor qword [r12+rbx*8],1
    inc ebx
    cmp ebx,NEBO_TOOLING_CONTRACT_SIZE/8
    jb .mutate

    xor edi,edi
    jmp .exit
%assign i 1
%rep 20
.fail%+i:
    mov edi,i
    jmp .exit
%assign i i+1
%endrep
.exit:
    mov eax,60
    syscall
