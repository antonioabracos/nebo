; Nebo Assembly — MF028 negative Console routing and scan binding scenarios
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/semantic/intrinsic/intrinsic_table.inc"
%include "compiler/semantic/console-routing/console_routing_table.inc"
%include "compiler/semantic/console-routing/console_route_diagnostics.inc"

extern neboc_console_routing_table_init
extern neboc_console_route_analyze
extern neboc_console_route_validate_contracts
extern neboc_console_route_diagnostic_name
extern neboc_host_process_exit

global _start

%define ROUTE_CAPACITY 8

section .rodata
expected_duplicate: db "duplicate-console-binding"
expected_scan_binding: db "scan-binding-required"
expected_invalid_receiver: db "invalid-scan-receiver"
expected_ambiguous: db "ambiguous-console-chain"
expected_terminal: db "invalid-route-terminal-type"

section .bss align=16
route_entries: resb ROUTE_CAPACITY * NEBOC_CONSOLE_ROUTE_SIZE
route_table: resb NEBOC_CONSOLE_ROUTING_TABLE_SIZE
request: resb NEBOC_CONSOLE_ROUTE_REQUEST_SIZE
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
 cmp eax,8
 ja test_usage
 mov r12d,eax
 call setup_table
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
 jmp scenario_8

; NEBO-ROUTE-NEG-008 — duplicate Console binding is diagnosed.
scenario_1:
 call clear_request
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SHAPE_OFFSET],NEBOC_ROUTE_SHAPE_VALUE_CONSOLE_BIND
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_INITIAL_VALUE_NODE_OFFSET],11
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_CONSOLE_CALL_NODE_OFFSET],12
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_BINDING_SYMBOL_OFFSET],301
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SOURCE_ORDER_OFFSET],1
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_CONSOLE_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_TEXT_CONSOLE
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_TERMINAL_TYPE_OFFSET],NEBOC_TYPE_ID_CONSOLE
 call analyze
 test eax,eax
 jnz test_fail
 cmp qword [rel route_table+NEBOC_CONSOLE_ROUTING_TABLE_COUNT_OFFSET],1
 jne test_fail
 call clear_request
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SHAPE_OFFSET],NEBOC_ROUTE_SHAPE_VALUE_CONSOLE_BIND
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_INITIAL_VALUE_NODE_OFFSET],13
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_CONSOLE_CALL_NODE_OFFSET],14
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_BINDING_SYMBOL_OFFSET],301
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SOURCE_ORDER_OFFSET],2
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_CONSOLE_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_INT_CONSOLE
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_TERMINAL_TYPE_OFFSET],NEBOC_TYPE_ID_CONSOLE
 call analyze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONSOLE_ROUTE_ERROR_DUPLICATE_BINDING
 jne test_fail
 mov edi,NEBOC_CONSOLE_ROUTE_ERROR_DUPLICATE_BINDING
 lea rsi,[rel expected_duplicate]
 mov edx,NEBOC_CONSOLE_ROUTE_DIAGNOSTIC_DUPLICATE_BINDING_LENGTH
 call expect_diag
 test eax,eax
 jnz test_fail
 cmp qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_OUT_ROUTE_ID_OFFSET],0
 jne test_fail
 cmp qword [rel route_table+NEBOC_CONSOLE_ROUTING_TABLE_COUNT_OFFSET],1
 jne test_fail
 jmp test_pass

; NEBO-ROUTE-NEG-009 — every scan terminal requires a binding.
scenario_2:
 call clear_request
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SHAPE_OFFSET],NEBOC_ROUTE_SHAPE_TEXT_SCAN_BIND
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_NODE_OFFSET],21
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SOURCE_ORDER_OFFSET],1
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_TEXT_SCAN
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_TERMINAL_TYPE_OFFSET],NEBOC_TYPE_ID_PENDING_TEXT
 call analyze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONSOLE_ROUTE_ERROR_SCAN_BINDING_REQUIRED
 jne test_fail
 mov edi,NEBOC_CONSOLE_ROUTE_ERROR_SCAN_BINDING_REQUIRED
 lea rsi,[rel expected_scan_binding]
 mov edx,NEBOC_CONSOLE_ROUTE_DIAGNOSTIC_SCAN_BINDING_LENGTH
 call expect_diag
 test eax,eax
 jnz test_fail
 cmp qword [rel route_table+NEBOC_CONSOLE_ROUTING_TABLE_COUNT_OFFSET],0
 jne test_fail
 jmp test_pass

