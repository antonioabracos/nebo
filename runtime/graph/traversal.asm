; STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-F04 bounded generation-authenticated BFS/DFS traversal.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/graph/graph_contract.inc"
extern neboc_graph_validate
extern neboc_graph_validate_handle
section .text

; begin(traversal*, graph*, start_handle, handle_scratch*, visited_u8*, kind)
NEBOC_ABI_FUNCTION neboc_traversal_begin
 test rdi,rdi
 jz .begin_bad
 test rdi,7
 jnz .begin_bad
 test rsi,rsi
 jz .begin_bad
 test rcx,rcx
 jz .begin_bad
 test r8,r8
 jz .begin_bad
 cmp r9,NEBO_TRAVERSAL_BFS
 je .kind_ok
 cmp r9,NEBO_TRAVERSAL_DFS
 jne .begin_bad
.kind_ok:
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
 mov rdi,r13
 call neboc_graph_validate
 test eax,eax
 jnz .begin_done
 mov rdi,r13
 mov rsi,r14
 call neboc_graph_validate_handle
 test eax,eax
 jnz .begin_done
 mov r10,rdx
 mov rdi,r12
 mov ecx,NEBO_TRAVERSAL_SIZE/8
 xor eax,eax
 rep stosq
 mov [r12+NEBO_TRAVERSAL_OWNER],r13
 mov [r12+NEBO_TRAVERSAL_BUFFER],r15
 mov [r12+NEBO_TRAVERSAL_VISITED],rbp
 mov rax,[r13+NEBO_GRAPH_CAPACITY]
 mov [r12+NEBO_TRAVERSAL_CAPACITY],rax
 mov rax,[r13+NEBO_GRAPH_GENERATION]
 mov [r12+NEBO_TRAVERSAL_GRAPH_GENERATION],rax
 mov [r12+NEBO_TRAVERSAL_KIND],r9
 mov qword [r12+NEBO_TRAVERSAL_TAIL],1
 mov [r15],r14
 xor ecx,ecx
.zero_visited:
 cmp rcx,[r12+NEBO_TRAVERSAL_CAPACITY]
 jae .mark_start
 mov byte [rbp+rcx],0
 inc rcx
 jmp .zero_visited
.mark_start:
 mov byte [rbp+r10],1
 cmp qword [r13+NEBO_GRAPH_BORROW],-1
 je .begin_limit
 inc qword [r13+NEBO_GRAPH_BORROW]
 xor eax,eax
 jmp .begin_done
.begin_limit:
 mov qword [r12+NEBO_TRAVERSAL_RELEASED],1
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.begin_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.begin_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; next(traversal*, out_handle*, found*)
NEBOC_ABI_FUNCTION neboc_traversal_next
 test rdi,rdi
 jz .next_bad
 test rsi,rsi
 jz .next_bad
 test rdx,rdx
 jz .next_bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r14,rsi
 mov r15,rdx
 mov qword [r14],NEBO_INVALID_HANDLE
 mov qword [r15],0
 cmp qword [r12+NEBO_TRAVERSAL_RELEASED],0
 jne .next_source
 mov r13,[r12+NEBO_TRAVERSAL_OWNER]
 test r13,r13
 jz .next_source
 mov rax,[r13+NEBO_GRAPH_GENERATION]
 cmp rax,[r12+NEBO_TRAVERSAL_GRAPH_GENERATION]
 jne .next_source
 cmp qword [r12+NEBO_TRAVERSAL_KIND],NEBO_TRAVERSAL_BFS
 je .bfs
 cmp qword [r12+NEBO_TRAVERSAL_KIND],NEBO_TRAVERSAL_DFS
 je .dfs
 jmp .next_source
.bfs:
 mov rax,[r12+NEBO_TRAVERSAL_HEAD]
 cmp rax,[r12+NEBO_TRAVERSAL_TAIL]
 jae .next_end
 mov rcx,[r12+NEBO_TRAVERSAL_BUFFER]
 mov rbp,[rcx+rax*8]
 inc qword [r12+NEBO_TRAVERSAL_HEAD]
 mov r10d,ebp
 xor r11d,r11d
