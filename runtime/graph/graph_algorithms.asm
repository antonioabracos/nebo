; STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-F05 bounded reachability, topological order and unweighted path.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/graph/graph_contract.inc"
extern neboc_graph_validate
extern neboc_graph_validate_handle
section .text

; validate algorithm scratch bundle in rcx/rsi depending on caller.
; reachable(graph*, from, to, scratch*, out_bool*)
NEBOC_ABI_FUNCTION neboc_graph_reachable
 test rcx,rcx
 jz .reach_bad
 test r8,r8
 jz .reach_bad
 cmp qword [rcx+NEBO_GRAPH_ALGO_FRONTIER],0
 je .reach_bad
 cmp qword [rcx+NEBO_GRAPH_ALGO_VISITED],0
 je .reach_bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r8
 mov qword [rbp],0
 call neboc_graph_validate
 test eax,eax
 jnz .reach_done
 mov rdi,r12
 mov rsi,r13
 call neboc_graph_validate_handle
 test eax,eax
 jnz .reach_done
 mov rdi,r12
 mov rsi,r14
 call neboc_graph_validate_handle
 test eax,eax
 jnz .reach_done
 mov rax,[r15+NEBO_GRAPH_ALGO_VISITED]
 xor ecx,ecx
.reach_zero:
 cmp rcx,[r12+NEBO_GRAPH_CAPACITY]
 jae .reach_seed
 mov byte [rax+rcx],0
 inc rcx
 jmp .reach_zero
.reach_seed:
 mov ecx,r13d
 mov byte [rax+rcx],1
 mov rdx,[r15+NEBO_GRAPH_ALGO_FRONTIER]
 mov [rdx],rcx
 xor r10d,r10d
 mov r11d,1
.reach_loop:
 cmp r10,r11
 jae .reach_not_found
 mov rdx,[r15+NEBO_GRAPH_ALGO_FRONTIER]
 mov r9,[rdx+r10*8]
 inc r10
 cmp r9d,r14d
 je .reach_found
 xor ecx,ecx
.reach_scan:
 cmp rcx,[r12+NEBO_GRAPH_CAPACITY]
 jae .reach_loop
 mov rax,r9
 imul rax,[r12+NEBO_GRAPH_CAPACITY]
 add rax,rcx
 mov rdx,[r12+nebo_graph_GRAPH_ADJACENCY_semantic_graph_native_vertical]
 cmp byte [rdx+rax],0
 je .reach_next
 mov rdx,[r15+NEBO_GRAPH_ALGO_VISITED]
 cmp byte [rdx+rcx],0
 jne .reach_next
 mov rax,[r12+NEBO_GRAPH_ALIVE]
 cmp byte [rax+rcx],1
 jne .reach_next
 mov byte [rdx+rcx],1
 cmp r11,[r12+NEBO_GRAPH_CAPACITY]
 jae .reach_limit
 mov rdx,[r15+NEBO_GRAPH_ALGO_FRONTIER]
 mov [rdx+r11*8],rcx
 inc r11
.reach_next:
 inc rcx
 jmp .reach_scan
.reach_found:
 mov qword [rbp],1
.reach_not_found:
 xor eax,eax
 jmp .reach_done
.reach_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .reach_done
.reach_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.reach_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; topological_sort(graph*, scratch*) publishes handles and length on success.
NEBOC_ABI_FUNCTION neboc_graph_topological_sort
 test rsi,rsi
 jz .topo_bad
 cmp qword [rsi+NEBO_GRAPH_ALGO_AUX],0
 je .topo_bad
 cmp qword [rsi+NEBO_GRAPH_ALGO_VISITED],0
 je .topo_bad
 cmp qword [rsi+NEBO_GRAPH_ALGO_OUTPUT],0
 je .topo_bad
 cmp qword [rsi+NEBO_GRAPH_ALGO_OUT_LENGTH],0
 je .topo_bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov rax,[r13+NEBO_GRAPH_ALGO_OUT_LENGTH]
 mov qword [rax],0
 call neboc_graph_validate
 test eax,eax
 jnz .topo_done
 test qword [r12+NEBO_GRAPH_FLAGS],NEBO_GRAPH_UNDIRECTED
 jnz .topo_source
 mov r14,[r13+NEBO_GRAPH_ALGO_AUX]
 mov r15,[r13+NEBO_GRAPH_ALGO_VISITED]
 xor ecx,ecx
