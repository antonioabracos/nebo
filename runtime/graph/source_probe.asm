; G009 source-to-effect probe over the real bounded Tree/Graph owners.
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/graph/graph_contract.inc"

extern neboc_tree_init
extern neboc_tree_add
extern neboc_tree_get
extern neboc_tree_replace
extern neboc_tree_parent
extern neboc_tree_remove_subtree
extern neboc_tree_root
extern neboc_tree_degree
extern neboc_tree_children
extern neboc_tree_height
extern neboc_tree_preorder
extern neboc_tree_postorder
extern neboc_tree_lowest_common_ancestor
extern neboc_graph_init
extern neboc_graph_add_node
extern neboc_graph_get_node
extern neboc_graph_add_edge
extern neboc_graph_remove_edge
extern neboc_graph_remove_node
extern neboc_graph_degree
extern neboc_graph_neighbors
extern neboc_traversal_begin
extern neboc_traversal_next
extern neboc_traversal_release
extern neboc_graph_topological_sort
extern neboc_graph_shortest_path_unweighted
extern neboc_graph_has_cycle
extern neboc_graph_dijkstra
extern neboc_graph_connected_components

%define P_TREE 0
%define P_TREE_VALUES 80
%define P_TREE_GENERATIONS 144
%define P_TREE_ALIVE 176
%define P_TREE_PARENTS 184
%define P_GRAPH 256
%define P_GRAPH_STORAGE 352
%define P_GRAPH_VALUES 400
%define P_GRAPH_GENERATIONS 464
%define P_GRAPH_ALIVE 496
%define P_GRAPH_ADJACENCY 504
%define P_GRAPH_WEIGHTS 568
%define P_TRAVERSAL 1088
%define P_TRAVERSAL_BUFFER 1168
%define P_TRAVERSAL_VISITED 1232
%define P_ALGO 1240
%define P_ALGO_FRONTIER 1280
%define P_ALGO_AUX 1344
%define P_ALGO_VISITED 1408
%define P_ALGO_OUTPUT 1416
%define P_ALGO_LENGTH 1480
%define P_OUT_A 1488
%define P_OUT_B 1496
%define P_OUT_C 1504
%define P_OUT_D 1512
%define P_OUT_E 1520
%define P_HANDLES 1536

%macro INIT_TREE 0
 lea rdi,[rsp+P_TREE]
 lea rsi,[rsp+P_TREE_VALUES]
 lea rdx,[rsp+P_TREE_GENERATIONS]
 lea rcx,[rsp+P_TREE_ALIVE]
 lea r8,[rsp+P_TREE_PARENTS]
 mov r9d,8
 call neboc_tree_init
%endmacro

%macro PREP_GRAPH_STORAGE 0
 lea rax,[rsp+P_GRAPH_VALUES]
 mov [rsp+P_GRAPH_STORAGE+NEBO_GRAPH_STORAGE_VALUES],rax
 lea rax,[rsp+P_GRAPH_GENERATIONS]
 mov [rsp+P_GRAPH_STORAGE+NEBO_GRAPH_STORAGE_GENERATIONS],rax
 lea rax,[rsp+P_GRAPH_ALIVE]
 mov [rsp+P_GRAPH_STORAGE+NEBO_GRAPH_STORAGE_ALIVE],rax
 lea rax,[rsp+P_GRAPH_ADJACENCY]
 mov [rsp+P_GRAPH_STORAGE+NEBO_GRAPH_STORAGE_ADJACENCY],rax
 lea rax,[rsp+P_GRAPH_WEIGHTS]
 mov [rsp+P_GRAPH_STORAGE+NEBO_GRAPH_STORAGE_WEIGHTS],rax
%endmacro

%macro INIT_GRAPH 1
 PREP_GRAPH_STORAGE
 lea rdi,[rsp+P_GRAPH]
 lea rsi,[rsp+P_GRAPH_STORAGE]
 mov edx,5
 mov ecx,%1
 call neboc_graph_init
%endmacro

%macro PREP_ALGO 0
 lea rax,[rsp+P_ALGO_FRONTIER]
 mov [rsp+P_ALGO+NEBO_GRAPH_ALGO_FRONTIER],rax
 lea rax,[rsp+P_ALGO_AUX]
 mov [rsp+P_ALGO+NEBO_GRAPH_ALGO_AUX],rax
 lea rax,[rsp+P_ALGO_VISITED]
 mov [rsp+P_ALGO+NEBO_GRAPH_ALGO_VISITED],rax
 lea rax,[rsp+P_ALGO_OUTPUT]
 mov [rsp+P_ALGO+NEBO_GRAPH_ALGO_OUTPUT],rax
 lea rax,[rsp+P_ALGO_LENGTH]
 mov [rsp+P_ALGO+NEBO_GRAPH_ALGO_OUT_LENGTH],rax
