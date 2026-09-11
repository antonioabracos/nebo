bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/metrics/compiler_metrics.inc"
global _start
extern neboc_compiler_metrics_new,neboc_compiler_metrics_phase_timer
extern neboc_compiler_metrics_counter,neboc_compiler_metrics_memory_snapshot
extern neboc_compiler_metrics_io_snapshot,neboc_compiler_metrics_cache_event
extern neboc_compiler_metrics_trace_event,neboc_compiler_metrics_summary
extern neboc_compiler_metrics_export
extern neboc_cli_timings,neboc_cli_compiler_profile,neboc_cli_compiler_report
extern neboc_host_process_exit

section .data
base_context:
 dq 0x20260810,0x1001,0x2001,0x3001,0x4001
 dq NEBOC_METRICS_MODE_COLD,1,NEBOC_METRICS_CORRECTNESS_PASS
 dq 0,0,0,0,7,5,0
trace_fields: dq 11,22,33,44

section .bss align=16
context: resb NEBOC_METRICS_CTX_SIZE
disabled_context: resb NEBOC_METRICS_CTX_SIZE
warm_context: resb NEBOC_METRICS_CTX_SIZE
incremental_context: resb NEBOC_METRICS_CTX_SIZE
bad_context: resb NEBOC_METRICS_CTX_SIZE
small_context: resb NEBOC_METRICS_CTX_SIZE
events: resb NEBOC_METRICS_EVENT_SIZE*16
disabled_events: resb NEBOC_METRICS_EVENT_SIZE
mode_events: resb NEBOC_METRICS_EVENT_SIZE*2
small_events: resb NEBOC_METRICS_EVENT_SIZE
summary: resb NEBOC_METRICS_SUMMARY_SIZE
report_summary: resb NEBOC_METRICS_SUMMARY_SIZE
cli_summary: resb NEBOC_METRICS_SUMMARY_SIZE
export_a: resb NEBOC_METRICS_EXPORT_HEADER_SIZE+NEBOC_METRICS_EVENT_SIZE*16
export_b: resb NEBOC_METRICS_EXPORT_HEADER_SIZE+NEBOC_METRICS_EVENT_SIZE*16

section .text
copy_context:
 ; rdi=destination
 lea rsi,[rel base_context]
 mov ecx,NEBOC_METRICS_CTX_SIZE/8
 rep movsq
 ret

