bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/graph/graph_contract.inc"
extern neboc_graph_init
extern neboc_graph_add_node
extern neboc_graph_add_edge
extern neboc_graph_remove_edge
extern neboc_graph_reachable
extern neboc_graph_topological_sort
extern neboc_graph_shortest_path_unweighted
global _start
section .text
_start:
 lea rax,[rel values]
 mov [rel storage+NEBO_GRAPH_STORAGE_VALUES],rax
 lea rax,[rel generations]
 mov [rel storage+NEBO_GRAPH_STORAGE_GENERATIONS],rax
 lea rax,[rel alive]
 mov [rel storage+NEBO_GRAPH_STORAGE_ALIVE],rax
 lea rax,[rel adjacency]
 mov [rel storage+NEBO_GRAPH_STORAGE_ADJACENCY],rax
 lea rax,[rel weights]
 mov [rel storage+NEBO_GRAPH_STORAGE_WEIGHTS],rax
 lea rax,[rel frontier]
 mov [rel algo+NEBO_GRAPH_ALGO_FRONTIER],rax
 lea rax,[rel aux]
 mov [rel algo+NEBO_GRAPH_ALGO_AUX],rax
 lea rax,[rel visited]
 mov [rel algo+NEBO_GRAPH_ALGO_VISITED],rax
 lea rax,[rel output]
 mov [rel algo+NEBO_GRAPH_ALGO_OUTPUT],rax
 lea rax,[rel out_length]
 mov [rel algo+NEBO_GRAPH_ALGO_OUT_LENGTH],rax
 lea rdi,[rel graph]
 lea rsi,[rel storage]
 mov edx,5
 mov ecx,NEBO_GRAPH_DIRECTED
 call neboc_graph_init
 test eax,eax
 jnz fail1
 lea rdi,[rel graph]
 mov esi,10
 lea rdx,[rel node_a]
 call neboc_graph_add_node
 test eax,eax
 jnz fail1
 lea rdi,[rel graph]
 mov esi,20
 lea rdx,[rel node_b]
 call neboc_graph_add_node
 test eax,eax
 jnz fail1
 lea rdi,[rel graph]
 mov esi,30
 lea rdx,[rel node_c]
 call neboc_graph_add_node
 test eax,eax
 jnz fail1
 lea rdi,[rel graph]
 mov esi,40
 lea rdx,[rel node_d]
 call neboc_graph_add_node
 test eax,eax
 jnz fail1
 lea rdi,[rel graph]
 mov esi,50
 lea rdx,[rel node_e]
 call neboc_graph_add_node
 test eax,eax
 jnz fail1

 lea rdi,[rel graph]
 mov rsi,[rel node_a]
 mov rdx,[rel node_b]
 mov ecx,1
 call neboc_graph_add_edge
 test eax,eax
 jnz fail2
 lea rdi,[rel graph]
 mov rsi,[rel node_a]
 mov rdx,[rel node_c]
 mov ecx,1
 call neboc_graph_add_edge
 test eax,eax
 jnz fail2
 lea rdi,[rel graph]
 mov rsi,[rel node_b]
 mov rdx,[rel node_d]
 mov ecx,1
 call neboc_graph_add_edge
 test eax,eax
 jnz fail2
 lea rdi,[rel graph]
 mov rsi,[rel node_c]
 mov rdx,[rel node_d]
 mov ecx,1
 call neboc_graph_add_edge
 test eax,eax
 jnz fail2
 lea rdi,[rel graph]
 mov rsi,[rel node_d]
 mov rdx,[rel node_e]
 mov ecx,1
 call neboc_graph_add_edge
 test eax,eax
 jnz fail2

 lea rdi,[rel graph]
 mov rsi,[rel node_a]
 mov rdx,[rel node_e]
 lea rcx,[rel algo]
 lea r8,[rel result]
 call neboc_graph_reachable
 test eax,eax
 jnz fail3
 cmp qword [rel result],1
 jne fail3

 lea rdi,[rel graph]
 mov rsi,[rel node_e]
 mov rdx,[rel node_a]
 lea rcx,[rel algo]
 lea r8,[rel result]
 call neboc_graph_reachable
 test eax,eax
 jnz fail4
 cmp qword [rel result],0
 jne fail4

 lea rdi,[rel graph]
 lea rsi,[rel algo]
 call neboc_graph_topological_sort
 test eax,eax
 jnz fail5
 cmp qword [rel out_length],5
 jne fail5
 mov rax,[rel node_a]
 cmp [rel output],rax
 jne fail5
 mov rax,[rel node_b]
 cmp [rel output+8],rax
 jne fail5
 mov rax,[rel node_c]
 cmp [rel output+16],rax
 jne fail5
 mov rax,[rel node_d]
 cmp [rel output+24],rax
 jne fail5
 mov rax,[rel node_e]
 cmp [rel output+32],rax
 jne fail5

 lea rdi,[rel graph]
 mov rsi,[rel node_a]
 mov rdx,[rel node_e]
 lea rcx,[rel algo]
 call neboc_graph_shortest_path_unweighted
 test eax,eax
 jnz fail6
 cmp qword [rel out_length],4
 jne fail6
 mov rax,[rel node_a]
 cmp [rel output],rax
 jne fail6
 mov rax,[rel node_b]
 cmp [rel output+8],rax
 jne fail6
 mov rax,[rel node_d]
 cmp [rel output+16],rax
 jne fail6
 mov rax,[rel node_e]
 cmp [rel output+24],rax
 jne fail6

 lea rdi,[rel graph]
 mov rsi,[rel node_e]
 mov rdx,[rel node_a]
 lea rcx,[rel algo]
 call neboc_graph_shortest_path_unweighted
 test eax,eax
 jnz fail7
 cmp qword [rel out_length],0
 jne fail7

 lea rdi,[rel graph]
 mov rsi,[rel node_e]
 mov rdx,[rel node_a]
 mov ecx,1
 call neboc_graph_add_edge
 test eax,eax
 jnz fail8
 mov qword [rel out_length],99
 lea rdi,[rel graph]
 lea rsi,[rel algo]
 call neboc_graph_topological_sort
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail8
 cmp qword [rel out_length],0
 jne fail8

 lea rdi,[rel graph]
 mov rsi,[rel node_e]
 mov rdx,[rel node_a]
 lea rcx,[rel result]
 call neboc_graph_remove_edge
 test eax,eax
 jnz fail9
 cmp qword [rel result],1
 jne fail9
 lea rdi,[rel graph]
 lea rsi,[rel algo]
 call neboc_graph_topological_sort
 test eax,eax
 jnz fail9
 cmp qword [rel out_length],5
 jne fail9

 lea rdi,[rel graph]
 mov rsi,[rel node_c]
 mov rdx,[rel node_c]
 lea rcx,[rel algo]
 call neboc_graph_shortest_path_unweighted
 test eax,eax
 jnz fail10
 cmp qword [rel out_length],1
 jne fail10
 mov rax,[rel node_c]
 cmp [rel output],rax
 jne fail10

 lea rdi,[rel graph]
 mov rsi,[rel node_a]
 mov rdx,[rel node_e]
 xor ecx,ecx
 lea r8,[rel result]
 call neboc_graph_reachable
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail11
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
exit:
 mov eax,60
 syscall
section .bss
align 8
graph: resb nebo_graph_GRAPH_SIZE_semantic_graph_native_vertical
storage: resb NEBO_GRAPH_STORAGE_SIZE
values: resq 5
generations: resd 5
alive: resb 5
adjacency: resb 25
padding: resb 6
weights: resq 25
algo: resb NEBO_GRAPH_ALGO_SCRATCH_SIZE
frontier: resq 5
aux: resq 5
visited: resb 5
padding2: resb 3
output: resq 5
out_length: resq 1
result: resq 1
node_a: resq 1
node_b: resq 1
node_c: resq 1
node_d: resq 1
node_e: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
