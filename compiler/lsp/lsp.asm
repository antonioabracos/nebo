; MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-F05 bounded stdio LSP state ledger.
bits 64
default rel
%define NEBO_LSP_IMPLEMENTATION 1
%include "compiler/lsp/lsp.inc"

section .text
global nebo_lsp_init
global nebo_lsp_validate
global nebo_lsp_document_apply
global nebo_lsp_request_begin
global nebo_lsp_request_cancel

nebo_lsp_init:
    test rdi,rdi
    jz .argument
    test rdi,7
    jnz .argument
    mov rax,NEBO_LSP_MAGIC
    mov [rdi+NEBO_LSP_STATE_MAGIC],rax
    mov qword [rdi+NEBO_LSP_STATE_VERSION],NEBO_LSP_VERSION
    mov qword [rdi+NEBO_LSP_STATE_DOCUMENTS],0
    mov qword [rdi+NEBO_LSP_STATE_BYTES],0
    mov qword [rdi+NEBO_LSP_STATE_DOCUMENT_VERSION],0
    mov qword [rdi+NEBO_LSP_STATE_PENDING_ID],0
    mov qword [rdi+NEBO_LSP_STATE_CANCELED_ID],0
    mov qword [rdi+NEBO_LSP_STATE_MAX_DOCUMENTS],NEBO_LSP_MAX_DOCUMENTS
    mov qword [rdi+NEBO_LSP_STATE_MAX_BYTES],NEBO_LSP_MAX_DOCUMENT_BYTES
    mov qword [rdi+NEBO_LSP_STATE_FLAGS],NEBO_LSP_REQUIRED_FLAGS
    xor eax,eax
    ret
.argument:
    mov eax,NEBO_LSP_ERROR_ARGUMENT
    ret

nebo_lsp_validate:
    test rdi,rdi
    jz .argument
    test rdi,7
    jnz .argument
    mov rax,NEBO_LSP_MAGIC
    cmp [rdi+NEBO_LSP_STATE_MAGIC],rax
    jne .contract
    cmp qword [rdi+NEBO_LSP_STATE_VERSION],NEBO_LSP_VERSION
    jne .contract
    cmp qword [rdi+NEBO_LSP_STATE_MAX_DOCUMENTS],NEBO_LSP_MAX_DOCUMENTS
    jne .contract
    cmp qword [rdi+NEBO_LSP_STATE_MAX_BYTES],NEBO_LSP_MAX_DOCUMENT_BYTES
    jne .contract
    cmp qword [rdi+NEBO_LSP_STATE_FLAGS],NEBO_LSP_REQUIRED_FLAGS
    jne .contract
    cmp qword [rdi+NEBO_LSP_STATE_DOCUMENTS],NEBO_LSP_MAX_DOCUMENTS
    ja .contract
    cmp qword [rdi+NEBO_LSP_STATE_BYTES],NEBO_LSP_MAX_DOCUMENT_BYTES
    ja .contract
    xor eax,eax
    ret
.argument:
    mov eax,NEBO_LSP_ERROR_ARGUMENT
    ret
.contract:
    mov eax,NEBO_LSP_ERROR_CONTRACT
    ret

; rdi=state, rsi=complete snapshot bytes, rdx=monotonic version, rcx=open/change.
nebo_lsp_document_apply:
    push r12
    push r13
    push r14
    mov r12,rsi
    mov r13,rdx
    mov r14,rcx
    call nebo_lsp_validate
    test eax,eax
    jnz .done
    cmp r12,NEBO_LSP_MAX_DOCUMENT_BYTES
    ja .limit
    cmp r13,[rdi+NEBO_LSP_STATE_DOCUMENT_VERSION]
    jbe .stale
    cmp r14,NEBO_LSP_DOCUMENT_OPEN
    je .open
    cmp r14,NEBO_LSP_DOCUMENT_CHANGE
    jne .argument
    cmp qword [rdi+NEBO_LSP_STATE_DOCUMENTS],0
    je .state
    mov [rdi+NEBO_LSP_STATE_BYTES],r12
    mov [rdi+NEBO_LSP_STATE_DOCUMENT_VERSION],r13
    xor eax,eax
    jmp .done
.open:
    cmp qword [rdi+NEBO_LSP_STATE_DOCUMENTS],NEBO_LSP_MAX_DOCUMENTS
    jae .limit
    inc qword [rdi+NEBO_LSP_STATE_DOCUMENTS]
    mov [rdi+NEBO_LSP_STATE_BYTES],r12
    mov [rdi+NEBO_LSP_STATE_DOCUMENT_VERSION],r13
    xor eax,eax
    jmp .done
.argument:
    mov eax,NEBO_LSP_ERROR_ARGUMENT
    jmp .done
.limit:
    mov eax,NEBO_LSP_ERROR_LIMIT
    jmp .done
.stale:
    mov eax,NEBO_LSP_ERROR_STALE
    jmp .done
.state:
    mov eax,NEBO_LSP_ERROR_STATE
.done:
    pop r14
    pop r13
    pop r12
    ret

nebo_lsp_request_begin:
    push rsi
    call nebo_lsp_validate
    pop rsi
    test eax,eax
    jnz .done
    test rsi,rsi
    jz .argument
    mov [rdi+NEBO_LSP_STATE_PENDING_ID],rsi
    mov qword [rdi+NEBO_LSP_STATE_CANCELED_ID],0
    xor eax,eax
.done:
    ret
.argument:
    mov eax,NEBO_LSP_ERROR_ARGUMENT
    ret

nebo_lsp_request_cancel:
    push rsi
    call nebo_lsp_validate
    pop rsi
    test eax,eax
    jnz .done
    test rsi,rsi
    jz .argument
    cmp rsi,[rdi+NEBO_LSP_STATE_PENDING_ID]
    jne .stale
    mov [rdi+NEBO_LSP_STATE_CANCELED_ID],rsi
    mov qword [rdi+NEBO_LSP_STATE_PENDING_ID],0
    xor eax,eax
.done:
    ret
.argument:
    mov eax,NEBO_LSP_ERROR_ARGUMENT
    ret
.stale:
    mov eax,NEBO_LSP_ERROR_STALE
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
