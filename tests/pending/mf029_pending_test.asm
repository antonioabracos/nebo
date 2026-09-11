; Nebo Assembly — MF029 Pending records and dependency graph scenarios
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/intrinsic/intrinsic_table.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/semantic/database/semantic_database.inc"
%include "compiler/dependency/pending/pending_table.inc"
%include "compiler/dependency/graph/dependency_graph.inc"
%include "compiler/dependency/graph/dependency_dump.inc"
%include "compiler/dependency/graph/dependency_diagnostics.inc"

extern neboc_pending_table_init
extern neboc_pending_table_get
extern neboc_pending_record_create
extern neboc_dependency_graph_init
extern neboc_dependency_graph_register_pending
extern neboc_dependency_graph_get_node
extern neboc_dependency_graph_get_edge
extern neboc_dependency_graph_add_edge
extern neboc_dependency_graph_freeze
extern neboc_dependency_dump
extern neboc_dependency_graph_diagnostic_name
extern neboc_semantic_database_attach_dependencies
extern neboc_host_process_exit

global _start

%define PENDING_CAPACITY 8
%define EDGE_CAPACITY 16
%define DUMP_CAPACITY 8192

section .rodata
expected_dump:
 incbin "tests/pending/goldens/dependency-graph.txt"
expected_dump_end:
expected_cycle: db 'pending-dependency-cycle'

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
dump_request_a: resb NEBOC_DEPENDENCY_DUMP_SIZE
dump_request_b: resb NEBOC_DEPENDENCY_DUMP_SIZE
dump_a: resb DUMP_CAPACITY
dump_b: resb DUMP_CAPACITY
out_ptr: resq 1
diag_ptr: resq 1
diag_len: resq 1
database: resb NEBOC_SEMANTIC_DATABASE_SIZE

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

; NEBO-PENDING-CONTRACT-001 — scan creates a complete Pending<Text> record.
scenario_1:
 lea rdi,[rel pending_table_a]
 lea rsi,[rel pending_request_a]
 mov edx,101
 mov ecx,1
 mov r8d,NEBOC_INTRINSIC_ID_TEXT_SCAN
 mov r9d,1
 call create_pending_simple
 test eax,eax
 jnz test_fail
 cmp qword [rel pending_request_a+NEBOC_PENDING_REQUEST_OUT_PENDING_ID_OFFSET],1
 jne test_fail
 lea rdi,[rel pending_table_a]
 mov esi,1
 lea rdx,[rel out_ptr]
 call neboc_pending_table_get
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_ptr]
 cmp qword [rbx+NEBOC_PENDING_RECORD_PENDING_TYPE_ID_OFFSET],NEBOC_TYPE_ID_PENDING_TEXT
 jne test_fail
 cmp qword [rbx+NEBOC_PENDING_RECORD_RESULT_TYPE_ID_OFFSET],NEBOC_TYPE_ID_TEXT
 jne test_fail
 cmp qword [rbx+NEBOC_PENDING_RECORD_ROUTE_ID_OFFSET],1
 jne test_fail
 mov rax,[rbx+NEBOC_PENDING_RECORD_FLAGS_OFFSET]
 and rax,NEBOC_PENDING_REQUIRED_FLAGS
 cmp rax,NEBOC_PENDING_REQUIRED_FLAGS
 jne test_fail
 jmp test_pass

