; Nebo Assembly — MF027 compile-time Console routing native scenarios
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/intrinsic/intrinsic_table.inc"
%include "compiler/semantic/console-routing/console_routing_table.inc"
%include "compiler/semantic/console-routing/console_route_dump.inc"
%include "compiler/semantic/database/semantic_database.inc"

extern neboc_console_routing_table_init
extern neboc_console_routing_table_get
extern neboc_console_route_analyze
extern neboc_console_routing_table_freeze
extern neboc_console_route_dump
extern neboc_semantic_database_attach_routes
extern neboc_host_process_exit

global _start

section .rodata
expected_routes:
 incbin "tests/routing/goldens/011-console-routes.txt"
expected_routes_end:

%define ROUTE_CAPACITY 8
%define DUMP_CAPACITY 4096

section .bss align=16
route_entries_a: resb ROUTE_CAPACITY * NEBOC_CONSOLE_ROUTE_SIZE
route_entries_b: resb ROUTE_CAPACITY * NEBOC_CONSOLE_ROUTE_SIZE
route_table_a: resb NEBOC_CONSOLE_ROUTING_TABLE_SIZE
route_table_b: resb NEBOC_CONSOLE_ROUTING_TABLE_SIZE
request_a: resb NEBOC_CONSOLE_ROUTE_REQUEST_SIZE
request_b: resb NEBOC_CONSOLE_ROUTE_REQUEST_SIZE
dump_request_a: resb NEBOC_CONSOLE_ROUTE_DUMP_REQUEST_SIZE
dump_request_b: resb NEBOC_CONSOLE_ROUTE_DUMP_REQUEST_SIZE
dump_a: resb DUMP_CAPACITY
dump_b: resb DUMP_CAPACITY
database: resb NEBOC_SEMANTIC_DATABASE_SIZE
out_ptr: resq 1

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
 call setup_tables
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

scenario_1:
 lea rdi,[rel route_table_a]
 lea rsi,[rel request_a]
 mov edx,NEBOC_ROUTE_SHAPE_VALUE_CONSOLE
 mov ecx,11
 mov r8d,12
 xor r9d,r9d
 mov r10d,1
 call analyze_simple
 test eax,eax
 jnz test_fail
 cmp qword [rel request_a+NEBOC_CONSOLE_ROUTE_REQUEST_OUT_ROUTE_ID_OFFSET],1
 jne test_fail
 cmp qword [rel request_a+NEBOC_CONSOLE_ROUTE_REQUEST_OUT_MODE_OFFSET],NEBOC_CONSOLE_ROUTE_MODE_DEFAULT
 jne test_fail
 mov esi,1
 call get_route_a
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_ptr]
 cmp qword [rbx+NEBOC_CONSOLE_ROUTE_IDENTITY_SOURCE_OFFSET],NEBOC_CONSOLE_IDENTITY_DEFAULT
 jne test_fail
 cmp qword [rbx+NEBOC_CONSOLE_ROUTE_IDENTITY_ID_OFFSET],NEBOC_CONSOLE_DEFAULT_IDENTITY_ID
 jne test_fail
 cmp qword [rbx+NEBOC_CONSOLE_ROUTE_OPERATION_MASK_OFFSET],NEBOC_ROUTE_OPERATION_ENSURE_DEFAULT | NEBOC_ROUTE_OPERATION_APPEND_INITIAL
 jne test_fail
 jmp test_pass

scenario_2:
 lea rdi,[rel route_table_a]
 lea rsi,[rel request_a]
 mov edx,NEBOC_ROUTE_SHAPE_VALUE_CONSOLE_BIND
 mov ecx,21
 mov r8d,22
 mov r9d,301
 mov r10d,1
 call analyze_simple
 test eax,eax
 jnz test_fail
 cmp qword [rel request_a+NEBOC_CONSOLE_ROUTE_REQUEST_OUT_MODE_OFFSET],NEBOC_CONSOLE_ROUTE_MODE_NAMED
 jne test_fail
 mov esi,1
 call get_route_a
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_ptr]
 cmp qword [rbx+NEBOC_CONSOLE_ROUTE_IDENTITY_SOURCE_OFFSET],NEBOC_CONSOLE_IDENTITY_BINDING_SYMBOL
 jne test_fail
 cmp qword [rbx+NEBOC_CONSOLE_ROUTE_IDENTITY_ID_OFFSET],301
 jne test_fail
 test qword [rbx+NEBOC_CONSOLE_ROUTE_FLAGS_OFFSET],NEBOC_ROUTE_FLAG_CREATES_INDEPENDENT
 jz test_fail
 jmp test_pass

