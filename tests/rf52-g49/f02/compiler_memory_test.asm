bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/memory/compiler_memory.inc"
global _start
extern neboc_compiler_arena_new,neboc_arena_allocate,neboc_arena_mark
extern neboc_arena_reset,neboc_arena_stats,neboc_intern_pool_new
extern neboc_intern_pool_intern,neboc_compact_id_table_new
extern neboc_memory_pressure_level,neboc_memory_evict_caches
extern neboc_memory_leak_report,neboc_cli_compiler_memory
extern neboc_host_process_exit

section .data
layout_a: dq 24,16
layout_b: dq 40,32
layout_oom: dq 1024,8
layout_bad: dq 8,3
alpha: db "alpha"
beta: db "beta"
gamma: db "gamma"
pressure: dq 79,100,80,95
cache_a:
 dq 3,32,NEBOC_CACHE_RECOMPUTABLE,NEBOC_CACHE_ACTIVE
 dq 1,16,NEBOC_CACHE_RECOMPUTABLE,NEBOC_CACHE_ACTIVE
 dq 2,64,NEBOC_CACHE_SOURCE_OF_TRUTH,NEBOC_CACHE_ACTIVE
cache_b:
 dq 3,32,NEBOC_CACHE_RECOMPUTABLE,NEBOC_CACHE_ACTIVE
 dq 1,16,NEBOC_CACHE_RECOMPUTABLE,NEBOC_CACHE_ACTIVE
 dq 2,64,NEBOC_CACHE_SOURCE_OF_TRUTH,NEBOC_CACHE_ACTIVE

section .bss align=32
arena: resb neboc_compiler_memory_ARENA_SIZE
backing: resb 512
mark_zero: resb NEBOC_COMPILER_MEMORY_ARENA_MARK_SIZE
mark_after_a: resb NEBOC_COMPILER_MEMORY_ARENA_MARK_SIZE
arena_stats: resb NEBOC_ARENA_STATS_SIZE
allocation: resq 1
arena_list: resq 1
leak_report: resb NEBOC_LEAK_REPORT_SIZE
memory_summary: resb NEBOC_MEMORY_SUMMARY_SIZE
intern_config: resb NEBOC_INTERN_CONFIG_SIZE
intern_config_2: resb NEBOC_INTERN_CONFIG_SIZE
intern_pool: resb NEBOC_INTERN_SIZE
intern_pool_2: resb NEBOC_INTERN_SIZE
intern_entries: resb NEBOC_INTERN_ENTRY_SIZE*2
intern_entries_2: resb NEBOC_INTERN_ENTRY_SIZE*2
intern_payload: resb 64
intern_payload_2: resb 64
intern_id: resq 1
compact_ids: resb NEBOC_COMPACT_ID_SIZE
pressure_level: resq 1
evict_a: resb NEBOC_EVICT_REPORT_SIZE
evict_b: resb NEBOC_EVICT_REPORT_SIZE