; NEBO-PENDING-CONTRACT-002 — a Text consumer creates the producer edge.
scenario_2:
 call create_and_register_one
 test eax,eax
 jnz test_fail
 lea rdi,[rel graph_a]
 lea rsi,[rel edge_request_a]
 mov edx,1
 xor ecx,ecx
 mov r8d,201
 mov r9d,501
 mov r10d,1
 call add_edge_simple
 test eax,eax
 jnz test_fail
 cmp qword [rel edge_request_a+NEBOC_DEPENDENCY_REQUEST_OUT_EDGE_ID_OFFSET],1
 jne test_fail
 lea rdi,[rel graph_a]
 mov esi,1
 lea rdx,[rel out_ptr]
 call neboc_dependency_graph_get_edge
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_ptr]
 cmp qword [rbx+NEBOC_DEPENDENCY_EDGE_PRODUCER_PENDING_ID_OFFSET],1
 jne test_fail
 cmp qword [rbx+NEBOC_DEPENDENCY_EDGE_CONSUMER_NODE_ID_OFFSET],201
 jne test_fail
 cmp qword [rbx+NEBOC_DEPENDENCY_EDGE_CONSUMER_SYMBOL_ID_OFFSET],501
 jne test_fail
 cmp qword [rbx+NEBOC_DEPENDENCY_EDGE_FLAGS_OFFSET],NEBOC_DEPENDENCY_EDGE_FLAG_TERMINAL_CONSUMER | NEBOC_DEPENDENCY_EDGE_FLAG_SOURCE_ORDERED
 jne test_fail
 jmp test_pass

; NEBO-PENDING-CONTRACT-003 — an unrelated Pending remains independent.
scenario_3:
 call create_two_and_register
 test eax,eax
 jnz test_fail
 lea rdi,[rel graph_a]
 lea rsi,[rel edge_request_a]
 mov edx,1
 xor ecx,ecx
 mov r8d,301
 mov r9d,601
 mov r10d,1
 call add_edge_simple
 test eax,eax
 jnz test_fail
 lea rdi,[rel graph_a]
 mov esi,2
 lea rdx,[rel out_ptr]
 call neboc_dependency_graph_get_node
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_ptr]
 cmp qword [rbx+NEBOC_DEPENDENCY_NODE_EDGE_COUNT_OFFSET],0
 jne test_fail
 cmp qword [rbx+NEBOC_DEPENDENCY_NODE_INDEGREE_OFFSET],0
 jne test_fail
 mov rax,[rbx+NEBOC_DEPENDENCY_NODE_FLAGS_OFFSET]
 test rax,NEBOC_DEPENDENCY_NODE_FLAG_INDEPENDENT
 jz test_fail
 test rax,NEBOC_DEPENDENCY_NODE_FLAG_ORPHAN
 jz test_fail
 jmp test_pass

; NEBO-PENDING-CONTRACT-004 — dependents are canonicalized by source order.
scenario_4:
 call create_and_register_one
 test eax,eax
 jnz test_fail
 lea rdi,[rel graph_a]
 lea rsi,[rel edge_request_a]
 mov edx,1
 xor ecx,ecx
 mov r8d,430
 mov r9d,730
 mov r10d,30
 call add_edge_simple
 test eax,eax
 jnz test_fail
 lea rdi,[rel graph_a]
 lea rsi,[rel edge_request_a]
 mov edx,1
 xor ecx,ecx
 mov r8d,410
 mov r9d,710
 mov r10d,10
 call add_edge_simple
 test eax,eax
 jnz test_fail
 lea rdi,[rel graph_a]
 lea rsi,[rel edge_request_a]
 mov edx,1
 xor ecx,ecx
 mov r8d,420
 mov r9d,720
 mov r10d,20
 call add_edge_simple
 test eax,eax
 jnz test_fail
 mov r13d,1
 mov r14d,10
.order_loop:
 lea rdi,[rel graph_a]
 mov rsi,r13
 lea rdx,[rel out_ptr]
 call neboc_dependency_graph_get_edge
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_ptr]
 cmp [rbx+NEBOC_DEPENDENCY_EDGE_SOURCE_ORDER_OFFSET],r14
 jne test_fail
 cmp [rbx+NEBOC_DEPENDENCY_EDGE_CONTINUATION_SEED_ID_OFFSET],r13
 jne test_fail
 inc r13
 add r14,10
 cmp r13,4
 jb .order_loop
 jmp test_pass