; NEBO-ROUTE-NEG-010 — named scan receiver must resolve to Console.
scenario_3:
 call clear_request
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SHAPE_OFFSET],NEBOC_ROUTE_SHAPE_NAMED_SCAN_BIND
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_NODE_OFFSET],31
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_BINDING_SYMBOL_OFFSET],401
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SOURCE_ORDER_OFFSET],1
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_CONSOLE_SCAN
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_ID_CONSOLE
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_TERMINAL_TYPE_OFFSET],NEBOC_TYPE_ID_PENDING_TEXT
 call analyze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONSOLE_ROUTE_ERROR_INVALID_SCAN_RECEIVER
 jne test_fail
 mov edi,NEBOC_CONSOLE_ROUTE_ERROR_INVALID_SCAN_RECEIVER
 lea rsi,[rel expected_invalid_receiver]
 mov edx,NEBOC_CONSOLE_ROUTE_DIAGNOSTIC_INVALID_RECEIVER_LENGTH
 call expect_diag
 test eax,eax
 jnz test_fail
 call clear_request
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SHAPE_OFFSET],NEBOC_ROUTE_SHAPE_NAMED_SCAN_BIND
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_NODE_OFFSET],32
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_BINDING_SYMBOL_OFFSET],402
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_RECEIVER_SYMBOL_OFFSET],302
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SOURCE_ORDER_OFFSET],2
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_CONSOLE_SCAN
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_ID_TEXT
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_TERMINAL_TYPE_OFFSET],NEBOC_TYPE_ID_PENDING_TEXT
 call analyze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONSOLE_ROUTE_ERROR_INVALID_SCAN_RECEIVER
 jne test_fail
 jmp test_pass

; Infrastructure — ambiguous chains are rejected before materialization.
scenario_4:
 call clear_request
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SHAPE_OFFSET],NEBOC_ROUTE_SHAPE_VALUE_CONSOLE_SCAN_BIND
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_INITIAL_VALUE_NODE_OFFSET],41
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_CONSOLE_CALL_NODE_OFFSET],42
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_NODE_OFFSET],43
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_BINDING_SYMBOL_OFFSET],403
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SOURCE_ORDER_OFFSET],1
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_CONSOLE_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_TEXT_CONSOLE
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_CONSOLE_SCAN
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_TERMINAL_TYPE_OFFSET],NEBOC_TYPE_ID_PENDING_TEXT
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_CHAIN_FLAGS_OFFSET],NEBOC_CONSOLE_ROUTE_CHAIN_FLAG_AMBIGUOUS
 call analyze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONSOLE_ROUTE_ERROR_AMBIGUOUS_CHAIN
 jne test_fail
 jmp test_pass

; Infrastructure — a Console route cannot terminate as Void.
scenario_5:
 call clear_request
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SHAPE_OFFSET],NEBOC_ROUTE_SHAPE_VALUE_CONSOLE
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_INITIAL_VALUE_NODE_OFFSET],51
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_CONSOLE_CALL_NODE_OFFSET],52
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SOURCE_ORDER_OFFSET],1
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_CONSOLE_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_BOOL_CONSOLE
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_TERMINAL_TYPE_OFFSET],NEBOC_TYPE_ID_VOID
 call analyze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONSOLE_ROUTE_ERROR_INVALID_TERMINAL_TYPE
 jne test_fail
 jmp test_pass

