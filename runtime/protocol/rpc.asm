; AST-HIR-LIR-PLANNER-E-OTIMIZACAO-F03: bounded local unary RPC with explicit effects and deadlines.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/protocol/rpc.inc"
section .text

; rdi=service, rsi=version, rdx=methods, rcx=count
NEBOC_ABI_FUNCTION nebo_service_define
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp rcx,NEBO_RPC_MAX_METHODS
    ja .limit
    test rcx,rcx
    jz .invalid
    test rdx,rdx
    jz .invalid
    xor r8d,r8d
.method_loop:
    cmp r8,rcx
    jae .commit
    mov r9,r8
    imul r9,NEBO_METHOD_SIZE
    mov rax,[rdx+r9+NEBO_METHOD_ID]
    test rax,rax
    jz .invalid
    test qword [rdx+r9+NEBO_METHOD_FLAGS],NEBO_RPC_METHOD_UNARY
    jz .invalid
    mov r10,r8
    inc r10
.duplicate_loop:
    cmp r10,rcx
    jae .next
    mov r11,r10
    imul r11,NEBO_METHOD_SIZE
    cmp rax,[rdx+r11+NEBO_METHOD_ID]
    je .duplicate
    inc r10
    jmp .duplicate_loop
.next:
    inc r8
    jmp .method_loop
.commit:
    mov [rdi+NEBO_SERVICE_VERSION],rsi
    mov [rdi+NEBO_SERVICE_METHOD_COUNT],rcx
    mov [rdi+NEBO_SERVICE_METHODS],rdx
    mov qword [rdi+NEBO_SERVICE_IMPLEMENTATION],0
    mov qword [rdi+NEBO_SERVICE_ALLOWED_EFFECTS],0
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.limit:
    mov eax,NEBO_LIMIT
    ret
.duplicate:
    mov eax,NEBO_DUPLICATE_ID
    ret

; rdi=method, rsi=id, rdx=request type, rcx=response type, r8=flags
NEBOC_ABI_FUNCTION nebo_rpc_method_unary
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    test rdx,rdx
    jz .invalid
    test rcx,rcx
    jz .invalid
    test r8,~NEBO_RPC_METHOD_IDEMPOTENT
    jnz .invalid
    mov [rdi+NEBO_METHOD_ID],rsi
    mov [rdi+NEBO_METHOD_REQUEST_TYPE],rdx
    mov [rdi+NEBO_METHOD_RESPONSE_TYPE],rcx
    mov qword [rdi+NEBO_METHOD_EFFECTS],0
    or r8,NEBO_RPC_METHOD_UNARY
    mov [rdi+NEBO_METHOD_FLAGS],r8
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret

; rdi=method, rsi=required effects, rdx=declaration capability mask
NEBOC_ABI_FUNCTION nebo_method_effects
    test rdi,rdi
    jz .invalid
    mov rax,rsi
    not rdx
    and rax,rdx
    jnz .denied
    mov [rdi+NEBO_METHOD_EFFECTS],rsi
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.denied:
    mov eax,NEBO_EFFECT_DENIED
    ret

; rdi=service, rsi=implementation function, rdx=allowed effects
NEBOC_ABI_FUNCTION nebo_service_expose
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    mov rcx,[rdi+NEBO_SERVICE_METHOD_COUNT]
    test rcx,rcx
    jz .invalid
    mov r8,[rdi+NEBO_SERVICE_METHODS]
    xor r9d,r9d
.effect_loop:
    cmp r9,rcx
    jae .commit
    mov r10,r9
    imul r10,NEBO_METHOD_SIZE
    mov rax,[r8+r10+NEBO_METHOD_EFFECTS]
    mov r11,rdx
    not r11
    and rax,r11
    jnz .denied
    inc r9
    jmp .effect_loop
.commit:
    mov [rdi+NEBO_SERVICE_IMPLEMENTATION],rsi
    mov [rdi+NEBO_SERVICE_ALLOWED_EFFECTS],rdx
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.denied:
    mov eax,NEBO_EFFECT_DENIED
    ret

; rdi=client, rsi=service, rdx=endpoint kind, rcx=capability, r8=logical now
NEBOC_ABI_FUNCTION nebo_rpc_client_connect
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp rdx,NEBO_RPC_ENDPOINT_MEMORY
    jne .unavailable
    test rcx,rcx
    jz .denied
    cmp qword [rsi+NEBO_SERVICE_IMPLEMENTATION],0
    je .unavailable
    mov [rdi+NEBO_CLIENT_SERVICE],rsi
    mov [rdi+NEBO_CLIENT_ENDPOINT],rdx
    mov [rdi+NEBO_CLIENT_CAPABILITY],rcx
    mov qword [rdi+NEBO_CLIENT_STATE],NEBO_RPC_CLIENT_READY
    mov qword [rdi+NEBO_CLIENT_NEXT_ID],1
    mov [rdi+NEBO_CLIENT_NOW],r8
    mov qword [rdi+NEBO_CLIENT_META+NEBO_META_STATUS],NEBO_OK
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
.unavailable:
    mov eax,NEBO_UNAVAILABLE
    ret
