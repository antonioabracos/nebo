; Nebo Assembly — MF030 continuations, cancellation and lowering-plan scenarios
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/intrinsic/intrinsic_table.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/dependency/pending/pending_table.inc"
%include "compiler/dependency/graph/dependency_graph.inc"
%include "compiler/dependency/continuation/continuation_table.inc"
%include "compiler/lowering/function_lowering_plan.inc"
%include "compiler/lowering/lowering_dump.inc"
%include "compiler/lowering/lowering_diagnostics.inc"

extern neboc_pending_table_init
extern neboc_pending_record_create
extern neboc_dependency_graph_init
extern neboc_dependency_graph_register_pending
extern neboc_dependency_graph_add_edge
extern neboc_dependency_graph_freeze
extern neboc_continuation_table_init
extern neboc_continuation_table_get
extern neboc_continuation_create_from_edge
extern neboc_continuation_mark_ready
extern neboc_continuation_cancel_from_pending
extern neboc_continuation_table_freeze
extern neboc_function_lowering_table_init
extern neboc_function_lowering_table_get_plan
extern neboc_function_lowering_table_get_operation
extern neboc_function_lowering_plan_create_scan
extern neboc_function_lowering_table_freeze
extern neboc_lowering_dump
extern neboc_lowering_diagnostic_name
extern neboc_host_process_exit

global _start

%define PENDING_CAPACITY 4
%define EDGE_CAPACITY 8
%define CONTINUATION_CAPACITY 8
%define PLAN_CAPACITY 4
%define OPERATION_CAPACITY 32
%define DUMP_CAPACITY 16384

section .rodata
expected_dump:
 incbin "tests/lowering/goldens/function-lowering-plan.txt"
expected_dump_end:
expected_duplicate: db 'duplicate-pending-resolution-error'
expected_orphan: db 'orphan-pending-at-exit'

section .bss align=16
pending_entries_a: resb PENDING_CAPACITY * NEBOC_PENDING_RECORD_SIZE
pending_entries_b: resb PENDING_CAPACITY * NEBOC_PENDING_RECORD_SIZE
pending_table_a: resb NEBOC_PENDING_TABLE_SIZE
pending_table_b: resb NEBOC_PENDING_TABLE_SIZE
nodes_a: resb PENDING_CAPACITY * NEBOC_DEPENDENCY_NODE_SIZE
nodes_b: resb PENDING_CAPACITY * NEBOC_DEPENDENCY_NODE_SIZE
edges_a: resb EDGE_CAPACITY * NEBOC_DEPENDENCY_EDGE_SIZE
edges_b: resb EDGE_CAPACITY * NEBOC_DEPENDENCY_EDGE_SIZE
graph_a: resb NEBOC_DEPENDENCY_GRAPH_SIZE
graph_b: resb NEBOC_DEPENDENCY_GRAPH_SIZE
pending_request_a: resb NEBOC_PENDING_REQUEST_SIZE
pending_request_b: resb NEBOC_PENDING_REQUEST_SIZE
edge_request_a: resb NEBOC_DEPENDENCY_REQUEST_SIZE
edge_request_b: resb NEBOC_DEPENDENCY_REQUEST_SIZE
continuations_a: resb CONTINUATION_CAPACITY * NEBOC_CONTINUATION_DESCRIPTOR_SIZE
continuations_b: resb CONTINUATION_CAPACITY * NEBOC_CONTINUATION_DESCRIPTOR_SIZE
cancellation_edges_a: resb CONTINUATION_CAPACITY * NEBOC_CANCELLATION_EDGE_SIZE
cancellation_edges_b: resb CONTINUATION_CAPACITY * NEBOC_CANCELLATION_EDGE_SIZE
continuation_table_a: resb NEBOC_CONTINUATION_TABLE_SIZE
continuation_table_b: resb NEBOC_CONTINUATION_TABLE_SIZE
continuation_request_a: resb NEBOC_CONTINUATION_REQUEST_SIZE
continuation_request_b: resb NEBOC_CONTINUATION_REQUEST_SIZE
plans_a: resb PLAN_CAPACITY * NEBOC_FUNCTION_PLAN_SIZE
plans_b: resb PLAN_CAPACITY * NEBOC_FUNCTION_PLAN_SIZE
operations_a: resb OPERATION_CAPACITY * NEBOC_LOWERING_OPERATION_SIZE
operations_b: resb OPERATION_CAPACITY * NEBOC_LOWERING_OPERATION_SIZE
lowering_table_a: resb NEBOC_LOWERING_TABLE_SIZE
lowering_table_b: resb NEBOC_LOWERING_TABLE_SIZE
plan_request_a: resb NEBOC_FUNCTION_PLAN_REQUEST_SIZE
plan_request_b: resb NEBOC_FUNCTION_PLAN_REQUEST_SIZE
dump_request_a: resb NEBOC_LOWERING_DUMP_SIZE
dump_request_b: resb NEBOC_LOWERING_DUMP_SIZE
dump_a: resb DUMP_CAPACITY
dump_b: resb DUMP_CAPACITY
out_ptr: resq 1
out_count: resq 1
diag_ptr: resq 1
diag_len: resq 1

