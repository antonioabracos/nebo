bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/graph/graph_contract.inc"
extern neboc_graph_init
extern neboc_graph_add_node
extern neboc_graph_get_node
extern neboc_graph_replace_node
extern neboc_graph_add_edge
extern neboc_graph_edge_weight
extern neboc_graph_remove_edge
extern neboc_graph_remove_node
global _start
section .text
_start:
 lea rax,[rel values1]
 mov [rel storage1+NEBO_GRAPH_STORAGE_VALUES],rax
 lea rax,[rel generations1]
 mov [rel storage1+NEBO_GRAPH_STORAGE_GENERATIONS],rax
 lea rax,[rel alive1]
 mov [rel storage1+NEBO_GRAPH_STORAGE_ALIVE],rax
 lea rax,[rel adjacency1]
 mov [rel storage1+NEBO_GRAPH_STORAGE_ADJACENCY],rax
 lea rax,[rel weights1]
 mov [rel storage1+NEBO_GRAPH_STORAGE_WEIGHTS],rax
 lea rdi,[rel graph1]
 lea rsi,[rel storage1]
 mov edx,4
 mov ecx,NEBO_GRAPH_DIRECTED
 call neboc_graph_init
 test eax,eax
 jnz fail1
 cmp qword [rel graph1+NEBO_GRAPH_CAPACITY],4
 jne fail1

 lea rdi,[rel graph1]
 mov esi,10
 lea rdx,[rel node_a]
 call neboc_graph_add_node
 test eax,eax
 jnz fail2
 lea rdi,[rel graph1]
 mov esi,20
 lea rdx,[rel node_b]
 call neboc_graph_add_node
 test eax,eax
 jnz fail2
 lea rdi,[rel graph1]
 mov esi,30
 lea rdx,[rel node_c]
 call neboc_graph_add_node
 test eax,eax
 jnz fail2

 lea rdi,[rel graph1]
 mov rsi,[rel node_b]
 lea rdx,[rel out]
 call neboc_graph_get_node
 test eax,eax
 jnz fail3
 cmp qword [rel out],20
 jne fail3
 lea rdi,[rel graph1]
 mov rsi,[rel node_b]
 mov edx,22
 lea rcx,[rel out]
 call neboc_graph_replace_node
 test eax,eax
 jnz fail3
 cmp qword [rel out],20
 jne fail3

 lea rdi,[rel graph1]
 mov rsi,[rel node_a]
 mov rdx,[rel node_b]
 mov ecx,7
 call neboc_graph_add_edge
 test eax,eax
 jnz fail4
 cmp qword [rel graph1+NEBO_GRAPH_EDGE_COUNT],1
 jne fail4
 lea rdi,[rel graph1]
 mov rsi,[rel node_a]
 mov rdx,[rel node_b]
 lea rcx,[rel out]
 lea r8,[rel found]
 call neboc_graph_edge_weight
 test eax,eax
 jnz fail4
 cmp qword [rel found],1
 jne fail4
 cmp qword [rel out],7
 jne fail4

 lea rdi,[rel graph1]
 mov rsi,[rel node_b]
 mov rdx,[rel node_a]
 lea rcx,[rel out]
 lea r8,[rel found]
 call neboc_graph_edge_weight
 test eax,eax
 jnz fail5
 cmp qword [rel found],0
 jne fail5

 lea rdi,[rel graph1]
 mov rsi,[rel node_a]
 mov rdx,[rel node_b]
 mov ecx,8
 call neboc_graph_add_edge
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail6
 lea rdi,[rel graph1]
 mov rsi,[rel node_a]
 mov rdx,[rel node_a]
 mov ecx,1
 call neboc_graph_add_edge
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail6

 lea rdi,[rel graph1]
 mov rsi,[rel node_b]
 mov rdx,[rel node_c]
 mov ecx,9
 call neboc_graph_add_edge
 test eax,eax
 jnz fail7
 cmp qword [rel graph1+NEBO_GRAPH_EDGE_COUNT],2
 jne fail7
 lea rdi,[rel graph1]
 mov rsi,[rel node_b]
 call neboc_graph_remove_node
 test eax,eax
 jnz fail7
 cmp qword [rel graph1+NEBO_GRAPH_EDGE_COUNT],0
 jne fail7

 lea rdi,[rel graph1]
 mov rsi,[rel node_b]
 lea rdx,[rel out]
 call neboc_graph_get_node
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail8
 lea rdi,[rel graph1]
 mov esi,40
 lea rdx,[rel node_reuse]
 call neboc_graph_add_node
 test eax,eax
 jnz fail8
 mov rax,[rel node_b]
 mov edx,eax
 mov rax,[rel node_reuse]
 cmp edx,eax
 jne fail8
 cmp rax,[rel node_b]
 je fail8

 mov qword [rel graph1+NEBO_GRAPH_BORROW],1
 lea rdi,[rel graph1]
 mov rsi,[rel node_a]
 mov rdx,[rel node_c]
 mov ecx,3
 call neboc_graph_add_edge
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail9
 mov qword [rel graph1+NEBO_GRAPH_BORROW],0

 lea rax,[rel values2]
 mov [rel storage2+NEBO_GRAPH_STORAGE_VALUES],rax
 lea rax,[rel generations2]
 mov [rel storage2+NEBO_GRAPH_STORAGE_GENERATIONS],rax
 lea rax,[rel alive2]
 mov [rel storage2+NEBO_GRAPH_STORAGE_ALIVE],rax
 lea rax,[rel adjacency2]
 mov [rel storage2+NEBO_GRAPH_STORAGE_ADJACENCY],rax
 lea rax,[rel weights2]
 mov [rel storage2+NEBO_GRAPH_STORAGE_WEIGHTS],rax
 lea rdi,[rel graph2]
 lea rsi,[rel storage2]
 mov edx,3
 mov ecx,NEBO_GRAPH_UNDIRECTED | NEBO_GRAPH_ALLOW_SELF
 call neboc_graph_init
 test eax,eax
 jnz fail10
 lea rdi,[rel graph2]
 mov esi,1
 lea rdx,[rel node_d]
 call neboc_graph_add_node
 test eax,eax
 jnz fail10
 lea rdi,[rel graph2]
 mov esi,2
 lea rdx,[rel node_e]
 call neboc_graph_add_node
 test eax,eax
 jnz fail10

 lea rdi,[rel graph2]
 mov rsi,[rel node_d]
 mov rdx,[rel node_e]
 mov ecx,5
 call neboc_graph_add_edge
 test eax,eax
 jnz fail11
 lea rdi,[rel graph2]
 mov rsi,[rel node_e]
 mov rdx,[rel node_d]
 lea rcx,[rel out]
 lea r8,[rel found]
 call neboc_graph_edge_weight
 test eax,eax
 jnz fail11
 cmp qword [rel found],1
 jne fail11
 cmp qword [rel out],5
 jne fail11

 lea rdi,[rel graph2]
 mov rsi,[rel node_d]
 mov rdx,[rel node_d]
 mov ecx,4
 call neboc_graph_add_edge
 test eax,eax
 jnz fail12
 cmp qword [rel graph2+NEBO_GRAPH_EDGE_COUNT],2
 jne fail12

 lea rdi,[rel graph2]
 mov rsi,[rel node_d]
 mov rdx,[rel node_e]
 lea rcx,[rel found]
 call neboc_graph_remove_edge
 test eax,eax
 jnz fail13
 cmp qword [rel found],1
 jne fail13
 lea rdi,[rel graph2]
 mov rsi,[rel node_e]
 mov rdx,[rel node_d]
 lea rcx,[rel out]
 lea r8,[rel found]
 call neboc_graph_edge_weight
 test eax,eax
 jnz fail13
 cmp qword [rel found],0
 jne fail13

 lea rdi,[rel graph2]
 mov rsi,[rel node_d]
 mov rdx,[rel node_e]
 mov rcx,-1
 call neboc_graph_add_edge
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail14

 lea rdi,[rel graph2]
 lea rsi,[rel storage2]
 mov edx,33
 mov ecx,NEBO_GRAPH_DIRECTED
 call neboc_graph_init
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail15
 lea rdi,[rel graph2]
 lea rsi,[rel storage2]
 mov edx,3
 mov ecx,NEBO_GRAPH_DIRECTED | NEBO_GRAPH_ALLOW_MULTI
 call neboc_graph_init
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail15
 xor edi,edi
 jmp exit
