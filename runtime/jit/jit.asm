; DOCUMENTACAO-SEMANTICA-INTENT-LAW-E-CONTRATOS-F04 bounded local x86_64 JIT. Raw Linux syscalls, never RWX.
bits 64
default rel

%define JIT_ADDR 0
%define JIT_BYTES 8
%define JIT_CAPABILITY 16
%define JIT_STATE 24
%define JIT_MAX_FUNCTIONS 32
%define JIT_MAX_MILLIS 40
%define JIT_SESSION_SIZE 48

%define JIT_STATE_NEW 1
%define JIT_STATE_RX 2
%define JIT_STATE_INVALIDATED 3
%define JIT_STATE_COLLECTED 4

%define JIT_E_CONTRACT -4601
%define JIT_E_CAPABILITY -4602
%define JIT_E_STATE -4603
%define JIT_E_ENVIRONMENT -4604

%define SYS_MMAP 9
%define SYS_MPROTECT 10
%define SYS_MUNMAP 11
%define PROT_READ 1
%define PROT_WRITE 2
%define PROT_EXEC 4
%define MAP_PRIVATE_ANONYMOUS 0x22

section .text
global nebo_jit_new
global nebo_jit_set_budget
global nebo_jit_compile_i64_v0
global nebo_jit_call_i64_v0
global nebo_jit_address_privileged
global nebo_jit_invalidate
global nebo_jit_code_cache
global nebo_jit_collect
global nebo_jit_security_report

; rdi=session, rsi=non-zero capability
nebo_jit_new:
    test rdi,rdi
    jz .contract
    test rsi,rsi
    jz .capability
    cmp qword [rdi+JIT_STATE],0
    jne .state
    mov qword [rdi+JIT_ADDR],0
    mov qword [rdi+JIT_BYTES],4096
    mov [rdi+JIT_CAPABILITY],rsi
    mov qword [rdi+JIT_STATE],JIT_STATE_NEW
    mov qword [rdi+JIT_MAX_FUNCTIONS],1
    mov qword [rdi+JIT_MAX_MILLIS],1000
    xor eax,eax
    ret
.contract: mov rax,JIT_E_CONTRACT
    ret
.capability: mov rax,JIT_E_CAPABILITY
    ret
.state: mov rax,JIT_E_STATE
    ret

; rdi=session, rsi=bytes (1..4096), rdx=functions (1), rcx=milliseconds (1..1000)
nebo_jit_set_budget:
    test rdi,rdi
    jz .contract
    cmp qword [rdi+JIT_STATE],JIT_STATE_NEW
    jne .state
    test rsi,rsi
    jz .contract
    cmp rsi,4096
    ja .contract
    cmp rdx,1
    jne .contract
    test rcx,rcx
    jz .contract
    cmp rcx,1000
    ja .contract
    mov [rdi+JIT_BYTES],rsi
    mov [rdi+JIT_MAX_FUNCTIONS],rdx
    mov [rdi+JIT_MAX_MILLIS],rcx
    xor eax,eax
    ret
.contract: mov rax,JIT_E_CONTRACT
    ret
.state: mov rax,JIT_E_STATE
    ret

; rdi=session, rsi=capability, rdx=constant I64 result; fixed () -> I64 signature.
nebo_jit_compile_i64_v0:
    push r12
    push r13
    push r14
    mov r12,rdi
    mov r13,rdx
    test r12,r12
    jz .contract
    cmp [r12+JIT_CAPABILITY],rsi
    jne .capability
    cmp qword [r12+JIT_STATE],JIT_STATE_NEW
    jne .state
    cmp qword [r12+JIT_BYTES],11
    jb .contract
    mov eax,SYS_MMAP
    xor edi,edi
    mov esi,4096
    mov edx,PROT_READ|PROT_WRITE
    mov r10d,MAP_PRIVATE_ANONYMOUS
    mov r8,-1
    xor r9d,r9d
    syscall
    cmp rax,-4095
    jae .environment
    mov r14,rax
    mov byte [r14],0x48
    mov byte [r14+1],0xb8
    mov [r14+2],r13
    mov byte [r14+10],0xc3
    mov eax,SYS_MPROTECT
    mov rdi,r14
    mov esi,4096
    mov edx,PROT_READ|PROT_EXEC
    syscall
    test rax,rax
    jnz .unmap_environment
    mov [r12+JIT_ADDR],r14
    mov qword [r12+JIT_BYTES],11
    mov qword [r12+JIT_STATE],JIT_STATE_RX
    xor eax,eax
    jmp .done
