; ASYNC-AWAIT-E-CONCORRENCIA-ESTRUTURADA-F01 bounded topologically ordered model graph contract
bits 64
default rel
%define NEBO_MODEL_CONTRACT_IMPLEMENTATION 1
%include "compiler/semantic/ml/model_contract.inc"
section .text
global nebo_model_validate
global nebo_model_summary
global nebo_model_eval_ready

; graph: nodes*,node_count,edges*,edge_count,params*,param_count,flags,reserved
; node: id:u32 op:u16 dtype:u16 rank:u32 dims[4]:u32 flags:u32
nebo_model_validate:
    test rdi,rdi
    jz .argument
    cmp qword [rdi+56],0
    jne .argument
    cmp qword [rdi+48],4096
    ja .limit
    mov r8,[rdi+8]
    test r8,r8
    jz .limit
    cmp r8,64
    ja .limit
    cmp qword [rdi],0
    je .argument
    mov r9,[rdi+24]
    cmp r9,128
    ja .limit
    test r9,r9
    jz .nodes
    cmp qword [rdi+16],0
    je .argument
.nodes:
    xor ecx,ecx
    mov r10,[rdi]
.node_loop:
    cmp rcx,r8
    jae .edges
    mov eax,ecx
    cmp [r10],eax
    jne .identity
    movzx eax,word [r10+4]
    test eax,eax
    jz .shape
    cmp eax,8
    ja .shape
    cmp word [r10+6],NEBO_MODEL_DTYPE_F64
    jne .dtype
    mov eax,[r10+8]
    test eax,eax
    jz .shape
    cmp eax,4
    ja .shape
    mov r11d,eax
    mov eax,1
    xor edx,edx
.dim_loop:
    cmp edx,r11d
    jae .node_ok
    mov esi,[r10+12+rdx*4]
    test esi,esi
    jz .shape
    cmp esi,64
    ja .shape
    imul rax,rsi
    cmp rax,4096
    ja .shape
    inc edx
    jmp .dim_loop
.node_ok:
    add r10,NEBO_MODEL_NODE_BYTES
    inc ecx
    jmp .node_loop
.edges:
    xor ecx,ecx
    mov r10,[rdi+16]
.edge_loop:
    cmp rcx,r9
    jae .ok
    mov eax,[r10]
    mov edx,[r10+4]
    cmp rax,r8
    jae .edge
    cmp rdx,r8
    jae .edge
    cmp eax,edx
    jae .cycle
    ; Canonical edge list is strictly lexicographic, preventing duplicates.
    test rcx,rcx
    jz .edge_ok
    mov esi,[r10-8]
    cmp eax,esi
    jb .edge
    ja .edge_ok
    cmp edx,[r10-4]
    jbe .edge
.edge_ok:
    add r10,NEBO_MODEL_EDGE_BYTES
    inc ecx
    jmp .edge_loop
.ok:
    xor eax,eax
    ret
.argument: mov eax,NEBO_MODEL_E_ARGUMENT
    ret
.limit: mov eax,NEBO_MODEL_E_LIMIT
    ret
.identity: mov eax,NEBO_MODEL_E_IDENTITY
    ret
.dtype: mov eax,NEBO_MODEL_E_DTYPE
    ret
.shape: mov eax,NEBO_MODEL_E_SHAPE
    ret
.edge: mov eax,NEBO_MODEL_E_EDGE
    ret
.cycle: mov eax,NEBO_MODEL_E_CYCLE
    ret

; rdi=graph rsi=out summary[32]: nodes,edges,params,max_rank
nebo_model_summary:
    push r12
    push r13
    mov r12,rdi
    mov r13,rsi
    sub rsp,8
    call nebo_model_validate
    add rsp,8
    test eax,eax
    jnz .summary_done
    test r13,r13
    jz .summary_argument
    xor r8d,r8d
    xor ecx,ecx
    mov r9,[r12]
.rank:
    cmp rcx,[r12+8]
    jae .publish
    mov eax,[r9+8]
    cmp eax,r8d
    cmova r8d,eax
    add r9,NEBO_MODEL_NODE_BYTES
    inc rcx
    jmp .rank
.publish:
    mov rax,[r12+8]
    mov [r13],rax
    mov rax,[r12+24]
    mov [r13+8],rax
    mov rax,[r12+48]
    mov [r13+16],rax
    mov [r13+24],r8
    xor eax,eax
    jmp .summary_done
.summary_argument:
    mov eax,NEBO_MODEL_E_ARGUMENT
.summary_done:
    pop r13
    pop r12
    ret

nebo_model_eval_ready:
    jmp nebo_model_validate
section .note.GNU-stack noalloc noexec nowrite progbits