section .text
_start:
 mov rax,[rsp]
 cmp rax,2
 jne test_usage
 mov rax,[rsp+16]
 cmp byte [rax+1],0
 jne test_usage
 movzx eax,byte [rax]
 sub eax,'0'
 cmp eax,1
 jb test_usage
 cmp eax,9
 ja test_usage
 mov r12d,eax
 call setup_a
 test eax,eax
 jnz test_fail
 cmp r12d,1
 je scenario_1
 cmp r12d,2
 je scenario_2
 cmp r12d,3
 je scenario_3
 cmp r12d,4
 je scenario_4
 cmp r12d,5
 je scenario_5
 cmp r12d,6
 je scenario_6
 cmp r12d,7
 je scenario_7
 cmp r12d,8
 je scenario_8
 jmp scenario_9

; Infrastructure — descriptor identity and deterministic entry symbol.
scenario_1:
 call build_graph_a
 test eax,eax
 jnz test_fail
 call build_continuations_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel continuation_table_a]
 mov esi,1
 lea rdx,[rel out_ptr]
 call neboc_continuation_table_get
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_ptr]
 cmp qword [rbx+NEBOC_CONTINUATION_DESCRIPTOR_ID_OFFSET],1
 jne test_fail
 cmp qword [rbx+NEBOC_CONTINUATION_DESCRIPTOR_SEED_ID_OFFSET],1
 jne test_fail
 cmp qword [rbx+NEBOC_CONTINUATION_DESCRIPTOR_FUNCTION_ID_OFFSET],7
 jne test_fail
 mov rax,0x0000000700000001
 cmp [rbx+NEBOC_CONTINUATION_DESCRIPTOR_ENTRY_SYMBOL_ID_OFFSET],rax
 jne test_fail
 mov rax,[rbx+NEBOC_CONTINUATION_DESCRIPTOR_FLAGS_OFFSET]
 and rax,NEBOC_CONTINUATION_REQUIRED_FLAGS
 cmp rax,NEBOC_CONTINUATION_REQUIRED_FLAGS
 jne test_fail
 jmp test_pass

; Infrastructure — Function Lowering Plan has the canonical Console/scan sequence.
scenario_2:
 call build_complete_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel lowering_table_a]
 mov esi,1
 lea rdx,[rel out_ptr]
 call neboc_function_lowering_table_get_plan
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_ptr]
 cmp qword [rbx+NEBOC_FUNCTION_PLAN_FUNCTION_ID_OFFSET],7
 jne test_fail
 cmp qword [rbx+NEBOC_FUNCTION_PLAN_OPERATION_COUNT_OFFSET],NEBOC_LOWERING_OPERATION_COUNT
 jne test_fail
 mov r13d,1
 mov r14d,1
.operation_check:
 lea rdi,[rel lowering_table_a]
 mov rsi,r13
 lea rdx,[rel out_ptr]
 call neboc_function_lowering_table_get_operation
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_ptr]
 cmp [rbx+NEBOC_LOWERING_OPERATION_KIND_OFFSET],r14
 jne test_fail
 inc r13
 inc r14
 cmp r13,NEBOC_LOWERING_OPERATION_COUNT+1
 jb .operation_check
 jmp test_pass

; NEBO-PENDING-CONTRACT-006 — cancellation propagates transitively.
scenario_3:
 call build_graph_a
 test eax,eax
 jnz test_fail
 call build_continuations_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel continuation_table_a]
 mov esi,1
 lea rdx,[rel out_count]
 call neboc_continuation_cancel_from_pending
 test eax,eax
 jnz test_fail
 cmp qword [rel out_count],2
 jne test_fail
 mov r13d,1