.denied:
    mov eax,NEBO_EFFECT_DENIED
    ret

; rdi=client, rsi=method id, rdx=request, rcx=options, r8=response
NEBOC_ABI_FUNCTION nebo_client_call
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rdx
    mov r14,rcx
    mov r15,r8
    test r12,r12
    jz .invalid
    test r13,r13
    jz .invalid
    test r14,r14
    jz .invalid
    test r15,r15
    jz .invalid
    cmp qword [r12+NEBO_CLIENT_STATE],NEBO_RPC_CLIENT_READY
    jne .cancelled
    mov rax,[r14+NEBO_CALL_DEADLINE]
    cmp rax,[r12+NEBO_CLIENT_NOW]
    jb .deadline
    mov rax,[r14+NEBO_CALL_CANCEL_FLAG]
    test rax,rax
    jz .find
    cmp qword [rax],0
    jne .cancelled
.find:
    mov r10,[r12+NEBO_CLIENT_SERVICE]
    mov rcx,[r10+NEBO_SERVICE_METHOD_COUNT]
    mov r8,[r10+NEBO_SERVICE_METHODS]
    xor edx,edx
.find_loop:
    cmp rdx,rcx
    jae .not_found
    mov r9,rdx
    imul r9,NEBO_METHOD_SIZE
    cmp rsi,[r8+r9+NEBO_METHOD_ID]
    je .invoke
    inc rdx
    jmp .find_loop
.invoke:
    mov rax,[r8+r9+NEBO_METHOD_EFFECTS]
    mov rdx,[r10+NEBO_SERVICE_ALLOWED_EFFECTS]
    not rdx
    and rax,rdx
    jnz .denied
    mov rax,[r12+NEBO_CLIENT_NEXT_ID]
    mov [r12+NEBO_CLIENT_META+NEBO_META_REQUEST_ID],rax
    inc rax
    mov [r12+NEBO_CLIENT_NEXT_ID],rax
    mov qword [r12+NEBO_CLIENT_META+NEBO_META_ATTEMPTS],1
    mov rax,[r12+NEBO_CLIENT_NOW]
    mov [r12+NEBO_CLIENT_META+NEBO_META_START],rax
    mov [r12+NEBO_CLIENT_META+NEBO_META_END],rax
    mov rax,[r12+NEBO_CLIENT_ENDPOINT]
    mov [r12+NEBO_CLIENT_META+NEBO_META_PROVENANCE],rax
    mov rax,[r10+NEBO_SERVICE_IMPLEMENTATION]
    mov rdi,rsi
    mov rsi,r13
    mov rdx,r15
    call rax
    mov [r12+NEBO_CLIENT_META+NEBO_META_STATUS],rax
    jmp .done
.invalid:
    mov eax,NEBO_INVALID
    jmp .record_failure
.deadline:
    mov eax,NEBO_DEADLINE
    jmp .record_failure
.cancelled:
    mov eax,NEBO_CANCELLED
    jmp .record_failure
.not_found:
    mov eax,NEBO_NOT_FOUND
    jmp .record_failure
.denied:
    mov eax,NEBO_EFFECT_DENIED
.record_failure:
    test r12,r12
    jz .done
    mov [r12+NEBO_CLIENT_META+NEBO_META_STATUS],rax
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

; rdi=client, rsi=48-byte output
NEBOC_ABI_FUNCTION nebo_call_metadata
    test rdi,rdi
    jz .invalid
    test rsi,rsi
    jz .invalid
    lea rax,[rdi+NEBO_CLIENT_META]
    mov rdi,rsi
    mov rsi,rax
    mov ecx,NEBO_META_SIZE/8
    rep movsq
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret

; rdi=client
NEBOC_ABI_FUNCTION nebo_call_cancel
    test rdi,rdi
    jz .invalid
    mov qword [rdi+NEBO_CLIENT_STATE],NEBO_RPC_CLIENT_CANCELLED
    mov qword [rdi+NEBO_CLIENT_META+NEBO_META_STATUS],NEBO_CANCELLED
    xor eax,eax
    ret
.invalid:
    mov eax,NEBO_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
