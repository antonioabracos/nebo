; PLUGINS-FFI-E-EXTENSIBILIDADE-F02 typed topologically ordered probabilistic graph validation.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/probabilistic/model_graph.inc"
section .text
; rdi=nodes, rsi=count, rdx=report. kind: 0 parameter,1 latent,2 observed,3 deterministic.
NEBOC_ABI_FUNCTION nebo_prob_graph_validate
    test rdi,rdi
    jz .invalid
    test rdx,rdx
    jz .invalid
    test rsi,rsi
    jz .invalid
    cmp rsi,NEBO_GRAPH_MAX_NODES
    ja .limit
    xor ecx,ecx
    xor r8d,r8d                   ; roots
    xor r9d,r9d                   ; observed
    xor r10d,r10d                 ; deterministic
.loop:
    mov rax,rcx
    shl rax,4
    mov r11,[rdi+rax+NEBO_GRAPH_NODE_PARENT]
    cmp r11,-1
    je .root
    test r11,r11
    js .invalid
    cmp r11,rcx
    jae .invalid                 ; canonical order proves acyclicity
    jmp .kind
.root:
    inc r8
.kind:
    mov r11d,[rdi+rax+NEBO_GRAPH_NODE_KIND]
    cmp r11d,3
    ja .invalid
    cmp r11d,2
    jne .not_observed
    inc r9
.not_observed:
    cmp r11d,3
    jne .plate
    inc r10
.plate:
    mov r11d,[rdi+rax+NEBO_GRAPH_NODE_PLATE]
    test r11d,r11d
    jz .invalid
    cmp r11d,NEBO_GRAPH_MAX_PLATE
    ja .limit
    inc rcx
    cmp rcx,rsi
    jb .loop
    mov [rdx+NEBO_GRAPH_REPORT_NODES],rsi
    mov [rdx+NEBO_GRAPH_REPORT_ROOTS],r8
    mov [rdx+NEBO_GRAPH_REPORT_OBSERVED],r9
    mov [rdx+NEBO_GRAPH_REPORT_DETERMINISTIC],r10
    xor eax,eax
    ret
.invalid: mov eax,NEBO_GRAPH_INVALID
    ret
.limit: mov eax,NEBO_GRAPH_LIMIT
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
