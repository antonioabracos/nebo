; SCHEDULER-F06 bounded deterministic module scheduling state machine.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/scheduler/scheduler.inc"

section .text
; rdi=graph rsi=id -> rax=node pointer, rdx=index or -1.
graph_find:
 xor edx,edx
.loop:
 cmp rdx,[rdi+NEBOC_GRAPH_NODE_COUNT_OFFSET]
 jae .missing
 imul rax,rdx,NEBOC_NODE_SIZE
 add rax,rdi
 add rax,NEBOC_GRAPH_NODES_OFFSET
 cmp [rax+NEBOC_NODE_ID_OFFSET],rsi
 je .done
 inc rdx
 jmp .loop
.missing:
 xor eax,eax
 mov rdx,-1
.done: ret

NEBOC_ABI_FUNCTION neboc_build_graph_from_modules
 ; rdi=graph rsi=modules rdx=count rcx=edge-id pairs r8=edge count.
 test rdi,rdi
 jz .invalid0
 test rsi,rsi
 jz .invalid0
 test rdx,rdx
 jz .invalid0
 cmp rdx,NEBOC_SCHED_MAX_NODES
 ja .limit0
 cmp r8,NEBOC_SCHED_MAX_EDGES
 ja .limit0
 test r8,r8
 jz .save
 test rcx,rcx
 jz .invalid0
.save:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 mov qword [rbx+NEBOC_GRAPH_ACTIVE_OFFSET],0
 mov [rbx+NEBOC_GRAPH_NODE_COUNT_OFFSET],r13
 mov [rbx+NEBOC_GRAPH_EDGE_COUNT_OFFSET],r15
 xor ecx,ecx
.copy_nodes:
 cmp rcx,r13
 jae .sort
 imul rax,rcx,NEBOC_NODE_SIZE
 add rax,rbx
 add rax,NEBOC_GRAPH_NODES_OFFSET
 imul rdx,rcx,24
 add rdx,r12
 mov r8,[rdx]
 test r8,r8
 jz .invalid
 mov [rax],r8
 mov r8,[rdx+8]
 test r8,r8
 jz .invalid
 mov [rax+8],r8
 mov r8,[rdx+16]
 test r8,r8
 jz .invalid
 mov [rax+16],r8
 mov qword [rax+24],0
 mov qword [rax+32],0
 inc rcx
 jmp .copy_nodes
.sort:
 mov ecx,1
.sort_outer:
 cmp rcx,r13
 jae .unique
 mov rdx,rcx
.sort_inner:
 test rdx,rdx
 jz .sort_next
 imul rax,rdx,NEBOC_NODE_SIZE
 add rax,rbx
 add rax,NEBOC_GRAPH_NODES_OFFSET
 lea r8,[rax-NEBOC_NODE_SIZE]
 mov r9,[r8]
 cmp r9,[rax]
 jbe .sort_next
 xor r10d,r10d
.swap:
 cmp r10d,NEBOC_NODE_SIZE/8
 jae .swapped
 mov r11,[r8+r10*8]
 xchg r11,[rax+r10*8]
 mov [r8+r10*8],r11
 inc r10
 jmp .swap
.swapped:
 dec rdx
 jmp .sort_inner
.sort_next:
 inc rcx
 jmp .sort_outer
.unique:
 mov ecx,1
.unique_loop:
 cmp rcx,r13
 jae .edges
 imul rax,rcx,NEBOC_NODE_SIZE
 add rax,rbx
 add rax,NEBOC_GRAPH_NODES_OFFSET
 mov rdx,[rax-NEBOC_NODE_SIZE]
 cmp rdx,[rax]
 je .invalid
 inc rcx
 jmp .unique_loop
.edges:
 xor ecx,ecx
.edge_loop:
 cmp rcx,r15
 jae .cycle_prepare
 mov rax,rcx
 shl rax,4
 add rax,r14
 mov rdx,[rax]
 mov [rsp],rdx
 mov rax,[rax+8]
 mov [rsp+8],rax
 cmp [rsp],rax
 je .cycle
 mov rdi,rbx
 mov rsi,[rsp]
 call graph_find
 test rax,rax
 jz .invalid
 mov [rsp+16],rdx
 mov rdi,rbx
 mov rsi,[rsp+8]
 call graph_find
 test rax,rax
 jz .invalid
 imul rax,rcx,NEBOC_EDGE_SIZE
 add rax,rbx
 add rax,NEBOC_GRAPH_EDGES_OFFSET
 mov r9,[rsp+16]
 mov [rax],r9
 mov [rax+8],rdx
 inc rcx
 jmp .edge_loop