scenario_3:
 lea rdi,[rel route_table_a]
 lea rsi,[rel request_a]
 mov edx,NEBOC_ROUTE_SHAPE_TEXT_SCAN_BIND
 mov ecx,31
 mov r8d,0
 mov r9d,401
 mov r10d,1
 call analyze_simple
 test eax,eax
 jnz test_fail
 cmp qword [rel request_a+NEBOC_CONSOLE_ROUTE_REQUEST_OUT_MODE_OFFSET],NEBOC_CONSOLE_ROUTE_MODE_SCAN_DEFAULT
 jne test_fail
 mov esi,1
 call get_route_a
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_ptr]
 cmp qword [rbx+NEBOC_CONSOLE_ROUTE_SCAN_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_TEXT_SCAN
 jne test_fail
 cmp qword [rbx+NEBOC_CONSOLE_ROUTE_OPERATION_MASK_OFFSET],NEBOC_ROUTE_OPERATION_ENSURE_DEFAULT | NEBOC_ROUTE_OPERATION_SCAN | NEBOC_ROUTE_OPERATION_BIND_RESULT
 jne test_fail
 jmp test_pass

scenario_4:
 lea rdi,[rel route_table_a]
 lea rsi,[rel request_a]
 call clear_request
 mov qword [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_SHAPE_OFFSET],NEBOC_ROUTE_SHAPE_NAMED_SCAN_BIND
 mov qword [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_NODE_OFFSET],41
 mov qword [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_BINDING_SYMBOL_OFFSET],402
 mov qword [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_RECEIVER_SYMBOL_OFFSET],302
 mov qword [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_SOURCE_ORDER_OFFSET],1
 mov qword [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_CONSOLE_SCAN
 call neboc_console_route_analyze
 test eax,eax
 jnz test_fail
 cmp qword [rel request_a+NEBOC_CONSOLE_ROUTE_REQUEST_OUT_MODE_OFFSET],NEBOC_CONSOLE_ROUTE_MODE_SCAN_NAMED
 jne test_fail
 mov esi,1
 call get_route_a
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_ptr]
 cmp qword [rbx+NEBOC_CONSOLE_ROUTE_IDENTITY_SOURCE_OFFSET],NEBOC_CONSOLE_IDENTITY_RECEIVER_SYMBOL
 jne test_fail
 cmp qword [rbx+NEBOC_CONSOLE_ROUTE_IDENTITY_ID_OFFSET],302
 jne test_fail
 jmp test_pass

scenario_5:
 lea rdi,[rel route_table_a]
 lea rsi,[rel request_a]
 call clear_request
 mov qword [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_SHAPE_OFFSET],NEBOC_ROUTE_SHAPE_VALUE_CONSOLE_SCAN_BIND
 mov qword [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_INITIAL_VALUE_NODE_OFFSET],51
 mov qword [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_CONSOLE_CALL_NODE_OFFSET],52
 mov qword [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_NODE_OFFSET],53
 mov qword [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_BINDING_SYMBOL_OFFSET],403
 mov qword [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_SOURCE_ORDER_OFFSET],1
 mov qword [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_CONSOLE_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_TEXT_CONSOLE
 mov qword [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_CONSOLE_SCAN
 call neboc_console_route_analyze
 test eax,eax
 jnz test_fail
 cmp qword [rel request_a+NEBOC_CONSOLE_ROUTE_REQUEST_OUT_MODE_OFFSET],NEBOC_CONSOLE_ROUTE_MODE_ANONYMOUS
 jne test_fail
 mov esi,1
 call get_route_a
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_ptr]
 cmp qword [rbx+NEBOC_CONSOLE_ROUTE_IDENTITY_SOURCE_OFFSET],NEBOC_CONSOLE_IDENTITY_ANONYMOUS_ROUTE
 jne test_fail
 cmp qword [rbx+NEBOC_CONSOLE_ROUTE_IDENTITY_ID_OFFSET],1
 jne test_fail
 cmp qword [rbx+NEBOC_CONSOLE_ROUTE_OPERATION_COUNT_OFFSET],4
 jne test_fail
 jmp test_pass

scenario_6:
 lea rdi,[rel route_table_a]
 lea rsi,[rel request_a]
 mov edx,NEBOC_ROUTE_SHAPE_VALUE_CONSOLE_BIND
 mov ecx,61
 mov r8d,62
 mov r9d,501
 mov r10d,1
 call analyze_simple
 test eax,eax
 jnz test_fail
 lea rdi,[rel route_table_a]
 lea rsi,[rel request_a]
 mov edx,NEBOC_ROUTE_SHAPE_VALUE_CONSOLE_BIND
 mov ecx,63
 mov r8d,64
 mov r9d,502
 mov r10d,2
 call analyze_simple
 test eax,eax
 jnz test_fail
 cmp qword [rel route_table_a+NEBOC_CONSOLE_ROUTING_TABLE_COUNT_OFFSET],2
 jne test_fail
 mov esi,1
 call get_route_a
 mov rbx,[rel out_ptr]
 mov r13,[rbx+NEBOC_CONSOLE_ROUTE_IDENTITY_ID_OFFSET]
 mov esi,2
 call get_route_a
 mov rbx,[rel out_ptr]
 cmp r13,[rbx+NEBOC_CONSOLE_ROUTE_IDENTITY_ID_OFFSET]
 je test_fail
 cmp qword [rbx+NEBOC_CONSOLE_ROUTE_ID_OFFSET],2
 jne test_fail
 jmp test_pass

scenario_7:
 mov r13d,1
.anon_loop:
 lea rdi,[rel route_table_a]
 lea rsi,[rel request_a]
 call clear_request
 mov qword [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_SHAPE_OFFSET],NEBOC_ROUTE_SHAPE_VALUE_CONSOLE_SCAN_BIND
 lea rax,[r13+70]
 mov [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_INITIAL_VALUE_NODE_OFFSET],rax
 lea rax,[r13+80]
 mov [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_CONSOLE_CALL_NODE_OFFSET],rax
 lea rax,[r13+90]
 mov [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_NODE_OFFSET],rax
 lea rax,[r13+600]
 mov [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_BINDING_SYMBOL_OFFSET],rax
 mov [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_SOURCE_ORDER_OFFSET],r13
 mov qword [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_CONSOLE_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_TEXT_CONSOLE
 mov qword [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_CONSOLE_SCAN
 call neboc_console_route_analyze
 test eax,eax
 jnz test_fail
 inc r13
 cmp r13,3
 jb .anon_loop
 mov esi,1
 call get_route_a
 mov rbx,[rel out_ptr]
 mov r13,[rbx+NEBOC_CONSOLE_ROUTE_IDENTITY_ID_OFFSET]
 mov esi,2
 call get_route_a
 mov rbx,[rel out_ptr]
 cmp r13,[rbx+NEBOC_CONSOLE_ROUTE_IDENTITY_ID_OFFSET]
 je test_fail
 cmp r13,1
 jne test_fail
 cmp qword [rbx+NEBOC_CONSOLE_ROUTE_IDENTITY_ID_OFFSET],2
 jne test_fail
 jmp test_pass

scenario_8:
 lea rdi,[rel route_table_a]
 lea rsi,[rel request_a]
 call build_canonical
 test eax,eax
 jnz test_fail
 lea rdi,[rel route_table_b]
 lea rsi,[rel request_b]
 call build_canonical
 test eax,eax
 jnz test_fail
 mov rax,[rel route_table_a+NEBOC_CONSOLE_ROUTING_TABLE_HASH_OFFSET]
 cmp rax,[rel route_table_b+NEBOC_CONSOLE_ROUTING_TABLE_HASH_OFFSET]
 jne test_fail
 lea rdi,[rel dump_request_a]
 lea rsi,[rel route_table_a]
 lea rdx,[rel dump_a]
 call make_dump
 test eax,eax
 jnz test_fail
 lea rdi,[rel dump_request_b]
 lea rsi,[rel route_table_b]
 lea rdx,[rel dump_b]
 call make_dump
 test eax,eax
 jnz test_fail
 mov rcx,[rel dump_request_a+NEBOC_CONSOLE_ROUTE_DUMP_LENGTH_OFFSET]
 cmp rcx,[rel dump_request_b+NEBOC_CONSOLE_ROUTE_DUMP_LENGTH_OFFSET]
 jne test_fail
 cmp rcx,expected_routes_end-expected_routes
 jne test_fail
 push rcx
 lea rsi,[rel dump_a]
 lea rdi,[rel expected_routes]
 repe cmpsb
 pop rcx
 jne test_fail
 lea rsi,[rel dump_a]
 lea rdi,[rel dump_b]
 repe cmpsb
 jne test_fail
 jmp test_pass

scenario_9:
 lea rdi,[rel route_table_a]
 lea rsi,[rel request_a]
 call build_canonical
 test eax,eax
 jnz test_fail
 lea rdi,[rel database]
 call clear_database
 lea rdi,[rel database]
 lea rsi,[rel route_table_a]
 call neboc_semantic_database_attach_routes
 test eax,eax
 jnz test_fail
 lea rax,[rel route_table_a]
 cmp [rel database+NEBOC_SEMANTIC_DATABASE_ROUTE_TABLE_OFFSET],rax
 jne test_fail
 xor r13d,r13d
.metadata_loop:
 cmp r13,[rel route_table_a+NEBOC_CONSOLE_ROUTING_TABLE_COUNT_OFFSET]
 jae test_pass
 mov rax,r13
 imul rax,NEBOC_CONSOLE_ROUTE_SIZE
 lea rbx,[rel route_entries_a]
 add rbx,rax
 mov rax,[rbx+NEBOC_CONSOLE_ROUTE_FLAGS_OFFSET]
 and rax,NEBOC_ROUTE_REQUIRED_COMPLETE_FLAGS
 cmp rax,NEBOC_ROUTE_REQUIRED_COMPLETE_FLAGS
 jne test_fail
 cmp qword [rbx+NEBOC_CONSOLE_ROUTE_OPERATION_MASK_OFFSET],0
 je test_fail
 cmp qword [rbx+NEBOC_CONSOLE_ROUTE_OPERATION_COUNT_OFFSET],0
 je test_fail
 cmp qword [rbx+NEBOC_CONSOLE_ROUTE_HASH_OFFSET],0
 je test_fail
 inc r13
 jmp .metadata_loop

; analyze_simple(table, request, shape, initial_or_scan, console_node, binding, source_order)
analyze_simple:
 mov r11,rcx
 push rdi
 push rsi
 call clear_request
 pop rsi
 pop rdi
 mov [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_SHAPE_OFFSET],rdx
 mov [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_SOURCE_ORDER_OFFSET],r10
 cmp edx,NEBOC_ROUTE_SHAPE_TEXT_SCAN_BIND
 je .simple_scan
 mov [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_INITIAL_VALUE_NODE_OFFSET],r11
 mov [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_CONSOLE_CALL_NODE_OFFSET],r8
 mov [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_BINDING_SYMBOL_OFFSET],r9
 mov qword [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_CONSOLE_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_TEXT_CONSOLE
 jmp neboc_console_route_analyze
.simple_scan:
 mov [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_NODE_OFFSET],r11
 mov [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_BINDING_SYMBOL_OFFSET],r9
 mov qword [rsi+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_TEXT_SCAN
 jmp neboc_console_route_analyze

; build_canonical(table*, request*)
build_canonical:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 ; default
 mov rdi,r12
 mov rsi,r13
 mov edx,NEBOC_ROUTE_SHAPE_VALUE_CONSOLE
 mov ecx,101
 mov r8d,102
 xor r9d,r9d
 mov r10d,1
 call analyze_simple
 test eax,eax
 jnz .build_done
 ; named
 mov rdi,r12
 mov rsi,r13
 mov edx,NEBOC_ROUTE_SHAPE_VALUE_CONSOLE_BIND
 mov ecx,103
 mov r8d,104
 mov r9d,701
 mov r10d,2
 call analyze_simple
 test eax,eax
 jnz .build_done
 ; scan default
 mov rdi,r12
 mov rsi,r13
 mov edx,NEBOC_ROUTE_SHAPE_TEXT_SCAN_BIND
 mov ecx,105
 xor r8d,r8d
 mov r9d,702
 mov r10d,3
 call analyze_simple
 test eax,eax
 jnz .build_done
 ; scan named
 mov rdi,r12
 mov rsi,r13
 call clear_request
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_SHAPE_OFFSET],NEBOC_ROUTE_SHAPE_NAMED_SCAN_BIND
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_NODE_OFFSET],106
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_BINDING_SYMBOL_OFFSET],703
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_RECEIVER_SYMBOL_OFFSET],701
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_SOURCE_ORDER_OFFSET],4
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_CONSOLE_SCAN
 mov rdi,r12
 mov rsi,r13
 call neboc_console_route_analyze
 test eax,eax
 jnz .build_done
 ; anonymous
 mov rdi,r12
 mov rsi,r13
 call clear_request
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_SHAPE_OFFSET],NEBOC_ROUTE_SHAPE_VALUE_CONSOLE_SCAN_BIND
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_INITIAL_VALUE_NODE_OFFSET],107
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_CONSOLE_CALL_NODE_OFFSET],108
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_NODE_OFFSET],109
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_BINDING_SYMBOL_OFFSET],704
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_SOURCE_ORDER_OFFSET],5
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_CONSOLE_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_TEXT_CONSOLE
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_CONSOLE_SCAN
 mov rdi,r12
 mov rsi,r13
 call neboc_console_route_analyze
 test eax,eax
 jnz .build_done
 mov rdi,r12
 call neboc_console_routing_table_freeze