; NEBO-PENDING-NEG-005 — a static dependency cycle is rejected without mutation.
scenario_5:
 call create_two_and_register
 test eax,eax
 jnz test_fail
 lea rdi,[rel graph_a]
 lea rsi,[rel edge_request_a]
 mov edx,1
 mov ecx,2
 mov r8d,501
 mov r9d,801
 mov r10d,1
 call add_edge_simple
 test eax,eax
 jnz test_fail
 lea rdi,[rel graph_a]
 lea rsi,[rel edge_request_a]
 mov edx,2
 mov ecx,1
 mov r8d,502
 mov r9d,802
 mov r10d,2
 call add_edge_simple
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel edge_request_a+NEBOC_DEPENDENCY_REQUEST_ERROR_CODE_OFFSET],NEBOC_DEPENDENCY_ERROR_CYCLE
 jne test_fail
 cmp qword [rel graph_a+NEBOC_DEPENDENCY_GRAPH_EDGE_COUNT_OFFSET],1
 jne test_fail
 cmp qword [rel graph_a+NEBOC_DEPENDENCY_GRAPH_CYCLE_FROM_OFFSET],2
 jne test_fail
 cmp qword [rel graph_a+NEBOC_DEPENDENCY_GRAPH_CYCLE_TO_OFFSET],1
 jne test_fail
 mov edi,NEBOC_DEPENDENCY_ERROR_CYCLE
 lea rsi,[rel diag_ptr]
 lea rdx,[rel diag_len]
 call neboc_dependency_graph_diagnostic_name
 test eax,eax
 jnz test_fail
 cmp qword [rel diag_len],NEBOC_DEPENDENCY_DIAGNOSTIC_CYCLE_LENGTH
 jne test_fail
 mov rsi,[rel diag_ptr]
 lea rdi,[rel expected_cycle]
 mov ecx,NEBOC_DEPENDENCY_DIAGNOSTIC_CYCLE_LENGTH
 repe cmpsb
 jne test_fail
 jmp test_pass

; NEBO-PENDING-CONTRACT-008 — continuation seed IDs and dumps are deterministic.
scenario_6:
 call setup_b
 test eax,eax
 jnz test_fail
 lea rdi,[rel pending_table_a]
 lea rsi,[rel graph_a]
 lea rdx,[rel pending_request_a]
 lea rcx,[rel edge_request_a]
 xor r8d,r8d
 call build_canonical
 test eax,eax
 jnz test_fail
 lea rdi,[rel pending_table_b]
 lea rsi,[rel graph_b]
 lea rdx,[rel pending_request_b]
 lea rcx,[rel edge_request_b]
 mov r8d,1
 call build_canonical
 test eax,eax
 jnz test_fail
 mov rax,[rel graph_a+NEBOC_DEPENDENCY_GRAPH_HASH_OFFSET]
 cmp rax,[rel graph_b+NEBOC_DEPENDENCY_GRAPH_HASH_OFFSET]
 jne test_fail
 lea rdi,[rel dump_request_a]
 lea rsi,[rel pending_table_a]
 lea rdx,[rel graph_a]
 lea rcx,[rel dump_a]
 call make_dump
 test eax,eax
 jnz test_fail
 lea rdi,[rel dump_request_b]
 lea rsi,[rel pending_table_b]
 lea rdx,[rel graph_b]
 lea rcx,[rel dump_b]
 call make_dump
 test eax,eax
 jnz test_fail
 mov rcx,[rel dump_request_a+NEBOC_DEPENDENCY_DUMP_LENGTH_OFFSET]
 cmp rcx,[rel dump_request_b+NEBOC_DEPENDENCY_DUMP_LENGTH_OFFSET]
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

