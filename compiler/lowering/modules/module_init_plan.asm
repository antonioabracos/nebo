bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/modules/module_init.inc"

section .text

; module_init_plan_new(nodes, count, target_module_id, out_plan) -> status
; The stable order is dependency-first and ties are broken by ModuleId, never
; source enumeration, object order, filesystem order, or linker order.
global neboc_module_init_plan
global neboc_module_init_plan_new
align 16
neboc_module_init_plan:
neboc_module_init_plan_new:
 cld
 test rdi,rdi
 jz .arg
 test rdi,7
 jnz .arg
 test rcx,rcx
 jz .arg
 test rcx,7
 jnz .arg
 test rsi,rsi
 jz .source
 cmp rsi,NEBOC_INIT_MAX
 ja .limit
 test rdx,rdx
 jz .source
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rdi,r15
 xor eax,eax
 mov ecx,NEBOC_INIT_PLAN_SIZE/8
 rep stosq
 mov [r15+NEBOC_INIT_PLAN_NODES],r12
 mov [r15+NEBOC_INIT_PLAN_COUNT],r13
 mov [r15+NEBOC_INIT_PLAN_CAPACITY],r13
 mov [r15+NEBOC_INIT_PLAN_TARGET],r14
 xor ebx,ebx
 xor ebp,ebp
.validate:
 cmp rbx,r13
 jae .order_begin
 mov rax,rbx
 shl rax,6
 lea r10,[r12+rax]
 mov rax,[r10+NEBOC_INIT_NODE_ID]
 test rax,rax
 jz .bad
 cmp rax,r14
 jne .target_next
 mov ebp,1
.target_next:
 mov rdx,[r10+NEBOC_INIT_NODE_DEPENDENCIES]
 mov ecx,r13d
 mov rax,1
 shl rax,cl
 dec rax
 not rax
 test rdx,rax
 jnz .bad
 mov rax,[r10+NEBOC_INIT_NODE_KIND]
 cmp rax,NEBOC_INIT_KIND_REJECTED
 ja .bad
 cmp rax,NEBOC_INIT_KIND_PURE
 jne .not_pure
 inc qword [r15+NEBOC_INIT_PLAN_PURE_COUNT]
 jmp .unique
.not_pure:
 cmp rax,NEBOC_INIT_KIND_RUNTIME
 jne .rejected
 inc qword [r15+NEBOC_INIT_PLAN_RUNTIME_COUNT]
 jmp .unique
.rejected:
 inc qword [r15+NEBOC_INIT_PLAN_REJECTED_COUNT]
.unique:
 lea r8,[rbx+1]
.unique_loop:
 cmp r8,r13
 jae .validate_next
 mov rax,r8
 shl rax,6
 mov rax,[r12+rax+NEBOC_INIT_NODE_ID]
 cmp rax,[r10+NEBOC_INIT_NODE_ID]
 je .bad
 inc r8
 jmp .unique_loop
.validate_next:
 inc rbx
 jmp .validate

.order_begin:
 test ebp,ebp
 jz .bad
 xor ebp,ebp
 xor ebx,ebx
 mov r11,1469598103934665603
 xor r11,r14
 imul r11,r11,16777619
.position:
 cmp rbx,r13
 jae .ordered
 mov r8,-1
 xor r9d,r9d
.candidate:
 cmp r9,r13
 jae .candidate_done
 bt rbp,r9
 jc .candidate_next
 mov rax,r9
 shl rax,6
 mov rdx,[r12+rax+NEBOC_INIT_NODE_DEPENDENCIES]
 mov rcx,rbp
 not rcx
 test rdx,rcx
 jnz .candidate_next
 cmp r8,-1
 je .choose
 mov rcx,r8
 shl rcx,6
 mov rdx,[r12+rax+NEBOC_INIT_NODE_ID]
 cmp rdx,[r12+rcx+NEBOC_INIT_NODE_ID]
 jae .candidate_next