.cancel_check:
 lea rdi,[rel continuation_table_a]
 mov rsi,r13
 lea rdx,[rel out_ptr]
 call neboc_continuation_table_get
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_ptr]
 cmp qword [rbx+NEBOC_CONTINUATION_DESCRIPTOR_STATE_OFFSET],NEBOC_CONTINUATION_STATE_CANCELLED
 jne test_fail
 inc r13
 cmp r13,3
 jb .cancel_check
 cmp qword [rel continuation_table_a+NEBOC_CONTINUATION_TABLE_CANCELLED_COUNT_OFFSET],2
 jne test_fail
 jmp test_pass

; NEBO-PENDING-NEG-007 — duplicate resolution is a controlled internal error.
scenario_4:
 call build_graph_a
 test eax,eax
 jnz test_fail
 call build_continuations_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel continuation_table_a]
 mov esi,1
 call neboc_continuation_mark_ready
 test eax,eax
 jnz test_fail
 lea rdi,[rel continuation_table_a]
 mov esi,1
 call neboc_continuation_mark_ready
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 jne test_fail
 cmp qword [rel continuation_table_a+NEBOC_CONTINUATION_TABLE_LAST_ERROR_OFFSET],NEBOC_CONTINUATION_ERROR_DUPLICATE_RESOLUTION
 jne test_fail
 mov edi,NEBOC_CONTINUATION_ERROR_DUPLICATE_RESOLUTION
 lea rsi,[rel diag_ptr]
 lea rdx,[rel diag_len]
 call neboc_lowering_diagnostic_name
 test eax,eax
 jnz test_fail
 cmp qword [rel diag_len],NEBOC_LOWERING_DIAGNOSTIC_DUPLICATE_RESOLUTION_LENGTH
 jne test_fail
 mov rsi,[rel diag_ptr]
 lea rdi,[rel expected_duplicate]
 mov ecx,NEBOC_LOWERING_DIAGNOSTIC_DUPLICATE_RESOLUTION_LENGTH
 repe cmpsb
 jne test_fail
 jmp test_pass

; NEBO-PENDING-SECURITY-010 — orphan Pending at exit is rejected.
scenario_5:
 call build_graph_with_orphan_a
 test eax,eax
 jnz test_fail
 call build_continuations_one_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel continuation_table_a]
 call neboc_continuation_table_freeze
 test eax,eax
 jnz test_fail
 call build_plan_one_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel lowering_table_a]
 lea rsi,[rel pending_table_a]
 lea rdx,[rel continuation_table_a]
 call neboc_function_lowering_table_freeze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel lowering_table_a+NEBOC_LOWERING_TABLE_LAST_ERROR_OFFSET],NEBOC_LOWERING_ERROR_ORPHAN_PENDING_AT_EXIT
 jne test_fail
 mov edi,NEBOC_LOWERING_ERROR_ORPHAN_PENDING_AT_EXIT
 lea rsi,[rel diag_ptr]
 lea rdx,[rel diag_len]
 call neboc_lowering_diagnostic_name
 test eax,eax
 jnz test_fail
 cmp qword [rel diag_len],NEBOC_LOWERING_DIAGNOSTIC_ORPHAN_PENDING_LENGTH
 jne test_fail
 mov rsi,[rel diag_ptr]
 lea rdi,[rel expected_orphan]
 mov ecx,NEBOC_LOWERING_DIAGNOSTIC_ORPHAN_PENDING_LENGTH
 repe cmpsb
 jne test_fail
 jmp test_pass

; Infrastructure — dump and hashes are deterministic across two independent builds.
scenario_6:
 call setup_b
 test eax,eax
 jnz test_fail
 call build_complete_a
 test eax,eax
 jnz test_fail
 call build_complete_b
 test eax,eax
 jnz test_fail
 mov rax,[rel continuation_table_a+NEBOC_CONTINUATION_TABLE_HASH_OFFSET]
 cmp rax,[rel continuation_table_b+NEBOC_CONTINUATION_TABLE_HASH_OFFSET]
 jne test_fail
 mov rax,[rel lowering_table_a+NEBOC_LOWERING_TABLE_HASH_OFFSET]
 cmp rax,[rel lowering_table_b+NEBOC_LOWERING_TABLE_HASH_OFFSET]
 jne test_fail
 lea rdi,[rel dump_request_a]
 lea rsi,[rel continuation_table_a]
 lea rdx,[rel lowering_table_a]
 lea rcx,[rel dump_a]
 call make_dump
 test eax,eax
 jnz test_fail
 lea rdi,[rel dump_request_b]
 lea rsi,[rel continuation_table_b]
 lea rdx,[rel lowering_table_b]
 lea rcx,[rel dump_b]
 call make_dump
 test eax,eax
 jnz test_fail
 mov rcx,[rel dump_request_a+NEBOC_LOWERING_DUMP_LENGTH_OFFSET]
 cmp rcx,[rel dump_request_b+NEBOC_LOWERING_DUMP_LENGTH_OFFSET]
 jne test_fail
 cmp rcx,expected_dump_end-expected_dump
 jne test_fail
 push rcx
 lea rsi,[rel dump_a]
 lea rdi,[rel expected_dump]
 repe cmpsb
 pop rcx
 jne test_fail
 lea rsi,[rel dump_a]
 lea rdi,[rel dump_b]
 repe cmpsb
 jne test_fail
 jmp test_pass

