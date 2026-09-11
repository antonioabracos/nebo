bits 64
default rel
%include "runtime/reactive/graph.inc"
extern nebo_graph_init,nebo_graph_compile,nebo_graph_affected
section .data
edges dq 6,8,8,0
cycle dq 2,1
section .bss
graph resb nebo_graph_GRAPH_SIZE_reactive
order resq nebo_graph_GRAPH_MAX_NODES_reactive
indegree resq nebo_graph_GRAPH_MAX_NODES_reactive
affected resq 1
section .text
global _start
_start:
 lea rdi,[graph]
 lea rsi,[edges]
 mov edx,4
 mov ecx,64
 call nebo_graph_init
 test eax,eax
 jnz fail
 lea rdi,[graph]
 lea rsi,[order]
 lea rdx,[indegree]
 call nebo_graph_compile
 test eax,eax
 jnz fail
 cmp qword [graph+NEBO_GRAPH_COMPILED],1
 jne fail
 lea rdi,[graph]
 mov esi,1
 lea rdx,[affected]
 call nebo_graph_affected
 test eax,eax
 jnz fail
 cmp qword [affected],15
 jne fail
 lea rdi,[graph]
 lea rsi,[cycle]
 mov edx,2
 mov ecx,16
 call nebo_graph_init
 test eax,eax
 jnz fail
 lea rdi,[graph]
 lea rsi,[order]
 lea rdx,[indegree]
 call nebo_graph_compile
 cmp eax,NEBO_GRAPH_STATUS_CYCLE
 jne fail
 cmp qword [graph+NEBO_GRAPH_COMPILED],0
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
