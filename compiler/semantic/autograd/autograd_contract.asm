bits 64
default rel
%define NEBO_AUTOGRAD_CONTRACT_IMPLEMENTATION 1
%include "compiler/semantic/autograd/autograd_contract.inc"
section .text
global nebo_autograd_record
global nebo_autograd_requires_gradient
global nebo_autograd_gradient
global nebo_autograd_detach
global nebo_autograd_clear
global nebo_autograd_graph

; Tape: magic,state,generation,nodes*,node_count,node_cap,edges*,edge_count,
; edge_cap,saved_count,saved_cap,recording,reserved.
; Node32: id:u32,generation:u32,flags:u64,gradient*,saved_count:u64.
autograd_validate:
 test rdi,rdi
 jz .argument
 mov rax,NEBO_AUTOGRAD_MAGIC
 cmp [rdi],rax
 jne .state
 cmp qword [rdi+8],NEBO_AUTOGRAD_STATE_ACTIVE
 jne .state
 cmp qword [rdi+96],0
 jne .state
 cmp qword [rdi+88],1
 ja .state
 mov r8,[rdi+16]
 test r8,r8
 jz .generation
 mov r9,[rdi+32]
 cmp r9,[rdi+40]
 ja .limit
 cmp qword [rdi+40],NEBO_AUTOGRAD_MAX_NODES
 ja .limit
 test r9,r9
 jz .edges
 cmp qword [rdi+24],0
 je .argument
 xor ecx,ecx
 xor r10d,r10d
 mov r11,[rdi+24]
.nodes:
 cmp rcx,r9
 jae .saved
 cmp dword [r11],ecx
 jne .node
 cmp [r11+4],r8d
 jne .generation
 mov rax,[r11+8]
 test rax,~7
 jnz .node
 test rax,NEBO_AUTOGRAD_FLAG_DETACHED
 jz .node_not_detached
 test rax,NEBO_AUTOGRAD_FLAG_REQUIRES_GRAD | NEBO_AUTOGRAD_FLAG_HAS_GRAD
 jnz .node
.node_not_detached:
 test rax,NEBO_AUTOGRAD_FLAG_HAS_GRAD
 jz .node_no_grad
 cmp qword [r11+16],0
 je .gradient
.node_no_grad:
 add r10,[r11+24]
 jc .limit
 cmp r10,NEBO_AUTOGRAD_MAX_SAVED
 ja .limit
 add r11,NEBO_AUTOGRAD_NODE_SIZE
 inc rcx
 jmp .nodes
.saved:
 cmp r10,[rdi+72]
 jne .node
 cmp r10,[rdi+80]
 ja .limit
 cmp qword [rdi+80],NEBO_AUTOGRAD_MAX_SAVED
 ja .limit
.edges:
 mov r9,[rdi+56]
 cmp r9,[rdi+64]
 ja .limit
 cmp qword [rdi+64],NEBO_AUTOGRAD_MAX_EDGES
 ja .limit
 test r9,r9
 jz .ok
 cmp qword [rdi+48],0
 je .argument
 xor ecx,ecx
 mov r10,[rdi+48]
.edge_loop:
 cmp rcx,r9
 jae .ok
 mov eax,[r10]
 mov edx,[r10+4]
 cmp rax,[rdi+32]
 jae .edge
 cmp rdx,[rdi+32]
 jae .edge
 cmp eax,edx
 jae .edge
 test rcx,rcx
 jz .edge_next
 mov r8d,[r10-8]
 cmp eax,r8d
 jb .edge
 ja .edge_next
 cmp edx,[r10-4]
 jbe .edge
.edge_next:
 add r10,8
 inc rcx
 jmp .edge_loop
.ok: xor eax,eax
 ret
.argument: mov eax,NEBO_AUTOGRAD_E_ARGUMENT
 ret
.limit: mov eax,NEBO_AUTOGRAD_E_LIMIT
 ret
.state: mov eax,NEBO_AUTOGRAD_E_STATE
 ret
.generation: mov eax,NEBO_AUTOGRAD_E_GENERATION
 ret
.node: mov eax,NEBO_AUTOGRAD_E_NODE
 ret
.edge: mov eax,NEBO_AUTOGRAD_E_EDGE
 ret
.gradient: mov eax,NEBO_AUTOGRAD_E_GRADIENT
 ret

; rdi=tape,rsi=flags,rdx=gradient*,rcx=saved_count,r8=parent or NO_PARENT.
; eax=status, edx=new node id.
nebo_autograd_record:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 call autograd_validate
 test eax,eax
 jnz .record_no_id
 cmp qword [r12+88],1
 jne .record_state
 test r13,~3
 jnz .record_node
 test r13,NEBO_AUTOGRAD_FLAG_HAS_GRAD
 jz .record_grad_ready
 test r14,r14
 jz .record_gradient
.record_grad_ready:
 cmp r15,NEBO_AUTOGRAD_MAX_SAVED
 ja .record_limit
 mov rax,[r12+72]
 add rax,r15
 jc .record_limit
 cmp rax,[r12+80]
 ja .record_limit
 mov rcx,[r12+32]
 cmp rcx,[r12+40]
 jae .record_limit
 cmp rbx,NEBO_AUTOGRAD_NO_PARENT
 je .record_publish
 cmp rbx,rcx
 jae .record_edge
 mov rax,[r12+56]
 cmp rax,[r12+64]
 jae .record_limit