; Infrastructure — captures are exactly the minimal used-symbol set from MF029.
scenario_7:
 call build_graph_a
 test eax,eax
 jnz test_fail
 call build_continuations_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel continuation_table_a]
 mov esi,1
 lea rdx,[rel out_ptr]
 call neboc_continuation_table_get
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_ptr]
 cmp qword [rbx+NEBOC_CONTINUATION_DESCRIPTOR_CAPTURE_COUNT_OFFSET],2
 jne test_fail
 cmp qword [rbx+NEBOC_CONTINUATION_DESCRIPTOR_CAPTURE_0_OFFSET],11
 jne test_fail
 cmp qword [rbx+NEBOC_CONTINUATION_DESCRIPTOR_CAPTURE_1_OFFSET],33
 jne test_fail
 cmp qword [rbx+NEBOC_CONTINUATION_DESCRIPTOR_CAPTURE_2_OFFSET],0
 jne test_fail
 cmp qword [rbx+NEBOC_CONTINUATION_DESCRIPTOR_CAPTURE_3_OFFSET],0
 jne test_fail
 jmp test_pass

; Infrastructure — plans are target-independent and contain no physical layout.
scenario_8:
 call build_complete_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel lowering_table_a]
 mov esi,1
 lea rdx,[rel out_ptr]
 call neboc_function_lowering_table_get_plan
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_ptr]
 mov rax,[rbx+NEBOC_FUNCTION_PLAN_FLAGS_OFFSET]
 and rax,NEBOC_LOWERING_PLAN_REQUIRED_FLAGS
 cmp rax,NEBOC_LOWERING_PLAN_REQUIRED_FLAGS
 jne test_fail
 cmp qword [rbx+NEBOC_FUNCTION_PLAN_PARAMETER_COUNT_OFFSET],0
 jne test_fail
 cmp qword [rbx+NEBOC_FUNCTION_PLAN_LOCAL_BINDING_COUNT_OFFSET],1
 jne test_fail
 cmp qword [rbx+NEBOC_FUNCTION_PLAN_EXIT_PATH_COUNT_OFFSET],1
 jne test_fail
 jmp test_pass

; Infrastructure — full TR06 semantic plan is frozen and pointer-free hashed.
scenario_9:
 call build_complete_a
 test eax,eax
 jnz test_fail
 cmp qword [rel continuation_table_a+NEBOC_CONTINUATION_TABLE_STATE_OFFSET],NEBOC_CONTINUATION_TABLE_STATE_FROZEN
 jne test_fail
 cmp qword [rel lowering_table_a+NEBOC_LOWERING_TABLE_STATE_OFFSET],NEBOC_LOWERING_TABLE_STATE_FROZEN
 jne test_fail
 cmp qword [rel continuation_table_a+NEBOC_CONTINUATION_TABLE_HASH_OFFSET],0
 je test_fail
 cmp qword [rel lowering_table_a+NEBOC_LOWERING_TABLE_HASH_OFFSET],0
 je test_fail
 cmp qword [rel lowering_table_a+NEBOC_LOWERING_TABLE_FLAGS_OFFSET],NEBOC_LOWERING_PLAN_REQUIRED_FLAGS
 jne test_fail
 jmp test_pass

