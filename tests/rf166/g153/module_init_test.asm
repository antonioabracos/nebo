bits 64
default rel
%include "compiler/semantic/modules/module_init.inc"
%include "compiler/support/status/status_codes.inc"

global _start
extern neboc_pure_constants
extern neboc_module_init_plan_new
extern neboc_init_add_pure_constant
extern neboc_init_topological_order
extern neboc_init_required_effects
extern neboc_init_required_capabilities
extern neboc_module_init_effects
extern neboc_init_detect_cycles
extern neboc_init_execute_once
extern neboc_init_rollback
extern neboc_init_cleanup
extern neboc_init_report
extern neboc_module_init_diagnostic
extern neboc_module_init_atomic
extern neboc_module_startup

section .data
align 8
constant_values: dq 3,5,7
; id, dependencies, kind, effects, capabilities, value, SymbolId, reserved
nodes:
 dq 30,0,NEBOC_INIT_KIND_PURE,0,0,11,101,0
 dq 20,1,NEBOC_INIT_KIND_RUNTIME,1,1,13,102,0
 dq 10,2,NEBOC_INIT_KIND_RUNTIME,2,2,17,103,0
; Same graph in a different input enumeration. Dependency bits are remapped.
nodes_permuted:
 dq 10,4,NEBOC_INIT_KIND_RUNTIME,2,2,17,103,0
 dq 30,0,NEBOC_INIT_KIND_PURE,0,0,19,101,0
 dq 20,2,NEBOC_INIT_KIND_RUNTIME,1,1,13,102,0
cycle_nodes:
 dq 7,2,NEBOC_INIT_KIND_PURE,0,0,23,201,0
 dq 5,1,NEBOC_INIT_KIND_PURE,0,0,29,202,0
rejected_node:
 dq 9,0,NEBOC_INIT_KIND_REJECTED,4,8,31,301,0

section .bss
align 8
plan: resb NEBOC_INIT_PLAN_SIZE
plan_permuted: resb NEBOC_INIT_PLAN_SIZE
cycle_plan: resb NEBOC_INIT_PLAN_SIZE
rejected_plan: resb NEBOC_INIT_PLAN_SIZE
state: resb NEBOC_INIT_STATE_SIZE
failure_state: resb NEBOC_INIT_STATE_SIZE
failure_first_state: resb NEBOC_INIT_STATE_SIZE
capability_state: resb NEBOC_INIT_STATE_SIZE
rejected_state: resb NEBOC_INIT_STATE_SIZE
legacy_states: resq 3
order: resq NEBOC_INIT_MAX
cycle_ids: resq NEBOC_INIT_MAX
cycle_count: resq 1
scalar: resq 1
report: resb NEBOC_INIT_REPORT_SIZE
observed: resq 12

