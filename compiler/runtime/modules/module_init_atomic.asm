bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/modules/module_init.inc"

section .text

; Historical all-or-zero publication primitive, now bounded by the G153 node
; limit and retained for ABI compatibility.
NEBOC_ABI_FUNCTION neboc_module_init_atomic
 test rdi,rdi
 jz .atomic_arg
 test rsi,rsi
 jz .atomic_source
 cmp rsi,NEBOC_INIT_MAX
 ja .atomic_limit
 cmp rdx,rsi
 jb .atomic_rollback
 xor ecx,ecx
.atomic_commit:
 cmp rcx,rsi
 jae .atomic_ok
 mov qword [rdi+rcx*8],NEBOC_INIT_READY
 inc rcx
 jmp .atomic_commit
.atomic_rollback:
 xor ecx,ecx
.atomic_zero:
 cmp rcx,rsi
 jae .atomic_source
 mov qword [rdi+rcx*8],NEBOC_INIT_NOT_STARTED
 inc rcx
 jmp .atomic_zero
.atomic_ok:
 xor eax,eax
 ret
.atomic_arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.atomic_source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.atomic_limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; init.executeOnce(plan, runtime_state, failure_node_or_minus_one) -> status.
; No state is published until cycle/rejection/capability preflight completes.
NEBOC_ABI_FUNCTION neboc_init_execute_once
 test rdi,rdi
 jz .exec_arg
 test rsi,rsi
 jz .exec_arg
 test qword [rdi+NEBOC_INIT_PLAN_FLAGS],NEBOC_INIT_PLAN_HAS_CYCLE
 jnz .exec_source
 test qword [rdi+NEBOC_INIT_PLAN_FLAGS],NEBOC_INIT_PLAN_ORDERED
 jz .exec_source
 cmp qword [rdi+NEBOC_INIT_PLAN_REJECTED_COUNT],0
 jne .exec_source
 test qword [rsi+NEBOC_INIT_STATE_FLAGS],NEBOC_INIT_TERMINAL_FAILURE
 jnz .exec_source
 test qword [rsi+NEBOC_INIT_STATE_FLAGS],NEBOC_INIT_EXECUTED
 jnz .exec_ok
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
 mov r15,[r12+NEBOC_INIT_PLAN_NODES]
 xor eax,eax
 xor ecx,ecx
.caps:
 cmp rcx,[r12+NEBOC_INIT_PLAN_COUNT]
 jae .caps_done
 mov r8,rcx
 shl r8,6
 cmp qword [r15+r8+NEBOC_INIT_NODE_KIND],NEBOC_INIT_KIND_PURE
 je .caps_next
 or rax,[r15+r8+NEBOC_INIT_NODE_CAPABILITIES]
.caps_next:
 inc rcx
 jmp .caps
.caps_done:
 mov rcx,[r13+NEBOC_INIT_STATE_GRANTED_CAPABILITIES]
 not rcx
 test rax,rcx
 jnz .exec_preflight_fail
 xor ebx,ebx
.execute:
 cmp rbx,[r12+NEBOC_INIT_PLAN_COUNT]
 jae .execute_commit
 mov rbp,[r12+NEBOC_INIT_PLAN_ORDER+rbx*8]
 mov rax,rbp
 shl rax,6
 mov rcx,[r15+rax+NEBOC_INIT_NODE_KIND]
 mov qword [r13+rbp*8+NEBOC_INIT_STATE_NODE_STATES],NEBOC_INIT_RUNNING
 cmp rcx,NEBOC_INIT_KIND_PURE
 je .ready
 cmp rbp,r14
 je .injected_failure
 inc qword [r13+rbp*8+NEBOC_INIT_STATE_EXECUTE_COUNTS]
.ready:
 mov qword [r13+rbp*8+NEBOC_INIT_STATE_NODE_STATES],NEBOC_INIT_READY
 inc qword [r13+NEBOC_INIT_STATE_READY_COUNT]
 inc rbx
 jmp .execute
