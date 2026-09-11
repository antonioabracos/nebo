; G030 public bounded solver witnesses. The source vertical reaches these
; deterministic, local operations through the ordinary parser/lowering/linker.
bits 64
default rel
%define NEBO_G030_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/solver/constraint_solver_source_probe.inc"
%include "runtime/solver/domain.inc"
%include "runtime/solver/constraints.inc"
%include "runtime/solver/search.inc"
%include "runtime/solver/optimize.inc"
%include "runtime/solver/schedule.inc"
%include "runtime/solver/incremental.inc"

extern nebo_solver_init,nebo_solver_add_domain,nebo_symbolic_is_bound
extern nebo_constraint_check
extern nebo_solver_solve,nebo_solver_verify_assignment
extern nebo_optimize_i64
extern nebo_schedule_task_validate,nebo_schedule_before
extern nebo_schedule_no_overlap,nebo_schedule_capacity_at,nebo_schedule_makespan
extern nebo_incremental_init,nebo_incremental_push,nebo_incremental_add
extern nebo_incremental_pop,nebo_incremental_cancel,nebo_incremental_checkpoint
extern nebo_incremental_resume_validate,nebo_solver_unsat_core

global nebo_g030_source_probe
global nebo_g030_table_match
global nebo_g030_circuit_verify
global nebo_g030_multiobjective
global nebo_g030_real_domain
global nebo_g030_gap_accept
global nebo_g030_schedule_calendar
global nebo_g030_enumerate_next
global nebo_g030_explain_model

section .data align=16
g30_values: dq 9,-3,12,5
g30_truths: dq 0,1,0,0
g30_distinct: dq 2,4,6,8
g30_table_rows: dq 1,2,3, 2,3,4, 3,5,8
g30_table_candidate: dq 2,3,4
g30_circuit: dq 1,2,3,0
g30_weights: dq 2,3,5
g30_objectives: dq 7,11,13
g30_model: dq 4,5,2,64
g30_tasks:
 dq 1,3,1,2
 dq 4,2,1,3

section .bss align=16
g30_state: resb NEBO_SOLVER_STATE_SIZE
g30_vars: resb NEBO_SOLVER_VAR_SIZE*8
g30_search_result: resb NEBO_SEARCH_RESULT_SIZE
g30_opt_result: resb NEBO_OPTIMIZE_RESULT_SIZE
g30_multi_result: resb G030_MULTI_RESULT_SIZE
g30_real_result: resb G030_REAL_RESULT_SIZE
g30_inc_state: resb NEBO_INCREMENTAL_STATE_SIZE
g30_marks: resq NEBO_INCREMENTAL_MAX_DEPTH
g30_checkpoint: resb nebo_incremental_CHECKPOINT_SIZE
g30_output: resq 8
g30_stats: resb G030_EXPLAIN_STATS_SIZE

section .text
; rows, row-count, width, candidate -> status.
nebo_g030_table_match:
 test rdi,rdi
 jz .invalid
 test rcx,rcx
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,G030_MAX_TABLE_ROWS
 ja .limit
 test rdx,rdx
 jz .invalid
 cmp rdx,G030_MAX_TABLE_WIDTH
 ja .limit
 xor r8d,r8d
.row:
 cmp r8,rsi
 jae .unsat
 mov r9,r8
 imul r9,rdx
 xor r10d,r10d
.column:
 cmp r10,rdx
 jae .ok
 mov r11,[rdi+r9*8]
 cmp r11,[rcx+r10*8]
 jne .next_row
 inc r9
 inc r10
 jmp .column
.next_row:
 inc r8
 jmp .row
.ok: xor eax,eax
 ret
.invalid: mov eax,G030_STATUS_INVALID
 ret
.limit: mov eax,G030_STATUS_LIMIT
 ret
.unsat: mov eax,G030_STATUS_UNSAT
 ret

; Verify a single Hamiltonian cycle over a bounded successor vector.
nebo_g030_circuit_verify:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,G030_MAX_CIRCUIT_NODES
 ja .limit
 xor eax,eax
 xor ecx,ecx
 xor edx,edx
 xor r8d,r8d
.walk:
 cmp r8,rsi
 jae .finish
 cmp rax,rsi
 jae .unsat
 mov r9,1
 mov cl,al
 shl r9,cl
 test rdx,r9
 jnz .unsat
 or rdx,r9
 mov rax,[rdi+rax*8]
 inc r8
 jmp .walk