; NEBO-PENDING-CONTRACT-009 — captures include only values actually used.
scenario_7:
 call create_and_register_one
 test eax,eax
 jnz test_fail
 lea rdi,[rel edge_request_a]
 call clear_edge_request
 mov qword [rel edge_request_a+NEBOC_DEPENDENCY_REQUEST_PRODUCER_PENDING_ID_OFFSET],1
 mov qword [rel edge_request_a+NEBOC_DEPENDENCY_REQUEST_CONSUMER_NODE_ID_OFFSET],701
 mov qword [rel edge_request_a+NEBOC_DEPENDENCY_REQUEST_CONSUMER_SYMBOL_ID_OFFSET],901
 mov qword [rel edge_request_a+NEBOC_DEPENDENCY_REQUEST_SOURCE_ORDER_OFFSET],1
 mov qword [rel edge_request_a+NEBOC_DEPENDENCY_REQUEST_CAPTURE_CANDIDATE_COUNT_OFFSET],4
 mov qword [rel edge_request_a+NEBOC_DEPENDENCY_REQUEST_CAPTURE_USED_MASK_OFFSET],5
 mov qword [rel edge_request_a+NEBOC_DEPENDENCY_REQUEST_CAPTURE_0_OFFSET],11
 mov qword [rel edge_request_a+NEBOC_DEPENDENCY_REQUEST_CAPTURE_1_OFFSET],22
 mov qword [rel edge_request_a+NEBOC_DEPENDENCY_REQUEST_CAPTURE_2_OFFSET],33
 mov qword [rel edge_request_a+NEBOC_DEPENDENCY_REQUEST_CAPTURE_3_OFFSET],44
 lea rdi,[rel graph_a]
 lea rsi,[rel edge_request_a]
 call neboc_dependency_graph_add_edge
 test eax,eax
 jnz test_fail
 lea rdi,[rel graph_a]
 mov esi,1
 lea rdx,[rel out_ptr]
 call neboc_dependency_graph_get_edge
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_ptr]
 cmp qword [rbx+NEBOC_DEPENDENCY_EDGE_CAPTURE_COUNT_OFFSET],2
 jne test_fail
 cmp qword [rbx+NEBOC_DEPENDENCY_EDGE_CAPTURE_0_OFFSET],11
 jne test_fail
 cmp qword [rbx+NEBOC_DEPENDENCY_EDGE_CAPTURE_1_OFFSET],33
 jne test_fail
 cmp qword [rbx+NEBOC_DEPENDENCY_EDGE_CAPTURE_2_OFFSET],0
 jne test_fail
 cmp qword [rbx+NEBOC_DEPENDENCY_EDGE_CAPTURE_3_OFFSET],0
 jne test_fail
 test qword [rbx+NEBOC_DEPENDENCY_EDGE_FLAGS_OFFSET],NEBOC_DEPENDENCY_EDGE_FLAG_HAS_CAPTURES
 jz test_fail
 jmp test_pass

; Infrastructure — orphan checks are explicit and deterministic.
scenario_8:
 call create_three_and_register
 test eax,eax
 jnz test_fail
 lea rdi,[rel graph_a]
 lea rsi,[rel edge_request_a]
 mov edx,1
 xor ecx,ecx
 mov r8d,801
 mov r9d,1001
 mov r10d,1
 call add_edge_simple
 test eax,eax
 jnz test_fail
 lea rdi,[rel graph_a]
 lea rsi,[rel edge_request_a]
 mov edx,2
 xor ecx,ecx
 mov r8d,802
 mov r9d,1002
 mov r10d,2
 call add_edge_simple
 test eax,eax
 jnz test_fail
 lea rdi,[rel graph_a]
 lea rsi,[rel pending_table_a]
 call neboc_dependency_graph_freeze
 test eax,eax
 jnz test_fail
 cmp qword [rel graph_a+NEBOC_DEPENDENCY_GRAPH_ORPHAN_COUNT_OFFSET],1
 jne test_fail
 lea rdi,[rel pending_table_a]
 mov esi,3
 lea rdx,[rel out_ptr]
 call neboc_pending_table_get
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_ptr]
 cmp qword [rbx+NEBOC_PENDING_RECORD_STATE_OFFSET],NEBOC_PENDING_STATE_ORPHAN
 jne test_fail
 test qword [rbx+NEBOC_PENDING_RECORD_FLAGS_OFFSET],NEBOC_PENDING_FLAG_ORPHAN
 jz test_fail
 jmp test_pass