%endmacro

section .text
global nebo_g009_source_probe
nebo_g009_source_probe:
 push rbx
 push r12
 push r13
 mov r12d,edi
 mov r13d,esi
 sub rsp,4096
 cmp r12d,1
 je .nodes
 cmp r12d,2
 je .trees
 cmp r12d,3
 je .graphs
 cmp r12d,4
 je .traversal
 cmp r12d,5
 je .algorithms
 jmp .failure

.nodes:
 INIT_TREE
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TREE]
 mov rsi,NEBO_INVALID_HANDLE
 mov edx,r13d
 lea rcx,[rsp+P_OUT_A]
 call neboc_tree_add
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TREE]
 lea rsi,[rsp+P_OUT_B]
 lea rdx,[rsp+P_OUT_C]
 call neboc_tree_root
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_C],1
 jne .failure
 mov rax,[rsp+P_OUT_A]
 cmp [rsp+P_OUT_B],rax
 jne .failure
 lea rdi,[rsp+P_TREE]
 mov rsi,[rsp+P_OUT_A]
 lea rdx,[rsp+P_OUT_B]
 call neboc_tree_get
 test eax,eax
 jnz .failure
 mov eax,r13d
 cmp [rsp+P_OUT_B],rax
 jne .failure
 lea rdi,[rsp+P_TREE]
 mov rsi,[rsp+P_OUT_A]
 lea edx,[r13d+11]
 lea rcx,[rsp+P_OUT_B]
 call neboc_tree_replace
 test eax,eax
 jnz .failure
 mov eax,r13d
 cmp [rsp+P_OUT_B],rax
 jne .failure
 lea rdi,[rsp+P_TREE]
 mov rsi,[rsp+P_OUT_A]
 lea edx,[r13d+2]
 lea rcx,[rsp+P_OUT_D]
 call neboc_tree_add
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TREE]
 mov rsi,[rsp+P_OUT_A]
 lea rdx,[rsp+P_OUT_E]
 call neboc_tree_degree
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_E],1
 jne .failure
 jmp .success

.trees:
 INIT_TREE
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TREE]
 mov rsi,NEBO_INVALID_HANDLE
 mov edx,r13d
 lea rcx,[rsp+P_OUT_A]
 call neboc_tree_add
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TREE]
 mov rsi,[rsp+P_OUT_A]
 lea edx,[r13d+1]
 lea rcx,[rsp+P_OUT_B]
 call neboc_tree_add
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TREE]
 mov rsi,[rsp+P_OUT_A]
 lea edx,[r13d+2]
 lea rcx,[rsp+P_OUT_C]
 call neboc_tree_add
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TREE]
 mov rsi,[rsp+P_OUT_B]
 lea edx,[r13d+3]
 lea rcx,[rsp+P_OUT_D]
 call neboc_tree_add
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TREE]
 mov rsi,[rsp+P_OUT_D]
 lea rdx,[rsp+P_OUT_E]
 lea rcx,[rsp+P_ALGO_LENGTH]
 call neboc_tree_parent
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_ALGO_LENGTH],1
 jne .failure
 mov rax,[rsp+P_OUT_B]
 cmp [rsp+P_OUT_E],rax
 jne .failure
 lea rdi,[rsp+P_TREE]
 mov rsi,[rsp+P_OUT_A]
 lea rdx,[rsp+P_HANDLES]
 lea rcx,[rsp+P_ALGO_LENGTH]
 call neboc_tree_children
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_ALGO_LENGTH],2
 jne .failure
 lea rdi,[rsp+P_TREE]
 lea rsi,[rsp+P_OUT_E]
 call neboc_tree_height
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_E],3
 jne .failure
 mov qword [rsp+P_TREE+NEBO_TREE_BORROW],1
 lea rdi,[rsp+P_TREE]
 mov rsi,[rsp+P_OUT_A]
 mov edx,99
 lea rcx,[rsp+P_OUT_E]
 call neboc_tree_add
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .failure
 mov qword [rsp+P_TREE+NEBO_TREE_BORROW],0
 lea rdi,[rsp+P_TREE]
 mov rsi,[rsp+P_OUT_B]
 call neboc_tree_remove_subtree
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TREE]
 mov rsi,[rsp+P_OUT_D]
 lea rdx,[rsp+P_OUT_E]
 call neboc_tree_get
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .failure
 jmp .success

