; MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-F03 bounded persistent local REPL session ledger.
bits 64
default rel
%define NEBO_REPL_IMPLEMENTATION 1
%include "compiler/repl/repl.inc"

section .text
global nebo_repl_session_init
global nebo_repl_session_validate
global nebo_repl_session_record
global nebo_repl_session_reset

nebo_repl_session_init:
    test rdi,rdi
    jz .argument
    test rdi,7
    jnz .argument
    mov rax,NEBO_REPL_MAGIC
    mov [rdi+NEBO_REPL_SESSION_MAGIC],rax
    mov qword [rdi+NEBO_REPL_SESSION_VERSION],NEBO_REPL_VERSION
    mov qword [rdi+NEBO_REPL_SESSION_STATE],NEBO_REPL_STATE_ACTIVE
    mov qword [rdi+NEBO_REPL_SESSION_GENERATION],1
    mov qword [rdi+NEBO_REPL_SESSION_DECLARATIONS],0
    mov qword [rdi+NEBO_REPL_SESSION_SOURCE_BYTES],0
    mov qword [rdi+NEBO_REPL_SESSION_HISTORY],0
    mov qword [rdi+NEBO_REPL_SESSION_LOADS],0
    mov rax,NEBO_REPL_FNV1A64_OFFSET
    mov [rdi+NEBO_REPL_SESSION_DIGEST],rax
    mov qword [rdi+NEBO_REPL_SESSION_FLAGS],NEBO_REPL_REQUIRED_FLAGS
    xor eax,eax
    ret
.argument:
    mov eax,NEBO_REPL_ERROR_ARGUMENT
    ret

nebo_repl_session_validate:
    test rdi,rdi
    jz .argument
    test rdi,7
    jnz .argument
    mov rax,NEBO_REPL_MAGIC
    cmp [rdi+NEBO_REPL_SESSION_MAGIC],rax
    jne .contract
    cmp qword [rdi+NEBO_REPL_SESSION_VERSION],NEBO_REPL_VERSION
    jne .contract
    cmp qword [rdi+NEBO_REPL_SESSION_STATE],NEBO_REPL_STATE_ACTIVE
    jne .state
    cmp qword [rdi+NEBO_REPL_SESSION_GENERATION],0
    je .contract
    cmp qword [rdi+NEBO_REPL_SESSION_DECLARATIONS],NEBO_REPL_MAX_DECLARATIONS
    ja .contract
    cmp qword [rdi+NEBO_REPL_SESSION_SOURCE_BYTES],NEBO_REPL_MAX_SOURCE_BYTES
    ja .contract
    cmp qword [rdi+NEBO_REPL_SESSION_HISTORY],NEBO_REPL_MAX_HISTORY
    ja .contract
    cmp qword [rdi+NEBO_REPL_SESSION_LOADS],NEBO_REPL_MAX_LOADS
    ja .contract
    cmp qword [rdi+NEBO_REPL_SESSION_FLAGS],NEBO_REPL_REQUIRED_FLAGS
    jne .contract
    xor eax,eax
    ret
.argument:
    mov eax,NEBO_REPL_ERROR_ARGUMENT
    ret
.contract:
    mov eax,NEBO_REPL_ERROR_CONTRACT
    ret
.state:
    mov eax,NEBO_REPL_ERROR_STATE
    ret

; rdi=session, rsi=accepted source, rdx=bytes, rcx=record kind,
; r8=expected generation.  All limits are checked before ledger mutation.
nebo_repl_session_record:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15,rcx
    mov rbx,r8
    call nebo_repl_session_validate
    test eax,eax
    jnz .done
    test r13,r13
    jz .argument
    test r14,r14
    jz .argument
    cmp r14,NEBO_REPL_MAX_SOURCE_BYTES
    ja .limit
    cmp rbx,[r12+NEBO_REPL_SESSION_GENERATION]
    jne .stale
    cmp r15,NEBO_REPL_RECORD_EVALUATE
    je .kind_ok
    cmp r15,NEBO_REPL_RECORD_LOAD
    jne .kind
    cmp qword [r12+NEBO_REPL_SESSION_LOADS],NEBO_REPL_MAX_LOADS
    jae .limit
.kind_ok:
    cmp qword [r12+NEBO_REPL_SESSION_DECLARATIONS],NEBO_REPL_MAX_DECLARATIONS
    jae .limit
    cmp qword [r12+NEBO_REPL_SESSION_HISTORY],NEBO_REPL_MAX_HISTORY
    jae .limit
    mov rax,[r12+NEBO_REPL_SESSION_SOURCE_BYTES]
    add rax,r14
    jc .limit
    cmp rax,NEBO_REPL_MAX_SOURCE_BYTES
    ja .limit

    mov rdx,[r12+NEBO_REPL_SESSION_DIGEST]
    mov r8,NEBO_REPL_FNV1A64_PRIME
    xor ecx,ecx
.hash:
    cmp rcx,r14
    jae .publish
    movzx eax,byte [r13+rcx]
    xor rdx,rax
    imul rdx,r8
    inc rcx
    jmp .hash
.publish:
    mov [r12+NEBO_REPL_SESSION_DIGEST],rdx
    add [r12+NEBO_REPL_SESSION_SOURCE_BYTES],r14
    inc qword [r12+NEBO_REPL_SESSION_DECLARATIONS]
    inc qword [r12+NEBO_REPL_SESSION_HISTORY]
    cmp r15,NEBO_REPL_RECORD_LOAD
    jne .success
    inc qword [r12+NEBO_REPL_SESSION_LOADS]
.success:
    xor eax,eax
    jmp .done
.argument:
    mov eax,NEBO_REPL_ERROR_ARGUMENT
    jmp .done
.limit:
    mov eax,NEBO_REPL_ERROR_LIMIT
    jmp .done
.stale:
    mov eax,NEBO_REPL_ERROR_STALE
    jmp .done
.kind:
    mov eax,NEBO_REPL_ERROR_KIND
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_repl_session_reset:
    push rdi
    call nebo_repl_session_validate
    pop rdi
    test eax,eax
    jnz .done
    mov rax,[rdi+NEBO_REPL_SESSION_GENERATION]
    inc rax
    jz .state
    mov [rdi+NEBO_REPL_SESSION_GENERATION],rax
    mov qword [rdi+NEBO_REPL_SESSION_DECLARATIONS],0
    mov qword [rdi+NEBO_REPL_SESSION_SOURCE_BYTES],0
    mov qword [rdi+NEBO_REPL_SESSION_HISTORY],0
    mov qword [rdi+NEBO_REPL_SESSION_LOADS],0
    mov rax,NEBO_REPL_FNV1A64_OFFSET
    mov [rdi+NEBO_REPL_SESSION_DIGEST],rax
    xor eax,eax
.done:
    ret
.state:
    mov eax,NEBO_REPL_ERROR_STATE
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
