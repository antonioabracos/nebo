; Source-to-effect adapter for the public bounded reactive language surface.
; Every mode invokes reusable runtime owners and returns the source value only
; after checking independently observable state.
bits 64
default rel
%include "runtime/reactive/public.inc"
%include "runtime/reactive/transaction.inc"
%include "runtime/reactive/computed.inc"
%include "runtime/reactive/delta.inc"
%include "runtime/reactive/graph.inc"
%include "runtime/reactive/stream.inc"
%include "runtime/reactive/observe.inc"

extern nebo_signal_init
extern nebo_signal_map_add
extern nebo_signal_combine_add
extern nebo_signal_distinct_set
extern nebo_signal_subscribe
extern nebo_signal_cancel
extern nebo_cell_init
extern nebo_transaction_init
extern nebo_transaction_set
extern nebo_transaction_commit
extern nebo_transaction_rollback
extern nebo_computed_init
extern nebo_computed_add_dependency
extern nebo_computed_invalidate
extern nebo_computed_recompute_sum
extern nebo_list_init
extern nebo_list_patch
extern nebo_delta_invert
extern nebo_reactive_list_map_add
extern nebo_reactive_list_filter_even
extern nebo_reactive_list_sort_i64
extern nebo_reactive_dict_init
extern nebo_graph_init
extern nebo_graph_compile
extern nebo_graph_affected
extern nebo_trace_init
extern nebo_trace_append
extern nebo_reactive_graph_report
extern nebo_snapshot_validate
extern nebo_stream_init
extern nebo_stream_push
extern nebo_stream_pop
extern nebo_stream_cancel
extern nebo_stream_reduce_sum
extern nebo_signal_persist
extern nebo_signal_restore
extern nebo_reactive_await_stable

section .bss align=16
reactive_probe_signal_a: resb NEBO_SIGNAL_SIZE
reactive_probe_signal_b: resb NEBO_SIGNAL_SIZE
reactive_probe_signal_c: resb NEBO_SIGNAL_SIZE
reactive_probe_cell: resb nebo_transaction_CELL_SIZE
reactive_probe_tx: resb NEBO_TX_SIZE
reactive_probe_entries: resb NEBO_TX_ENTRY_SIZE*4
reactive_probe_computed: resb NEBO_COMPUTED_SIZE
reactive_probe_computed_report: resb NEBO_COMPUTED_REPORT_SIZE
reactive_probe_dependencies: resq 4
reactive_probe_list: resb NEBO_LIST_SIZE
reactive_probe_values: resq 8
reactive_probe_mapped: resq 8
reactive_probe_filtered: resq 8
reactive_probe_filtered_count: resq 1
reactive_probe_delta: resb NEBO_DELTA_SIZE
reactive_probe_inverse: resb NEBO_DELTA_SIZE
reactive_probe_dict: resb NEBO_REACTIVE_DICT_SIZE
reactive_probe_keys: resq 4
reactive_probe_dict_values: resq 4
reactive_probe_graph: resb nebo_graph_GRAPH_SIZE_reactive
reactive_probe_adjacency: resq 8
reactive_probe_order: resq 8
reactive_probe_indegree: resq 8
reactive_probe_affected: resq 1
reactive_probe_graph_report: resb NEBO_OBSERVE_GRAPH_REPORT_SIZE
reactive_probe_snapshot: resb NEBO_SNAPSHOT_SIZE
reactive_probe_trace: resb nebo_observe_TRACE_SIZE
reactive_probe_trace_entries: resb NEBO_TRACE_ENTRY_SIZE*8
reactive_probe_trace_event: resb NEBO_TRACE_ENTRY_SIZE
reactive_probe_stream: resb nebo_stream_STREAM_SIZE
reactive_probe_stream_values: resq 8
reactive_probe_stream_result: resq 1
reactive_probe_store: resb NEBO_REACTIVE_STORE_SIZE

section .text
reactive_probe_clear:
 xor eax,eax
 rep stosq
 ret