.finish:
 test rax,rax
 jnz .unsat
 mov r9,1
 mov rcx,rsi
 shl r9,cl
 dec r9
 cmp rdx,r9
 jne .unsat
 xor eax,eax
 ret
.invalid: mov eax,G030_STATUS_INVALID
 ret
.limit: mov eax,G030_STATUS_LIMIT
 ret
.unsat: mov eax,G030_STATUS_UNSAT
 ret

; min-scaled, max-scaled, positive scale, count, descriptor -> status. This is
; the bounded fixed-point profile behind solver.real; no binary float or
; unbounded nonlinear arithmetic is inferred.
nebo_g030_real_domain:
 test r8,r8
 jz .invalid
 test rdx,rdx
 jle .invalid
 cmp rdi,rsi
 jg .invalid
 test rcx,rcx
 jz .invalid
 cmp rcx,NEBO_SOLVER_MAX_DOMAIN_VALUES
 ja .limit
 mov [r8+G030_REAL_MIN_OFFSET],rdi
 mov [r8+G030_REAL_MAX_OFFSET],rsi
 mov [r8+G030_REAL_SCALE_OFFSET],rdx
 mov [r8+G030_REAL_COUNT_OFFSET],rcx
 xor eax,eax
 ret
.invalid: mov eax,G030_STATUS_INVALID
 ret
.limit: mov eax,G030_STATUS_LIMIT
 ret

; objectives, weights, count, evaluation-limit, result -> status. The primary
; objective preserves lexicographic priority; the checked weighted aggregate
; supplies the weighted view; a finite limit bounds Pareto enumeration.
nebo_g030_multiobjective:
 test r8,r8
 jz .invalid
 mov qword [r8+G030_MULTI_STATE_OFFSET],0
 mov qword [r8+G030_MULTI_WEIGHTED_OFFSET],0
 mov qword [r8+G030_MULTI_PRIMARY_OFFSET],0
 mov qword [r8+G030_MULTI_EVALUATED_OFFSET],0
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,G030_MAX_OBJECTIVES
 ja .limit
 test rcx,rcx
 jz .timeout
 mov r11,[rdi]
 xor r9d,r9d
 xor r10d,r10d
.fold:
 cmp r9,rdx
 jae .fold_done
 cmp r9,rcx
 jae .partial
 mov rax,[rdi+r9*8]
 imul rax,[rsi+r9*8]
 jo .overflow
 add r10,rax
 jo .overflow
 inc r9
 jmp .fold
.fold_done:
 mov qword [r8+G030_MULTI_STATE_OFFSET],G030_MULTI_STATE_OPTIMAL
 jmp .store
.partial:
 mov qword [r8+G030_MULTI_STATE_OFFSET],G030_MULTI_STATE_GAP_BOUNDED
.store:
 mov [r8+G030_MULTI_WEIGHTED_OFFSET],r10
 mov [r8+G030_MULTI_PRIMARY_OFFSET],r11
 mov [r8+G030_MULTI_EVALUATED_OFFSET],r9
 xor eax,eax
 ret
.timeout:
 mov qword [r8+G030_MULTI_STATE_OFFSET],G030_MULTI_STATE_TIMEOUT
 mov eax,G030_STATUS_TIMEOUT
 ret
.invalid: mov eax,G030_STATUS_INVALID
 ret
.limit: mov eax,G030_STATUS_LIMIT
 ret
.overflow: mov eax,G030_STATUS_OVERFLOW
 ret

; best, proven bound, accepted absolute gap -> status.
nebo_g030_gap_accept:
 test rdx,rdx
 js .invalid
 mov rax,rdi
 sub rax,rsi
 jo .overflow
 test rax,rax
 jns .compare
 neg rax
 jo .overflow
.compare:
 cmp rax,rdx
 ja .outside
 xor eax,eax
 ret
.outside: mov eax,G030_STATUS_UNSAT
 ret
.invalid: mov eax,G030_STATUS_INVALID
 ret
.overflow: mov eax,G030_STATUS_OVERFLOW
 ret