; Infrastructure — a Console binding cannot claim Pending<Text>.
scenario_6:
 call clear_request
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SHAPE_OFFSET],NEBOC_ROUTE_SHAPE_VALUE_CONSOLE_BIND
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_INITIAL_VALUE_NODE_OFFSET],61
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_CONSOLE_CALL_NODE_OFFSET],62
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_BINDING_SYMBOL_OFFSET],601
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SOURCE_ORDER_OFFSET],1
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_CONSOLE_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_TEXT_CONSOLE
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_TERMINAL_TYPE_OFFSET],NEBOC_TYPE_ID_PENDING_TEXT
 call analyze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONSOLE_ROUTE_ERROR_INVALID_TERMINAL_TYPE
 jne test_fail
 jmp test_pass

; Infrastructure — a scan binding must terminate as Pending<Text>, not Console.
scenario_7:
 call clear_request
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SHAPE_OFFSET],NEBOC_ROUTE_SHAPE_TEXT_SCAN_BIND
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_NODE_OFFSET],71
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_BINDING_SYMBOL_OFFSET],701
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SOURCE_ORDER_OFFSET],1
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_TEXT_SCAN
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_TERMINAL_TYPE_OFFSET],NEBOC_TYPE_ID_CONSOLE
 call analyze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONSOLE_ROUTE_ERROR_INVALID_TERMINAL_TYPE
 jne test_fail
 jmp test_pass

; Infrastructure — explicit Console and Pending<Text> terminals remain accepted.
scenario_8:
 call clear_request
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SHAPE_OFFSET],NEBOC_ROUTE_SHAPE_VALUE_CONSOLE_BIND
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_INITIAL_VALUE_NODE_OFFSET],81
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_CONSOLE_CALL_NODE_OFFSET],82
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_BINDING_SYMBOL_OFFSET],801
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SOURCE_ORDER_OFFSET],1
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_CONSOLE_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_INT_CONSOLE
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_TERMINAL_TYPE_OFFSET],NEBOC_TYPE_ID_CONSOLE
 call analyze
 test eax,eax
 jnz test_fail
 call clear_request
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SHAPE_OFFSET],NEBOC_ROUTE_SHAPE_TEXT_SCAN_BIND
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_NODE_OFFSET],83
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_BINDING_SYMBOL_OFFSET],802
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SOURCE_ORDER_OFFSET],2
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_TEXT_SCAN
 mov qword [rel request+NEBOC_CONSOLE_ROUTE_REQUEST_TERMINAL_TYPE_OFFSET],NEBOC_TYPE_ID_PENDING_TEXT
 call analyze
 test eax,eax
 jnz test_fail
 cmp qword [rel route_table+NEBOC_CONSOLE_ROUTING_TABLE_COUNT_OFFSET],2
 jne test_fail
 jmp test_pass

expect_diag:
 push rbx
 push r12
 push r13
 mov r12,rsi
 mov r13,rdx
 lea rsi,[rel diag_ptr]
 lea rdx,[rel diag_len]
 call neboc_console_route_diagnostic_name
 test eax,eax
 jnz .diag_done
 cmp [rel diag_len],r13
 jne .diag_fail
 mov rsi,[rel diag_ptr]
 mov rdi,r12
 mov rcx,r13
 repe cmpsb
 jne .diag_fail
 xor eax,eax
 jmp .diag_done
.diag_fail:
 mov eax,1
.diag_done:
 pop r13
 pop r12
 pop rbx
 ret

analyze:
 lea rdi,[rel route_table]
 lea rsi,[rel request]
 call neboc_console_route_analyze
 ret

setup_table:
 lea rdi,[rel route_table]
 lea rsi,[rel route_entries]
 mov edx,ROUTE_CAPACITY
 call neboc_console_routing_table_init
 ret

clear_request:
 lea rdi,[rel request]
 xor eax,eax
 mov ecx,NEBOC_CONSOLE_ROUTE_REQUEST_QWORDS
.clear_loop:
 mov [rdi],rax
 add rdi,8
 dec ecx
 jnz .clear_loop
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
