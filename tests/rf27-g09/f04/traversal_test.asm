bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/graph/graph_contract.inc"
extern neboc_graph_init
extern neboc_graph_add_node
extern neboc_graph_add_edge
extern neboc_traversal_begin
extern neboc_traversal_next
extern neboc_traversal_release
global _start

%macro EXPECT_NEXT 2
 lea rdi,[rel traversal]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_traversal_next
 test eax,eax
 jnz %2
 cmp qword [rel found],1
 jne %2
 mov rax,[rel %1]
 cmp [rel out],rax
 jne %2
%endmacro

%macro EXPECT_END 1
 lea rdi,[rel traversal]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_traversal_next
 test eax,eax
 jnz %1
 cmp qword [rel found],0
 jne %1
%endmacro

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
 mov rdx,[rel node_e]
 mov ecx,1
 call neboc_graph_add_edge
 test eax,eax
 jnz fail2

 lea rdi,[rel traversal]
 lea rsi,[rel graph]
 mov rdx,[rel node_a]
 lea rcx,[rel scratch]
 lea r8,[rel visited]
 mov r9d,NEBO_TRAVERSAL_BFS
 call neboc_traversal_begin
 test eax,eax
 jnz fail3
 cmp qword [rel graph+NEBO_GRAPH_BORROW],1
 jne fail3

 lea rdi,[rel graph]
 mov esi,99
 lea rdx,[rel spare]
 call neboc_graph_add_node
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail4

 EXPECT_NEXT node_a,fail5
 EXPECT_NEXT node_b,fail5
 EXPECT_NEXT node_c,fail5
 EXPECT_NEXT node_d,fail5
 EXPECT_NEXT node_e,fail5
 EXPECT_END fail5
 cmp qword [rel traversal+NEBO_TRAVERSAL_STEPS],5
 jne fail5

 lea rdi,[rel traversal]
 call neboc_traversal_release
 test eax,eax
 jnz fail6
 cmp qword [rel graph+NEBO_GRAPH_BORROW],0
 jne fail6

 lea rdi,[rel traversal]
 lea rsi,[rel graph]
 mov rdx,[rel node_a]
 lea rcx,[rel scratch]
 lea r8,[rel visited]
 mov r9d,NEBO_TRAVERSAL_DFS
 call neboc_traversal_begin
 test eax,eax
 jnz fail7
 EXPECT_NEXT node_a,fail8
 EXPECT_NEXT node_b,fail8
 EXPECT_NEXT node_d,fail8
 EXPECT_NEXT node_c,fail8
 EXPECT_NEXT node_e,fail8
 EXPECT_END fail8
 lea rdi,[rel traversal]
 call neboc_traversal_release
 test eax,eax
 jnz fail8

 lea rdi,[rel traversal]
 call neboc_traversal_release
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail9

 lea rdi,[rel traversal]
 lea rsi,[rel graph]
 mov rdx,[rel node_a]
 lea rcx,[rel scratch]
 lea r8,[rel visited]
 mov r9d,NEBO_TRAVERSAL_BFS
 call neboc_traversal_begin
 test eax,eax
 jnz fail10
 inc qword [rel graph+NEBO_GRAPH_GENERATION]
 lea rdi,[rel traversal]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_traversal_next
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail10
 dec qword [rel graph+NEBO_GRAPH_GENERATION]
 lea rdi,[rel traversal]
 call neboc_traversal_release
 test eax,eax
 jnz fail10

 lea rdi,[rel traversal]
 lea rsi,[rel graph]
 mov rdx,[rel node_a]
 lea rcx,[rel scratch]
 lea r8,[rel visited]
 mov r9d,3
 call neboc_traversal_begin
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail11

 lea rdi,[rel traversal]
 lea rsi,[rel graph]
 mov rdx,[rel node_a]
 xor ecx,ecx
 lea r8,[rel visited]
 mov r9d,NEBO_TRAVERSAL_BFS
 call neboc_traversal_begin
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail12
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
traversal: resb NEBO_TRAVERSAL_SIZE
scratch: resq 5
visited: resb 5
node_a: resq 1
node_b: resq 1
node_c: resq 1
node_d: resq 1
node_e: resq 1
spare: resq 1
out: resq 1
found: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