setup_a:
 lea rdi,[rel pending_table_a]
 lea rsi,[rel pending_entries_a]
 mov edx,PENDING_CAPACITY
 call neboc_pending_table_init
 test eax,eax
 jnz .done
 lea rdi,[rel graph_a]
 lea rsi,[rel nodes_a]
 mov edx,PENDING_CAPACITY
 lea rcx,[rel edges_a]
 mov r8d,EDGE_CAPACITY
 call neboc_dependency_graph_init
 test eax,eax
 jnz .done
 lea rdi,[rel continuation_table_a]
 lea rsi,[rel continuations_a]
 mov edx,CONTINUATION_CAPACITY
 lea rcx,[rel cancellation_edges_a]
 mov r8d,CONTINUATION_CAPACITY
 call neboc_continuation_table_init
 test eax,eax
 jnz .done
 lea rdi,[rel lowering_table_a]
 lea rsi,[rel plans_a]
 mov edx,PLAN_CAPACITY
 lea rcx,[rel operations_a]
 mov r8d,OPERATION_CAPACITY
 call neboc_function_lowering_table_init
.done:
 ret

setup_b:
 lea rdi,[rel pending_table_b]
 lea rsi,[rel pending_entries_b]
 mov edx,PENDING_CAPACITY
 call neboc_pending_table_init
 test eax,eax
 jnz .done
 lea rdi,[rel graph_b]
 lea rsi,[rel nodes_b]
 mov edx,PENDING_CAPACITY
 lea rcx,[rel edges_b]
 mov r8d,EDGE_CAPACITY
 call neboc_dependency_graph_init
 test eax,eax
 jnz .done
 lea rdi,[rel continuation_table_b]
 lea rsi,[rel continuations_b]
 mov edx,CONTINUATION_CAPACITY
 lea rcx,[rel cancellation_edges_b]
 mov r8d,CONTINUATION_CAPACITY
 call neboc_continuation_table_init
 test eax,eax
 jnz .done
 lea rdi,[rel lowering_table_b]
 lea rsi,[rel plans_b]
 mov edx,PLAN_CAPACITY
 lea rcx,[rel operations_b]
 mov r8d,OPERATION_CAPACITY
 call neboc_function_lowering_table_init
.done:
 ret

build_complete_a:
 call build_graph_a
 test eax,eax
 jnz .done
 call build_continuations_a
 test eax,eax
 jnz .done
 lea rdi,[rel continuation_table_a]
 call neboc_continuation_table_freeze
 test eax,eax
 jnz .done
 call build_plan_a
 test eax,eax
 jnz .done
 lea rdi,[rel lowering_table_a]
 lea rsi,[rel pending_table_a]
 lea rdx,[rel continuation_table_a]
 call neboc_function_lowering_table_freeze
.done:
 ret

build_complete_b:
 call build_graph_b
 test eax,eax
 jnz .done
 call build_continuations_b
 test eax,eax
 jnz .done
 lea rdi,[rel continuation_table_b]
 call neboc_continuation_table_freeze
 test eax,eax
 jnz .done
 call build_plan_b
 test eax,eax
 jnz .done
 lea rdi,[rel lowering_table_b]
 lea rsi,[rel pending_table_b]
 lea rdx,[rel continuation_table_b]
 call neboc_function_lowering_table_freeze
.done:
 ret

build_graph_a:
 lea rdi,[rel pending_table_a]
 lea rsi,[rel graph_a]
 lea rdx,[rel pending_request_a]
 lea rcx,[rel edge_request_a]
 jmp build_graph_common
build_graph_b:
 lea rdi,[rel pending_table_b]
 lea rsi,[rel graph_b]
 lea rdx,[rel pending_request_b]
 lea rcx,[rel edge_request_b]
 jmp build_graph_common

