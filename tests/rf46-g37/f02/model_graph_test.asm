bits 64
default rel
%include "runtime/probabilistic/model_graph.inc"
extern nebo_prob_graph_validate
section .data
nodes:
    dq -1
    dd 0,1
    dq 0
    dd 1,4
    dq 1
    dd 2,4
    dq 1
    dd 3,4
bad_nodes:
    dq 1
    dd 0,1
    dq -1
    dd 1,1
section .bss
report resb NEBO_GRAPH_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[nodes]
    mov esi,4
    lea rdx,[report]
    call nebo_prob_graph_validate
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_GRAPH_REPORT_ROOTS],1
    jne fail
    cmp qword [report+NEBO_GRAPH_REPORT_OBSERVED],1
    jne fail
    cmp qword [report+NEBO_GRAPH_REPORT_DETERMINISTIC],1
    jne fail
    mov qword [report],0x1234
    lea rdi,[bad_nodes]
    mov esi,2
    lea rdx,[report]
    call nebo_prob_graph_validate
    cmp eax,NEBO_GRAPH_INVALID
    jne fail
    cmp qword [report],0x1234
    jne fail
    xor edi,edi
    jmp exit
fail: mov edi,1
exit: mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