; Infrastructure — frozen dependency domains attach to SemanticDatabase.
scenario_9:
 call create_and_register_one
 test eax,eax
 jnz test_fail
 lea rdi,[rel graph_a]
 lea rsi,[rel edge_request_a]
 mov edx,1
 xor ecx,ecx
 mov r8d,901
 mov r9d,1101
 mov r10d,1
 call add_edge_simple
 test eax,eax
 jnz test_fail
 lea rdi,[rel graph_a]
 lea rsi,[rel pending_table_a]
 call neboc_dependency_graph_freeze
 test eax,eax
 jnz test_fail
 lea rdi,[rel database]
 call clear_database
 lea rdi,[rel database]
 lea rsi,[rel pending_table_a]
 lea rdx,[rel graph_a]
 call neboc_semantic_database_attach_dependencies
 test eax,eax
 jnz test_fail
 lea rax,[rel pending_table_a]
 cmp [rel database+NEBOC_SEMANTIC_DATABASE_PENDING_TABLE_OFFSET],rax
 jne test_fail
 lea rax,[rel graph_a]
 cmp [rel database+NEBOC_SEMANTIC_DATABASE_DEPENDENCY_GRAPH_OFFSET],rax
 jne test_fail
 mov rax,[rel graph_a+NEBOC_DEPENDENCY_GRAPH_FLAGS_OFFSET]
 and rax,NEBOC_DEPENDENCY_GRAPH_REQUIRED_FLAGS
 cmp rax,NEBOC_DEPENDENCY_GRAPH_REQUIRED_FLAGS
 jne test_fail
 jmp test_pass

; setup_a/setup_b
setup_a:
 lea rdi,[rel pending_table_a]
 lea rsi,[rel pending_entries_a]
 mov edx,PENDING_CAPACITY
 call neboc_pending_table_init
 test eax,eax
 jnz .setup_a_done
 lea rdi,[rel graph_a]
 lea rsi,[rel nodes_a]
 mov edx,PENDING_CAPACITY
 lea rcx,[rel edges_a]
 mov r8d,EDGE_CAPACITY
 call neboc_dependency_graph_init
.setup_a_done:
 ret

setup_b:
 lea rdi,[rel pending_table_b]
 lea rsi,[rel pending_entries_b]
 mov edx,PENDING_CAPACITY
 call neboc_pending_table_init
 test eax,eax
 jnz .setup_b_done
 lea rdi,[rel graph_b]
 lea rsi,[rel nodes_b]
 mov edx,PENDING_CAPACITY
 lea rcx,[rel edges_b]
 mov r8d,EDGE_CAPACITY
 call neboc_dependency_graph_init
.setup_b_done:
 ret

; create_pending_simple(table*, request*, scan_node, route_id, intrinsic_id, source_order)
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

create_and_register_one:
 lea rdi,[rel pending_table_a]
 lea rsi,[rel pending_request_a]
 mov edx,111
 mov ecx,1
 mov r8d,NEBOC_INTRINSIC_ID_TEXT_SCAN
 mov r9d,1
 call create_pending_simple
 test eax,eax
 jnz .create_one_done
 lea rdi,[rel graph_a]
 lea rsi,[rel pending_table_a]
 mov edx,1
 call neboc_dependency_graph_register_pending
.create_one_done:
 ret

create_two_and_register:
 call create_and_register_one
 test eax,eax
 jnz .create_two_done
 lea rdi,[rel pending_table_a]
 lea rsi,[rel pending_request_a]
 mov edx,112
 mov ecx,2
 mov r8d,NEBOC_INTRINSIC_ID_CONSOLE_SCAN
 mov r9d,2
 call create_pending_simple
 test eax,eax
 jnz .create_two_done
 lea rdi,[rel graph_a]
 lea rsi,[rel pending_table_a]
 mov edx,2
 call neboc_dependency_graph_register_pending
.create_two_done:
 ret

create_three_and_register:
 call create_two_and_register
 test eax,eax
 jnz .create_three_done
 lea rdi,[rel pending_table_a]
 lea rsi,[rel pending_request_a]
 mov edx,113
 mov ecx,3
 mov r8d,NEBOC_INTRINSIC_ID_TEXT_SCAN
 mov r9d,3
 call create_pending_simple
 test eax,eax
 jnz .create_three_done
 lea rdi,[rel graph_a]
 lea rsi,[rel pending_table_a]
 mov edx,3
 call neboc_dependency_graph_register_pending