.cycle_prepare:
 xor r12d,r12d
 xor r14d,r14d
.kahn:
 cmp r14,r13
 jae .success
 xor ecx,ecx
 xor r15d,r15d
.candidate:
 cmp rcx,r13
 jae .no_candidate
 bt r12,rcx
 jc .candidate_next
 xor edx,edx
.deps:
 cmp rdx,[rbx+NEBOC_GRAPH_EDGE_COUNT_OFFSET]
 jae .take
 imul rax,rdx,NEBOC_EDGE_SIZE
 add rax,rbx
 add rax,NEBOC_GRAPH_EDGES_OFFSET
 cmp [rax],rcx
 jne .dep_next
 mov r8,[rax+8]
 bt r12,r8
 jnc .candidate_next
.dep_next:
 inc rdx
 jmp .deps
.take:
 bts r12,rcx
 inc r14
 mov r15d,1
 jmp .kahn
.candidate_next:
 inc rcx
 jmp .candidate
.no_candidate:
 test r15,r15
 jz .cycle
 jmp .kahn
.success:
 mov qword [rbx+NEBOC_GRAPH_ACTIVE_OFFSET],1
 xor eax,eax
 jmp .done
.cycle:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.limit0: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid0: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_build_graph_ready_nodes
 ; rdi=graph rsi=completed bitmask rdx=ids rcx=capacity r8=count output.
 test rdi,rdi
 jz .invalid
 test r8,r8
 jz .invalid
 cmp qword [rdi+NEBOC_GRAPH_ACTIVE_OFFSET],1
 jne .invalid
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 xor r9d,r9d
 xor r10d,r10d
.node:
 cmp r9,[rbx]
 jae .publish
 bt r12,r9
 jc .next
 xor r11d,r11d
.deps:
 cmp r11,[rbx+8]
 jae .ready
 imul rax,r11,NEBOC_EDGE_SIZE
 add rax,rbx
 add rax,NEBOC_GRAPH_EDGES_OFFSET
 cmp [rax],r9
 jne .dep_next
 mov rdx,[rax+8]
 bt r12,rdx
 jnc .next
.dep_next: inc r11
 jmp .deps
.ready:
 cmp r10,rcx
 jae .limit
 test r13,r13
 jz .invalid_saved
 imul rax,r9,NEBOC_NODE_SIZE
 add rax,rbx
 add rax,NEBOC_GRAPH_NODES_OFFSET
 mov rax,[rax]
 mov [r13+r10*8],rax
 inc r10
.next: inc r9
 jmp .node
.publish:
 mov [r8],r10
 xor eax,eax
 jmp .done
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid_saved: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done: pop r13
 pop r12
 pop rbx
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_compile_scheduler_new
 ; rdi=scheduler rsi=config.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rsi]
 test rax,rax
 jz .invalid
 cmp rax,NEBOC_SCHED_MAX_WORKERS
 ja .limit
 cmp qword [rsi+8],0
 je .invalid
 cmp qword [rsi+16],0
 je .invalid
 mov rdx,[rsi+24]
 test rdx,rdx
 jz .invalid
 cmp rdx,NEBOC_SCHED_MAX_TASKS
 ja .limit
 cmp qword [rsi+32],0
 je .invalid
 mov rcx,[rsi+40]
 cmp rcx,rdx
 jb .invalid
 mov r8,rdi
 xor eax,eax
 mov ecx,NEBOC_SCHED_SIZE/8
 rep stosq
 mov rax,[rsi]
 mov [r8],rax
 mov rax,[rsi+8]
 mov [r8+8],rax
 mov rax,[rsi+16]
 mov [r8+16],rax
 mov rax,[rsi+24]
 mov [r8+24],rax
 mov rax,[rsi+32]
 mov [r8+40],rax
 mov rax,[rsi+40]
 mov [r8+48],rax
 mov rax,[rsi+48]
 mov [r8+64],rax
 mov qword [r8+72],1
 mov qword [r8+128],1
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_scheduler_submit
 ; rdi=scheduler rsi=unit rdx=phase rcx=memory r8=work.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 test r8,r8
 jz .invalid
 cmp qword [rdi+128],1
 jne .invalid
 cmp qword [rdi+80],0
 jne .invalid_source
 cmp rcx,[rdi+8]
 ja .limit
 mov r9,[rdi+32]
 cmp r9,[rdi+24]
 jae .limit
 mov rax,r9
 imul rax,NEBOC_TASK_SIZE
 add rax,[rdi+16]
 mov [rax],rsi
 mov [rax+8],rdx
 mov [rax+16],rcx
 mov [rax+24],r8
 mov qword [rax+32],NEBOC_TASK_PENDING
 mov qword [rax+40],0
 mov qword [rax+48],0
 inc r9
 mov [rdi+32],r9
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_scheduler_run
 ; Deterministic bounded state-machine run; no OS thread claim.
 test rdi,rdi
 jz .invalid0
 test rsi,rsi
 jz .invalid0
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 cmp qword [rbx+128],1
 jne .invalid
 cmp qword [r12+16],1
 jne .invalid
 cmp qword [rbx+80],0
 jne .cancelled
 mov rax,[rbx+32]
 cmp rax,[rbx+48]
 ja .limit
 ; Canonical insertion sort by unit id.
 mov r13d,1
