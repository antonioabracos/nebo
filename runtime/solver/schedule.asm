; CONSOLE-VISUAL-DASHBOARD-E-PLOTS-F05 bounded interval scheduling predicates and reports.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/solver/schedule.inc"
section .text
NEBOC_ABI_FUNCTION nebo_schedule_task_validate
 ; task, horizon
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBO_TASK_DURATION]
 test rax,rax
 jz .invalid
 add rax,[rdi+NEBO_TASK_START]
 jc .overflow
 cmp rax,rsi
 ja .horizon
 cmp qword [rdi+NEBO_TASK_AMOUNT],0
 je .invalid
 xor eax,eax
 ret
.invalid: mov eax,NEBO_SCHEDULE_STATUS_INVALID
 ret
.overflow: mov eax,NEBO_SCHEDULE_STATUS_OVERFLOW
 ret
.horizon: mov eax,NEBO_SCHEDULE_STATUS_HORIZON
 ret

NEBOC_ABI_FUNCTION nebo_schedule_before
 ; first task, second task
 test rdi,rdi
 jz .invalid_before
 test rsi,rsi
 jz .invalid_before
 mov rax,[rdi+NEBO_TASK_START]
 add rax,[rdi+NEBO_TASK_DURATION]
 jc .overflow_before
 cmp rax,[rsi+NEBO_TASK_START]
 ja .conflict_before
 xor eax,eax
 ret
.invalid_before: mov eax,NEBO_SCHEDULE_STATUS_INVALID
 ret
.overflow_before: mov eax,NEBO_SCHEDULE_STATUS_OVERFLOW
 ret
.conflict_before: mov eax,NEBO_SCHEDULE_STATUS_CONFLICT
 ret

NEBOC_ABI_FUNCTION nebo_schedule_no_overlap
 test rdi,rdi
 jz .invalid_overlap
 test rsi,rsi
 jz .invalid_overlap
 mov rax,[rdi+NEBO_TASK_START]
 add rax,[rdi+NEBO_TASK_DURATION]
 jc .overflow_overlap
 cmp rax,[rsi+NEBO_TASK_START]
 jbe .ok_overlap
 mov rax,[rsi+NEBO_TASK_START]
 add rax,[rsi+NEBO_TASK_DURATION]
 jc .overflow_overlap
 cmp rax,[rdi+NEBO_TASK_START]
 jbe .ok_overlap
 mov eax,NEBO_SCHEDULE_STATUS_CONFLICT
 ret
.ok_overlap: xor eax,eax
 ret
.invalid_overlap: mov eax,NEBO_SCHEDULE_STATUS_INVALID
 ret
.overflow_overlap: mov eax,NEBO_SCHEDULE_STATUS_OVERFLOW
 ret

NEBOC_ABI_FUNCTION nebo_schedule_capacity_at
 ; tasks, count, time, capacity
 test rdi,rdi
 jz .invalid_capacity
 test rsi,rsi
 jz .invalid_capacity
 cmp rsi,NEBO_SCHEDULE_MAX_TASKS
 ja .limit_capacity
 xor eax,eax
 xor r8d,r8d
.capacity_loop:
 cmp rax,rsi
 jae .capacity_done
 mov r9,rax
 imul r9,nebo_schedule_TASK_SIZE
 cmp rdx,[rdi+r9+NEBO_TASK_START]
 jb .capacity_next
 mov r10,[rdi+r9+NEBO_TASK_START]
 add r10,[rdi+r9+NEBO_TASK_DURATION]
 jc .capacity_overflow
 cmp rdx,r10
 jae .capacity_next
 add r8,[rdi+r9+NEBO_TASK_AMOUNT]
 jc .capacity_overflow
.capacity_next: inc rax
 jmp .capacity_loop
.capacity_done:
 cmp r8,rcx
 ja .capacity_exceeded
 xor eax,eax
 ret
.invalid_capacity: mov eax,NEBO_SCHEDULE_STATUS_INVALID
 ret
.limit_capacity: mov eax,NEBO_SCHEDULE_STATUS_LIMIT
 ret
.capacity_exceeded: mov eax,NEBO_SCHEDULE_STATUS_CAPACITY
 ret
.capacity_overflow: mov eax,NEBO_SCHEDULE_STATUS_OVERFLOW
 ret

NEBOC_ABI_FUNCTION nebo_schedule_makespan
 ; tasks, count, output
 test rdx,rdx
 jz .invalid_makespan
 mov qword [rdx],0
 test rdi,rdi
 jz .invalid_makespan
 test rsi,rsi
 jz .invalid_makespan
 cmp rsi,NEBO_SCHEDULE_MAX_TASKS
 ja .limit_makespan
 xor eax,eax
 xor ecx,ecx
.makespan_loop:
 cmp rax,rsi
 jae .makespan_done
 mov r8,rax
 imul r8,nebo_schedule_TASK_SIZE
 mov r9,[rdi+r8+NEBO_TASK_START]
 add r9,[rdi+r8+NEBO_TASK_DURATION]
 jc .overflow_makespan
 cmp r9,rcx
 jbe .makespan_next
 mov rcx,r9
.makespan_next: inc rax
 jmp .makespan_loop
.makespan_done: mov [rdx],rcx
 xor eax,eax
 ret
.invalid_makespan: mov eax,NEBO_SCHEDULE_STATUS_INVALID
 ret
.limit_makespan: mov eax,NEBO_SCHEDULE_STATUS_LIMIT
 ret
.overflow_makespan: mov eax,NEBO_SCHEDULE_STATUS_OVERFLOW
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