.execute_commit:
 or qword [r13+NEBOC_INIT_STATE_FLAGS],NEBOC_INIT_EXECUTED
 xor eax,eax
 jmp .exec_done
.injected_failure:
 mov qword [r13+rbp*8+NEBOC_INIT_STATE_NODE_STATES],NEBOC_INIT_FAILED
 mov [r13+NEBOC_INIT_STATE_FAILURE_NODE],rbp
.failure_reverse:
 test rbx,rbx
 jz .failure_cleared
 dec rbx
 mov rbp,[r12+NEBOC_INIT_PLAN_ORDER+rbx*8]
 mov rax,rbp
 shl rax,6
 cmp qword [r15+rax+NEBOC_INIT_NODE_KIND],NEBOC_INIT_KIND_RUNTIME
 jne .failure_reset
 mov rcx,[r13+rbp*8+NEBOC_INIT_STATE_EXECUTE_COUNTS]
 cmp rcx,[r13+rbp*8+NEBOC_INIT_STATE_CLEANUP_COUNTS]
 jbe .failure_reset
 inc qword [r13+rbp*8+NEBOC_INIT_STATE_CLEANUP_COUNTS]
 mov r8,[r13+NEBOC_INIT_STATE_CLEANUP_ORDER_COUNT]
 mov [r13+r8*8+NEBOC_INIT_STATE_CLEANUP_ORDER],rbp
 inc qword [r13+NEBOC_INIT_STATE_CLEANUP_ORDER_COUNT]
.failure_reset:
 mov qword [r13+rbp*8+NEBOC_INIT_STATE_NODE_STATES],NEBOC_INIT_NOT_STARTED
 jmp .failure_reverse
.failure_cleared:
 xor ecx,ecx
.failure_zero_states:
 cmp rcx,[r12+NEBOC_INIT_PLAN_COUNT]
 jae .failure_finish
 mov qword [r13+rcx*8+NEBOC_INIT_STATE_NODE_STATES],NEBOC_INIT_NOT_STARTED
 inc rcx
 jmp .failure_zero_states
.failure_finish:
 mov qword [r13+NEBOC_INIT_STATE_READY_COUNT],0
 or qword [r13+NEBOC_INIT_STATE_FLAGS],NEBOC_INIT_ROLLED_BACK|NEBOC_INIT_TERMINAL_FAILURE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .exec_done
.exec_preflight_fail:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.exec_done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret
.exec_ok:
 xor eax,eax
 ret
.exec_arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.exec_source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE

; init.rollback(plan, state) -> status. Idempotent and reverse-topological.
NEBOC_ABI_FUNCTION neboc_init_rollback
 test rdi,rdi
 jz .rollback_arg
 test rsi,rsi
 jz .rollback_arg
 test qword [rdi+NEBOC_INIT_PLAN_FLAGS],NEBOC_INIT_PLAN_HAS_CYCLE
 jnz .rollback_source
 test qword [rdi+NEBOC_INIT_PLAN_FLAGS],NEBOC_INIT_PLAN_ORDERED
 jz .rollback_source
 push rbx
 push rbp
 push r12
 mov r12,[rdi+NEBOC_INIT_PLAN_NODES]
 mov rbx,[rdi+NEBOC_INIT_PLAN_COUNT]
.rollback_reverse:
 test rbx,rbx
 jz .rollback_done
 dec rbx
 mov rbp,[rdi+NEBOC_INIT_PLAN_ORDER+rbx*8]
 mov rax,rbp
 shl rax,6
 cmp qword [r12+rax+NEBOC_INIT_NODE_KIND],NEBOC_INIT_KIND_RUNTIME
 jne .rollback_state
 mov rcx,[rsi+rbp*8+NEBOC_INIT_STATE_EXECUTE_COUNTS]
 cmp rcx,[rsi+rbp*8+NEBOC_INIT_STATE_CLEANUP_COUNTS]
 jbe .rollback_state
 inc qword [rsi+rbp*8+NEBOC_INIT_STATE_CLEANUP_COUNTS]
 mov r8,[rsi+NEBOC_INIT_STATE_CLEANUP_ORDER_COUNT]
 mov [rsi+r8*8+NEBOC_INIT_STATE_CLEANUP_ORDER],rbp
 inc qword [rsi+NEBOC_INIT_STATE_CLEANUP_ORDER_COUNT]