.sort_outer:
 cmp r13,[rbx+32]
 jae .loop
 mov r14,r13
.sort_inner:
 test r14,r14
 jz .sort_next
 imul rax,r14,NEBOC_TASK_SIZE
 add rax,[rbx+16]
 lea rdx,[rax-NEBOC_TASK_SIZE]
 mov rcx,[rdx]
 cmp rcx,[rax]
 jbe .sort_next
 xor r15d,r15d
.swap:
 cmp r15d,NEBOC_TASK_SIZE/8
 jae .swapped
 mov rcx,[rdx+r15*8]
 xchg rcx,[rax+r15*8]
 mov [rdx+r15*8],rcx
 inc r15
 jmp .swap
.swapped: dec r14
 jmp .sort_inner
.sort_next: inc r13
 jmp .sort_outer
.loop:
 mov rax,[rbx+120]
 cmp rax,[rbx+32]
 jae .success
 xor r13d,r13d
 xor r14d,r14d
 xor r15d,r15d
.select:
 cmp r13,[rbx+32]
 jae .complete_wave
 cmp r14,[rbx]
 jae .complete_wave
 imul rax,r13,NEBOC_TASK_SIZE
 add rax,[rbx+16]
 cmp qword [rax+32],NEBOC_TASK_PENDING
 jne .select_next
 mov rdi,r12
 mov rsi,[rax]
 call graph_find
 test rax,rax
 jz .invalid
 mov [rsp],rdx
 xor ecx,ecx
.deps:
 cmp rcx,[r12+8]
 jae .memory
 imul rax,rcx,NEBOC_EDGE_SIZE
 add rax,r12
 add rax,NEBOC_GRAPH_EDGES_OFFSET
 mov rdx,[rsp]
 cmp [rax],rdx
 jne .dep_next
 mov rdx,[rax+8]
 imul rax,rdx,NEBOC_NODE_SIZE
 add rax,r12
 add rax,NEBOC_GRAPH_NODES_OFFSET
 cmp qword [rax+24],NEBOC_TASK_COMPLETED
 jne .select_next
.dep_next: inc rcx
 jmp .deps
.memory:
 imul rax,r13,NEBOC_TASK_SIZE
 add rax,[rbx+16]
 mov rcx,[rax+16]
 add rcx,r15
 cmp rcx,[rbx+8]
 ja .throttle
 mov r15,rcx
 mov qword [rax+32],NEBOC_TASK_RUNNING
 inc r14
 mov [rax+40],r14
 inc qword [rbx+56]
 mov rdx,[rbx+56]
 mov [rax+48],rdx
 mov rcx,rdx
 dec rcx
 imul rcx,NEBOC_TRACE_SIZE
 add rcx,[rbx+40]
 mov rdx,[rax]
 mov [rcx],rdx
 mov rdx,[rax+8]
 mov [rcx+8],rdx
 mov rdx,[rax+40]
 mov [rcx+16],rdx
 mov rdx,[rax+48]
 mov [rcx+24],rdx
 jmp .select_next
.throttle: inc qword [rbx+112]
.select_next: inc r13
 jmp .select
.complete_wave:
 test r14,r14
 jz .blocked
 cmp r14,[rbx+96]
 jbe .peak_mem
 mov [rbx+96],r14
.peak_mem:
 cmp r15,[rbx+104]
 jbe .complete_scan
 mov [rbx+104],r15
.complete_scan:
 xor r13d,r13d