fail1: mov edi,1
 jmp exit
fail2: mov edi,2
 jmp exit
fail3: mov edi,3
 jmp exit
fail4: mov edi,4
 jmp exit
fail5: mov edi,5
 jmp exit
fail6: mov edi,6
 jmp exit
fail7: mov edi,7
 jmp exit
fail8: mov edi,8
 jmp exit
fail9: mov edi,9
 jmp exit
fail10: mov edi,10
 jmp exit
fail11: mov edi,11
 jmp exit
fail12: mov edi,12
 jmp exit
fail13: mov edi,13
 jmp exit
fail14: mov edi,14
 jmp exit
fail15: mov edi,15
exit:
 mov eax,60
 syscall
section .bss
align 8
graph1: resb nebo_graph_GRAPH_SIZE_semantic_graph_native_vertical
storage1: resb NEBO_GRAPH_STORAGE_SIZE
values1: resq 4
generations1: resd 4
alive1: resb 4
adjacency1: resb 16
padding1: resb 4
weights1: resq 16
graph2: resb nebo_graph_GRAPH_SIZE_semantic_graph_native_vertical
storage2: resb NEBO_GRAPH_STORAGE_SIZE
values2: resq 3
generations2: resd 3
alive2: resb 3
adjacency2: resb 9
weights2: resq 9
node_a: resq 1
node_b: resq 1
node_c: resq 1
node_reuse: resq 1
node_d: resq 1
node_e: resq 1
out: resq 1
found: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
