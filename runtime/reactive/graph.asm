; MEDIA-IMAGEM-AUDIO-E-VIDEO-F04 deterministic DAG compilation and affected-region propagation.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/reactive/graph.inc"
section .text
NEBOC_ABI_FUNCTION nebo_graph_init
 test rdi,rdi
 jz .invalid_init
 mov qword [rdi+NEBO_GRAPH_COMPILED],0
 mov qword [rdi+NEBO_GRAPH_ORDER_HASH],0
 test rsi,rsi
 jz .invalid_init
 test rdx,rdx
 jz .invalid_init
 cmp rdx,nebo_graph_GRAPH_MAX_NODES_reactive
 ja .limit_init
 test rcx,rcx
 jz .limit_init
 mov [rdi+nebo_graph_GRAPH_ADJACENCY_reactive],rsi
 mov [rdi+NEBO_GRAPH_NODE_COUNT],rdx
 mov [rdi+NEBO_GRAPH_STEP_BUDGET],rcx
 xor eax,eax
 ret
.invalid_init: mov eax,NEBO_GRAPH_STATUS_INVALID
 ret
.limit_init: mov eax,NEBO_GRAPH_STATUS_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_graph_compile
 ; graph, order[64], indegree scratch[64]
 test rdi,rdi
 jz .invalid_compile
 test rsi,rsi
 jz .invalid_compile
 test rdx,rdx
 jz .invalid_compile
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,[r12+NEBO_GRAPH_NODE_COUNT]
 xor eax,eax
.clear:
 cmp rax,r15
 jae .indegrees
 mov qword [r14+rax*8],0
 mov qword [r13+rax*8],0
 inc rax
 jmp .clear
.indegrees:
 xor eax,eax
 mov r8,[r12+nebo_graph_GRAPH_ADJACENCY_reactive]
.source_loop:
 cmp rax,r15
 jae .seed
 mov rcx,[r8+rax*8]
.edge_loop:
 test rcx,rcx
 jz .source_next
 bsf r9,rcx
 btr rcx,r9
 cmp r9,r15
 jae .invalid_pop
 inc qword [r14+r9*8]
 jmp .edge_loop
.source_next: inc rax
 jmp .source_loop
.seed:
 xor eax,eax
 xor r9d,r9d
.seed_loop:
 cmp rax,r15
 jae .walk
 cmp qword [r14+rax*8],0
 jne .seed_next
 mov [r13+r9*8],rax
 inc r9
.seed_next: inc rax
 jmp .seed_loop
.walk:
 xor r10d,r10d
 xor r11d,r11d
.walk_loop:
 cmp r10,r9
 jae .walk_done
 cmp r11,[r12+NEBO_GRAPH_STEP_BUDGET]
 jae .timeout_pop
 inc r11
 mov rax,[r13+r10*8]
 mov rcx,[r8+rax*8]
.release_loop:
 test rcx,rcx
 jz .walk_next
 bsf rdx,rcx
 btr rcx,rdx
 dec qword [r14+rdx*8]
 jnz .release_loop
 mov [r13+r9*8],rdx
 inc r9
 jmp .release_loop
.walk_next: inc r10
 jmp .walk_loop
.walk_done:
 cmp r9,r15
 jne .cycle_pop
 xor eax,eax
 mov rbx,1469598103934665603
.hash_loop:
 cmp rax,r15
 jae .compiled
 xor rbx,[r13+rax*8]
 mov rdx,1099511628211
 imul rbx,rdx
 inc rax
 jmp .hash_loop
.compiled:
 mov qword [r12+NEBO_GRAPH_COMPILED],1
 mov [r12+NEBO_GRAPH_ORDER_HASH],rbx
 xor eax,eax
 jmp .return
.invalid_pop: mov eax,NEBO_GRAPH_STATUS_INVALID
 jmp .return
.cycle_pop: mov eax,NEBO_GRAPH_STATUS_CYCLE
 jmp .return
.timeout_pop: mov eax,NEBO_GRAPH_STATUS_TIMEOUT
.return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_compile: mov eax,NEBO_GRAPH_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_graph_affected
 ; graph, changed bitmask, affected output
 test rdx,rdx
 jz .invalid_affected
 mov qword [rdx],0
 test rdi,rdi
 jz .invalid_affected
 cmp qword [rdi+NEBO_GRAPH_COMPILED],1
 jne .invalid_affected
 test rsi,rsi
 jz .invalid_affected
 mov r8,rsi
 mov r9,rsi
 mov r10,[rdi+nebo_graph_GRAPH_ADJACENCY_reactive]
 xor r11d,r11d
.closure:
 cmp r11,[rdi+NEBO_GRAPH_STEP_BUDGET]
 jae .timeout_affected
 inc r11
 xor ecx,ecx
 mov rax,r9
.closure_edges:
 test rax,rax
 jz .closure_next
 bsf rsi,rax
 btr rax,rsi
 or rcx,[r10+rsi*8]
 jmp .closure_edges
.closure_next:
 mov rsi,r8
 not rsi
 and rcx,rsi
 test rcx,rcx
 jz .closure_done
 or r8,rcx
 mov r9,rcx
 jmp .closure
.closure_done: mov [rdx],r8
 xor eax,eax
 ret
.invalid_affected: mov eax,NEBO_GRAPH_STATUS_INVALID
 ret
.timeout_affected: mov eax,NEBO_GRAPH_STATUS_TIMEOUT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