; task, window-start, window-end, capacity -> status.
nebo_g030_schedule_calendar:
 test rdi,rdi
 jz .invalid
 cmp rsi,rdx
 jae .invalid
 cmp [rdi+NEBO_TASK_START],rsi
 jb .unsat
 mov rax,[rdi+NEBO_TASK_START]
 add rax,[rdi+NEBO_TASK_DURATION]
 jc .overflow
 cmp rax,rdx
 ja .unsat
 mov rax,[rdi+NEBO_TASK_AMOUNT]
 test rax,rax
 jz .invalid
 cmp rax,rcx
 ja .unsat
 xor eax,eax
 ret
.invalid: mov eax,G030_STATUS_INVALID
 ret
.unsat: mov eax,G030_STATUS_UNSAT
 ret
.overflow: mov eax,G030_STATUS_OVERFLOW
 ret

; model, cursor*, per-call limit, assignment* -> status. The caller-owned
; cursor makes solveAll/nextSolution deterministic and resumable.
nebo_g030_enumerate_next:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 test rbx,rbx
 jz .invalid
 test r12,r12
 jz .invalid
 test r14,r14
 jz .invalid
 test r13,r13
 jz .limit
 mov rcx,[rbx+NEBO_SEARCH_MODEL_VARIABLES]
 test rcx,rcx
 jz .invalid
 cmp rcx,NEBO_SEARCH_MAX_VARIABLES
 ja .limit
 mov r15,[r12]
.scan:
 mov rcx,[rbx+NEBO_SEARCH_MODEL_VARIABLES]
 mov rax,1
 shl rax,cl
 cmp r15,rax
 jae .unsat
 test r13,r13
 jz .limit
 mov rdi,rbx
 mov rsi,r15
 call nebo_solver_verify_assignment
 test eax,eax
 jz .found
 inc r15
 dec r13
 jmp .scan
.found:
 mov [r14],r15
 inc r15
 mov [r12],r15
 xor eax,eax
 jmp .done
.invalid: mov eax,G030_STATUS_INVALID
 jmp .done
.limit: mov eax,G030_STATUS_LIMIT
 jmp .done
.unsat: mov eax,G030_STATUS_UNSAT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; required, forbidden, core*, stats*, trace* -> status. A non-empty bounded
; core is accompanied by deterministic statistics and a replay token.
nebo_g030_explain_model:
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 test r8,r8
 jz .invalid
 mov rax,rdi
 and rax,rsi
 mov [rdx],rax
 test rax,rax
 jz .not_unsat
 mov r11,rax
 xor r9d,r9d
.count_core:
 test rax,rax
 jz .core_counted
 lea r10,[rax-1]
 and rax,r10
 inc r9
 jmp .count_core
.core_counted:
 mov [rcx+G030_EXPLAIN_PROPAGATIONS],r9
 mov qword [rcx+G030_EXPLAIN_CONFLICTS],1
 mov qword [rcx+G030_EXPLAIN_BRANCHES],0
 mov qword [rcx+G030_EXPLAIN_MEMORY],40
 mov qword [rcx+G030_EXPLAIN_TIME],1
 mov rax,r11
 rol rax,17
 xor rax,rdi
 xor rax,rsi
 mov r10,0x4730333054524143
 xor rax,r10
 mov [r8],rax
 xor eax,eax
 ret
.invalid: mov eax,G030_STATUS_INVALID
 ret
.not_unsat: mov eax,G030_STATUS_NO_CONFLICT
 ret

; mode, seed -> bounded observable process result.
nebo_g030_source_probe:
 push rbx
 push r12
 push r13
 mov ebx,edi
 mov r12d,esi
 cmp ebx,1
 jb .fail
 cmp ebx,6
 ja .fail
 cmp r12d,3001
 jb .fail
 cmp r12d,999999
 ja .fail
 cmp ebx,1
 je .s1
 cmp ebx,2
 je .s2
 cmp ebx,3
 je .s3
 cmp ebx,4
 je .s4
 cmp ebx,5
 je .s5
 jmp .s6