.bfs_scan:
 cmp r11,[r12+NEBO_TRAVERSAL_CAPACITY]
 jae .publish
 mov rax,r10
 imul rax,[r13+NEBO_GRAPH_CAPACITY]
 add rax,r11
 mov rcx,[r13+nebo_graph_GRAPH_ADJACENCY_semantic_graph_native_vertical]
 cmp byte [rcx+rax],0
 je .bfs_next
 mov rcx,[r12+NEBO_TRAVERSAL_VISITED]
 cmp byte [rcx+r11],0
 jne .bfs_next
 mov rax,[r13+NEBO_GRAPH_ALIVE]
 cmp byte [rax+r11],1
 jne .bfs_next
 mov byte [rcx+r11],1
 mov rax,[r13+NEBO_GRAPH_GENERATIONS]
 mov eax,[rax+r11*4]
 shl rax,32
 or rax,r11
 mov rcx,[r12+NEBO_TRAVERSAL_TAIL]
 cmp rcx,[r12+NEBO_TRAVERSAL_CAPACITY]
 jae .next_limit
 mov rdx,[r12+NEBO_TRAVERSAL_BUFFER]
 mov [rdx+rcx*8],rax
 inc qword [r12+NEBO_TRAVERSAL_TAIL]
.bfs_next:
 inc r11
 jmp .bfs_scan
.dfs:
 mov rax,[r12+NEBO_TRAVERSAL_TAIL]
 test rax,rax
 jz .next_end
 dec rax
 mov [r12+NEBO_TRAVERSAL_TAIL],rax
 mov rcx,[r12+NEBO_TRAVERSAL_BUFFER]
 mov rbp,[rcx+rax*8]
 mov r10d,ebp
 mov r11,[r12+NEBO_TRAVERSAL_CAPACITY]
.dfs_scan:
 test r11,r11
 jz .publish
 dec r11
 mov rax,r10
 imul rax,[r13+NEBO_GRAPH_CAPACITY]
 add rax,r11
 mov rcx,[r13+nebo_graph_GRAPH_ADJACENCY_semantic_graph_native_vertical]
 cmp byte [rcx+rax],0
 je .dfs_scan
 mov rcx,[r12+NEBO_TRAVERSAL_VISITED]
 cmp byte [rcx+r11],0
 jne .dfs_scan
 mov rax,[r13+NEBO_GRAPH_ALIVE]
 cmp byte [rax+r11],1
 jne .dfs_scan
 mov byte [rcx+r11],1
 mov rax,[r13+NEBO_GRAPH_GENERATIONS]
 mov eax,[rax+r11*4]
 shl rax,32
 or rax,r11
 mov rcx,[r12+NEBO_TRAVERSAL_TAIL]
 cmp rcx,[r12+NEBO_TRAVERSAL_CAPACITY]
 jae .next_limit
 mov rdx,[r12+NEBO_TRAVERSAL_BUFFER]
 mov [rdx+rcx*8],rax
 inc qword [r12+NEBO_TRAVERSAL_TAIL]
 jmp .dfs_scan
.publish:
 mov [r14],rbp
 mov qword [r15],1
 inc qword [r12+NEBO_TRAVERSAL_STEPS]
 xor eax,eax
 jmp .next_done
.next_end: xor eax,eax
 jmp .next_done
.next_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .next_done
.next_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
.next_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.next_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_traversal_release
 test rdi,rdi
 jz .release_bad
 cmp qword [rdi+NEBO_TRAVERSAL_RELEASED],0
 jne .release_source
 mov rax,[rdi+NEBO_TRAVERSAL_OWNER]
 test rax,rax
 jz .release_source
 cmp qword [rax+NEBO_GRAPH_BORROW],0
 je .release_source
 dec qword [rax+NEBO_GRAPH_BORROW]
 mov qword [rdi+NEBO_TRAVERSAL_RELEASED],1
 xor eax,eax
 ret
.release_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.release_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