reactive_probe_signals:
 mov rdi,reactive_probe_signal_a
 mov esi,r13d
 call nebo_signal_init
 test eax,eax
 jnz .bad
 cmp [rel reactive_probe_signal_a+NEBO_SIGNAL_VALUE],r13
 jne .bad
 mov rdi,reactive_probe_signal_a
 mov rsi,reactive_probe_signal_b
 mov edx,3
 call nebo_signal_map_add
 test eax,eax
 jnz .bad
 mov rdi,reactive_probe_signal_a
 mov rsi,reactive_probe_signal_b
 mov rdx,reactive_probe_signal_c
 call nebo_signal_combine_add
 test eax,eax
 jnz .bad
 mov rax,r13
 add rax,r13
 add rax,3
 cmp [rel reactive_probe_signal_c+NEBO_SIGNAL_VALUE],rax
 jne .bad
 mov rdi,reactive_probe_signal_c
 mov rsi,rax
 call nebo_signal_distinct_set
 cmp eax,NEBO_REACTIVE_PUBLIC_UNCHANGED
 jne .bad
 mov rdi,reactive_probe_signal_c
 call nebo_signal_subscribe
 test eax,eax
 jnz .bad
 cmp qword [rel reactive_probe_signal_c+NEBO_SIGNAL_SUBSCRIBED],1
 jne .bad
 mov rdi,reactive_probe_signal_c
 call nebo_signal_cancel
 test eax,eax
 jnz .bad
 cmp qword [rel reactive_probe_signal_c+NEBO_SIGNAL_CANCELLED],1
 jne .bad
 cmp qword [rel reactive_probe_signal_c+NEBO_SIGNAL_VERSION],1
 jne .bad
 xor eax,eax
 ret
.bad: mov eax,1
 ret

reactive_probe_cells:
 mov rdi,reactive_probe_cell
 mov esi,r13d
 call nebo_cell_init
 test eax,eax
 jnz .bad
 mov rdi,reactive_probe_tx
 mov rsi,reactive_probe_entries
 mov edx,4
 call nebo_transaction_init
 test eax,eax
 jnz .bad
 mov rdi,reactive_probe_tx
 mov rsi,reactive_probe_cell
 lea rdx,[r13+1]
 call nebo_transaction_set
 test eax,eax
 jnz .bad
 cmp qword [rel reactive_probe_tx+NEBO_TX_COUNT],1
 jne .bad
 mov rdi,reactive_probe_tx
 call nebo_transaction_commit
 test eax,eax
 jnz .bad
 lea rax,[r13+1]
 cmp [rel reactive_probe_cell+NEBO_CELL_VALUE],rax
 jne .bad
 cmp qword [rel reactive_probe_cell+NEBO_CELL_VERSION],2
 jne .bad
 mov rdi,reactive_probe_tx
 mov rsi,reactive_probe_entries
 mov edx,4
 call nebo_transaction_init
 test eax,eax
 jnz .bad
 mov rdi,reactive_probe_tx
 mov rsi,reactive_probe_cell
 lea rdx,[r13+3]
 call nebo_transaction_set
 test eax,eax
 jnz .bad
 mov rdi,reactive_probe_tx
 call nebo_transaction_rollback
 test eax,eax
 jnz .bad
 lea rax,[r13+1]
 cmp [rel reactive_probe_cell+NEBO_CELL_VALUE],rax
 jne .bad
 cmp qword [rel reactive_probe_tx+NEBO_TX_COUNT],0
 jne .bad
 xor eax,eax
 ret
.bad: mov eax,1
 ret