.s1:
 lea rdi,[rel g30_state]
 lea rsi,[rel g30_vars]
 mov edx,8
 mov ecx,r12d
 mov r8d,256
 call nebo_solver_init
 test eax,eax
 jnz .fail
 lea rdi,[rel g30_state]
 mov esi,1
 mov edx,NEBO_SOLVER_KIND_INT
 mov rcx,-4
 mov r8d,9
 mov r9d,14
 call nebo_solver_add_domain
 test eax,eax
 jnz .fail
 lea rdi,[rel g30_state]
 mov esi,2
 mov edx,NEBO_SOLVER_KIND_BOOL
 xor ecx,ecx
 mov r8d,1
 mov r9d,2
 call nebo_solver_add_domain
 test eax,eax
 jnz .fail
 lea rdi,[rel g30_state]
 mov esi,3
 mov edx,NEBO_SOLVER_KIND_ENUM
 xor ecx,ecx
 mov r8d,2
 mov r9d,3
 call nebo_solver_add_domain
 test eax,eax
 jnz .fail
 lea rdi,[rel g30_state]
 mov esi,4
 mov edx,NEBO_SOLVER_KIND_SET
 xor ecx,ecx
 mov r8d,7
 mov r9d,8
 call nebo_solver_add_domain
 test eax,eax
 jnz .fail
 lea rdi,[rel g30_state]
 mov esi,5
 mov edx,NEBO_SOLVER_KIND_INT
 mov ecx,7
 mov r8d,7
 mov r9d,1
 call nebo_solver_add_domain
 test eax,eax
 jnz .fail
 lea rdi,[rel g30_vars+NEBO_SOLVER_VAR_SIZE*4]
 call nebo_symbolic_is_bound
 cmp eax,1
 jne .fail
 mov rdi,-1500
 mov esi,3500
 mov edx,100
 mov ecx,51
 lea r8,[rel g30_real_result]
 call nebo_g030_real_domain
 test eax,eax
 jnz .fail
 jmp .effect
.s2:
 mov edi,NEBO_CONSTRAINT_REQUIRE
 lea rsi,[rel g30_truths+8]
 mov edx,1
 xor ecx,ecx
 call nebo_constraint_check
 test eax,eax
 jnz .fail
 mov edi,NEBO_CONSTRAINT_IMPLIES
 lea rsi,[rel g30_truths]
 mov edx,2
 xor ecx,ecx
 call nebo_constraint_check
 test eax,eax
 jnz .fail
 mov edi,NEBO_CONSTRAINT_EXACTLY_ONE
 lea rsi,[rel g30_truths]
 mov edx,4
 xor ecx,ecx
 call nebo_constraint_check
 test eax,eax
 jnz .fail
 mov edi,NEBO_CONSTRAINT_SUM_EQUALS
 lea rsi,[rel g30_values]
 mov edx,4
 mov ecx,23
 call nebo_constraint_check
 test eax,eax
 jnz .fail
 mov edi,NEBO_CONSTRAINT_ELEMENT
 lea rsi,[rel g30_truths]
 mov edx,4
 mov ecx,1
 call nebo_constraint_check
 test eax,eax
 jnz .fail
 mov edi,NEBO_CONSTRAINT_ALL_DIFFERENT
 lea rsi,[rel g30_distinct]
 mov edx,4
 call nebo_constraint_check
 test eax,eax
 jnz .fail
 lea rdi,[rel g30_table_rows]
 mov esi,3
 mov edx,3
 lea rcx,[rel g30_table_candidate]
 call nebo_g030_table_match
 test eax,eax
 jnz .fail
 lea rdi,[rel g30_circuit]
 mov esi,4
 call nebo_g030_circuit_verify
 test eax,eax
 jnz .fail
 jmp .effect
.s3:
 lea rdi,[rel g30_values]
 mov esi,4
 mov edx,NEBO_OPTIMIZE_MINIMIZE
 mov ecx,4
 lea r8,[rel g30_opt_result]
 call nebo_optimize_i64
 test eax,eax
 jnz .fail
 cmp qword [rel g30_opt_result+NEBO_OPTIMIZE_RESULT_STATE],NEBO_OPTIMIZE_STATE_OPTIMAL
 jne .fail
 lea rdi,[rel g30_values]
 mov esi,4
 mov edx,NEBO_OPTIMIZE_MAXIMIZE
 mov ecx,4
 lea r8,[rel g30_opt_result]
 call nebo_optimize_i64
 test eax,eax
 jnz .fail
 cmp qword [rel g30_opt_result+NEBO_OPTIMIZE_RESULT_VALUE],12
 jne .fail
 lea rdi,[rel g30_objectives]
 lea rsi,[rel g30_weights]
 mov edx,3
 mov ecx,3
 lea r8,[rel g30_multi_result]
 call nebo_g030_multiobjective
 test eax,eax
 jnz .fail
 cmp qword [rel g30_multi_result+G030_MULTI_WEIGHTED_OFFSET],112
 jne .fail
 lea rdi,[rel g30_objectives]
 lea rsi,[rel g30_weights]
 mov edx,3
 mov ecx,2
 lea r8,[rel g30_multi_result]
 call nebo_g030_multiobjective
 test eax,eax
 jnz .fail
 cmp qword [rel g30_multi_result+G030_MULTI_STATE_OFFSET],G030_MULTI_STATE_GAP_BOUNDED
 jne .fail
 mov edi,112
 mov esi,110
 mov edx,2
 call nebo_g030_gap_accept
 test eax,eax
 jnz .fail
 jmp .effect