.build_done:
 pop r13
 pop r12
 pop rbx
 ret

make_dump:
 push r12
 mov r12,rdi
 xor eax,eax
 mov ecx,NEBOC_CONSOLE_ROUTE_DUMP_REQUEST_SIZE/8
.clear_dump:
 mov [rdi],rax
 add rdi,8
 dec ecx
 jnz .clear_dump
 mov [r12+NEBOC_CONSOLE_ROUTE_DUMP_TABLE_OFFSET],rsi
 mov [r12+NEBOC_CONSOLE_ROUTE_DUMP_BUFFER_OFFSET],rdx
 mov qword [r12+NEBOC_CONSOLE_ROUTE_DUMP_CAPACITY_OFFSET],DUMP_CAPACITY
 mov rdi,r12
 call neboc_console_route_dump
 pop r12
 ret

clear_request:
 push rdi
 mov rdi,rsi
 xor eax,eax
 mov ecx,NEBOC_CONSOLE_ROUTE_REQUEST_QWORDS
.clear_request_loop:
 mov [rdi],rax
 add rdi,8
 dec ecx
 jnz .clear_request_loop
 pop rdi
 ret

clear_database:
 push rdi
 xor eax,eax
 mov ecx,NEBOC_SEMANTIC_DATABASE_QWORDS
.clear_database_loop:
 mov [rdi],rax
 add rdi,8
 dec ecx
 jnz .clear_database_loop
 pop rdi
 ret

get_route_a:
 lea rdi,[rel route_table_a]
 lea rdx,[rel out_ptr]
 call neboc_console_routing_table_get
 ret

setup_tables:
 lea rdi,[rel route_table_a]
 lea rsi,[rel route_entries_a]
 mov edx,ROUTE_CAPACITY
 call neboc_console_routing_table_init
 test eax,eax
 jnz .setup_done
 lea rdi,[rel route_table_b]
 lea rsi,[rel route_entries_b]
 mov edx,ROUTE_CAPACITY
 call neboc_console_routing_table_init
.setup_done:
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
