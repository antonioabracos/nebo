bits 64
default rel
%include "compiler/lsp/lsp.inc"

section .bss
align 16
state resb NEBO_LSP_STATE_SIZE

section .text
global _start
_start:
    lea rdi,[state]
    call nebo_lsp_init
    test eax,eax
    jnz .fail1
    lea rdi,[state]
    call nebo_lsp_validate
    test eax,eax
    jnz .fail2
    cmp qword [state+NEBO_LSP_STATE_MAX_DOCUMENTS],64
    jne .fail3
    cmp qword [state+NEBO_LSP_STATE_MAX_BYTES],1048576
    jne .fail4
    lea rdi,[state]
    mov esi,128
    mov edx,1
    mov ecx,NEBO_LSP_DOCUMENT_OPEN
    call nebo_lsp_document_apply
    test eax,eax
    jnz .fail5
    cmp qword [state+NEBO_LSP_STATE_DOCUMENTS],1
    jne .fail6
    cmp qword [state+NEBO_LSP_STATE_DOCUMENT_VERSION],1
    jne .fail7
    lea rdi,[state]
    mov esi,256
    mov edx,2
    mov ecx,NEBO_LSP_DOCUMENT_CHANGE
    call nebo_lsp_document_apply
    test eax,eax
    jnz .fail8
    cmp qword [state+NEBO_LSP_STATE_BYTES],256
    jne .fail9
    lea rdi,[state]
    mov esi,1
    mov edx,2
    mov ecx,NEBO_LSP_DOCUMENT_CHANGE
    call nebo_lsp_document_apply
    cmp eax,NEBO_LSP_ERROR_STALE
    jne .fail10
    cmp qword [state+NEBO_LSP_STATE_BYTES],256
    jne .fail10
    lea rdi,[state]
    mov esi,1048577
    mov edx,3
    mov ecx,NEBO_LSP_DOCUMENT_CHANGE
    call nebo_lsp_document_apply
    cmp eax,NEBO_LSP_ERROR_LIMIT
    jne .fail11
    lea rdi,[state]
    mov esi,77
    call nebo_lsp_request_begin
    test eax,eax
    jnz .fail12
    cmp qword [state+NEBO_LSP_STATE_PENDING_ID],77
    jne .fail13
    lea rdi,[state]
    mov esi,77
    call nebo_lsp_request_cancel
    test eax,eax
    jnz .fail14
    cmp qword [state+NEBO_LSP_STATE_CANCELED_ID],77
    jne .fail14
    lea rdi,[state]
    mov esi,78
    call nebo_lsp_request_cancel
    cmp eax,NEBO_LSP_ERROR_STALE
    jne .fail15
    xor edi,edi
    jmp .exit
%assign i 1
%rep 15
.fail%+i:
    mov edi,i
    jmp .exit
%assign i i+1
%endrep
.exit:
    mov eax,60
    syscall