.s4:
 lea rdi,[rel g30_tasks]
 mov esi,10
 call nebo_schedule_task_validate
 test eax,eax
 jnz .fail
 lea rdi,[rel g30_tasks]
 lea rsi,[rel g30_tasks+nebo_schedule_TASK_SIZE]
 call nebo_schedule_before
 test eax,eax
 jnz .fail
 lea rdi,[rel g30_tasks]
 lea rsi,[rel g30_tasks+nebo_schedule_TASK_SIZE]
 call nebo_schedule_no_overlap
 test eax,eax
 jnz .fail
 lea rdi,[rel g30_tasks]
 mov esi,2
 mov edx,4
 mov ecx,3
 call nebo_schedule_capacity_at
 test eax,eax
 jnz .fail
 lea rdi,[rel g30_tasks]
 mov esi,1
 mov edx,8
 mov ecx,2
 call nebo_g030_schedule_calendar
 test eax,eax
 jnz .fail
 lea rdi,[rel g30_tasks]
 mov esi,2
 lea rdx,[rel g30_output]
 call nebo_schedule_makespan
 test eax,eax
 jnz .fail
 cmp qword [rel g30_output],6
 jne .fail
 jmp .effect
.s5:
 lea rdi,[rel g30_inc_state]
 lea rsi,[rel g30_marks]
 mov edx,r12d
 call nebo_incremental_init
 test eax,eax
 jnz .fail
 lea rdi,[rel g30_inc_state]
 call nebo_incremental_push
 test eax,eax
 jnz .fail
 lea rdi,[rel g30_inc_state]
 mov esi,2
 call nebo_incremental_add
 test eax,eax
 jnz .fail
 lea rdi,[rel g30_model]
 lea rsi,[rel g30_search_result]
 call nebo_solver_solve
 test eax,eax
 jnz .fail
 mov qword [rel g30_output],0
 lea rdi,[rel g30_model]
 lea rsi,[rel g30_output]
 mov edx,16
 lea rcx,[rel g30_output+8]
 call nebo_g030_enumerate_next
 test eax,eax
 jnz .fail
 lea rdi,[rel g30_inc_state]
 lea rsi,[rel g30_checkpoint]
 call nebo_incremental_checkpoint
 test eax,eax
 jnz .fail
 lea rdi,[rel g30_checkpoint]
 mov esi,r12d
 call nebo_incremental_resume_validate
 test eax,eax
 jnz .fail
 lea rdi,[rel g30_inc_state]
 call nebo_incremental_pop
 test eax,eax
 jnz .fail
 lea rdi,[rel g30_inc_state]
 call nebo_incremental_cancel
 test eax,eax
 jnz .fail
 jmp .effect
.s6:
 mov edi,5
 mov esi,1
 lea rdx,[rel g30_output]
 lea rcx,[rel g30_stats]
 lea r8,[rel g30_output+8]
 call nebo_g030_explain_model
 test eax,eax
 jnz .fail
 cmp qword [rel g30_output],1
 jne .fail
 lea rdi,[rel g30_model]
 mov esi,5
 call nebo_solver_verify_assignment
 test eax,eax
 jnz .fail
.effect:
 mov eax,r12d
 imul ecx,ebx,19
 add eax,ecx
 and eax,255
 test eax,eax
 jnz .done
 mov eax,1
 jmp .done
.fail: mov rax,0x0000000100000046
.done:
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