section .text
_start:
 ; Invalid pointers and empty plans are rejected before mutation.
 xor edi,edi
 mov esi,3
 mov edx,10
 lea rcx,[rel plan]
 call neboc_module_init_plan_new
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 lea rdi,[rel nodes]
 xor esi,esi
 mov edx,10
 lea rcx,[rel plan]
 call neboc_module_init_plan_new
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail

 ; Pure compile-time constant evaluation is an observed value, not existence.
 lea rdi,[rel constant_values]
 mov esi,3
 lea rdx,[rel scalar]
 call neboc_pure_constants
 test eax,eax
 jnz .fail
 cmp qword [rel scalar],15
 jne .fail

 lea rdi,[rel nodes]
 mov esi,3
 mov edx,10
 lea rcx,[rel plan]
 call neboc_module_init_plan_new
 test eax,eax
 jnz .fail
 lea rdi,[rel plan]
 mov esi,101
 mov edx,19
 call neboc_init_add_pure_constant
 test eax,eax
 jnz .fail
 cmp qword [rel nodes+NEBOC_INIT_NODE_VALUE],19
 jne .fail

 lea rdi,[rel plan]
 lea rsi,[rel order]
 mov edx,NEBOC_INIT_MAX
 call neboc_init_topological_order
 test eax,eax
 jnz .fail
 cmp qword [rel order],0
 jne .fail
 cmp qword [rel order+8],1
 jne .fail
 cmp qword [rel order+16],2
 jne .fail

 ; Equivalent node enumeration has the same ordered ModuleIds and digest.
 lea rdi,[rel nodes_permuted]
 mov esi,3
 mov edx,10
 lea rcx,[rel plan_permuted]
 call neboc_module_init_plan_new
 test eax,eax
 jnz .fail
 mov rax,[rel plan+NEBOC_INIT_PLAN_DIGEST]
 cmp rax,[rel plan_permuted+NEBOC_INIT_PLAN_DIGEST]
 jne .fail
 cmp qword [rel plan_permuted+NEBOC_INIT_PLAN_ORDER],1
 jne .fail
 cmp qword [rel plan_permuted+NEBOC_INIT_PLAN_ORDER+8],2
 jne .fail
 cmp qword [rel plan_permuted+NEBOC_INIT_PLAN_ORDER+16],0
 jne .fail

 lea rdi,[rel plan]
 lea rsi,[rel scalar]
 call neboc_init_required_effects
 test eax,eax
 jnz .fail
 cmp qword [rel scalar],3
 jne .fail
 mov qword [rel observed+24],3
 lea rdi,[rel plan]
 lea rsi,[rel scalar]
 call neboc_init_required_capabilities
 test eax,eax
 jnz .fail
 cmp qword [rel scalar],3
 jne .fail
 mov qword [rel observed+32],3
 mov edi,3
 mov esi,3
 lea rdx,[rel scalar]
 call neboc_module_init_effects
 test eax,eax
 jnz .fail
 mov edi,3
 mov esi,1
 lea rdx,[rel scalar]
 call neboc_module_init_effects
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail

 lea rdi,[rel plan]
 lea rsi,[rel report]
 call neboc_init_report
 test eax,eax
 jnz .fail
 cmp qword [rel report+NEBOC_INIT_REPORT_TOTAL],3
 jne .fail
 cmp qword [rel report+NEBOC_INIT_REPORT_PURE],1
 jne .fail
 cmp qword [rel report+NEBOC_INIT_REPORT_RUNTIME],2
 jne .fail
 cmp qword [rel report+NEBOC_INIT_REPORT_REJECTED],0
 jne .fail

 ; Startup executes runtime nodes once. Pure metadata becomes READY without
 ; executing user code, and repeated execute/cleanup are no-ops.
 mov qword [rel state+NEBOC_INIT_STATE_GRANTED_CAPABILITIES],3
 lea rdi,[rel plan]
 lea rsi,[rel state]
 mov rdx,-1
 call neboc_module_startup
 test eax,eax
 jnz .fail
 cmp qword [rel state+NEBOC_INIT_STATE_READY_COUNT],3
 jne .fail
 cmp qword [rel state+NEBOC_INIT_STATE_EXECUTE_COUNTS],0
 jne .fail
 cmp qword [rel state+NEBOC_INIT_STATE_EXECUTE_COUNTS+8],1
 jne .fail
 cmp qword [rel state+NEBOC_INIT_STATE_EXECUTE_COUNTS+16],1
 jne .fail
 lea rdi,[rel plan]
 lea rsi,[rel state]
 mov rdx,-1
 call neboc_init_execute_once
 test eax,eax
 jnz .fail
 cmp qword [rel state+NEBOC_INIT_STATE_EXECUTE_COUNTS+8],1
 jne .fail
 lea rdi,[rel plan]
 lea rsi,[rel state]
 call neboc_init_cleanup
 test eax,eax
 jnz .fail
 lea rdi,[rel plan]
 lea rsi,[rel state]
 call neboc_init_cleanup
 test eax,eax
 jnz .fail
 cmp qword [rel state+NEBOC_INIT_STATE_CLEANUP_COUNTS+8],1
 jne .fail
 cmp qword [rel state+NEBOC_INIT_STATE_CLEANUP_COUNTS+16],1
 jne .fail
 cmp qword [rel state+NEBOC_INIT_STATE_CLEANUP_ORDER_COUNT],2
 jne .fail
 cmp qword [rel state+NEBOC_INIT_STATE_CLEANUP_ORDER],2
 jne .fail
 cmp qword [rel state+NEBOC_INIT_STATE_CLEANUP_ORDER+8],1
 jne .fail
 lea rdi,[rel plan]
 lea rsi,[rel state]
 call neboc_init_rollback
 test eax,eax
 jnz .fail
 lea rdi,[rel plan]
 lea rsi,[rel state]
 mov rdx,-1
 call neboc_init_execute_once
 test eax,eax
 jnz .fail
 cmp qword [rel state+NEBOC_INIT_STATE_EXECUTE_COUNTS+8],1
 jne .fail
 cmp qword [rel state+NEBOC_INIT_STATE_EXECUTE_COUNTS+16],1
 jne .fail

 ; Failure at the final runtime node rolls back the earlier runtime node and
 ; publishes zero READY nodes. Retrying a failed state is fail-closed.
 mov qword [rel failure_state+NEBOC_INIT_STATE_GRANTED_CAPABILITIES],3
 lea rdi,[rel plan]
 lea rsi,[rel failure_state]
 mov edx,2
 call neboc_init_execute_once
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 cmp qword [rel failure_state+NEBOC_INIT_STATE_READY_COUNT],0
 jne .fail
 cmp qword [rel failure_state+NEBOC_INIT_STATE_EXECUTE_COUNTS+8],1
 jne .fail
 cmp qword [rel failure_state+NEBOC_INIT_STATE_EXECUTE_COUNTS+16],0
 jne .fail
 cmp qword [rel failure_state+NEBOC_INIT_STATE_CLEANUP_COUNTS+8],1
 jne .fail
 cmp qword [rel failure_state+NEBOC_INIT_STATE_CLEANUP_ORDER_COUNT],1
 jne .fail
 cmp qword [rel failure_state+NEBOC_INIT_STATE_CLEANUP_ORDER],1
 jne .fail
 lea rdi,[rel plan]
 lea rsi,[rel failure_state]
 mov rdx,-1
 call neboc_init_execute_once
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail

 ; The other runtime node is also an independently injected failure point.
 mov qword [rel failure_first_state+NEBOC_INIT_STATE_GRANTED_CAPABILITIES],3
 lea rdi,[rel plan]
 lea rsi,[rel failure_first_state]
 mov edx,1
 call neboc_init_execute_once
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 cmp qword [rel failure_first_state+NEBOC_INIT_STATE_READY_COUNT],0
 jne .fail
 cmp qword [rel failure_first_state+NEBOC_INIT_STATE_EXECUTE_COUNTS+8],0
 jne .fail
 cmp qword [rel failure_first_state+NEBOC_INIT_STATE_CLEANUP_ORDER_COUNT],0
 jne .fail

 ; Capability gaps fail before any node state or side effect is mutated.
 mov qword [rel capability_state+NEBOC_INIT_STATE_GRANTED_CAPABILITIES],1
 lea rdi,[rel plan]
 lea rsi,[rel capability_state]
 mov rdx,-1
 call neboc_init_execute_once
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 cmp qword [rel capability_state+NEBOC_INIT_STATE_FLAGS],0
 jne .fail
 cmp qword [rel capability_state+NEBOC_INIT_STATE_READY_COUNT],0
 jne .fail

 ; Cycles are represented canonically and rejected before startup.
 lea rdi,[rel cycle_nodes]
 mov esi,2
 mov edx,7
 lea rcx,[rel cycle_plan]
 call neboc_module_init_plan_new
 test eax,eax
 jnz .fail
 lea rdi,[rel cycle_plan]
 lea rsi,[rel order]
 mov edx,NEBOC_INIT_MAX
 call neboc_init_topological_order
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 lea rdi,[rel cycle_plan]
 lea rsi,[rel cycle_ids]
 mov edx,NEBOC_INIT_MAX
 lea rcx,[rel cycle_count]
 call neboc_init_detect_cycles
 test eax,eax
 jnz .fail
 cmp qword [rel cycle_count],2
 jne .fail
 cmp qword [rel cycle_ids],5
 jne .fail
 cmp qword [rel cycle_ids+8],7
 jne .fail

 mov edi,NEBOC_INIT_REASON_CYCLE
 lea rsi,[rel scalar]
 call neboc_module_init_diagnostic
 test eax,eax
 jnz .fail
 cmp qword [rel scalar],NEBOC_INIT_DIAG_BASE+NEBOC_INIT_REASON_CYCLE
 jne .fail

 ; Hidden/rejected initialization and over-limit plans fail closed.
 lea rdi,[rel rejected_node]
 mov esi,1
 mov edx,9
 lea rcx,[rel rejected_plan]
 call neboc_module_init_plan_new
 test eax,eax
 jnz .fail
 mov qword [rel rejected_state+NEBOC_INIT_STATE_GRANTED_CAPABILITIES],-1
 lea rdi,[rel rejected_plan]
 lea rsi,[rel rejected_state]
 mov rdx,-1
 call neboc_init_execute_once
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 lea rdi,[rel nodes]
 mov esi,NEBOC_INIT_MAX+1
 mov edx,10
 lea rcx,[rel plan_permuted]
 call neboc_module_init_plan_new
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail

 ; Compatibility atomic publication remains all-or-zero and bounded.
 lea rdi,[rel legacy_states]
 mov esi,3
 mov edx,3
 call neboc_module_init_atomic
 test eax,eax
 jnz .fail
 cmp qword [rel legacy_states+16],NEBOC_INIT_READY
 jne .fail

 ; Emit a binary observation consumed by an independent Python oracle.
 mov qword [rel observed],30
 mov qword [rel observed+8],20
 mov qword [rel observed+16],10
 mov qword [rel observed+40],1
 mov qword [rel observed+48],1
 mov qword [rel observed+56],1
 mov qword [rel observed+64],1
 mov qword [rel observed+72],5
 mov qword [rel observed+80],7
 mov qword [rel observed+88],NEBOC_INIT_DIAG_BASE+NEBOC_INIT_REASON_CYCLE
 mov eax,1
 mov edi,1
 lea rsi,[rel observed]
 mov edx,96
 syscall
 cmp rax,96
 jne .fail
 xor edi,edi
 jmp .exit
.fail:
 mov edi,1
.exit:
 mov eax,60
 syscall