section .text
_start:
 sub rsp,8

 ; A phase arena uses caller-owned storage and begins with a reusable zero mark.
 lea rdi,[rel arena]
 lea rsi,[rel backing]
 mov edx,512
 mov ecx,NEBOC_ARENA_POLICY_PHASE
 mov r8d,0xa1
 call neboc_compiler_arena_new
 test eax,eax
 jne .fail1
 lea rdi,[rel arena]
 lea rsi,[rel mark_zero]
 call neboc_arena_mark
 test eax,eax
 jne .fail2
 lea rdi,[rel arena]
 lea rsi,[rel layout_a]
 lea rdx,[rel allocation]
 call neboc_arena_allocate
 test eax,eax
 jne .fail3
 mov rax,[rel allocation]
 test rax,15
 jnz .fail4
 lea rdi,[rel arena]
 lea rsi,[rel mark_after_a]
 call neboc_arena_mark
 test eax,eax
 jne .fail5
 lea rdi,[rel arena]
 lea rsi,[rel layout_b]
 lea rdx,[rel allocation]
 call neboc_arena_allocate
 test eax,eax
 jne .fail6
 mov rax,[rel allocation]
 test rax,31
 jnz .fail7

 ; Live borrows prevent reset and leave every arena counter untouched.
 mov r12,[rel arena+NEBOC_ARENA_USED_OFFSET]
 mov qword [rel arena+NEBOC_ARENA_BORROW_COUNT_OFFSET],1
 lea rdi,[rel arena]
 lea rsi,[rel mark_after_a]
 call neboc_arena_reset
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail8
 cmp r12,[rel arena+NEBOC_ARENA_USED_OFFSET]
 jne .fail9
 mov qword [rel arena+NEBOC_ARENA_BORROW_COUNT_OFFSET],0
 lea rdi,[rel arena]
 lea rsi,[rel mark_after_a]
 call neboc_arena_reset
 test eax,eax
 jne .fail10
 mov rax,[rel mark_after_a+NEBOC_ARENA_MARK_USED_OFFSET]
 cmp rax,[rel arena+NEBOC_ARENA_USED_OFFSET]
 jne .fail11
 lea rdi,[rel arena]
 lea rsi,[rel mark_after_a]
 call neboc_arena_reset
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail12

 ; OOM and invalid layout are failure-atomic, including the output pointer.
 mov qword [rel allocation],0x11223344
 mov r12,[rel arena+NEBOC_ARENA_USED_OFFSET]
 lea rdi,[rel arena]
 lea rsi,[rel layout_oom]
 lea rdx,[rel allocation]
 call neboc_arena_allocate
 cmp eax,NEBOC_STATUS_OUT_OF_MEMORY
 jne .fail13
 cmp qword [rel allocation],0x11223344
 jne .fail14
 cmp r12,[rel arena+NEBOC_ARENA_USED_OFFSET]
 jne .fail15
 lea rdi,[rel arena]
 lea rsi,[rel layout_bad]
 lea rdx,[rel allocation]
 call neboc_arena_allocate
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail16
 lea rdi,[rel arena]
 lea rsi,[rel arena_stats]
 call neboc_arena_stats
 test eax,eax
 jne .fail17
 cmp qword [rel arena_stats+NEBOC_ARENA_STATS_ALLOCATIONS_OFFSET],1
 jne .fail18
 mov rax,[rel arena_stats+NEBOC_ARENA_STATS_HIGH_WATER_OFFSET]
 cmp rax,[rel arena_stats+NEBOC_ARENA_STATS_USED_OFFSET]
 jbe .fail19

 ; Configure a session-scoped, versioned, compact-u8 intern pool.
 lea rax,[rel intern_entries]
 mov [rel intern_config+NEBOC_INTERN_CONFIG_ENTRIES_OFFSET],rax
 mov qword [rel intern_config+NEBOC_INTERN_CONFIG_MAX_ENTRIES_OFFSET],2
 lea rax,[rel intern_payload]
 mov [rel intern_config+NEBOC_INTERN_CONFIG_PAYLOAD_OFFSET],rax
 mov qword [rel intern_config+NEBOC_INTERN_CONFIG_MAX_BYTES_OFFSET],64
 mov qword [rel intern_config+NEBOC_INTERN_CONFIG_KIND_OFFSET],1
 mov qword [rel intern_config+NEBOC_INTERN_CONFIG_SESSION_OFFSET],0x55
 mov qword [rel intern_config+NEBOC_INTERN_CONFIG_VERSION_OFFSET],1
 mov qword [rel intern_config+NEBOC_INTERN_CONFIG_ID_WIDTH_OFFSET],NEBOC_ID_WIDTH_U8
 lea rdi,[rel intern_pool]
 lea rsi,[rel intern_config]
 call neboc_intern_pool_new
 test eax,eax
 jne .fail20
 lea rdi,[rel intern_pool]
 lea rsi,[rel alpha]
 mov edx,5
 lea rcx,[rel intern_id]
 call neboc_intern_pool_intern
 test eax,eax
 jne .fail21
 cmp qword [rel intern_id],1
 jne .fail22
 lea rdi,[rel intern_pool]
 lea rsi,[rel alpha]
 mov edx,5
 lea rcx,[rel intern_id]
 call neboc_intern_pool_intern
 test eax,eax
 jne .fail23
 cmp qword [rel intern_pool+NEBOC_INTERN_COUNT_OFFSET],1
 jne .fail24
 cmp qword [rel intern_pool+NEBOC_INTERN_USED_BYTES_OFFSET],5
 jne .fail25
 lea rdi,[rel intern_pool]
 lea rsi,[rel beta]
 mov edx,4
 lea rcx,[rel intern_id]
 call neboc_intern_pool_intern
 test eax,eax
 jne .fail26
 cmp qword [rel intern_id],2
 jne .fail27
 cmp qword [rel intern_pool+NEBOC_INTERN_USED_BYTES_OFFSET],9
 jne .fail28
 mov qword [rel intern_id],0x7788
 lea rdi,[rel intern_pool]
 lea rsi,[rel gamma]
 mov edx,5
 lea rcx,[rel intern_id]
 call neboc_intern_pool_intern
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail29
 cmp qword [rel intern_id],0x7788
 jne .fail30
 cmp qword [rel intern_pool+NEBOC_INTERN_USED_BYTES_OFFSET],9
 jne .fail31

 ; A second session receives its own identity domain, never a serialized ID.
 lea rax,[rel intern_entries_2]
 mov [rel intern_config_2+NEBOC_INTERN_CONFIG_ENTRIES_OFFSET],rax
 mov qword [rel intern_config_2+NEBOC_INTERN_CONFIG_MAX_ENTRIES_OFFSET],2
 lea rax,[rel intern_payload_2]
 mov [rel intern_config_2+NEBOC_INTERN_CONFIG_PAYLOAD_OFFSET],rax
 mov qword [rel intern_config_2+NEBOC_INTERN_CONFIG_MAX_BYTES_OFFSET],64
 mov qword [rel intern_config_2+NEBOC_INTERN_CONFIG_KIND_OFFSET],1
 mov qword [rel intern_config_2+NEBOC_INTERN_CONFIG_SESSION_OFFSET],0x56
 mov qword [rel intern_config_2+NEBOC_INTERN_CONFIG_VERSION_OFFSET],1
 mov qword [rel intern_config_2+NEBOC_INTERN_CONFIG_ID_WIDTH_OFFSET],NEBOC_ID_WIDTH_U8
 lea rdi,[rel intern_pool_2]
 lea rsi,[rel intern_config_2]
 call neboc_intern_pool_new
 test eax,eax
 jne .fail32
 lea rdi,[rel intern_pool_2]
 lea rsi,[rel alpha]
 mov edx,5
 lea rcx,[rel intern_id]
 call neboc_intern_pool_intern
 test eax,eax
 jne .fail33
 cmp qword [rel intern_id],1
 jne .fail34
 mov rax,[rel intern_pool+NEBOC_INTERN_SESSION_OFFSET]
 cmp rax,[rel intern_pool_2+NEBOC_INTERN_SESSION_OFFSET]
 je .fail35

 ; Compact table widths are explicit and bounded.
 lea rdi,[rel compact_ids]
 mov esi,NEBOC_ID_WIDTH_U8
 mov edx,0x55
 mov ecx,1
 call neboc_compact_id_table_new
 test eax,eax
 jne .fail36
 cmp qword [rel compact_ids+NEBOC_COMPACT_ID_MAX_OFFSET],255
 jne .fail37
 lea rdi,[rel compact_ids]
 mov esi,3
 mov edx,0x55
 mov ecx,1
 call neboc_compact_id_table_new
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail38

 ; Explicit thresholds classify pressure without host/RSS inference.
 lea rdi,[rel pressure]
 lea rsi,[rel pressure_level]
 call neboc_memory_pressure_level
 test eax,eax
 jne .fail39
 cmp qword [rel pressure_level],NEBOC_MEMORY_PRESSURE_NORMAL
 jne .fail40
 mov qword [rel pressure+NEBOC_PRESSURE_USED_OFFSET],80
 lea rdi,[rel pressure]
 lea rsi,[rel pressure_level]
 call neboc_memory_pressure_level
 test eax,eax
 jne .fail41
 cmp qword [rel pressure_level],NEBOC_MEMORY_PRESSURE_HIGH
 jne .fail42
 mov qword [rel pressure+NEBOC_PRESSURE_USED_OFFSET],95
 lea rdi,[rel pressure]
 lea rsi,[rel pressure_level]
 call neboc_memory_pressure_level
 test eax,eax
 jne .fail43
 cmp qword [rel pressure_level],NEBOC_MEMORY_PRESSURE_CRITICAL
 jne .fail44

 ; Eviction is deterministic by stable ID and never removes truth state.
 lea rdi,[rel cache_a]
 mov esi,3
 mov edx,20
 lea rcx,[rel evict_a]
 call neboc_memory_evict_caches
 test eax,eax
 jne .fail45
 lea rdi,[rel cache_b]
 mov esi,3
 mov edx,20
 lea rcx,[rel evict_b]
 call neboc_memory_evict_caches
 test eax,eax
 jne .fail46
 cmp qword [rel evict_a+NEBOC_EVICT_FREED_BYTES_OFFSET],48
 jne .fail47
 cmp qword [rel evict_a+NEBOC_EVICT_ITEMS_OFFSET],2
 jne .fail48
 cmp qword [rel evict_a+NEBOC_EVICT_REMAINING_BYTES_OFFSET],64
 jne .fail49
 cmp qword [rel evict_a+NEBOC_EVICT_REMAINING_ITEMS_OFFSET],1
 jne .fail50
 cmp qword [rel cache_a+NEBOC_CACHE_ENTRY_SIZE*2+NEBOC_CACHE_ENTRY_ACTIVE_OFFSET],1
 jne .fail51
 lea rsi,[rel cache_a]
 lea rdi,[rel cache_b]
 mov ecx,NEBOC_CACHE_ENTRY_SIZE*3
 repe cmpsb
 jne .fail52
 lea rsi,[rel evict_a]
 lea rdi,[rel evict_b]
 mov ecx,NEBOC_EVICT_REPORT_SIZE
 repe cmpsb
 jne .fail53

 ; Leak and CLI summaries are local, bounded and expose unavailable metrics.
 lea rax,[rel arena]
 mov [rel arena_list],rax
 lea rdi,[rel arena_list]
 mov esi,1
 lea rdx,[rel leak_report]
 call neboc_memory_leak_report
 test eax,eax
 jne .fail54
 cmp qword [rel leak_report+NEBOC_LEAK_ARENAS_OFFSET],1
 jne .fail55
 lea rdi,[rel arena_list]
 mov esi,1
 lea rdx,[rel memory_summary]
 call neboc_cli_compiler_memory
 test eax,eax
 jne .fail56
 cmp qword [rel memory_summary+NEBOC_MEMORY_SUMMARY_AVAILABLE_OFFSET],NEBOC_MEMORY_AVAILABLE_ARENAS
 jne .fail57

 ; Reinitialization closes the phase lifetime and makes the leak report clean.
 lea rdi,[rel arena]
 lea rsi,[rel backing]
 mov edx,512
 mov ecx,NEBOC_ARENA_POLICY_PHASE
 mov r8d,0xa1
 call neboc_compiler_arena_new
 test eax,eax
 jne .fail58
 lea rdi,[rel arena_list]
 mov esi,1
 lea rdx,[rel leak_report]
 call neboc_memory_leak_report
 test eax,eax
 jne .fail59
 cmp qword [rel leak_report+NEBOC_LEAK_ARENAS_OFFSET],0
 jne .fail60
 cmp qword [rel leak_report+NEBOC_LEAK_LIVE_BYTES_OFFSET],0
 jne .fail61

 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 61
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep

section .note.GNU-stack noalloc noexec nowrite progbits
