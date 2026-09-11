bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/memory/project_pressure.inc"
global _start
extern neboc_project_model_load,neboc_project_lazy_module
extern neboc_project_chunk_diagnostics,neboc_project_incremental_link_plan
extern neboc_project_file_watch,neboc_project_pressure_policy
extern neboc_project_progress_snapshot,neboc_project_scalability_report
extern neboc_project_synthetic_corpus,neboc_cli_project_report
extern neboc_cli_build_memory_budget,neboc_host_process_exit
section .data
diagnostics: dq 2,101, 1,102, 2,103, 1,104, 2,105
changed: dq 9,2,15
events: dq 2,1, 2,2, 9,1
section .bss align=16
modules_a: resb NEBOC_PROJECT_MODULE_SIZE*16
modules_b: resb NEBOC_PROJECT_MODULE_SIZE*16
project: resb NEBOC_PROJECT_SIZE
project_bad: resb NEBOC_PROJECT_SIZE
manifest: resb NEBOC_PROJECT_MANIFEST_SIZE
limits: resb NEBOC_PROJECT_LIMIT_SIZE
module_ptr: resq 1
diag_out: resb NEBOC_PROJECT_DIAGNOSTIC_SIZE*8
out_count: resq 1
link_plan: resq 8
watch_report: resb NEBOC_PROJECT_WATCH_SIZE
progress: resb NEBOC_PROJECT_PROGRESS_SIZE
report: resb NEBOC_PROJECT_REPORT_SIZE
section .text
_start:
 sub rsp,8
 ; Synthetic corpus is local, deterministic and independent of paths.
 lea rdi,[rel modules_a]
 mov esi,16
 mov edx,32
 mov ecx,7
 call neboc_project_synthetic_corpus
 test eax,eax
 jne .fail1
 lea rdi,[rel modules_b]
 mov esi,16
 mov edx,32
 mov ecx,7
 call neboc_project_synthetic_corpus
 test eax,eax
 jne .fail2
 lea rsi,[rel modules_a]
 lea rdi,[rel modules_b]
 mov ecx,(NEBOC_PROJECT_MODULE_SIZE*16)/8
 repe cmpsq
 jne .fail3

 lea rax,[rel modules_a]
 mov [rel manifest+NEBOC_PROJECT_MANIFEST_MODULES_OFFSET],rax
 mov qword [rel manifest+NEBOC_PROJECT_MANIFEST_COUNT_OFFSET],16
 mov qword [rel limits+NEBOC_PROJECT_LIMIT_MODULES_OFFSET],16
 mov qword [rel limits+NEBOC_PROJECT_LIMIT_BYTES_OFFSET],1024
 lea rax,[rel diagnostics]
 mov [rel limits+NEBOC_PROJECT_LIMIT_DIAGNOSTICS_OFFSET],rax
 mov qword [rel limits+NEBOC_PROJECT_LIMIT_DIAGNOSTIC_COUNT_OFFSET],5
 mov qword [rel limits+NEBOC_PROJECT_LIMIT_DIAGNOSTIC_CAPACITY_OFFSET],5
 lea rdi,[rel project]
 lea rsi,[rel manifest]
 lea rdx,[rel limits]
 call neboc_project_model_load
 test eax,eax
 jne .fail4
 cmp qword [rel project+NEBOC_PROJECT_MODULE_COUNT_OFFSET],16
 jne .fail5

 ; Lazy materialization occurs once for a demanded module.
 lea rdi,[rel project]
 mov esi,9
 lea rdx,[rel module_ptr]
 call neboc_project_lazy_module
 test eax,eax
 jne .fail6
 mov rax,[rel module_ptr]
 cmp qword [rax+NEBOC_PROJECT_MODULE_ID_OFFSET],9
 jne .fail7
 lea rdi,[rel project]
 mov esi,9
 lea rdx,[rel module_ptr]
 call neboc_project_lazy_module
 test eax,eax
 jne .fail8
 cmp qword [rel project+NEBOC_PROJECT_QUERIES_OFFSET],1
 jne .fail9

 ; Diagnostics are chunked without dropping error-severity records.
 lea rdi,[rel project]
 mov esi,2
 lea rdx,[rel diag_out]
 mov ecx,8
 lea r8,[rel out_count]
 call neboc_project_chunk_diagnostics
 test eax,eax
 jne .fail10
 cmp qword [rel out_count],2
 jne .fail11
 cmp qword [rel diag_out],2
 jne .fail12
 lea rdi,[rel project]
 mov esi,8
 lea rdx,[rel diag_out]
 mov ecx,8
 lea r8,[rel out_count]
 call neboc_project_chunk_diagnostics
 test eax,eax
 jne .fail13
 cmp qword [rel out_count],3
 jne .fail14
 cmp qword [rel diag_out],2
 jne .fail15
 cmp qword [rel project+NEBOC_PROJECT_DIAGNOSTIC_CURSOR_OFFSET],5
 jne .fail16

 ; Link plan canonicalizes changed objects by manifest module order.
 lea rdi,[rel project]
 lea rsi,[rel changed]
 mov edx,3
 lea rcx,[rel link_plan]
 mov r8d,8
 lea r9,[rel out_count]
 call neboc_project_incremental_link_plan
 test eax,eax
 jne .fail17
 cmp qword [rel out_count],3
 jne .fail18
 cmp qword [rel link_plan],2
 jne .fail19
 cmp qword [rel link_plan+8],9
 jne .fail20
 cmp qword [rel link_plan+16],15
 jne .fail21

 ; Local change events coalesce by module identity, not filename.
 lea rdi,[rel project]
 lea rsi,[rel events]
 mov edx,3
 mov ecx,1
 lea r8,[rel watch_report]
 call neboc_project_file_watch
 test eax,eax
 jne .fail22
 cmp qword [rel watch_report+NEBOC_PROJECT_WATCH_UNIQUE_OFFSET],2
 jne .fail23
 cmp qword [rel watch_report+NEBOC_PROJECT_WATCH_COALESCED_OFFSET],1
 jne .fail24

 ; Pressure reduces parallelism; graceful failure preserves state.
 lea rdi,[rel project]
 mov esi,1
 call neboc_project_pressure_policy
 test eax,eax
 jne .fail25
 cmp qword [rel project+NEBOC_PROJECT_WORKERS_OFFSET],2
 jne .fail26
 lea rdi,[rel project]
 mov esi,2
 call neboc_project_pressure_policy
 test eax,eax
 jne .fail27
 cmp qword [rel project+NEBOC_PROJECT_WORKERS_OFFSET],1
 jne .fail28
 lea rdi,[rel project]
 mov esi,3
 call neboc_project_pressure_policy
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail29
 cmp qword [rel project+NEBOC_PROJECT_PRESSURE_OFFSET],2
 jne .fail30

 lea rdi,[rel project]
 lea rsi,[rel progress]
 call neboc_project_progress_snapshot
 test eax,eax
 jne .fail31
 cmp qword [rel progress+NEBOC_PROJECT_PROGRESS_PENDING_OFFSET],16
 jne .fail32
 cmp qword [rel progress+NEBOC_PROJECT_PROGRESS_MATERIALIZED_OFFSET],1
 jne .fail33
 lea rdi,[rel project]
 lea rsi,[rel report]
 call neboc_cli_project_report
 test eax,eax
 jne .fail34
 cmp qword [rel report],16
 jne .fail35
 cmp qword [rel report+24],1
 jne .fail36
 cmp qword [rel report+40],3
 jne .fail37
 cmp qword [rel report+48],5
 jne .fail38

 ; A memory ceiling cannot undercut the live graph.
 lea rdi,[rel project]
 mov esi,1
 call neboc_cli_build_memory_budget
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail39
 lea rdi,[rel project]
 mov rsi,[rel project+NEBOC_PROJECT_TOTAL_BYTES_OFFSET]
 call neboc_cli_build_memory_budget
 test eax,eax
 jne .fail40

 ; Non-canonical manifests fail atomically.
 mov qword [rel modules_b+NEBOC_PROJECT_MODULE_ID_OFFSET],2
 mov qword [rel modules_b+NEBOC_PROJECT_MODULE_SIZE+NEBOC_PROJECT_MODULE_ID_OFFSET],1
 lea rax,[rel modules_b]
 mov [rel manifest+NEBOC_PROJECT_MANIFEST_MODULES_OFFSET],rax
 lea rdi,[rel project_bad]
 lea rsi,[rel manifest]
 lea rdx,[rel limits]
 call neboc_project_model_load
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail41
 cmp qword [rel project_bad+NEBOC_PROJECT_ACTIVE_OFFSET],0
 jne .fail42

 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 42
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