_start:
 sub rsp,8
 lea rdi,[rel context]
 call copy_context
 lea rdi,[rel context]
 lea rsi,[rel events]
 mov edx,16
 call neboc_compiler_metrics_new
 test eax,eax
 jne .fail1

 ; Stable phase IDs retain caller-measured wall/CPU values.
 lea rdi,[rel context]
 mov esi,1
 mov edx,0x501
 mov ecx,20
 mov r8d,15
 call neboc_compiler_metrics_phase_timer
 test eax,eax
 jne .fail2
 lea rdi,[rel context]
 mov esi,2
 mov edx,0x502
 mov ecx,50
 mov r8d,35
 call neboc_compiler_metrics_phase_timer
 test eax,eax
 jne .fail3
 lea rdi,[rel context]
 mov esi,1
 mov edx,10
 call neboc_compiler_metrics_counter
 test eax,eax
 jne .fail4
 lea rdi,[rel context]
 mov esi,1
 mov edx,100
 mov ecx,200
 xor r8d,r8d                 ; RSS explicitly unavailable.
 xor r9d,r9d                 ; virtual memory explicitly unavailable.
 call neboc_compiler_metrics_memory_snapshot
 test eax,eax
 jne .fail5
 lea rdi,[rel context]
 mov esi,1
 mov edx,1000
 mov ecx,2000
 mov r8d,3
 mov r9d,4
 call neboc_compiler_metrics_io_snapshot
 test eax,eax
 jne .fail6
 lea rdi,[rel context]
 mov esi,NEBOC_METRICS_CACHE_HIT
 mov edx,1
 call neboc_compiler_metrics_cache_event
 test eax,eax
 jne .fail7
 lea rdi,[rel context]
 mov esi,NEBOC_METRICS_CACHE_MISS
 mov edx,1
 call neboc_compiler_metrics_cache_event
 test eax,eax
 jne .fail8
 lea rdi,[rel context]
 mov esi,7
 lea rdx,[rel trace_fields]
 mov ecx,4
 call neboc_compiler_metrics_trace_event
 test eax,eax
 jne .fail9

 lea rdi,[rel context]
 lea rsi,[rel summary]
 call neboc_compiler_metrics_summary
 test eax,eax
 jne .fail10
 cmp qword [rel summary+NEBOC_METRICS_SUMMARY_EVENT_COUNT_OFFSET],8
 jne .fail11
 cmp qword [rel summary+NEBOC_METRICS_SUMMARY_WALL_OFFSET],70
 jne .fail12
 cmp qword [rel summary+NEBOC_METRICS_SUMMARY_CPU_OFFSET],50
 jne .fail13
 cmp qword [rel summary+NEBOC_METRICS_SUMMARY_CRITICAL_PHASE_OFFSET],2
 jne .fail14
 cmp qword [rel summary+NEBOC_METRICS_SUMMARY_CRITICAL_UNIT_OFFSET],0x502
 jne .fail15
 cmp qword [rel summary+NEBOC_METRICS_SUMMARY_CRITICAL_WALL_OFFSET],50
 jne .fail16
 cmp qword [rel summary+NEBOC_METRICS_SUMMARY_COUNTER_TOTAL_OFFSET],10
 jne .fail17
 cmp qword [rel summary+NEBOC_METRICS_SUMMARY_PEAK_HEAP_OFFSET],200
 jne .fail18
 cmp qword [rel summary+NEBOC_METRICS_SUMMARY_PEAK_RSS_OFFSET],0
 jne .fail19
 cmp qword [rel summary+NEBOC_METRICS_SUMMARY_IO_READ_OFFSET],1000
 jne .fail20
 cmp qword [rel summary+NEBOC_METRICS_SUMMARY_IO_WRITE_OFFSET],2000
 jne .fail21
 cmp qword [rel summary+NEBOC_METRICS_SUMMARY_CACHE_HITS_OFFSET],1
 jne .fail22
 cmp qword [rel summary+NEBOC_METRICS_SUMMARY_CACHE_OTHER_OFFSET],1
 jne .fail23
 cmp qword [rel summary+NEBOC_METRICS_SUMMARY_TRACE_COUNT_OFFSET],1
 jne .fail24
 cmp qword [rel summary+NEBOC_METRICS_SUMMARY_OVERHEAD_WALL_OFFSET],7
 jne .fail25

 ; Export has no absolute timestamp and is byte-deterministic.
 lea rdi,[rel context]
 lea rsi,[rel export_a]
 mov edx,NEBOC_METRICS_EXPORT_HEADER_SIZE+NEBOC_METRICS_EVENT_SIZE*16
 mov ecx,NEBOC_METRICS_FORMAT_JSON
 call neboc_compiler_metrics_export
 cmp eax,NEBOC_METRICS_EXPORT_HEADER_SIZE+NEBOC_METRICS_EVENT_SIZE*8
 jne .fail26
 mov r12,rax
 lea rdi,[rel context]
 lea rsi,[rel export_b]
 mov edx,NEBOC_METRICS_EXPORT_HEADER_SIZE+NEBOC_METRICS_EVENT_SIZE*16
 mov ecx,NEBOC_METRICS_FORMAT_JSON
 call neboc_cli_compiler_profile
 cmp rax,r12
 jne .fail27
 lea rsi,[rel export_a]
 lea rdi,[rel export_b]
 mov rcx,r12
 repe cmpsb
 jne .fail28
 lea rdi,[rel export_a]
 mov rsi,r12
 lea rdx,[rel report_summary]
 call neboc_cli_compiler_report
 test eax,eax
 jne .fail29
 cmp qword [rel report_summary+NEBOC_METRICS_SUMMARY_WALL_OFFSET],70
 jne .fail30
 lea rdi,[rel context]
 lea rsi,[rel cli_summary]
 call neboc_cli_timings
 test eax,eax
 jne .fail31
 cmp qword [rel cli_summary+NEBOC_METRICS_SUMMARY_EVENT_COUNT_OFFSET],8
 jne .fail32

 ; Instrumentation can be disabled without changing compilation behavior.
 lea rdi,[rel disabled_context]
 call copy_context
 mov qword [rel disabled_context+NEBOC_METRICS_CTX_ENABLED_OFFSET],0
 lea rdi,[rel disabled_context]
 lea rsi,[rel disabled_events]
 mov edx,1
 call neboc_compiler_metrics_new
 test eax,eax
 jne .fail33
 lea rdi,[rel disabled_context]
 mov esi,1
 mov edx,1
 mov ecx,10
 mov r8d,10
 call neboc_compiler_metrics_phase_timer
 test eax,eax
 jne .fail34
 cmp qword [rel disabled_context+NEBOC_METRICS_CTX_COUNT_OFFSET],0
 jne .fail35

 ; Cold, warm and incremental identities are accepted, never conflated.
 lea rdi,[rel warm_context]
 call copy_context
 mov qword [rel warm_context+NEBOC_METRICS_CTX_MODE_OFFSET],NEBOC_METRICS_MODE_WARM
 lea rdi,[rel warm_context]
 lea rsi,[rel mode_events]
 mov edx,1
 call neboc_compiler_metrics_new
 test eax,eax
 jne .fail36
 lea rdi,[rel incremental_context]
 call copy_context
 mov qword [rel incremental_context+NEBOC_METRICS_CTX_MODE_OFFSET],NEBOC_METRICS_MODE_INCREMENTAL
 lea rdi,[rel incremental_context]
 lea rsi,[rel mode_events+NEBOC_METRICS_EVENT_SIZE]
 mov edx,1
 call neboc_compiler_metrics_new
 test eax,eax
 jne .fail37

 ; Missing factual manifest, failed correctness and all bounds reject.
 lea rdi,[rel bad_context]
 call copy_context
 mov qword [rel bad_context+NEBOC_METRICS_CTX_HARDWARE_OFFSET],0
 lea rdi,[rel bad_context]
 lea rsi,[rel mode_events]
 mov edx,1
 call neboc_compiler_metrics_new
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail38
 lea rdi,[rel bad_context]
 call copy_context
 mov qword [rel bad_context+NEBOC_METRICS_CTX_CORRECTNESS_OFFSET],0
 lea rdi,[rel bad_context]
 lea rsi,[rel mode_events]
 mov edx,1
 call neboc_compiler_metrics_new
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail39
 lea rdi,[rel bad_context]
 call copy_context
 lea rdi,[rel bad_context]
 lea rsi,[rel mode_events]
 mov edx,NEBOC_METRICS_MAX_EVENTS+1
 call neboc_compiler_metrics_new
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail40
 lea rdi,[rel context]
 mov esi,1
 lea rdx,[rel trace_fields]
 mov ecx,NEBOC_METRICS_MAX_TRACE_FIELDS+1
 call neboc_compiler_metrics_trace_event
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail41
 lea rdi,[rel small_context]
 call copy_context
 lea rdi,[rel small_context]
 lea rsi,[rel small_events]
 mov edx,1
 call neboc_compiler_metrics_new
 test eax,eax
 jne .fail42
 lea rdi,[rel small_context]
 mov esi,1
 mov edx,1
 call neboc_compiler_metrics_counter
 test eax,eax
 jne .fail43
 lea rdi,[rel small_context]
 mov esi,2
 mov edx,1
 call neboc_compiler_metrics_counter
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail44
 cmp qword [rel small_context+NEBOC_METRICS_CTX_DROPPED_OFFSET],1
 jne .fail45
 lea rdi,[rel export_a]
 mov esi,NEBOC_METRICS_EXPORT_HEADER_SIZE-1
 lea rdx,[rel report_summary]
 call neboc_cli_compiler_report
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail46

 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 46
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep

section .note.GNU-stack noalloc noexec nowrite progbits