.graphs:
 INIT_GRAPH NEBO_GRAPH_DIRECTED
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 mov esi,r13d
 lea rdx,[rsp+P_OUT_A]
 call neboc_graph_add_node
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 lea esi,[r13d+1]
 lea rdx,[rsp+P_OUT_B]
 call neboc_graph_add_node
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 lea esi,[r13d+2]
 lea rdx,[rsp+P_OUT_C]
 call neboc_graph_add_node
 test eax,eax
 jnz .failure
 ; Negative weights, self edges and duplicate edges fail before mutation.
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_A]
 mov rdx,[rsp+P_OUT_B]
 mov rcx,-1
 call neboc_graph_add_edge
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .failure
 cmp qword [rsp+P_GRAPH+NEBO_GRAPH_EDGE_COUNT],0
 jne .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_A]
 mov rdx,[rsp+P_OUT_A]
 mov ecx,1
 call neboc_graph_add_edge
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_A]
 mov rdx,[rsp+P_OUT_B]
 mov ecx,7
 call neboc_graph_add_edge
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_A]
 mov rdx,[rsp+P_OUT_B]
 mov ecx,8
 call neboc_graph_add_edge
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .failure
 cmp qword [rsp+P_GRAPH+NEBO_GRAPH_EDGE_COUNT],1
 jne .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_B]
 mov rdx,[rsp+P_OUT_C]
 mov ecx,9
 call neboc_graph_add_edge
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_B]
 lea rdx,[rsp+P_OUT_D]
 call neboc_graph_degree
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_D],2
 jne .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_A]
 lea rdx,[rsp+P_HANDLES]
 lea rcx,[rsp+P_ALGO_LENGTH]
 call neboc_graph_neighbors
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_ALGO_LENGTH],1
 jne .failure
 mov rax,[rsp+P_OUT_B]
 cmp [rsp+P_HANDLES],rax
 jne .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_A]
 mov rdx,[rsp+P_OUT_B]
 lea rcx,[rsp+P_OUT_D]
 call neboc_graph_remove_edge
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_D],1
 jne .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_B]
 call neboc_graph_remove_node
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_B]
 lea rdx,[rsp+P_OUT_D]
 call neboc_graph_get_node
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .failure
 INIT_GRAPH NEBO_GRAPH_UNDIRECTED
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 mov esi,r13d
 lea rdx,[rsp+P_OUT_A]
 call neboc_graph_add_node
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 lea esi,[r13d+1]
 lea rdx,[rsp+P_OUT_B]
 call neboc_graph_add_node
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_A]
 mov rdx,[rsp+P_OUT_B]
 mov ecx,5
 call neboc_graph_add_edge
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_B]
 lea rdx,[rsp+P_HANDLES]
 lea rcx,[rsp+P_ALGO_LENGTH]
 call neboc_graph_neighbors
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_ALGO_LENGTH],1
 jne .failure
 jmp .success

