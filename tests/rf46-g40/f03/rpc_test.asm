bits 64
default rel
%include "runtime/protocol/rpc.inc"
extern nebo_service_define
extern nebo_rpc_method_unary
extern nebo_method_effects
extern nebo_service_expose
extern nebo_rpc_client_connect
extern nebo_client_call
extern nebo_call_metadata
extern nebo_call_cancel
section .bss
service resb NEBO_SERVICE_SIZE
method resb NEBO_METHOD_SIZE
client resb NEBO_CLIENT_SIZE
options resb NEBO_CALL_OPTIONS_SIZE
metadata resb NEBO_META_SIZE
request resq 1
response resq 1
cancel_flag resq 1
section .text
handler:
    cmp rdi,7
    jne .bad
    mov rax,[rsi]
    inc rax
    mov [rdx],rax
    xor eax,eax
    ret
.bad:
    mov eax,NEBO_NOT_FOUND
    ret
global _start
_start:
    lea rdi,[method]
    mov esi,7
    mov edx,1
    mov ecx,2
    mov r8d,NEBO_RPC_METHOD_IDEMPOTENT
    call nebo_rpc_method_unary
    test eax,eax
    jnz fail
    lea rdi,[method]
    mov esi,4
    mov edx,4
    call nebo_method_effects
    test eax,eax
    jnz fail
    lea rdi,[service]
    mov esi,1
    lea rdx,[method]
    mov ecx,1
    call nebo_service_define
    test eax,eax
    jnz fail
    lea rdi,[service]
    lea rsi,[handler]
    mov edx,4
    call nebo_service_expose
    test eax,eax
    jnz fail
    lea rdi,[client]
    lea rsi,[service]
    mov edx,NEBO_RPC_ENDPOINT_MEMORY
    mov ecx,0x55
    mov r8d,100
    call nebo_rpc_client_connect
    test eax,eax
    jnz fail
    mov qword [request],41
    mov qword [options+NEBO_CALL_DEADLINE],101
    lea rax,[cancel_flag]
    mov [options+NEBO_CALL_CANCEL_FLAG],rax
    lea rdi,[client]
    mov esi,7
    lea rdx,[request]
    lea rcx,[options]
    lea r8,[response]
    call nebo_client_call
    test eax,eax
    jnz fail
    cmp qword [response],42
    jne fail
    lea rdi,[client]
    lea rsi,[metadata]
    call nebo_call_metadata
    test eax,eax
    jnz fail
    cmp qword [metadata+NEBO_META_REQUEST_ID],1
    jne fail
    cmp qword [metadata+NEBO_META_ATTEMPTS],1
    jne fail
    ; Deadline and cancellation are distinguishable and failure-atomic.
    mov qword [response],0x7777
    mov qword [options+NEBO_CALL_DEADLINE],99
    lea rdi,[client]
    mov esi,7
    lea rdx,[request]
    lea rcx,[options]
    lea r8,[response]
    call nebo_client_call
    cmp eax,NEBO_DEADLINE
    jne fail
    cmp qword [response],0x7777
    jne fail
    mov qword [options+NEBO_CALL_DEADLINE],101
    mov qword [cancel_flag],1
    lea rdi,[client]
    mov esi,7
    lea rdx,[request]
    lea rcx,[options]
    lea r8,[response]
    call nebo_client_call
    cmp eax,NEBO_CANCELLED
    jne fail
    mov qword [cancel_flag],0
    lea rdi,[client]
    call nebo_call_cancel
    test eax,eax
    jnz fail
    lea rdi,[client]
    mov esi,7
    lea rdx,[request]
    lea rcx,[options]
    lea r8,[response]
    call nebo_client_call
    cmp eax,NEBO_CANCELLED
    jne fail
    ; Unavailable endpoint is factual.
    lea rdi,[client]
    lea rsi,[service]
    mov edx,2
    mov ecx,1
    xor r8d,r8d
    call nebo_rpc_client_connect
    cmp eax,NEBO_UNAVAILABLE
    jne fail
    xor edi,edi
    jmp exit
fail:
    mov edi,1
exit:
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