reactive_probe_computation:
 mov rdi,reactive_probe_computed
 mov esi,r13d
 call nebo_computed_init
 test eax,eax
 jnz .bad
 mov rdi,reactive_probe_computed
 xor esi,esi
 call nebo_computed_add_dependency
 test eax,eax
 jnz .bad
 mov rdi,reactive_probe_computed
 mov esi,1
 call nebo_computed_add_dependency
 test eax,eax
 jnz .bad
 mov rdi,reactive_probe_computed
 mov rsi,r13
 call nebo_computed_invalidate
 test eax,eax
 jnz .bad
 mov [rel reactive_probe_dependencies],r13
 mov qword [rel reactive_probe_dependencies+8],2
 mov rdi,reactive_probe_computed
 mov rsi,reactive_probe_dependencies
 mov edx,2
 mov rcx,reactive_probe_computed_report
 call nebo_computed_recompute_sum
 test eax,eax
 jnz .bad
 lea rax,[r13+2]
 cmp [rel reactive_probe_computed+NEBO_COMPUTED_VALUE],rax
 jne .bad
 cmp qword [rel reactive_probe_computed_report+NEBO_COMPUTED_REPORT_DEPENDENCIES],2
 jne .bad
 cmp [rel reactive_probe_computed_report+NEBO_COMPUTED_REPORT_REASON],r13
 jne .bad
 cmp qword [rel reactive_probe_computed+NEBO_COMPUTED_DEPENDENCY_MASK],3
 jne .bad
 ; The bounded cache policy is eager-on-read: a valid node is not recomputed.
 mov rdi,reactive_probe_computed
 mov rsi,reactive_probe_dependencies
 mov edx,2
 mov rcx,reactive_probe_computed_report
 call nebo_computed_recompute_sum
 cmp eax,NEBO_COMPUTED_STATUS_VALID
 jne .bad
 ; Dependents are observed through the same explicit bounded dataflow owner.
 lea rdi,[rel reactive_probe_adjacency]
 mov ecx,8
 call reactive_probe_clear
 mov qword [rel reactive_probe_adjacency],2
 mov qword [rel reactive_probe_adjacency+8],4
 mov rdi,reactive_probe_graph
 mov rsi,reactive_probe_adjacency
 mov edx,3
 mov ecx,8
 call nebo_graph_init
 test eax,eax
 jnz .bad
 mov rdi,reactive_probe_graph
 mov rsi,reactive_probe_order
 mov rdx,reactive_probe_indegree
 call nebo_graph_compile
 test eax,eax
 jnz .bad
 mov rdi,reactive_probe_graph
 mov esi,1
 mov rdx,reactive_probe_affected
 call nebo_graph_affected
 test eax,eax
 jnz .bad
 cmp qword [rel reactive_probe_affected],7
 jne .bad
 xor eax,eax
 ret
.bad: mov eax,1
 ret

reactive_probe_collections:
 mov [rel reactive_probe_values],r13
 lea rax,[r13+1]
 mov [rel reactive_probe_values+8],rax
 lea rax,[r13+2]
 mov [rel reactive_probe_values+16],rax
 mov rdi,reactive_probe_list
 mov rsi,reactive_probe_values
 mov edx,8
 mov ecx,3
 call nebo_list_init
 test eax,eax
 jnz .bad
 mov qword [rel reactive_probe_delta+NEBO_DELTA_KIND],NEBO_DELTA_UPDATE
 mov qword [rel reactive_probe_delta+NEBO_DELTA_INDEX],1
 lea rax,[r13+1]
 mov [rel reactive_probe_delta+NEBO_DELTA_OLD_VALUE],rax
 lea rax,[r13+5]
 mov [rel reactive_probe_delta+NEBO_DELTA_NEW_VALUE],rax
 mov rdi,reactive_probe_list
 mov rsi,reactive_probe_delta
 call nebo_list_patch
 test eax,eax
 jnz .bad
 mov rdi,reactive_probe_delta
 mov rsi,reactive_probe_inverse
 call nebo_delta_invert
 test eax,eax
 jnz .bad
 mov rdi,reactive_probe_list
 mov rsi,reactive_probe_inverse
 call nebo_list_patch
 test eax,eax
 jnz .bad
 lea rax,[r13+1]
 cmp [rel reactive_probe_values+8],rax
 jne .bad
 mov rdi,reactive_probe_values
 mov esi,3
 mov rdx,reactive_probe_mapped
 mov ecx,4
 call nebo_reactive_list_map_add
 test eax,eax
 jnz .bad
 lea rax,[r13+4]
 cmp [rel reactive_probe_mapped],rax
 jne .bad
 mov rdi,reactive_probe_mapped
 mov esi,3
 mov rdx,reactive_probe_filtered
 mov rcx,reactive_probe_filtered_count
 call nebo_reactive_list_filter_even
 test eax,eax
 jnz .bad
 mov rdi,reactive_probe_mapped
 mov esi,3
 call nebo_reactive_list_sort_i64
 test eax,eax
 jnz .bad
 mov [rel reactive_probe_keys],r13
 mov [rel reactive_probe_dict_values],r13
 mov rdi,reactive_probe_dict
 mov rsi,reactive_probe_keys
 mov rdx,reactive_probe_dict_values
 mov ecx,1
 mov r8d,4
 call nebo_reactive_dict_init
 test eax,eax
 jnz .bad
 cmp qword [rel reactive_probe_dict+NEBO_REACTIVE_DICT_COUNT],1
 jne .bad
 xor eax,eax
 ret
