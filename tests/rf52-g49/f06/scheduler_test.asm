bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/scheduler/scheduler.inc"
global _start
extern neboc_build_graph_from_modules,neboc_build_graph_ready_nodes
extern neboc_compile_scheduler_new,neboc_scheduler_submit,neboc_scheduler_run
extern neboc_scheduler_cancel,neboc_scheduler_deterministic_mode
extern neboc_scheduler_critical_path,neboc_scheduler_oversubscription_report
extern neboc_scheduler_trace,neboc_cli_build_jobs,neboc_cli_scheduler_report
extern neboc_host_process_exit

section .data
modules: dq 4,5,4, 2,3,4, 1,2,4, 3,4,4
cycle_modules: dq 1,2,4, 2,3,4
edges: dq 2,1, 3,1, 4,2, 4,3
cycle_edges: dq 1,2, 2,1

section .bss align=16
graph: resb NEBOC_GRAPH_SIZE
graph2: resb NEBOC_GRAPH_SIZE
sched: resb NEBOC_SCHED_SIZE
tasks: resb NEBOC_TASK_SIZE*8
trace: resb NEBOC_TRACE_SIZE*8
trace_copy: resb NEBOC_TRACE_SIZE*8
config: resb NEBOC_SCHED_CONFIG_SIZE
ready: resq 8
ready_count: resq 1
critical: resb NEBOC_CRITICAL_REPORT_SIZE
over: resb NEBOC_OVER_REPORT_SIZE
report: resb NEBOC_SCHED_REPORT_SIZE

section .text
init_sched:
 lea rax,[rel tasks]
 mov [rel config+NEBOC_SCHED_CONFIG_TASKS_OFFSET],rax
 lea rax,[rel trace]
 mov [rel config+NEBOC_SCHED_CONFIG_TRACE_OFFSET],rax
 mov qword [rel config+NEBOC_SCHED_CONFIG_WORKERS_OFFSET],2
 mov qword [rel config+NEBOC_SCHED_CONFIG_MEMORY_OFFSET],10
 mov qword [rel config+NEBOC_SCHED_CONFIG_TASK_CAPACITY_OFFSET],8
 mov qword [rel config+NEBOC_SCHED_CONFIG_TRACE_CAPACITY_OFFSET],8
 mov qword [rel config+NEBOC_SCHED_CONFIG_EXTERNAL_WORKERS_OFFSET],1
 lea rdi,[rel sched]
 lea rsi,[rel config]
 jmp neboc_compile_scheduler_new