; build_graph_common(pending_table*, graph*, pending_request*, edge_request*)
build_graph_common:
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rbx,rcx
 mov rdi,r12
 mov rsi,r14
 mov edx,101
 mov ecx,1
 mov r8d,NEBOC_INTRINSIC_ID_TEXT_SCAN
 mov r9d,1
 call create_pending_simple
 test eax,eax
 jnz .done
 mov rdi,r13
 mov rsi,r12
 mov edx,1
 call neboc_dependency_graph_register_pending
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r14
 mov edx,102
 mov ecx,2
 mov r8d,NEBOC_INTRINSIC_ID_CONSOLE_SCAN
 mov r9d,2
 call create_pending_simple
 test eax,eax
 jnz .done
 mov rdi,r13
 mov rsi,r12
 mov edx,2
 call neboc_dependency_graph_register_pending
 test eax,eax
 jnz .done
 ; Edge 1: Pending 1 feeds Pending 2; captures candidates 11,22,33 but uses 11 and 33.
 mov rdi,rbx
 call clear_edge_request
 mov qword [rbx+NEBOC_DEPENDENCY_REQUEST_PRODUCER_PENDING_ID_OFFSET],1
 mov qword [rbx+NEBOC_DEPENDENCY_REQUEST_CONSUMER_PENDING_ID_OFFSET],2
 mov qword [rbx+NEBOC_DEPENDENCY_REQUEST_CONSUMER_NODE_ID_OFFSET],201
 mov qword [rbx+NEBOC_DEPENDENCY_REQUEST_CONSUMER_SYMBOL_ID_OFFSET],501
 mov qword [rbx+NEBOC_DEPENDENCY_REQUEST_SOURCE_ORDER_OFFSET],1
 mov qword [rbx+NEBOC_DEPENDENCY_REQUEST_CAPTURE_CANDIDATE_COUNT_OFFSET],3
 mov qword [rbx+NEBOC_DEPENDENCY_REQUEST_CAPTURE_USED_MASK_OFFSET],5
 mov qword [rbx+NEBOC_DEPENDENCY_REQUEST_CAPTURE_0_OFFSET],11
 mov qword [rbx+NEBOC_DEPENDENCY_REQUEST_CAPTURE_1_OFFSET],22
 mov qword [rbx+NEBOC_DEPENDENCY_REQUEST_CAPTURE_2_OFFSET],33
 mov rdi,r13
 mov rsi,rbx
 call neboc_dependency_graph_add_edge
 test eax,eax
 jnz .done
 ; Edge 2: Pending 2 feeds terminal operation.
 mov rdi,rbx
 call clear_edge_request
 mov qword [rbx+NEBOC_DEPENDENCY_REQUEST_PRODUCER_PENDING_ID_OFFSET],2
 mov qword [rbx+NEBOC_DEPENDENCY_REQUEST_CONSUMER_NODE_ID_OFFSET],202
 mov qword [rbx+NEBOC_DEPENDENCY_REQUEST_CONSUMER_SYMBOL_ID_OFFSET],502
 mov qword [rbx+NEBOC_DEPENDENCY_REQUEST_SOURCE_ORDER_OFFSET],2
 mov qword [rbx+NEBOC_DEPENDENCY_REQUEST_CAPTURE_CANDIDATE_COUNT_OFFSET],1
 mov qword [rbx+NEBOC_DEPENDENCY_REQUEST_CAPTURE_USED_MASK_OFFSET],1
 mov qword [rbx+NEBOC_DEPENDENCY_REQUEST_CAPTURE_0_OFFSET],44
 mov rdi,r13
 mov rsi,rbx
 call neboc_dependency_graph_add_edge
 test eax,eax
 jnz .done
 mov rdi,r13
 mov rsi,r12
 call neboc_dependency_graph_freeze
.done:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Variant with a third orphan Pending and only one dependent edge.
build_graph_with_orphan_a:
 lea rdi,[rel pending_table_a]
 lea rsi,[rel pending_request_a]
 mov edx,101
 mov ecx,1
 mov r8d,NEBOC_INTRINSIC_ID_TEXT_SCAN
 mov r9d,1
 call create_pending_simple
 test eax,eax
 jnz .done
 lea rdi,[rel graph_a]
 lea rsi,[rel pending_table_a]
 mov edx,1
 call neboc_dependency_graph_register_pending
 test eax,eax
 jnz .done
 lea rdi,[rel pending_table_a]
 lea rsi,[rel pending_request_a]
 mov edx,102
 mov ecx,2
 mov r8d,NEBOC_INTRINSIC_ID_TEXT_SCAN
 mov r9d,2
 call create_pending_simple
 test eax,eax
 jnz .done
 lea rdi,[rel graph_a]
 lea rsi,[rel pending_table_a]
 mov edx,2
 call neboc_dependency_graph_register_pending
 test eax,eax
 jnz .done
 lea rdi,[rel edge_request_a]
 call clear_edge_request
 mov qword [rel edge_request_a+NEBOC_DEPENDENCY_REQUEST_PRODUCER_PENDING_ID_OFFSET],1
 mov qword [rel edge_request_a+NEBOC_DEPENDENCY_REQUEST_CONSUMER_NODE_ID_OFFSET],301
 mov qword [rel edge_request_a+NEBOC_DEPENDENCY_REQUEST_CONSUMER_SYMBOL_ID_OFFSET],601
 mov qword [rel edge_request_a+NEBOC_DEPENDENCY_REQUEST_SOURCE_ORDER_OFFSET],1
 lea rdi,[rel graph_a]
 lea rsi,[rel edge_request_a]
 call neboc_dependency_graph_add_edge
 test eax,eax
 jnz .done
 lea rdi,[rel graph_a]
 lea rsi,[rel pending_table_a]
 call neboc_dependency_graph_freeze