.create_three_done:
 ret

; add_edge_simple(graph*, request*, producer, consumer_pending, consumer_node, consumer_symbol, source_order)
add_edge_simple:
 push rdi
 push rsi
 push rdx
 push rcx
 push r8
 push r9
 push r10
 mov rdi,rsi
 call clear_edge_request
 pop r10
 pop r9
 pop r8
 pop rcx
 pop rdx
 pop rsi
 pop rdi
 mov [rsi+NEBOC_DEPENDENCY_REQUEST_PRODUCER_PENDING_ID_OFFSET],rdx
 mov [rsi+NEBOC_DEPENDENCY_REQUEST_CONSUMER_PENDING_ID_OFFSET],rcx
 mov [rsi+NEBOC_DEPENDENCY_REQUEST_CONSUMER_NODE_ID_OFFSET],r8
 mov [rsi+NEBOC_DEPENDENCY_REQUEST_CONSUMER_SYMBOL_ID_OFFSET],r9
 mov [rsi+NEBOC_DEPENDENCY_REQUEST_SOURCE_ORDER_OFFSET],r10
 jmp neboc_dependency_graph_add_edge

; build_canonical(pending_table*, graph*, pending_request*, edge_request*, reverse_edges)
build_canonical:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov ebx,r8d
 ; three Pending records in fixed source order
 mov rdi,r12
 mov rsi,r14
 mov edx,1001
 mov ecx,11
 mov r8d,NEBOC_INTRINSIC_ID_TEXT_SCAN
 mov r9d,1
 call create_pending_simple
 test eax,eax
 jnz .canonical_done
 mov rdi,r13
 mov rsi,r12
 mov edx,1
 call neboc_dependency_graph_register_pending
 test eax,eax
 jnz .canonical_done
 mov rdi,r12
 mov rsi,r14
 mov edx,1002
 mov ecx,12
 mov r8d,NEBOC_INTRINSIC_ID_CONSOLE_SCAN
 mov r9d,2
 call create_pending_simple
 test eax,eax
 jnz .canonical_done
 mov rdi,r13
 mov rsi,r12
 mov edx,2
 call neboc_dependency_graph_register_pending
 test eax,eax
 jnz .canonical_done
 mov rdi,r12
 mov rsi,r14
 mov edx,1003
 mov ecx,13
 mov r8d,NEBOC_INTRINSIC_ID_TEXT_SCAN
 mov r9d,3
 call create_pending_simple
 test eax,eax
 jnz .canonical_done
 mov rdi,r13
 mov rsi,r12
 mov edx,3
 call neboc_dependency_graph_register_pending
 test eax,eax
 jnz .canonical_done
 test ebx,ebx
 jnz .canonical_reverse
 ; canonical insertion order variant A: 30,10,20,40
 mov r10d,30
 call canonical_edge_1
 test eax,eax
 jnz .canonical_done
 mov r10d,10
 call canonical_edge_2
 test eax,eax
 jnz .canonical_done
 mov r10d,20
 call canonical_edge_3
 test eax,eax
 jnz .canonical_done
 mov r10d,40
 call canonical_edge_4
 jmp .canonical_freeze
.canonical_reverse:
 ; variant B: 40,20,10,30
 mov r10d,40
 call canonical_edge_4
 test eax,eax
 jnz .canonical_done
 mov r10d,20
 call canonical_edge_3
 test eax,eax
 jnz .canonical_done
 mov r10d,10
 call canonical_edge_2
 test eax,eax
 jnz .canonical_done
 mov r10d,30
 call canonical_edge_1
.canonical_freeze:
 test eax,eax
 jnz .canonical_done
 mov rdi,r13
 mov rsi,r12
 call neboc_dependency_graph_freeze
.canonical_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