.choose:
 mov r8,r9
.candidate_next:
 inc r9
 jmp .candidate
.candidate_done:
 cmp r8,-1
 je .cycle
 lea rax,[r15+NEBOC_INIT_PLAN_ORDER]
 mov [rax+rbx*8],r8
 bts rbp,r8
 ; Canonical node facts plus a commutative dependency-identity fold make the
 ; digest invariant under equivalent input-node permutations.
 mov rax,r8
 shl rax,6
 lea r10,[r12+rax]
 mov rax,[r10+NEBOC_INIT_NODE_ID]
 xor r11,rax
 imul r11,r11,16777619
 mov rax,[r10+NEBOC_INIT_NODE_KIND]
 xor r11,rax
 imul r11,r11,16777619
 mov rax,[r10+NEBOC_INIT_NODE_EFFECTS]
 xor r11,rax
 imul r11,r11,16777619
 mov rax,[r10+NEBOC_INIT_NODE_CAPABILITIES]
 xor r11,rax
 imul r11,r11,16777619
 mov rax,[r10+NEBOC_INIT_NODE_VALUE]
 xor r11,rax
 imul r11,r11,16777619
 mov rax,[r10+NEBOC_INIT_NODE_SYMBOL]
 xor r11,rax
 imul r11,r11,16777619
 xor edx,edx
 xor r9d,r9d
.dep_fold:
 cmp r9,r13
 jae .dep_done
 bt qword [r10+NEBOC_INIT_NODE_DEPENDENCIES],r9
 jnc .dep_next
 mov rax,r9
 shl rax,6
 xor rdx,[r12+rax+NEBOC_INIT_NODE_ID]
.dep_next:
 inc r9
 jmp .dep_fold
.dep_done:
 xor r11,rdx
 imul r11,r11,16777619
 inc rbx
 jmp .position
.ordered:
 mov [r15+NEBOC_INIT_PLAN_ORDER_COUNT],r13
 mov [r15+NEBOC_INIT_PLAN_DIGEST],r11
 or qword [r15+NEBOC_INIT_PLAN_FLAGS],NEBOC_INIT_PLAN_ORDERED
 xor eax,eax
 jmp .done
.cycle:
 mov rcx,r13
 mov rax,1
 shl rax,cl
 dec rax
 not rbp
 and rbp,rax
 mov [r15+NEBOC_INIT_PLAN_CYCLE_MASK],rbp
 mov [r15+NEBOC_INIT_PLAN_ORDER_COUNT],rbx
 or qword [r15+NEBOC_INIT_PLAN_FLAGS],NEBOC_INIT_PLAN_HAS_CYCLE
 xor eax,eax
 jmp .done
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; init.topologicalOrder(plan, out_indices, capacity) -> status
NEBOC_ABI_FUNCTION neboc_init_topological_order
 test rdi,rdi
 jz .topo_arg
 test rsi,rsi
 jz .topo_arg
 test qword [rdi+NEBOC_INIT_PLAN_FLAGS],NEBOC_INIT_PLAN_HAS_CYCLE
 jnz .topo_source
 test qword [rdi+NEBOC_INIT_PLAN_FLAGS],NEBOC_INIT_PLAN_ORDERED
 jz .topo_source
 mov rcx,[rdi+NEBOC_INIT_PLAN_COUNT]
 cmp rdx,rcx
 jb .topo_limit
 xor eax,eax
.topo_copy:
 cmp rax,rcx
 jae .topo_ok
 mov r8,[rdi+NEBOC_INIT_PLAN_ORDER+rax*8]
 mov [rsi+rax*8],r8
 inc rax
 jmp .topo_copy
.topo_ok:
 xor eax,eax
 ret
