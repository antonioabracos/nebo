%ifndef NEBO_GRAPH_CONTRACT_INC
%define NEBO_GRAPH_CONTRACT_INC 1
%define NEBO_HANDLE_SIZE 8
%define NEBO_HANDLE_ALIGN 8
%define NEBO_INVALID_HANDLE 0xffffffffffffffff
%define nebo_graph_GRAPH_MAX_NODES_semantic_graph_native_vertical 32
%define NEBO_GRAPH_MAX_EDGES 256
%define NEBO_TREE_SIZE 72
%define NEBO_TREE_ALIGN 8
%define nebo_graph_GRAPH_SIZE_semantic_graph_native_vertical 96
%define NEBO_GRAPH_ALIGN 8
%define NEBO_TRAVERSAL_SIZE 80
%define NEBO_TRAVERSAL_ALIGN 8
%define NEBO_TRAVERSAL_BFS 1
%define NEBO_TRAVERSAL_DFS 2
; Traversal: owner, handle scratch, visited scratch, capacity, head/tail,
; authenticated graph generation, kind, released and step count.
%define NEBO_TRAVERSAL_OWNER 0
%define NEBO_TRAVERSAL_BUFFER 8
%define NEBO_TRAVERSAL_VISITED 16
%define NEBO_TRAVERSAL_CAPACITY 24
%define NEBO_TRAVERSAL_HEAD 32
%define NEBO_TRAVERSAL_TAIL 40
%define NEBO_TRAVERSAL_GRAPH_GENERATION 48
%define NEBO_TRAVERSAL_KIND 56
%define NEBO_TRAVERSAL_RELEASED 64
%define NEBO_TRAVERSAL_STEPS 72
; Algorithm scratch bundle: frontier[32], aux u64[32], visited u8[32],
; output handles[32], output-length pointer.
%define NEBO_GRAPH_ALGO_SCRATCH_SIZE 40
%define NEBO_GRAPH_ALGO_SCRATCH_ALIGN 8
%define NEBO_GRAPH_ALGO_FRONTIER 0
%define NEBO_GRAPH_ALGO_AUX 8
%define NEBO_GRAPH_ALGO_VISITED 16
%define NEBO_GRAPH_ALGO_OUTPUT 24
%define NEBO_GRAPH_ALGO_OUT_LENGTH 32
%define NEBO_GRAPH_DIRECTED 1
%define NEBO_GRAPH_UNDIRECTED 2
%define NEBO_GRAPH_ALLOW_SELF 4
%define NEBO_GRAPH_ALLOW_MULTI 8
; Graph caller-storage bundle: values, generations, alive, adjacency, weights.
%define NEBO_GRAPH_STORAGE_SIZE 40
%define NEBO_GRAPH_STORAGE_ALIGN 8
%define NEBO_GRAPH_STORAGE_VALUES 0
%define NEBO_GRAPH_STORAGE_GENERATIONS 8
%define NEBO_GRAPH_STORAGE_ALIVE 16
%define NEBO_GRAPH_STORAGE_ADJACENCY 24
%define NEBO_GRAPH_STORAGE_WEIGHTS 32
; Tree: values, generations, alive, parents, capacity, length, generation, root, borrow.
%define NEBO_TREE_VALUES 0
%define NEBO_TREE_GENERATIONS 8
%define NEBO_TREE_ALIVE 16
%define NEBO_TREE_PARENTS 24
%define NEBO_TREE_CAPACITY 32
%define NEBO_TREE_LENGTH 40
%define NEBO_TREE_GENERATION 48
%define NEBO_TREE_ROOT 56
%define NEBO_TREE_BORROW 64
; Graph: values, generations, alive, adjacency, weights, capacity, lengths, flags.
%define NEBO_GRAPH_VALUES 0
%define NEBO_GRAPH_GENERATIONS 8
%define NEBO_GRAPH_ALIVE 16
%define nebo_graph_GRAPH_ADJACENCY_semantic_graph_native_vertical 24
%define NEBO_GRAPH_WEIGHTS 32
%define NEBO_GRAPH_CAPACITY 40
%define NEBO_GRAPH_LENGTH 48
%define NEBO_GRAPH_EDGE_COUNT 56
%define NEBO_GRAPH_GENERATION 64
%define NEBO_GRAPH_FLAGS 72
%define NEBO_GRAPH_BORROW 80
%define NEBO_GRAPH_ALLOCATOR 88
%endif