.bad: mov eax,1
 ret

reactive_probe_dataflow:
 lea rdi,[rel reactive_probe_adjacency]
 mov ecx,8
 call reactive_probe_clear
 mov qword [rel reactive_probe_adjacency],2
 mov qword [rel reactive_probe_adjacency+8],4
 mov rdi,reactive_probe_graph
 mov rsi,reactive_probe_adjacency
 mov edx,3
 mov ecx,8
 call nebo_graph_init
 test eax,eax
 jnz .bad
 mov rdi,reactive_probe_graph
 mov rsi,reactive_probe_order
 mov rdx,reactive_probe_indegree
 call nebo_graph_compile
 test eax,eax
 jnz .bad
 mov rdi,reactive_probe_graph
 mov esi,1
 mov rdx,reactive_probe_affected
 call nebo_graph_affected
 test eax,eax
 jnz .bad
 cmp qword [rel reactive_probe_affected],7
 jne .bad
 mov rdi,reactive_probe_adjacency
 mov esi,3
 mov rdx,reactive_probe_graph_report
 call nebo_reactive_graph_report
 test eax,eax
 jnz .bad
 cmp qword [rel reactive_probe_graph_report+NEBO_GRAPH_REPORT_EDGES],2
 jne .bad
 mov rax,0x5245414354495645
 mov [rel reactive_probe_snapshot+NEBO_SNAPSHOT_SCHEMA],rax
 mov qword [rel reactive_probe_snapshot+NEBO_SNAPSHOT_VERSION],1
 mov rax,[rel reactive_probe_graph+NEBO_GRAPH_ORDER_HASH]
 mov [rel reactive_probe_snapshot+NEBO_SNAPSHOT_VALUE_HASH],rax
 mov [rel reactive_probe_snapshot+NEBO_SNAPSHOT_KEY_HASH],r13
 mov qword [rel reactive_probe_snapshot+NEBO_SNAPSHOT_CAPABILITY],NEBO_SNAPSHOT_CAP_LOCAL
 mov rdi,reactive_probe_snapshot
 mov rsi,0x5245414354495645
 mov edx,1
 call nebo_snapshot_validate
 test eax,eax
 jnz .bad
 xor eax,eax
 ret
.bad: mov eax,1
 ret