.done:
 ret

build_continuations_a:
 lea rdi,[rel continuation_table_a]
 lea rsi,[rel graph_a]
 lea rdx,[rel continuation_request_a]
 jmp build_continuations_common
build_continuations_b:
 lea rdi,[rel continuation_table_b]
 lea rsi,[rel graph_b]
 lea rdx,[rel continuation_request_b]
 jmp build_continuations_common
build_continuations_common:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 mov rdi,rbx
 call clear_continuation_request
 mov qword [rbx+NEBOC_CONTINUATION_REQUEST_EDGE_ID_OFFSET],1
 mov qword [rbx+NEBOC_CONTINUATION_REQUEST_FUNCTION_ID_OFFSET],7
 mov qword [rbx+NEBOC_CONTINUATION_REQUEST_DOMAIN_ID_OFFSET],1
 mov rdi,r12
 mov rsi,r13
 mov rdx,rbx
 call neboc_continuation_create_from_edge
 test eax,eax
 jnz .done
 mov rdi,rbx
 call clear_continuation_request
 mov qword [rbx+NEBOC_CONTINUATION_REQUEST_EDGE_ID_OFFSET],2
 mov qword [rbx+NEBOC_CONTINUATION_REQUEST_FUNCTION_ID_OFFSET],7
 mov qword [rbx+NEBOC_CONTINUATION_REQUEST_DOMAIN_ID_OFFSET],1
 mov rdi,r12
 mov rsi,r13
 mov rdx,rbx
 call neboc_continuation_create_from_edge
.done:
 pop r13
 pop r12
 pop rbx
 ret

build_continuations_one_a:
 lea rdi,[rel continuation_request_a]
 call clear_continuation_request
 mov qword [rel continuation_request_a+NEBOC_CONTINUATION_REQUEST_EDGE_ID_OFFSET],1
 mov qword [rel continuation_request_a+NEBOC_CONTINUATION_REQUEST_FUNCTION_ID_OFFSET],7
 mov qword [rel continuation_request_a+NEBOC_CONTINUATION_REQUEST_DOMAIN_ID_OFFSET],1
 lea rdi,[rel continuation_table_a]
 lea rsi,[rel graph_a]
 lea rdx,[rel continuation_request_a]
 jmp neboc_continuation_create_from_edge


build_plan_one_a:
 lea rdi,[rel plan_request_a]
 call clear_plan_request
 mov qword [rel plan_request_a+NEBOC_FUNCTION_PLAN_REQUEST_FUNCTION_ID_OFFSET],7
 mov qword [rel plan_request_a+NEBOC_FUNCTION_PLAN_REQUEST_SOURCE_ORDER_OFFSET],10
 mov qword [rel plan_request_a+NEBOC_FUNCTION_PLAN_REQUEST_SOURCE_NODE_ID_OFFSET],101
 mov qword [rel plan_request_a+NEBOC_FUNCTION_PLAN_REQUEST_ROUTE_ID_OFFSET],1
 mov qword [rel plan_request_a+NEBOC_FUNCTION_PLAN_REQUEST_PENDING_ID_OFFSET],1
 mov qword [rel plan_request_a+NEBOC_FUNCTION_PLAN_REQUEST_RUNTIME_CONTRACT_ID_OFFSET],NEBOC_RUNTIME_CONTRACT_TEXT_SCAN_DEFAULT
 mov qword [rel plan_request_a+NEBOC_FUNCTION_PLAN_REQUEST_FIRST_CONTINUATION_ID_OFFSET],1
 mov qword [rel plan_request_a+NEBOC_FUNCTION_PLAN_REQUEST_CONTINUATION_COUNT_OFFSET],1
 lea rdi,[rel lowering_table_a]
 lea rsi,[rel continuation_table_a]
 lea rdx,[rel plan_request_a]
 jmp neboc_function_lowering_plan_create_scan

build_plan_a:
 lea rdi,[rel lowering_table_a]
 lea rsi,[rel continuation_table_a]
 lea rdx,[rel plan_request_a]
 jmp build_plan_common