.traversal:
 INIT_GRAPH NEBO_GRAPH_DIRECTED
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 mov esi,r13d
 lea rdx,[rsp+P_OUT_A]
 call neboc_graph_add_node
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 lea esi,[r13d+1]
 lea rdx,[rsp+P_OUT_B]
 call neboc_graph_add_node
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 lea esi,[r13d+2]
 lea rdx,[rsp+P_OUT_C]
 call neboc_graph_add_node
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 lea esi,[r13d+3]
 lea rdx,[rsp+P_OUT_D]
 call neboc_graph_add_node
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_A]
 mov rdx,[rsp+P_OUT_B]
 mov ecx,1
 call neboc_graph_add_edge
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_A]
 mov rdx,[rsp+P_OUT_C]
 mov ecx,1
 call neboc_graph_add_edge
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_B]
 mov rdx,[rsp+P_OUT_D]
 mov ecx,1
 call neboc_graph_add_edge
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TRAVERSAL]
 lea rsi,[rsp+P_GRAPH]
 mov rdx,[rsp+P_OUT_A]
 lea rcx,[rsp+P_TRAVERSAL_BUFFER]
 lea r8,[rsp+P_TRAVERSAL_VISITED]
 mov r9d,NEBO_TRAVERSAL_BFS
 call neboc_traversal_begin
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TRAVERSAL]
 lea rsi,[rsp+P_OUT_E]
 lea rdx,[rsp+P_ALGO_LENGTH]
 call neboc_traversal_next
 test eax,eax
 jnz .failure
 mov rax,[rsp+P_OUT_A]
 cmp [rsp+P_OUT_E],rax
 jne .failure
 lea rdi,[rsp+P_TRAVERSAL]
 lea rsi,[rsp+P_OUT_E]
 lea rdx,[rsp+P_ALGO_LENGTH]
 call neboc_traversal_next
 test eax,eax
 jnz .failure
 mov rax,[rsp+P_OUT_B]
 cmp [rsp+P_OUT_E],rax
 jne .failure
 lea rdi,[rsp+P_TRAVERSAL]
 call neboc_traversal_release
 test eax,eax
 jnz .failure
 PREP_ALGO
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_A]
 mov rdx,[rsp+P_OUT_D]
 lea rcx,[rsp+P_ALGO]
 call neboc_graph_shortest_path_unweighted
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_ALGO_LENGTH],3
 jne .failure
 lea rdi,[rsp+P_TRAVERSAL]
 lea rsi,[rsp+P_GRAPH]
 mov rdx,[rsp+P_OUT_A]
 lea rcx,[rsp+P_TRAVERSAL_BUFFER]
 lea r8,[rsp+P_TRAVERSAL_VISITED]
 mov r9d,NEBO_TRAVERSAL_DFS
 call neboc_traversal_begin
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TRAVERSAL]
 lea rsi,[rsp+P_OUT_E]
 lea rdx,[rsp+P_ALGO_LENGTH]
 call neboc_traversal_next
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TRAVERSAL]
 call neboc_traversal_release
 test eax,eax
 jnz .failure
 INIT_TREE
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TREE]
 mov rsi,NEBO_INVALID_HANDLE
 mov edx,r13d
 lea rcx,[rsp+P_OUT_A]
 call neboc_tree_add
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TREE]
 mov rsi,[rsp+P_OUT_A]
 lea edx,[r13d+1]
 lea rcx,[rsp+P_OUT_B]
 call neboc_tree_add
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TREE]
 mov rsi,[rsp+P_OUT_A]
 lea edx,[r13d+2]
 lea rcx,[rsp+P_OUT_C]
 call neboc_tree_add
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TREE]
 mov rsi,[rsp+P_OUT_B]
 lea edx,[r13d+3]
 lea rcx,[rsp+P_OUT_D]
 call neboc_tree_add
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TREE]
 lea rsi,[rsp+P_HANDLES]
 lea rdx,[rsp+P_ALGO_LENGTH]
 call neboc_tree_preorder
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_ALGO_LENGTH],4
 jne .failure
 mov rax,[rsp+P_OUT_D]
 cmp [rsp+P_HANDLES+16],rax
 jne .failure
 lea rdi,[rsp+P_TREE]
 lea rsi,[rsp+P_HANDLES]
 lea rdx,[rsp+P_ALGO_LENGTH]
 call neboc_tree_postorder
 test eax,eax
 jnz .failure
 mov rax,[rsp+P_OUT_A]
 cmp [rsp+P_HANDLES+24],rax
 jne .failure
 jmp .success