_start:
 sub rsp,8
 lea rdi,[rel graph]
 lea rsi,[rel modules]
 mov edx,4
 lea rcx,[rel edges]
 mov r8d,4
 call neboc_build_graph_from_modules
 test eax,eax
 jne .fail1
 cmp qword [rel graph+NEBOC_GRAPH_ACTIVE_OFFSET],1
 jne .fail2
 cmp qword [rel graph+NEBOC_GRAPH_NODES_OFFSET],1
 jne .fail3
 lea rdi,[rel graph]
 xor esi,esi
 lea rdx,[rel ready]
 mov ecx,8
 lea r8,[rel ready_count]
 call neboc_build_graph_ready_nodes
 test eax,eax
 jne .fail4
 cmp qword [rel ready_count],1
 jne .fail5
 cmp qword [rel ready],1
 jne .fail6
 lea rdi,[rel graph]
 mov esi,1
 lea rdx,[rel ready]
 mov ecx,8
 lea r8,[rel ready_count]
 call neboc_build_graph_ready_nodes
 test eax,eax
 jne .fail7
 cmp qword [rel ready_count],2
 jne .fail8
 cmp qword [rel ready],2
 jne .fail9
 cmp qword [rel ready+8],3
 jne .fail10

 ; A cyclic graph never publishes active state.
 lea rdi,[rel graph2]
 lea rsi,[rel cycle_modules]
 mov edx,2
 lea rcx,[rel cycle_edges]
 mov r8d,2
 call neboc_build_graph_from_modules
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail11
 cmp qword [rel graph2+NEBOC_GRAPH_ACTIVE_OFFSET],0
 jne .fail12

 call init_sched
 test eax,eax
 jne .fail13
 ; Submit in reverse; run must canonicalize unit order.
 lea rdi,[rel sched]
 mov esi,4
 mov edx,1
 mov ecx,4
 mov r8d,5
 call neboc_scheduler_submit
 test eax,eax
 jne .fail14
 lea rdi,[rel sched]
 mov esi,3
 mov edx,1
 mov ecx,4
 mov r8d,4
 call neboc_scheduler_submit
 test eax,eax
 jne .fail15
 lea rdi,[rel sched]
 mov esi,2
 mov edx,1
 mov ecx,4
 mov r8d,3
 call neboc_scheduler_submit
 test eax,eax
 jne .fail16
 lea rdi,[rel sched]
 mov esi,1
 mov edx,1
 mov ecx,4
 mov r8d,2
 call neboc_scheduler_submit
 test eax,eax
 jne .fail17
 lea rdi,[rel sched]
 lea rsi,[rel graph]
 call neboc_scheduler_run
 test eax,eax
 jne .fail18
 cmp qword [rel sched+NEBOC_SCHED_COMPLETED_OFFSET],4
 jne .fail19
 cmp qword [rel sched+NEBOC_SCHED_PEAK_WORKERS_OFFSET],2
 jne .fail20
 cmp qword [rel sched+NEBOC_SCHED_PEAK_MEMORY_OFFSET],8
 jne .fail21
 cmp qword [rel trace+NEBOC_TRACE_UNIT_OFFSET],1
 jne .fail22
 cmp qword [rel trace+NEBOC_TRACE_SIZE+NEBOC_TRACE_UNIT_OFFSET],2
 jne .fail23
 cmp qword [rel trace+NEBOC_TRACE_SIZE*2+NEBOC_TRACE_UNIT_OFFSET],3
 jne .fail24
 cmp qword [rel trace+NEBOC_TRACE_SIZE*3+NEBOC_TRACE_UNIT_OFFSET],4
 jne .fail25
 cmp qword [rel trace+NEBOC_TRACE_SIZE+NEBOC_TRACE_WORKER_OFFSET],1
 jne .fail26
 cmp qword [rel trace+NEBOC_TRACE_SIZE*2+NEBOC_TRACE_WORKER_OFFSET],2
 jne .fail27

 lea rdi,[rel graph]
 lea rsi,[rel critical]
 call neboc_scheduler_critical_path
 test eax,eax
 jne .fail28
 cmp qword [rel critical+NEBOC_CRITICAL_UNIT_OFFSET],4
 jne .fail29
 cmp qword [rel critical+NEBOC_CRITICAL_WORK_OFFSET],11
 jne .fail30
 lea rdi,[rel sched]
 lea rsi,[rel over]
 call neboc_scheduler_oversubscription_report
 test eax,eax
 jne .fail31
 cmp qword [rel over+NEBOC_OVER_WORKERS_OFFSET],2
 jne .fail32
 cmp qword [rel over+NEBOC_OVER_EXTERNAL_OFFSET],1
 jne .fail33
 lea rdi,[rel sched]
 lea rsi,[rel trace_copy]
 mov edx,8
 lea r8,[rel ready_count]
 call neboc_scheduler_trace
 test eax,eax
 jne .fail34
 cmp qword [rel ready_count],4
 jne .fail35
 mov rax,[rel trace]
 cmp rax,[rel trace_copy]
 jne .fail36
 lea rdi,[rel sched]
 lea rsi,[rel graph]
 lea rdx,[rel report]
 call neboc_cli_scheduler_report
 test eax,eax
 jne .fail37
 cmp qword [rel report+NEBOC_OVER_REPORT_SIZE+NEBOC_CRITICAL_WORK_OFFSET],11
 jne .fail38

 ; Jobs cannot change after execution; deterministic mode is bounded.
 lea rdi,[rel sched]
 mov esi,3
 call neboc_cli_build_jobs
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail39
 lea rdi,[rel sched]
 mov esi,2
 call neboc_scheduler_deterministic_mode
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail40

 ; Cancellation owns pending tasks and blocks a later run.
 call init_sched
 test eax,eax
 jne .fail41
 lea rdi,[rel sched]
 mov esi,1
 mov edx,1
 mov ecx,4
 mov r8d,2
 call neboc_scheduler_submit
 test eax,eax
 jne .fail42
 lea rdi,[rel sched]
 mov esi,0xca
 call neboc_scheduler_cancel
 test eax,eax
 jne .fail43
 cmp qword [rel tasks+NEBOC_TASK_STATE_OFFSET],NEBOC_TASK_CANCELLED
 jne .fail44
 lea rdi,[rel sched]
 lea rsi,[rel graph]
 call neboc_scheduler_run
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail45

 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 45
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