.complete:
 cmp r13,[rbx+32]
 jae .loop
 imul rax,r13,NEBOC_TASK_SIZE
 add rax,[rbx+16]
 cmp qword [rax+32],NEBOC_TASK_RUNNING
 jne .complete_next
 mov qword [rax+32],NEBOC_TASK_COMPLETED
 inc qword [rbx+120]
 mov rdi,r12
 mov rsi,[rax]
 call graph_find
 mov qword [rax+24],NEBOC_TASK_COMPLETED
 mov rcx,[rax+8]
 mov [rax+32],rcx
 ; Critical cost = own work plus maximum completed dependency cost.
 xor r8d,r8d
 xor r9d,r9d
.critical_deps:
 cmp r9,[r12+8]
 jae .critical_done
 imul rcx,r9,NEBOC_EDGE_SIZE
 add rcx,r12
 add rcx,NEBOC_GRAPH_EDGES_OFFSET
 cmp [rcx],rdx
 jne .critical_next
 mov rcx,[rcx+8]
 imul rcx,NEBOC_NODE_SIZE
 add rcx,r12
 add rcx,NEBOC_GRAPH_NODES_OFFSET
 mov rcx,[rcx+32]
 cmp rcx,r8
 cmova r8,rcx
.critical_next: inc r9
 jmp .critical_deps
.critical_done:
 add [rax+32],r8
.complete_next: inc r13
 jmp .complete
.success: xor eax,eax
 jmp .done
.blocked: mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.cancelled: mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done: add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid0: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_scheduler_cancel
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rdi+128],1
 jne .invalid
 mov qword [rdi+80],1
 mov [rdi+88],rsi
 xor ecx,ecx
.loop:
 cmp rcx,[rdi+32]
 jae .done
 imul rax,rcx,NEBOC_TASK_SIZE
 add rax,[rdi+16]
 cmp qword [rax+32],NEBOC_TASK_PENDING
 jne .next
 mov qword [rax+32],NEBOC_TASK_CANCELLED
.next: inc rcx
 jmp .loop
.done: xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_scheduler_deterministic_mode
 test rdi,rdi
 jz .invalid
 cmp rsi,1
 ja .invalid
 mov [rdi+72],rsi
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_scheduler_critical_path
 ; rdi=graph rsi=report.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
.loop:
 cmp rcx,[rdi]
 jae .publish
 imul rax,rcx,NEBOC_NODE_SIZE
 add rax,rdi
 add rax,NEBOC_GRAPH_NODES_OFFSET
 mov rdx,[rax+32]
 cmp rdx,r8
 jbe .next
 mov r8,rdx
 mov r9,[rax]
.next: inc rcx
 jmp .loop
.publish: mov [rsi],r9
 mov [rsi+8],r8
 mov rax,[rdi]
 mov [rsi+16],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_scheduler_oversubscription_report
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi]
 mov [rsi],rax
 mov rax,[rdi+64]
 mov [rsi+8],rax
 mov rax,[rdi+96]
 mov [rsi+16],rax
 mov rax,[rdi+8]
 mov [rsi+24],rax
 mov rax,[rdi+104]
 mov [rsi+32],rax
 mov rax,[rdi+112]
 mov [rsi+40],rax
 mov rax,[rdi+32]
 mov [rsi+48],rax
 mov rax,[rdi+120]
 mov [rsi+56],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_scheduler_trace
 ; rdi=scheduler rsi=out rdx=capacity r8=count.
 test rdi,rdi
 jz .invalid
 test r8,r8
 jz .invalid
 mov rax,[rdi+56]
 cmp rax,rdx
 ja .limit
 test rax,rax
 jz .publish
 test rsi,rsi
 jz .invalid
 mov rcx,rax
 shl rcx,2
 mov rdx,rsi
 mov rsi,[rdi+40]
 mov rdi,rdx
 rep movsq
.publish: mov [r8],rax
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_build_jobs
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,NEBOC_SCHED_MAX_WORKERS
 ja .invalid
 cmp qword [rdi+120],0
 jne .invalid
 mov [rdi],rsi
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_scheduler_report
 ; rdi=scheduler rsi=graph rdx=combined report.
 test rdx,rdx
 jz .invalid
 push rbx
 mov rbx,rdx
 push rsi
 mov rsi,rbx
 call neboc_scheduler_oversubscription_report
 pop rdi
 test eax,eax
 jne .done
 lea rsi,[rbx+NEBOC_OVER_REPORT_SIZE]
 call neboc_scheduler_critical_path
.done: pop rbx
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