.topo_zero:
 cmp rcx,[r12+NEBO_GRAPH_CAPACITY]
 jae .topo_degrees
 mov qword [r14+rcx*8],0
 mov byte [r15+rcx],0
 inc rcx
 jmp .topo_zero
.topo_degrees:
 xor r10d,r10d
.topo_row:
 cmp r10,[r12+NEBO_GRAPH_CAPACITY]
 jae .topo_select_start
 xor r11d,r11d
.topo_col:
 cmp r11,[r12+NEBO_GRAPH_CAPACITY]
 jae .topo_row_next
 mov rax,r10
 imul rax,[r12+NEBO_GRAPH_CAPACITY]
 add rax,r11
 mov rdx,[r12+nebo_graph_GRAPH_ADJACENCY_semantic_graph_native_vertical]
 cmp byte [rdx+rax],0
 je .topo_col_next
 inc qword [r14+r11*8]
.topo_col_next:
 inc r11
 jmp .topo_col
.topo_row_next:
 inc r10
 jmp .topo_row
.topo_select_start:
 xor ebp,ebp
.topo_outer:
 cmp rbp,[r12+NEBO_GRAPH_LENGTH]
 jae .topo_success
 xor ecx,ecx
.topo_find:
 cmp rcx,[r12+NEBO_GRAPH_CAPACITY]
 jae .topo_cycle
 mov rax,[r12+NEBO_GRAPH_ALIVE]
 cmp byte [rax+rcx],1
 jne .topo_find_next
 cmp byte [r15+rcx],0
 jne .topo_find_next
 cmp qword [r14+rcx*8],0
 je .topo_select
.topo_find_next:
 inc rcx
 jmp .topo_find
.topo_select:
 mov byte [r15+rcx],1
 mov rax,[r12+NEBO_GRAPH_GENERATIONS]
 mov eax,[rax+rcx*4]
 shl rax,32
 or rax,rcx
 mov rdx,[r13+NEBO_GRAPH_ALGO_OUTPUT]
 mov [rdx+rbp*8],rax
 inc rbp
 xor r11d,r11d
.topo_relax:
 cmp r11,[r12+NEBO_GRAPH_CAPACITY]
 jae .topo_outer
 mov rax,rcx
 imul rax,[r12+NEBO_GRAPH_CAPACITY]
 add rax,r11
 mov rdx,[r12+nebo_graph_GRAPH_ADJACENCY_semantic_graph_native_vertical]
 cmp byte [rdx+rax],0
 je .topo_relax_next
 cmp qword [r14+r11*8],0
 je .topo_source
 dec qword [r14+r11*8]
.topo_relax_next:
 inc r11
 jmp .topo_relax
.topo_success:
 mov rax,[r13+NEBO_GRAPH_ALGO_OUT_LENGTH]
 mov [rax],rbp
 xor eax,eax
 jmp .topo_done
.topo_cycle:
.topo_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
.topo_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.topo_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; shortest_path_unweighted(graph*, from, to, scratch*)
NEBOC_ABI_FUNCTION neboc_graph_shortest_path_unweighted
 test rcx,rcx
 jz .sp_bad
 cmp qword [rcx+NEBO_GRAPH_ALGO_FRONTIER],0
 je .sp_bad
 cmp qword [rcx+NEBO_GRAPH_ALGO_AUX],0
 je .sp_bad
 cmp qword [rcx+NEBO_GRAPH_ALGO_VISITED],0
 je .sp_bad
 cmp qword [rcx+NEBO_GRAPH_ALGO_OUTPUT],0
 je .sp_bad
 cmp qword [rcx+NEBO_GRAPH_ALGO_OUT_LENGTH],0
 je .sp_bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rax,[r15+NEBO_GRAPH_ALGO_OUT_LENGTH]
 mov qword [rax],0
 call neboc_graph_validate
 test eax,eax
 jnz .sp_done
 mov rdi,r12
 mov rsi,r13
 call neboc_graph_validate_handle
 test eax,eax
 jnz .sp_done
 mov rdi,r12
 mov rsi,r14
 call neboc_graph_validate_handle
 test eax,eax
 jnz .sp_done
 mov r8,[r15+NEBO_GRAPH_ALGO_VISITED]
 mov r9,[r15+NEBO_GRAPH_ALGO_AUX]
 xor ecx,ecx