build_plan_b:
 lea rdi,[rel lowering_table_b]
 lea rsi,[rel continuation_table_b]
 lea rdx,[rel plan_request_b]
 jmp build_plan_common
build_plan_common:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 mov rdi,rbx
 call clear_plan_request
 mov qword [rbx+NEBOC_FUNCTION_PLAN_REQUEST_FUNCTION_ID_OFFSET],7
 mov qword [rbx+NEBOC_FUNCTION_PLAN_REQUEST_SOURCE_ORDER_OFFSET],10
 mov qword [rbx+NEBOC_FUNCTION_PLAN_REQUEST_SOURCE_NODE_ID_OFFSET],101
 mov qword [rbx+NEBOC_FUNCTION_PLAN_REQUEST_ROUTE_ID_OFFSET],1
 mov qword [rbx+NEBOC_FUNCTION_PLAN_REQUEST_PENDING_ID_OFFSET],1
 mov qword [rbx+NEBOC_FUNCTION_PLAN_REQUEST_RUNTIME_CONTRACT_ID_OFFSET],NEBOC_RUNTIME_CONTRACT_TEXT_SCAN_DEFAULT
 mov qword [rbx+NEBOC_FUNCTION_PLAN_REQUEST_FIRST_CONTINUATION_ID_OFFSET],1
 mov qword [rbx+NEBOC_FUNCTION_PLAN_REQUEST_CONTINUATION_COUNT_OFFSET],2
 mov rdi,r12
 mov rsi,r13
 mov rdx,rbx
 call neboc_function_lowering_plan_create_scan
 pop r13
 pop r12
 pop rbx
 ret

create_pending_simple:
 push rdi
 push rsi
 push rdx
 push rcx
 push r8
 push r9
 mov rdi,rsi
 call clear_pending_request
 pop r9
 pop r8
 pop rcx
 pop rdx
 pop rsi
 pop rdi
 mov [rsi+NEBOC_PENDING_REQUEST_SCAN_NODE_OFFSET],rdx
 mov [rsi+NEBOC_PENDING_REQUEST_ROUTE_ID_OFFSET],rcx
 mov [rsi+NEBOC_PENDING_REQUEST_INTRINSIC_ID_OFFSET],r8
 mov [rsi+NEBOC_PENDING_REQUEST_SOURCE_ORDER_OFFSET],r9
 mov qword [rsi+NEBOC_PENDING_REQUEST_TERMINAL_TYPE_OFFSET],NEBOC_TYPE_ID_PENDING_TEXT
 jmp neboc_pending_record_create

make_dump:
 push rdi
 mov [rdi+NEBOC_LOWERING_DUMP_CONTINUATION_TABLE_OFFSET],rsi
 mov [rdi+NEBOC_LOWERING_DUMP_PLAN_TABLE_OFFSET],rdx
 mov [rdi+NEBOC_LOWERING_DUMP_BUFFER_OFFSET],rcx
 mov qword [rdi+NEBOC_LOWERING_DUMP_CAPACITY_OFFSET],DUMP_CAPACITY
 mov qword [rdi+NEBOC_LOWERING_DUMP_LENGTH_OFFSET],0
 pop rdi
 jmp neboc_lowering_dump

clear_pending_request:
 xor eax,eax
 mov ecx,NEBOC_PENDING_REQUEST_QWORDS
.loop:
 mov [rdi],rax
 add rdi,8
 dec ecx
 jnz .loop
 ret
clear_edge_request:
 xor eax,eax
 mov ecx,NEBOC_DEPENDENCY_REQUEST_QWORDS
.loop:
 mov [rdi],rax
 add rdi,8
 dec ecx
 jnz .loop
 ret
clear_continuation_request:
 xor eax,eax
 mov ecx,NEBOC_CONTINUATION_REQUEST_QWORDS
.loop:
 mov [rdi],rax
 add rdi,8
 dec ecx
 jnz .loop
 ret
clear_plan_request:
 xor eax,eax
 mov ecx,NEBOC_FUNCTION_PLAN_REQUEST_QWORDS
.loop:
 mov [rdi],rax
 add rdi,8
 dec ecx
 jnz .loop
 ret

test_pass:
 xor edi,edi
 call neboc_host_process_exit
test_fail:
 mov edi,1
 call neboc_host_process_exit
test_usage:
 mov edi,64
 call neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