.topo_arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.topo_source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.topo_limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; init.detectCycles(plan, out_module_ids, capacity, out_count) -> status.
; The canonical blocked component is emitted by ModuleId order; acyclic plans
; emit zero records.
NEBOC_ABI_FUNCTION neboc_init_detect_cycles
 test rdi,rdi
 jz .cycle_arg
 test rcx,rcx
 jz .cycle_arg
 mov qword [rcx],0
 mov r8,[rdi+NEBOC_INIT_PLAN_CYCLE_MASK]
 test r8,r8
 jz .cycle_ok
 test rsi,rsi
 jz .cycle_arg
 push rbx
 push rbp
 push r12
 mov r12,[rdi+NEBOC_INIT_PLAN_NODES]
 xor ebx,ebx
.cycle_emit:
 test r8,r8
 jz .cycle_finish
 cmp rbx,rdx
 jae .cycle_pop_limit
 mov rbp,-1
 xor r9d,r9d
.cycle_pick:
 cmp r9,[rdi+NEBOC_INIT_PLAN_COUNT]
 jae .cycle_picked
 bt r8,r9
 jnc .cycle_pick_next
 cmp rbp,-1
 je .cycle_choose
 mov rax,r9
 shl rax,6
 mov r10,rbp
 shl r10,6
 mov rax,[r12+rax+NEBOC_INIT_NODE_ID]
 cmp rax,[r12+r10+NEBOC_INIT_NODE_ID]
 jae .cycle_pick_next
.cycle_choose:
 mov rbp,r9
.cycle_pick_next:
 inc r9
 jmp .cycle_pick
.cycle_picked:
 mov rax,rbp
 shl rax,6
 mov rax,[r12+rax+NEBOC_INIT_NODE_ID]
 mov [rsi+rbx*8],rax
 btr r8,rbp
 inc rbx
 jmp .cycle_emit
.cycle_finish:
 mov [rcx],rbx
 pop r12
 pop rbp
 pop rbx
.cycle_ok:
 xor eax,eax
 ret
.cycle_pop_limit:
 pop r12
 pop rbp
 pop rbx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
.cycle_arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; init.report(plan, out_report) -> status
NEBOC_ABI_FUNCTION neboc_init_report
 test rdi,rdi
 jz .report_arg
 test rsi,rsi
 jz .report_arg
 mov rax,[rdi+NEBOC_INIT_PLAN_COUNT]
 mov [rsi+NEBOC_INIT_REPORT_TOTAL],rax
 mov rax,[rdi+NEBOC_INIT_PLAN_PURE_COUNT]
 mov [rsi+NEBOC_INIT_REPORT_PURE],rax
 mov rax,[rdi+NEBOC_INIT_PLAN_RUNTIME_COUNT]
 mov [rsi+NEBOC_INIT_REPORT_RUNTIME],rax
 mov rax,[rdi+NEBOC_INIT_PLAN_REJECTED_COUNT]
 mov [rsi+NEBOC_INIT_REPORT_REJECTED],rax
 xor eax,eax
 xor edx,edx
 mov rcx,[rdi+NEBOC_INIT_PLAN_NODES]
 xor r8d,r8d
.report_masks:
 cmp r8,[rdi+NEBOC_INIT_PLAN_COUNT]
 jae .report_masks_done
 mov r9,r8
 shl r9,6
 or rax,[rcx+r9+NEBOC_INIT_NODE_EFFECTS]
 or rdx,[rcx+r9+NEBOC_INIT_NODE_CAPABILITIES]
 inc r8
 jmp .report_masks
.report_masks_done:
 mov [rsi+NEBOC_INIT_REPORT_EFFECTS],rax
 mov [rsi+NEBOC_INIT_REPORT_CAPABILITIES],rdx
 mov rax,[rdi+NEBOC_INIT_PLAN_DIGEST]
 mov [rsi+NEBOC_INIT_REPORT_DIGEST],rax
 mov rax,[rdi+NEBOC_INIT_PLAN_CYCLE_MASK]
 mov [rsi+NEBOC_INIT_REPORT_CYCLE_MASK],rax
 xor eax,eax
 ret
.report_arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