reactive_probe_observation:
 mov rdi,reactive_probe_trace
 mov rsi,reactive_probe_trace_entries
 mov edx,8
 call nebo_trace_init
 test eax,eax
 jnz .bad
 mov qword [rel reactive_probe_trace_event+NEBO_TRACE_ENTRY_KIND],1
 mov qword [rel reactive_probe_trace_event+NEBO_TRACE_ENTRY_NODE],0
 mov [rel reactive_probe_trace_event+NEBO_TRACE_ENTRY_CAUSE],r13
 mov qword [rel reactive_probe_trace_event+NEBO_TRACE_ENTRY_VERSION],1
 mov qword [rel reactive_probe_trace_event+NEBO_TRACE_ENTRY_COST],1
 mov rdi,reactive_probe_trace
 mov rsi,reactive_probe_trace_event
 call nebo_trace_append
 test eax,eax
 jnz .bad
 cmp qword [rel reactive_probe_trace+NEBO_TRACE_COUNT],1
 jne .bad
 lea rdi,[rel reactive_probe_adjacency]
 mov ecx,8
 call reactive_probe_clear
 mov qword [rel reactive_probe_adjacency],2
 mov rdi,reactive_probe_adjacency
 mov esi,2
 mov rdx,reactive_probe_graph_report
 call nebo_reactive_graph_report
 test eax,eax
 jnz .bad
 cmp qword [rel reactive_probe_graph_report+NEBO_GRAPH_REPORT_EDGES],1
 jne .bad
 mov rdi,reactive_probe_signal_a
 mov esi,r13d
 call nebo_signal_init
 test eax,eax
 jnz .bad
 mov rdi,reactive_probe_signal_a
 mov rsi,reactive_probe_store
 mov rdx,0x7265616374697665
 call nebo_signal_persist
 test eax,eax
 jnz .bad
 mov rdi,reactive_probe_signal_b
 xor esi,esi
 call nebo_signal_init
 test eax,eax
 jnz .bad
 mov rdi,reactive_probe_signal_b
 mov rsi,reactive_probe_store
 mov rdx,0x7265616374697665
 call nebo_signal_restore
 test eax,eax
 jnz .bad
 cmp [rel reactive_probe_signal_b+NEBO_SIGNAL_VALUE],r13
 jne .bad
 mov rdi,reactive_probe_stream
 mov rsi,reactive_probe_stream_values
 mov edx,4
 mov ecx,NEBO_STREAM_POLICY_REJECT
 call nebo_stream_init
 test eax,eax
 jnz .bad
 mov rdi,reactive_probe_stream
 mov rsi,r13
 call nebo_stream_push
 test eax,eax
 jnz .bad
 mov rdi,reactive_probe_stream
 lea rsi,[r13+2]
 call nebo_stream_push
 test eax,eax
 jnz .bad
 mov rdi,reactive_probe_stream
 mov rsi,reactive_probe_stream_result
 call nebo_stream_reduce_sum
 test eax,eax
 jnz .bad
 lea rax,[r13+r13]
 add rax,2
 cmp [rel reactive_probe_stream_result],rax
 jne .bad
 mov rdi,reactive_probe_signal_c
 mov rsi,rax
 call nebo_signal_init
 test eax,eax
 jnz .bad
 mov rax,[rel reactive_probe_stream_result]
 cmp [rel reactive_probe_signal_c+NEBO_SIGNAL_VALUE],rax
 jne .bad
 xor edi,edi
 call nebo_reactive_await_stable
 test eax,eax
 jnz .bad
 mov edi,1
 call nebo_reactive_await_stable
 cmp eax,NEBO_OBSERVE_STATUS_PENDING
 jne .bad
 mov rdi,reactive_probe_stream
 call nebo_stream_cancel
 test eax,eax
 jnz .bad
 xor eax,eax
 ret
.bad: mov eax,1
 ret

global nebo_reactive_source_probe
nebo_reactive_source_probe:
 push rbp
 mov rbp,rsp
 push r12
 push r13
 mov r12d,edi
 mov r13d,esi
 cmp r12d,1
 je .s01
 cmp r12d,2
 je .s02
 cmp r12d,3
 je .s03
 cmp r12d,4
 je .s04
 cmp r12d,5
 je .s05
 cmp r12d,6
 je .s06
 jmp .failed
.s01: call reactive_probe_signals
 jmp .check
.s02: call reactive_probe_cells
 jmp .check
.s03: call reactive_probe_computation
 jmp .check
.s04: call reactive_probe_collections
 jmp .check
.s05: call reactive_probe_dataflow
 jmp .check
.s06: call reactive_probe_observation
.check:
 test eax,eax
 jnz .failed
 mov eax,r13d
 jmp .done
.failed:
 mov eax,111
.done:
 pop r13
 pop r12
 leave
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
