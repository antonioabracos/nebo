; MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-F04 bounded offline package graph ledger.
bits 64
default rel
%define NEBO_PACKAGES_IMPLEMENTATION 1
%include "compiler/packages/packages.inc"

section .text
global nebo_packages_init
global nebo_packages_validate
global nebo_packages_reserve

nebo_packages_init:
    test rdi,rdi
    jz .argument
    test rdi,7
    jnz .argument
    mov rax,NEBO_PACKAGES_MAGIC
    mov [rdi+NEBO_PACKAGES_LEDGER_MAGIC],rax
    mov qword [rdi+NEBO_PACKAGES_LEDGER_VERSION],NEBO_PACKAGES_VERSION
    mov qword [rdi+NEBO_PACKAGES_LEDGER_MAX_NODES],NEBO_PACKAGES_MAX_NODES
    mov qword [rdi+NEBO_PACKAGES_LEDGER_MAX_EDGES],NEBO_PACKAGES_MAX_EDGES
    mov qword [rdi+NEBO_PACKAGES_LEDGER_MAX_PATH],NEBO_PACKAGES_MAX_PATH_BYTES
    mov qword [rdi+NEBO_PACKAGES_LEDGER_MAX_BYTES],NEBO_PACKAGES_MAX_PACKAGE_BYTES
    mov qword [rdi+NEBO_PACKAGES_LEDGER_FLAGS],NEBO_PACKAGES_REQUIRED_FLAGS
    mov qword [rdi+NEBO_PACKAGES_LEDGER_NODES],0
    mov qword [rdi+NEBO_PACKAGES_LEDGER_EDGES],0
    mov qword [rdi+NEBO_PACKAGES_LEDGER_DIGEST],0
    xor eax,eax
    ret
.argument:
    mov eax,NEBO_PACKAGES_ERROR_ARGUMENT
    ret

nebo_packages_validate:
    test rdi,rdi
    jz .argument
    test rdi,7
    jnz .argument
    mov rax,NEBO_PACKAGES_MAGIC
    cmp [rdi+NEBO_PACKAGES_LEDGER_MAGIC],rax
    jne .contract
    cmp qword [rdi+NEBO_PACKAGES_LEDGER_VERSION],NEBO_PACKAGES_VERSION
    jne .contract
    cmp qword [rdi+NEBO_PACKAGES_LEDGER_MAX_NODES],NEBO_PACKAGES_MAX_NODES
    jne .contract
    cmp qword [rdi+NEBO_PACKAGES_LEDGER_MAX_EDGES],NEBO_PACKAGES_MAX_EDGES
    jne .contract
    cmp qword [rdi+NEBO_PACKAGES_LEDGER_MAX_PATH],NEBO_PACKAGES_MAX_PATH_BYTES
    jne .contract
    cmp qword [rdi+NEBO_PACKAGES_LEDGER_MAX_BYTES],NEBO_PACKAGES_MAX_PACKAGE_BYTES
    jne .contract
    cmp qword [rdi+NEBO_PACKAGES_LEDGER_FLAGS],NEBO_PACKAGES_REQUIRED_FLAGS
    jne .contract
    cmp qword [rdi+NEBO_PACKAGES_LEDGER_NODES],NEBO_PACKAGES_MAX_NODES
    ja .contract
    cmp qword [rdi+NEBO_PACKAGES_LEDGER_EDGES],NEBO_PACKAGES_MAX_EDGES
    ja .contract
    xor eax,eax
    ret
.argument:
    mov eax,NEBO_PACKAGES_ERROR_ARGUMENT
    ret
.contract:
    mov eax,NEBO_PACKAGES_ERROR_CONTRACT
    ret

; rdi=ledger, rsi=additional nodes, rdx=additional edges, rcx=graph digest.
nebo_packages_reserve:
    push r12
    push r13
    push r14
    mov r12,rsi
    mov r13,rdx
    mov r14,rcx
    call nebo_packages_validate
    test eax,eax
    jnz .done
    test r12,r12
    jz .graph
    test r14,r14
    jz .graph
    mov rax,[rdi+NEBO_PACKAGES_LEDGER_NODES]
    add rax,r12
    jc .limit
    cmp rax,NEBO_PACKAGES_MAX_NODES
    ja .limit
    mov r8,[rdi+NEBO_PACKAGES_LEDGER_EDGES]
    add r8,r13
    jc .limit
    cmp r8,NEBO_PACKAGES_MAX_EDGES
    ja .limit
    mov [rdi+NEBO_PACKAGES_LEDGER_NODES],rax
    mov [rdi+NEBO_PACKAGES_LEDGER_EDGES],r8
    mov [rdi+NEBO_PACKAGES_LEDGER_DIGEST],r14
    xor eax,eax
    jmp .done
.limit:
    mov eax,NEBO_PACKAGES_ERROR_LIMIT
    jmp .done
.graph:
    mov eax,NEBO_PACKAGES_ERROR_GRAPH
.done:
    pop r14
    pop r13
    pop r12
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