.unmap_environment:
    mov eax,SYS_MUNMAP
    mov rdi,r14
    mov esi,4096
    syscall
.environment:
    mov rax,JIT_E_ENVIRONMENT
    jmp .done
.contract: mov rax,JIT_E_CONTRACT
    jmp .done
.capability: mov rax,JIT_E_CAPABILITY
    jmp .done
.state: mov rax,JIT_E_STATE
.done:
    pop r14
    pop r13
    pop r12
    ret

; rdi=session, rsi=capability
nebo_jit_call_i64_v0:
    test rdi,rdi
    jz .contract
    cmp [rdi+JIT_CAPABILITY],rsi
    jne .capability
    cmp qword [rdi+JIT_STATE],JIT_STATE_RX
    jne .state
    mov rax,[rdi+JIT_ADDR]
    test rax,rax
    jz .state
    call rax
    ret
.contract: mov rax,JIT_E_CONTRACT
    ret
.capability: mov rax,JIT_E_CAPABILITY
    ret
.state: mov rax,JIT_E_STATE
    ret

nebo_jit_address_privileged:
    test rdi,rdi
    jz .contract
    cmp [rdi+JIT_CAPABILITY],rsi
    jne .capability
    cmp qword [rdi+JIT_STATE],JIT_STATE_RX
    jne .state
    mov rax,[rdi+JIT_ADDR]
    ret
.contract: mov rax,JIT_E_CONTRACT
    ret
.capability: mov rax,JIT_E_CAPABILITY
    ret
.state: mov rax,JIT_E_STATE
    ret

nebo_jit_invalidate:
    test rdi,rdi
    jz .contract
    cmp [rdi+JIT_CAPABILITY],rsi
    jne .capability
    cmp qword [rdi+JIT_STATE],JIT_STATE_RX
    jne .state
    mov qword [rdi+JIT_STATE],JIT_STATE_INVALIDATED
    xor eax,eax
    ret
.contract: mov rax,JIT_E_CONTRACT
    ret
.capability: mov rax,JIT_E_CAPABILITY
    ret
.state: mov rax,JIT_E_STATE
    ret

; Returns address in rax and used bytes in rdx for privileged tooling.
nebo_jit_code_cache:
    call nebo_jit_address_privileged
    test rax,rax
    js .done
    mov rdx,[rdi+JIT_BYTES]
.done: ret

; rdi=session, rsi=capability; unmap exactly once.
nebo_jit_collect:
    push r12
    mov r12,rdi
    test r12,r12
    jz .contract
    cmp [r12+JIT_CAPABILITY],rsi
    jne .capability
    mov rax,[r12+JIT_STATE]
    cmp rax,JIT_STATE_RX
    je .unmap
    cmp rax,JIT_STATE_INVALIDATED
    jne .state
.unmap:
    mov rdi,[r12+JIT_ADDR]
    test rdi,rdi
    jz .state
    mov eax,SYS_MUNMAP
    mov esi,4096
    syscall
    test rax,rax
    jnz .environment
    mov qword [r12+JIT_ADDR],0
    mov qword [r12+JIT_BYTES],0
    mov qword [r12+JIT_STATE],JIT_STATE_COLLECTED
    xor eax,eax
    jmp .done
.contract: mov rax,JIT_E_CONTRACT
    jmp .done
.capability: mov rax,JIT_E_CAPABILITY
    jmp .done
.state: mov rax,JIT_E_STATE
    jmp .done
.environment: mov rax,JIT_E_ENVIRONMENT
.done:
    pop r12
    ret

; Returns state; states RX/invalidated imply mapping is RX and never RWX.
nebo_jit_security_report:
    test rdi,rdi
    jz .contract
    mov rax,[rdi+JIT_STATE]
    ret
.contract: mov rax,JIT_E_CONTRACT
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