.sp_zero:
 cmp rcx,[r12+NEBO_GRAPH_CAPACITY]
 jae .sp_seed
 mov byte [r8+rcx],0
 mov qword [r9+rcx*8],NEBO_INVALID_HANDLE
 inc rcx
 jmp .sp_zero
.sp_seed:
 mov ecx,r13d
 mov byte [r8+rcx],1
 mov rax,[r15+NEBO_GRAPH_ALGO_FRONTIER]
 mov [rax],rcx
 xor r10d,r10d
 mov r11d,1
.sp_bfs:
 cmp r10,r11
 jae .sp_unreachable
 mov rax,[r15+NEBO_GRAPH_ALGO_FRONTIER]
 mov rbp,[rax+r10*8]
 inc r10
 cmp ebp,r14d
 je .sp_reconstruct
 xor ecx,ecx
.sp_scan:
 cmp rcx,[r12+NEBO_GRAPH_CAPACITY]
 jae .sp_bfs
 mov rax,rbp
 imul rax,[r12+NEBO_GRAPH_CAPACITY]
 add rax,rcx
 mov rdx,[r12+nebo_graph_GRAPH_ADJACENCY_semantic_graph_native_vertical]
 cmp byte [rdx+rax],0
 je .sp_next
 cmp byte [r8+rcx],0
 jne .sp_next
 mov rax,[r12+NEBO_GRAPH_ALIVE]
 cmp byte [rax+rcx],1
 jne .sp_next
 mov byte [r8+rcx],1
 mov [r9+rcx*8],rbp
 cmp r11,[r12+NEBO_GRAPH_CAPACITY]
 jae .sp_limit
 mov rax,[r15+NEBO_GRAPH_ALGO_FRONTIER]
 mov [rax+r11*8],rcx
 inc r11
.sp_next:
 inc rcx
 jmp .sp_scan
.sp_reconstruct:
 xor r10d,r10d
 mov ecx,r14d
.sp_back:
 cmp r10,[r12+NEBO_GRAPH_CAPACITY]
 jae .sp_limit
 mov rax,[r12+NEBO_GRAPH_GENERATIONS]
 mov eax,[rax+rcx*4]
 shl rax,32
 or rax,rcx
 mov rdx,[r15+NEBO_GRAPH_ALGO_OUTPUT]
 mov [rdx+r10*8],rax
 inc r10
 cmp ecx,r13d
 je .sp_reverse
 mov rcx,[r9+rcx*8]
 cmp rcx,NEBO_INVALID_HANDLE
 je .sp_source
 jmp .sp_back
.sp_reverse:
 xor ecx,ecx
 mov r11,r10
 dec r11
 mov rdx,[r15+NEBO_GRAPH_ALGO_OUTPUT]
.sp_swap:
 cmp rcx,r11
 jae .sp_publish
 mov rax,[rdx+rcx*8]
 mov r8,[rdx+r11*8]
 mov [rdx+rcx*8],r8
 mov [rdx+r11*8],rax
 inc rcx
 dec r11
 jmp .sp_swap
.sp_publish:
 mov rax,[r15+NEBO_GRAPH_ALGO_OUT_LENGTH]
 mov [rax],r10
.sp_unreachable:
 xor eax,eax
 jmp .sp_done
.sp_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .sp_done
.sp_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
.sp_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.sp_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