.record_publish:
 mov rax,rcx
 imul rax,NEBO_AUTOGRAD_NODE_SIZE
 add rax,[r12+24]
 mov [rax],ecx
 mov rdx,[r12+16]
 mov [rax+4],edx
 mov [rax+8],r13
 mov [rax+16],r14
 mov [rax+24],r15
 inc qword [r12+32]
 add [r12+72],r15
 cmp rbx,NEBO_AUTOGRAD_NO_PARENT
 je .record_ok
 mov rax,[r12+56]
 mov rdx,[r12+48]
 mov [rdx+rax*8],ebx
 mov [rdx+rax*8+4],ecx
 inc qword [r12+56]
.record_ok:
 mov edx,ecx
 xor eax,eax
 jmp .record_return
.record_no_id: xor edx,edx
 jmp .record_return
.record_state: mov eax,NEBO_AUTOGRAD_E_STATE
 jmp .record_no_id
.record_limit: mov eax,NEBO_AUTOGRAD_E_LIMIT
 jmp .record_no_id
.record_node: mov eax,NEBO_AUTOGRAD_E_NODE
 jmp .record_no_id
.record_edge: mov eax,NEBO_AUTOGRAD_E_EDGE
 jmp .record_no_id
.record_gradient: mov eax,NEBO_AUTOGRAD_E_GRADIENT
 jmp .record_no_id
.record_return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=tape,rsi=node id,rdx=*boolean.
nebo_autograd_requires_gradient:
 call autograd_get_node
 test eax,eax
 jnz .requires_return
 test rdx,rdx
 jz .requires_argument
 xor eax,eax
 test qword [r8+8],NEBO_AUTOGRAD_FLAG_REQUIRES_GRAD
 setnz al
 mov [rdx],rax
 xor eax,eax
 ret
.requires_argument: mov eax,NEBO_AUTOGRAD_E_ARGUMENT
.requires_return: ret

; rdi=tape,rsi=node id,rdx=*gradient pointer.
nebo_autograd_gradient:
 call autograd_get_node
 test eax,eax
 jnz .gradient_return
 test rdx,rdx
 jz .gradient_argument
 test qword [r8+8],NEBO_AUTOGRAD_FLAG_HAS_GRAD
 jz .gradient_missing
 mov rax,[r8+16]
 mov [rdx],rax
 xor eax,eax
 ret
.gradient_argument: mov eax,NEBO_AUTOGRAD_E_ARGUMENT
 ret
.gradient_missing: mov eax,NEBO_AUTOGRAD_E_GRADIENT
.gradient_return: ret

; rdi=tape,rsi=node id. Detach is explicit and generation preserving.
nebo_autograd_detach:
 xor edx,edx
 call autograd_get_node
 test eax,eax
 jnz .detach_return
 mov qword [r8+8],NEBO_AUTOGRAD_FLAG_DETACHED
 mov qword [r8+16],0
 xor eax,eax
.detach_return: ret

nebo_autograd_clear:
 push r12
 mov r12,rdi
 call autograd_validate
 test eax,eax
 jnz .clear_return
 cmp qword [r12+16],-1
 je .clear_generation
 inc qword [r12+16]
 mov qword [r12+32],0
 mov qword [r12+56],0
 mov qword [r12+72],0
 mov qword [r12+88],0
 xor eax,eax
 jmp .clear_return
.clear_generation: mov eax,NEBO_AUTOGRAD_E_GENERATION
.clear_return:
 pop r12
 ret

; rdi=tape,rsi=Summary48: nodes,edges,saved,generation,recording,requires.
nebo_autograd_graph:
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 sub rsp,8
 call autograd_validate
 add rsp,8
 test eax,eax
 jnz .graph_return
 test r13,r13
 jz .graph_argument
 xor r8d,r8d
 xor ecx,ecx
 mov r9,[r12+24]
.graph_scan:
 cmp rcx,[r12+32]
 jae .graph_publish
 test qword [r9+8],NEBO_AUTOGRAD_FLAG_REQUIRES_GRAD
 setnz al
 movzx eax,al
 add r8,rax
 add r9,NEBO_AUTOGRAD_NODE_SIZE
 inc rcx
 jmp .graph_scan
.graph_publish:
 mov rax,[r12+32]
 mov [r13],rax
 mov rax,[r12+56]
 mov [r13+8],rax
 mov rax,[r12+72]
 mov [r13+16],rax
 mov rax,[r12+16]
 mov [r13+24],rax
 mov rax,[r12+88]
 mov [r13+32],rax
 mov [r13+40],r8
 xor eax,eax
 jmp .graph_return
.graph_argument: mov eax,NEBO_AUTOGRAD_E_ARGUMENT
.graph_return:
 pop r13
 pop r12
 ret

; rdi=tape,rsi=id. rdx is preserved for result pointer. r8=node on success.
autograd_get_node:
 push rdx
 call autograd_validate
 pop rdx
 test eax,eax
 jnz .get_return
 cmp rsi,[rdi+32]
 jae .get_node
 mov r8,rsi
 imul r8,NEBO_AUTOGRAD_NODE_SIZE
 add r8,[rdi+24]
 mov eax,[r8+4]
 cmp rax,[rdi+16]
 jne .get_generation
 xor eax,eax
 ret
.get_node: mov eax,NEBO_AUTOGRAD_E_NODE
 ret
.get_generation: mov eax,NEBO_AUTOGRAD_E_GENERATION
.get_return: ret
section .note.GNU-stack noalloc noexec nowrite progbits