.rollback_state:
 mov qword [rsi+rbp*8+NEBOC_INIT_STATE_NODE_STATES],NEBOC_INIT_NOT_STARTED
 jmp .rollback_reverse
.rollback_done:
 mov qword [rsi+NEBOC_INIT_STATE_READY_COUNT],0
 ; Preserve EXECUTED: rollback cannot reopen an exactly-once initializer.
 or qword [rsi+NEBOC_INIT_STATE_FLAGS],NEBOC_INIT_ROLLED_BACK
 pop r12
 pop rbp
 pop rbx
 xor eax,eax
 ret
.rollback_arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.rollback_source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE

; init.cleanup(plan, state) -> status. Each executed runtime node is cleaned at
; most once; repeated cleanup is an observable no-op.
NEBOC_ABI_FUNCTION neboc_init_cleanup
 test rdi,rdi
 jz .cleanup_arg
 test rsi,rsi
 jz .cleanup_arg
 test qword [rdi+NEBOC_INIT_PLAN_FLAGS],NEBOC_INIT_PLAN_HAS_CYCLE
 jnz .cleanup_source
 test qword [rdi+NEBOC_INIT_PLAN_FLAGS],NEBOC_INIT_PLAN_ORDERED
 jz .cleanup_source
 test qword [rsi+NEBOC_INIT_STATE_FLAGS],NEBOC_INIT_CLEANUP_COMPLETE
 jnz .cleanup_ok
 push rbx
 push rbp
 push r12
 mov r12,[rdi+NEBOC_INIT_PLAN_NODES]
 mov rbx,[rdi+NEBOC_INIT_PLAN_COUNT]
.cleanup_reverse:
 test rbx,rbx
 jz .cleanup_done
 dec rbx
 mov rbp,[rdi+NEBOC_INIT_PLAN_ORDER+rbx*8]
 mov rax,rbp
 shl rax,6
 cmp qword [r12+rax+NEBOC_INIT_NODE_KIND],NEBOC_INIT_KIND_RUNTIME
 jne .cleanup_state
 mov rcx,[rsi+rbp*8+NEBOC_INIT_STATE_EXECUTE_COUNTS]
 cmp rcx,[rsi+rbp*8+NEBOC_INIT_STATE_CLEANUP_COUNTS]
 jbe .cleanup_state
 inc qword [rsi+rbp*8+NEBOC_INIT_STATE_CLEANUP_COUNTS]
 mov r8,[rsi+NEBOC_INIT_STATE_CLEANUP_ORDER_COUNT]
 mov [rsi+r8*8+NEBOC_INIT_STATE_CLEANUP_ORDER],rbp
 inc qword [rsi+NEBOC_INIT_STATE_CLEANUP_ORDER_COUNT]
.cleanup_state:
 cmp qword [rsi+rbp*8+NEBOC_INIT_STATE_NODE_STATES],NEBOC_INIT_READY
 jne .cleanup_next
 mov qword [rsi+rbp*8+NEBOC_INIT_STATE_NODE_STATES],NEBOC_INIT_CLEANED
.cleanup_next:
 jmp .cleanup_reverse
.cleanup_done:
 mov qword [rsi+NEBOC_INIT_STATE_READY_COUNT],0
 or qword [rsi+NEBOC_INIT_STATE_FLAGS],NEBOC_INIT_CLEANUP_COMPLETE
 pop r12
 pop rbp
 pop rbx
.cleanup_ok:
 xor eax,eax
 ret
.cleanup_arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.cleanup_source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
