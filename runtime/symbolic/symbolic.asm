; IA-ASSISTIDA-LLM-TOOLS-E-GERACAO-SEGURA-F06 typed topological symbolic DAG dual evaluator.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/symbolic/symbolic.inc"
section .text

; rdi=nodes, rsi=count, edx=active symbol id, rcx=symbol value,
; r8=workspace[count] of {value,derivative}, r9=out pair.
NEBOC_ABI_FUNCTION nebo_symbolic_eval_dual_i64
    test rdi,rdi
    jz .pre_invalid
    test r8,r8
    jz .pre_invalid
    test r9,r9
    jz .pre_invalid
    test rsi,rsi
    jz .pre_invalid
    cmp rsi,NEBO_SYMBOLIC_MAX_NODES
    ja .pre_limit
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rsi
    mov r13,rdi
    mov r14,r8
    mov r15,r9
    mov ebx,edx
    xor r10d,r10d
.node:
    mov rax,r10
    imul rax,NEBO_SYMBOLIC_NODE_SIZE
    lea r11,[r13+rax]
    mov eax,[r11+NEBO_SYMBOLIC_KIND]
    cmp eax,NEBO_SYMBOLIC_CONST
    je .constant
    cmp eax,NEBO_SYMBOLIC_SYMBOL
    je .symbol
    cmp eax,NEBO_SYMBOLIC_ADD
    je .add
    cmp eax,NEBO_SYMBOLIC_MUL
    je .mul
    jmp .invalid
.constant:
    mov rax,[r11+NEBO_SYMBOLIC_VALUE]
    xor edx,edx
    jmp .store
.symbol:
    mov rax,rcx
    xor edx,edx
    cmp [r11+NEBO_SYMBOLIC_LEFT],ebx
    sete dl
    jmp .store
.add:
    mov eax,[r11+NEBO_SYMBOLIC_LEFT]
    mov edx,[r11+NEBO_SYMBOLIC_RIGHT]
    cmp eax,r10d
    jae .invalid
    cmp edx,r10d
    jae .invalid
    mov rsi,rax
    mov rdi,rdx
    shl rsi,4
    shl rdi,4
    mov rax,[r14+rsi]
    add rax,[r14+rdi]
    jo .overflow
    mov rdx,[r14+rsi+8]
    add rdx,[r14+rdi+8]
    jo .overflow
    jmp .store
.mul:
    mov eax,[r11+NEBO_SYMBOLIC_LEFT]
    mov edx,[r11+NEBO_SYMBOLIC_RIGHT]
    cmp eax,r10d
    jae .invalid
    cmp edx,r10d
    jae .invalid
    mov rsi,rax
    mov rdi,rdx
    shl rsi,4
    shl rdi,4
    mov rax,[r14+rsi]
    imul rax,[r14+rdi]
    jo .overflow
    mov rdx,[r14+rsi]
    imul rdx,[r14+rdi+8]
    jo .overflow
    mov r11,[r14+rsi+8]
    imul r11,[r14+rdi]
    jo .overflow
    add rdx,r11
    jo .overflow
.store:
    mov rsi,r10
    shl rsi,4
    mov [r14+rsi],rax
    mov [r14+rsi+8],rdx
    inc r10d
    cmp r10,r12
    jb .node
    dec r10
    shl r10,4
    mov rax,[r14+r10]
    mov rdx,[r14+r10+8]
    mov [r15],rax
    mov [r15+8],rdx
    xor eax,eax
    jmp .done
.invalid: mov eax,NEBO_SYMBOLIC_INVALID
    jmp .done
.overflow: mov eax,NEBO_SYMBOLIC_OVERFLOW
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.pre_invalid: mov eax,NEBO_SYMBOLIC_INVALID
    ret
.pre_limit: mov eax,NEBO_SYMBOLIC_LIMIT
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