canonical_edge_1:
 mov rdi,r15
 call clear_edge_request
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_PRODUCER_PENDING_ID_OFFSET],1
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_CONSUMER_NODE_ID_OFFSET],2001
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_CONSUMER_SYMBOL_ID_OFFSET],3001
 mov [r15+NEBOC_DEPENDENCY_REQUEST_SOURCE_ORDER_OFFSET],r10
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_CAPTURE_CANDIDATE_COUNT_OFFSET],2
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_CAPTURE_USED_MASK_OFFSET],1
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_CAPTURE_0_OFFSET],41
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_CAPTURE_1_OFFSET],42
 mov rdi,r13
 mov rsi,r15
 jmp neboc_dependency_graph_add_edge
canonical_edge_2:
 mov rdi,r15
 call clear_edge_request
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_PRODUCER_PENDING_ID_OFFSET],1
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_CONSUMER_NODE_ID_OFFSET],2002
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_CONSUMER_SYMBOL_ID_OFFSET],3002
 mov [r15+NEBOC_DEPENDENCY_REQUEST_SOURCE_ORDER_OFFSET],r10
 mov rdi,r13
 mov rsi,r15
 jmp neboc_dependency_graph_add_edge
canonical_edge_3:
 mov rdi,r15
 call clear_edge_request
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_PRODUCER_PENDING_ID_OFFSET],2
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_CONSUMER_PENDING_ID_OFFSET],3
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_CONSUMER_NODE_ID_OFFSET],2003
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_CONSUMER_SYMBOL_ID_OFFSET],3003
 mov [r15+NEBOC_DEPENDENCY_REQUEST_SOURCE_ORDER_OFFSET],r10
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_CAPTURE_CANDIDATE_COUNT_OFFSET],2
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_CAPTURE_USED_MASK_OFFSET],3
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_CAPTURE_0_OFFSET],51
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_CAPTURE_1_OFFSET],52
 mov rdi,r13
 mov rsi,r15
 jmp neboc_dependency_graph_add_edge
canonical_edge_4:
 mov rdi,r15
 call clear_edge_request
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_PRODUCER_PENDING_ID_OFFSET],3
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_CONSUMER_NODE_ID_OFFSET],2004
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_CONSUMER_SYMBOL_ID_OFFSET],3004
 mov [r15+NEBOC_DEPENDENCY_REQUEST_SOURCE_ORDER_OFFSET],r10
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_CAPTURE_CANDIDATE_COUNT_OFFSET],1
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_CAPTURE_USED_MASK_OFFSET],1
 mov qword [r15+NEBOC_DEPENDENCY_REQUEST_CAPTURE_0_OFFSET],61
 mov rdi,r13
 mov rsi,r15
 jmp neboc_dependency_graph_add_edge

; make_dump(request*, pending_table*, graph*, buffer*)
make_dump:
 push rdi
 mov [rdi+NEBOC_DEPENDENCY_DUMP_PENDING_TABLE_OFFSET],rsi
 mov [rdi+NEBOC_DEPENDENCY_DUMP_GRAPH_OFFSET],rdx
 mov [rdi+NEBOC_DEPENDENCY_DUMP_BUFFER_OFFSET],rcx
 mov qword [rdi+NEBOC_DEPENDENCY_DUMP_CAPACITY_OFFSET],DUMP_CAPACITY
 mov qword [rdi+NEBOC_DEPENDENCY_DUMP_LENGTH_OFFSET],0
 pop rdi
 jmp neboc_dependency_dump

clear_pending_request:
 xor eax,eax
 mov ecx,NEBOC_PENDING_REQUEST_QWORDS
.clear_pending_loop:
 mov [rdi],rax
 add rdi,8
 dec ecx
 jnz .clear_pending_loop
 ret
clear_edge_request:
 xor eax,eax
 mov ecx,NEBOC_DEPENDENCY_REQUEST_QWORDS
.clear_edge_loop:
 mov [rdi],rax
 add rdi,8
 dec ecx
 jnz .clear_edge_loop
 ret
clear_database:
 xor eax,eax
 mov ecx,NEBOC_SEMANTIC_DATABASE_QWORDS
.clear_database_loop:
 mov [rdi],rax
 add rdi,8
 dec ecx
 jnz .clear_database_loop
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