.algorithms:
 INIT_TREE
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TREE]
 mov rsi,NEBO_INVALID_HANDLE
 mov edx,r13d
 lea rcx,[rsp+P_OUT_A]
 call neboc_tree_add
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TREE]
 mov rsi,[rsp+P_OUT_A]
 lea edx,[r13d+1]
 lea rcx,[rsp+P_OUT_B]
 call neboc_tree_add
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TREE]
 mov rsi,[rsp+P_OUT_A]
 lea edx,[r13d+2]
 lea rcx,[rsp+P_OUT_C]
 call neboc_tree_add
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TREE]
 mov rsi,[rsp+P_OUT_B]
 lea edx,[r13d+3]
 lea rcx,[rsp+P_OUT_D]
 call neboc_tree_add
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TREE]
 mov rsi,[rsp+P_OUT_D]
 mov rdx,[rsp+P_OUT_C]
 lea rcx,[rsp+P_OUT_E]
 lea r8,[rsp+P_ALGO_LENGTH]
 call neboc_tree_lowest_common_ancestor
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_ALGO_LENGTH],1
 jne .failure
 mov rax,[rsp+P_OUT_A]
 cmp [rsp+P_OUT_E],rax
 jne .failure
 INIT_GRAPH NEBO_GRAPH_DIRECTED
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 mov esi,r13d
 lea rdx,[rsp+P_OUT_A]
 call neboc_graph_add_node
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 lea esi,[r13d+1]
 lea rdx,[rsp+P_OUT_B]
 call neboc_graph_add_node
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 lea esi,[r13d+2]
 lea rdx,[rsp+P_OUT_C]
 call neboc_graph_add_node
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 lea esi,[r13d+3]
 lea rdx,[rsp+P_OUT_D]
 call neboc_graph_add_node
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_A]
 mov rdx,[rsp+P_OUT_B]
 mov ecx,4
 call neboc_graph_add_edge
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_B]
 mov rdx,[rsp+P_OUT_C]
 mov ecx,5
 call neboc_graph_add_edge
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_A]
 mov rdx,[rsp+P_OUT_C]
 mov ecx,12
 call neboc_graph_add_edge
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_C]
 mov rdx,[rsp+P_OUT_D]
 mov ecx,1
 call neboc_graph_add_edge
 test eax,eax
 jnz .failure
 PREP_ALGO
 lea rdi,[rsp+P_GRAPH]
 lea rsi,[rsp+P_ALGO]
 lea rdx,[rsp+P_OUT_E]
 call neboc_graph_has_cycle
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_E],0
 jne .failure
 lea rdi,[rsp+P_GRAPH]
 lea rsi,[rsp+P_ALGO]
 call neboc_graph_topological_sort
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_ALGO_LENGTH],4
 jne .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_A]
 mov rdx,[rsp+P_OUT_D]
 lea rcx,[rsp+P_ALGO]
 call neboc_graph_shortest_path_unweighted
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_ALGO_LENGTH],3
 jne .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_A]
 mov rdx,[rsp+P_OUT_D]
 lea rcx,[rsp+P_ALGO]
 lea r8,[rsp+P_OUT_E]
 call neboc_graph_dijkstra
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_E],10
 jne .failure
 cmp qword [rsp+P_ALGO_LENGTH],4
 jne .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_D]
 mov rdx,[rsp+P_OUT_A]
 mov ecx,1
 call neboc_graph_add_edge
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 lea rsi,[rsp+P_ALGO]
 lea rdx,[rsp+P_OUT_E]
 call neboc_graph_has_cycle
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_E],1
 jne .failure
 ; Three nonnegative edges whose sum exceeds u64 must fail closed.
 INIT_GRAPH NEBO_GRAPH_DIRECTED
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 mov esi,r13d
 lea rdx,[rsp+P_OUT_A]
 call neboc_graph_add_node
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 lea esi,[r13d+1]
 lea rdx,[rsp+P_OUT_B]
 call neboc_graph_add_node
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 lea esi,[r13d+2]
 lea rdx,[rsp+P_OUT_C]
 call neboc_graph_add_node
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 lea esi,[r13d+3]
 lea rdx,[rsp+P_OUT_D]
 call neboc_graph_add_node
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_A]
 mov rdx,[rsp+P_OUT_B]
 mov rcx,0x7fffffffffffffff
 call neboc_graph_add_edge
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_B]
 mov rdx,[rsp+P_OUT_C]
 mov rcx,0x7fffffffffffffff
 call neboc_graph_add_edge
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_C]
 mov rdx,[rsp+P_OUT_D]
 mov ecx,2
 call neboc_graph_add_edge
 test eax,eax
 jnz .failure
 PREP_ALGO
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_A]
 mov rdx,[rsp+P_OUT_D]
 lea rcx,[rsp+P_ALGO]
 lea r8,[rsp+P_OUT_E]
 call neboc_graph_dijkstra
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .failure
 cmp qword [rsp+P_OUT_E],-1
 jne .failure
 cmp qword [rsp+P_ALGO_LENGTH],0
 jne .failure
 INIT_GRAPH NEBO_GRAPH_UNDIRECTED
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 mov esi,r13d
 lea rdx,[rsp+P_OUT_A]
 call neboc_graph_add_node
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 lea esi,[r13d+1]
 lea rdx,[rsp+P_OUT_B]
 call neboc_graph_add_node
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 lea esi,[r13d+2]
 lea rdx,[rsp+P_OUT_C]
 call neboc_graph_add_node
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_GRAPH]
 mov rsi,[rsp+P_OUT_A]
 mov rdx,[rsp+P_OUT_B]
 mov ecx,1
 call neboc_graph_add_edge
 test eax,eax
 jnz .failure
 PREP_ALGO
 lea rdi,[rsp+P_GRAPH]
 lea rsi,[rsp+P_ALGO]
 lea rdx,[rsp+P_OUT_E]
 call neboc_graph_connected_components
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_E],2
 jne .failure
 jmp .success

.success:
 mov eax,r13d
 jmp .done
.failure:
 mov eax,111
.done:
 add rsp,4096
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
