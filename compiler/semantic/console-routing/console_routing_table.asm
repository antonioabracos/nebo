; Nebo Assembly — MF027 compile-time Console routing table and analysis
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/intrinsic/intrinsic_table.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/semantic/console-routing/console_routing_table.inc"

section .text

; console_routing_table_init(table*, entries*, capacity)
NEBOC_ABI_FUNCTION neboc_console_routing_table_init
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov [rdi+NEBOC_CONSOLE_ROUTING_TABLE_DATA_OFFSET],rsi
 mov qword [rdi+NEBOC_CONSOLE_ROUTING_TABLE_COUNT_OFFSET],0
 mov [rdi+NEBOC_CONSOLE_ROUTING_TABLE_CAPACITY_OFFSET],rdx
 mov qword [rdi+NEBOC_CONSOLE_ROUTING_TABLE_STATE_OFFSET],NEBOC_CONSOLE_ROUTING_TABLE_STATE_MUTABLE
 mov qword [rdi+NEBOC_CONSOLE_ROUTING_TABLE_HASH_OFFSET],0
 mov qword [rdi+NEBOC_CONSOLE_ROUTING_TABLE_DEFAULT_IDENTITY_OFFSET],NEBOC_CONSOLE_DEFAULT_IDENTITY_ID
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; console_routing_table_get(table*, route_id, out_route_ptr*)
NEBOC_ABI_FUNCTION neboc_console_routing_table_get
 test rdi,rdi
 jz .get_invalid
 test rdx,rdx
 jz .get_invalid
 mov qword [rdx],0
 test rsi,rsi
 jz .get_invalid
 cmp rsi,[rdi+NEBOC_CONSOLE_ROUTING_TABLE_COUNT_OFFSET]
 ja .get_invalid
 mov rax,rsi
 dec rax
 imul rax,NEBOC_CONSOLE_ROUTE_SIZE
 add rax,[rdi+NEBOC_CONSOLE_ROUTING_TABLE_DATA_OFFSET]
 mov [rdx],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.get_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; console_route_validate_contracts(table*, request*)
; MF028 negative routing diagnostics are resolved before route materialization.
NEBOC_ABI_FUNCTION neboc_console_route_validate_contracts
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 test r13,r13
 jz .validate_no_output
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONSOLE_ROUTE_ERROR_NONE
 test r12,r12
 jz .validate_bad_table
 cmp qword [r12+NEBOC_CONSOLE_ROUTING_TABLE_STATE_OFFSET],NEBOC_CONSOLE_ROUTING_TABLE_STATE_MUTABLE
 jne .validate_bad_table
 mov r15,[r12+NEBOC_CONSOLE_ROUTING_TABLE_DATA_OFFSET]
 test r15,r15
 jz .validate_bad_table

 test qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_CHAIN_FLAGS_OFFSET],NEBOC_CONSOLE_ROUTE_CHAIN_FLAG_AMBIGUOUS
 jnz .validate_ambiguous

 mov r14,[r13+NEBOC_CONSOLE_ROUTE_REQUEST_SHAPE_OFFSET]
 cmp r14,NEBOC_ROUTE_SHAPE_VALUE_CONSOLE
 je .validate_terminal_console
 cmp r14,NEBOC_ROUTE_SHAPE_VALUE_CONSOLE_BIND
 je .validate_terminal_console
 cmp r14,NEBOC_ROUTE_SHAPE_TEXT_SCAN_BIND
 je .validate_scan
 cmp r14,NEBOC_ROUTE_SHAPE_NAMED_SCAN_BIND
 je .validate_named_scan
 cmp r14,NEBOC_ROUTE_SHAPE_VALUE_CONSOLE_SCAN_BIND
 je .validate_scan
 jmp .validate_duplicate

.validate_terminal_console:
 mov rax,[r13+NEBOC_CONSOLE_ROUTE_REQUEST_TERMINAL_TYPE_OFFSET]
 test rax,rax
 jz .validate_duplicate
 cmp rax,NEBOC_TYPE_ID_CONSOLE
 jne .validate_terminal
 jmp .validate_duplicate

.validate_named_scan:
 cmp qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_BINDING_SYMBOL_OFFSET],0
 je .validate_scan_binding
 cmp qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_RECEIVER_SYMBOL_OFFSET],0
 je .validate_receiver
 mov rax,[r13+NEBOC_CONSOLE_ROUTE_REQUEST_RECEIVER_TYPE_OFFSET]
 test rax,rax
 jz .validate_scan_terminal
 cmp rax,NEBOC_TYPE_ID_CONSOLE
 jne .validate_receiver
 jmp .validate_scan_terminal

.validate_scan:
 cmp qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_BINDING_SYMBOL_OFFSET],0
 je .validate_scan_binding
.validate_scan_terminal:
 mov rax,[r13+NEBOC_CONSOLE_ROUTE_REQUEST_TERMINAL_TYPE_OFFSET]
 test rax,rax
 jz .validate_duplicate
 cmp rax,NEBOC_TYPE_ID_PENDING_TEXT
 jne .validate_terminal

.validate_duplicate:
 mov rbx,[r13+NEBOC_CONSOLE_ROUTE_REQUEST_BINDING_SYMBOL_OFFSET]
 test rbx,rbx
 jz .validate_ok
 xor ecx,ecx
 mov r14,[r12+NEBOC_CONSOLE_ROUTING_TABLE_COUNT_OFFSET]
.validate_duplicate_loop:
 cmp rcx,r14
 jae .validate_ok
 mov rax,rcx
 imul rax,NEBOC_CONSOLE_ROUTE_SIZE
 lea rdx,[r15+rax]
 cmp [rdx+NEBOC_CONSOLE_ROUTE_BINDING_SYMBOL_OFFSET],rbx
 je .validate_duplicate_error
 inc rcx
 jmp .validate_duplicate_loop

.validate_ok:
 xor eax,eax
 jmp .validate_done
.validate_duplicate_error:
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONSOLE_ROUTE_ERROR_DUPLICATE_BINDING
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .validate_done
.validate_scan_binding:
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONSOLE_ROUTE_ERROR_SCAN_BINDING_REQUIRED
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .validate_done
.validate_receiver:
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONSOLE_ROUTE_ERROR_INVALID_SCAN_RECEIVER
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .validate_done
.validate_ambiguous:
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONSOLE_ROUTE_ERROR_AMBIGUOUS_CHAIN
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .validate_done
.validate_terminal:
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONSOLE_ROUTE_ERROR_INVALID_TERMINAL_TYPE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .validate_done
.validate_bad_table:
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONSOLE_ROUTE_ERROR_BAD_TABLE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .validate_done
.validate_no_output:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.validate_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; console_route_analyze(table*, request*)
; Valid positive routing forms are classified entirely at compile time.
NEBOC_ABI_FUNCTION neboc_console_route_analyze
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 test r13,r13
 jz .bad_request_no_output
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_OUT_ROUTE_ID_OFFSET],0
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_OUT_MODE_OFFSET],NEBOC_CONSOLE_ROUTE_MODE_INVALID
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONSOLE_ROUTE_ERROR_NONE
 test r12,r12
 jz .bad_table
 cmp qword [r12+NEBOC_CONSOLE_ROUTING_TABLE_STATE_OFFSET],NEBOC_CONSOLE_ROUTING_TABLE_STATE_MUTABLE
 jne .bad_table
 mov r15,[r12+NEBOC_CONSOLE_ROUTING_TABLE_DATA_OFFSET]
 test r15,r15
 jz .bad_table
 mov rdi,r12
 mov rsi,r13
 call neboc_console_route_validate_contracts
 test eax,eax
 jnz .done
 mov r14,[r12+NEBOC_CONSOLE_ROUTING_TABLE_COUNT_OFFSET]
 cmp r14,[r12+NEBOC_CONSOLE_ROUTING_TABLE_CAPACITY_OFFSET]
 jae .limit
 mov rax,r14
 imul rax,NEBOC_CONSOLE_ROUTE_SIZE
 add r15,rax
 lea rbx,[r14+1]
 mov [r15+NEBOC_CONSOLE_ROUTE_ID_OFFSET],rbx
 mov qword [r15+NEBOC_CONSOLE_ROUTE_MODE_OFFSET],NEBOC_CONSOLE_ROUTE_MODE_INVALID
 mov qword [r15+NEBOC_CONSOLE_ROUTE_IDENTITY_SOURCE_OFFSET],NEBOC_CONSOLE_IDENTITY_INVALID
 mov qword [r15+NEBOC_CONSOLE_ROUTE_IDENTITY_ID_OFFSET],0
 mov rax,[r13+NEBOC_CONSOLE_ROUTE_REQUEST_INITIAL_VALUE_NODE_OFFSET]
 mov [r15+NEBOC_CONSOLE_ROUTE_INITIAL_VALUE_NODE_OFFSET],rax
 mov rax,[r13+NEBOC_CONSOLE_ROUTE_REQUEST_CONSOLE_CALL_NODE_OFFSET]
 mov [r15+NEBOC_CONSOLE_ROUTE_CONSOLE_CALL_NODE_OFFSET],rax
 mov rax,[r13+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_NODE_OFFSET]
 mov [r15+NEBOC_CONSOLE_ROUTE_SCAN_NODE_OFFSET],rax
 mov rax,[r13+NEBOC_CONSOLE_ROUTE_REQUEST_BINDING_SYMBOL_OFFSET]
 mov [r15+NEBOC_CONSOLE_ROUTE_BINDING_SYMBOL_OFFSET],rax
 mov rax,[r13+NEBOC_CONSOLE_ROUTE_REQUEST_SOURCE_ORDER_OFFSET]
 mov [r15+NEBOC_CONSOLE_ROUTE_SOURCE_ORDER_OFFSET],rax
 mov qword [r15+NEBOC_CONSOLE_ROUTE_OPERATION_MASK_OFFSET],0
 mov qword [r15+NEBOC_CONSOLE_ROUTE_OPERATION_COUNT_OFFSET],0
 mov rax,[r13+NEBOC_CONSOLE_ROUTE_REQUEST_CONSOLE_INTRINSIC_ID_OFFSET]
 mov [r15+NEBOC_CONSOLE_ROUTE_CONSOLE_INTRINSIC_ID_OFFSET],rax
 mov rax,[r13+NEBOC_CONSOLE_ROUTE_REQUEST_SCAN_INTRINSIC_ID_OFFSET]
 mov [r15+NEBOC_CONSOLE_ROUTE_SCAN_INTRINSIC_ID_OFFSET],rax
 mov qword [r15+NEBOC_CONSOLE_ROUTE_FLAGS_OFFSET],NEBOC_ROUTE_FLAG_COMPILE_TIME_COMPLETE | NEBOC_ROUTE_FLAG_RUNTIME_HEURISTIC_FORBIDDEN
 mov qword [r15+NEBOC_CONSOLE_ROUTE_HASH_OFFSET],0

 mov rax,[r13+NEBOC_CONSOLE_ROUTE_REQUEST_SHAPE_OFFSET]
 cmp rax,NEBOC_ROUTE_SHAPE_VALUE_CONSOLE
 je .shape_default
 cmp rax,NEBOC_ROUTE_SHAPE_VALUE_CONSOLE_BIND
 je .shape_named
 cmp rax,NEBOC_ROUTE_SHAPE_TEXT_SCAN_BIND
 je .shape_scan_default
 cmp rax,NEBOC_ROUTE_SHAPE_NAMED_SCAN_BIND
 je .shape_scan_named
 cmp rax,NEBOC_ROUTE_SHAPE_VALUE_CONSOLE_SCAN_BIND
 je .shape_anonymous
 jmp .unsupported

.shape_default:
 cmp qword [r15+NEBOC_CONSOLE_ROUTE_INITIAL_VALUE_NODE_OFFSET],0
 je .bad_request
 cmp qword [r15+NEBOC_CONSOLE_ROUTE_CONSOLE_CALL_NODE_OFFSET],0
 je .bad_request
 cmp qword [r15+NEBOC_CONSOLE_ROUTE_CONSOLE_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_TEXT_CONSOLE
 jb .bad_request
 cmp qword [r15+NEBOC_CONSOLE_ROUTE_CONSOLE_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_BOOL_CONSOLE
 ja .bad_request
 mov qword [r15+NEBOC_CONSOLE_ROUTE_MODE_OFFSET],NEBOC_CONSOLE_ROUTE_MODE_DEFAULT
 mov qword [r15+NEBOC_CONSOLE_ROUTE_IDENTITY_SOURCE_OFFSET],NEBOC_CONSOLE_IDENTITY_DEFAULT
 mov rax,[r12+NEBOC_CONSOLE_ROUTING_TABLE_DEFAULT_IDENTITY_OFFSET]
 mov [r15+NEBOC_CONSOLE_ROUTE_IDENTITY_ID_OFFSET],rax
 mov qword [r15+NEBOC_CONSOLE_ROUTE_OPERATION_MASK_OFFSET],NEBOC_ROUTE_OPERATION_ENSURE_DEFAULT | NEBOC_ROUTE_OPERATION_APPEND_INITIAL
 mov qword [r15+NEBOC_CONSOLE_ROUTE_OPERATION_COUNT_OFFSET],2
 or qword [r15+NEBOC_CONSOLE_ROUTE_FLAGS_OFFSET],NEBOC_ROUTE_FLAG_HAS_INITIAL_VALUE | NEBOC_ROUTE_FLAG_HAS_CONSOLE_CALL | NEBOC_ROUTE_FLAG_REUSES_DEFAULT
 jmp .commit

.shape_named:
 cmp qword [r15+NEBOC_CONSOLE_ROUTE_INITIAL_VALUE_NODE_OFFSET],0
 je .bad_request
 cmp qword [r15+NEBOC_CONSOLE_ROUTE_CONSOLE_CALL_NODE_OFFSET],0
 je .bad_request
 mov rax,[r15+NEBOC_CONSOLE_ROUTE_BINDING_SYMBOL_OFFSET]
 test rax,rax
 jz .bad_request
 mov qword [r15+NEBOC_CONSOLE_ROUTE_MODE_OFFSET],NEBOC_CONSOLE_ROUTE_MODE_NAMED
 mov qword [r15+NEBOC_CONSOLE_ROUTE_IDENTITY_SOURCE_OFFSET],NEBOC_CONSOLE_IDENTITY_BINDING_SYMBOL
 mov [r15+NEBOC_CONSOLE_ROUTE_IDENTITY_ID_OFFSET],rax
 mov qword [r15+NEBOC_CONSOLE_ROUTE_OPERATION_MASK_OFFSET],NEBOC_ROUTE_OPERATION_CREATE_NAMED | NEBOC_ROUTE_OPERATION_APPEND_INITIAL | NEBOC_ROUTE_OPERATION_BIND_RESULT
 mov qword [r15+NEBOC_CONSOLE_ROUTE_OPERATION_COUNT_OFFSET],3
 or qword [r15+NEBOC_CONSOLE_ROUTE_FLAGS_OFFSET],NEBOC_ROUTE_FLAG_HAS_INITIAL_VALUE | NEBOC_ROUTE_FLAG_HAS_CONSOLE_CALL | NEBOC_ROUTE_FLAG_HAS_BINDING | NEBOC_ROUTE_FLAG_CREATES_INDEPENDENT
 jmp .commit

.shape_scan_default:
 cmp qword [r15+NEBOC_CONSOLE_ROUTE_SCAN_NODE_OFFSET],0
 je .bad_request
 cmp qword [r15+NEBOC_CONSOLE_ROUTE_BINDING_SYMBOL_OFFSET],0
 je .bad_request
 cmp qword [r15+NEBOC_CONSOLE_ROUTE_SCAN_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_TEXT_SCAN
 jne .bad_request
 mov qword [r15+NEBOC_CONSOLE_ROUTE_MODE_OFFSET],NEBOC_CONSOLE_ROUTE_MODE_SCAN_DEFAULT
 mov qword [r15+NEBOC_CONSOLE_ROUTE_IDENTITY_SOURCE_OFFSET],NEBOC_CONSOLE_IDENTITY_DEFAULT
 mov rax,[r12+NEBOC_CONSOLE_ROUTING_TABLE_DEFAULT_IDENTITY_OFFSET]
 mov [r15+NEBOC_CONSOLE_ROUTE_IDENTITY_ID_OFFSET],rax
 mov qword [r15+NEBOC_CONSOLE_ROUTE_OPERATION_MASK_OFFSET],NEBOC_ROUTE_OPERATION_ENSURE_DEFAULT | NEBOC_ROUTE_OPERATION_SCAN | NEBOC_ROUTE_OPERATION_BIND_RESULT
 mov qword [r15+NEBOC_CONSOLE_ROUTE_OPERATION_COUNT_OFFSET],3
 or qword [r15+NEBOC_CONSOLE_ROUTE_FLAGS_OFFSET],NEBOC_ROUTE_FLAG_HAS_SCAN | NEBOC_ROUTE_FLAG_HAS_BINDING | NEBOC_ROUTE_FLAG_REUSES_DEFAULT
 jmp .commit

.shape_scan_named:
 cmp qword [r15+NEBOC_CONSOLE_ROUTE_SCAN_NODE_OFFSET],0
 je .bad_request
 cmp qword [r15+NEBOC_CONSOLE_ROUTE_BINDING_SYMBOL_OFFSET],0
 je .bad_request
 mov rax,[r13+NEBOC_CONSOLE_ROUTE_REQUEST_RECEIVER_SYMBOL_OFFSET]
 test rax,rax
 jz .bad_request
 cmp qword [r15+NEBOC_CONSOLE_ROUTE_SCAN_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_CONSOLE_SCAN
 jne .bad_request
 mov qword [r15+NEBOC_CONSOLE_ROUTE_MODE_OFFSET],NEBOC_CONSOLE_ROUTE_MODE_SCAN_NAMED
 mov qword [r15+NEBOC_CONSOLE_ROUTE_IDENTITY_SOURCE_OFFSET],NEBOC_CONSOLE_IDENTITY_RECEIVER_SYMBOL
 mov [r15+NEBOC_CONSOLE_ROUTE_IDENTITY_ID_OFFSET],rax
 mov qword [r15+NEBOC_CONSOLE_ROUTE_OPERATION_MASK_OFFSET],NEBOC_ROUTE_OPERATION_SCAN | NEBOC_ROUTE_OPERATION_BIND_RESULT
 mov qword [r15+NEBOC_CONSOLE_ROUTE_OPERATION_COUNT_OFFSET],2
 or qword [r15+NEBOC_CONSOLE_ROUTE_FLAGS_OFFSET],NEBOC_ROUTE_FLAG_HAS_SCAN | NEBOC_ROUTE_FLAG_HAS_BINDING
 jmp .commit

.shape_anonymous:
 cmp qword [r15+NEBOC_CONSOLE_ROUTE_INITIAL_VALUE_NODE_OFFSET],0
 je .bad_request
 cmp qword [r15+NEBOC_CONSOLE_ROUTE_CONSOLE_CALL_NODE_OFFSET],0
 je .bad_request
 cmp qword [r15+NEBOC_CONSOLE_ROUTE_SCAN_NODE_OFFSET],0
 je .bad_request
 cmp qword [r15+NEBOC_CONSOLE_ROUTE_BINDING_SYMBOL_OFFSET],0
 je .bad_request
 cmp qword [r15+NEBOC_CONSOLE_ROUTE_SCAN_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_CONSOLE_SCAN
 jne .bad_request
 mov qword [r15+NEBOC_CONSOLE_ROUTE_MODE_OFFSET],NEBOC_CONSOLE_ROUTE_MODE_ANONYMOUS
 mov qword [r15+NEBOC_CONSOLE_ROUTE_IDENTITY_SOURCE_OFFSET],NEBOC_CONSOLE_IDENTITY_ANONYMOUS_ROUTE
 mov [r15+NEBOC_CONSOLE_ROUTE_IDENTITY_ID_OFFSET],rbx
 mov qword [r15+NEBOC_CONSOLE_ROUTE_OPERATION_MASK_OFFSET],NEBOC_ROUTE_OPERATION_CREATE_ANONYMOUS | NEBOC_ROUTE_OPERATION_APPEND_INITIAL | NEBOC_ROUTE_OPERATION_SCAN | NEBOC_ROUTE_OPERATION_BIND_RESULT
 mov qword [r15+NEBOC_CONSOLE_ROUTE_OPERATION_COUNT_OFFSET],4
 or qword [r15+NEBOC_CONSOLE_ROUTE_FLAGS_OFFSET],NEBOC_ROUTE_FLAG_HAS_INITIAL_VALUE | NEBOC_ROUTE_FLAG_HAS_CONSOLE_CALL | NEBOC_ROUTE_FLAG_HAS_SCAN | NEBOC_ROUTE_FLAG_HAS_BINDING | NEBOC_ROUTE_FLAG_CREATES_INDEPENDENT

.commit:
 mov rdi,r15
 call neboc_console_route_compute_hash
 test eax,eax
 jnz .bad_request
 inc r14
 mov [r12+NEBOC_CONSOLE_ROUTING_TABLE_COUNT_OFFSET],r14
 mov [r13+NEBOC_CONSOLE_ROUTE_REQUEST_OUT_ROUTE_ID_OFFSET],rbx
 mov rax,[r15+NEBOC_CONSOLE_ROUTE_MODE_OFFSET]
 mov [r13+NEBOC_CONSOLE_ROUTE_REQUEST_OUT_MODE_OFFSET],rax
 xor eax,eax
 jmp .done
.limit:
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONSOLE_ROUTE_ERROR_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.unsupported:
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONSOLE_ROUTE_ERROR_UNSUPPORTED_SHAPE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.bad_request:
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONSOLE_ROUTE_ERROR_BAD_REQUEST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.bad_table:
 mov qword [r13+NEBOC_CONSOLE_ROUTE_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONSOLE_ROUTE_ERROR_BAD_TABLE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.bad_request_no_output:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; console_route_compute_hash(route*)
NEBOC_ABI_FUNCTION neboc_console_route_compute_hash
 sub rsp,8
 test rdi,rdi
 jz .hash_invalid
 mov r8,rdi
 mov eax,NEBOC_CONSOLE_ROUTE_HASH_FNV1A32_OFFSET_BASIS
 xor ecx,ecx
.hash_field:
 cmp ecx,14
 jae .hash_done
 mov rdx,[r8+rcx*8]
 call .hash_qword
 inc ecx
 jmp .hash_field
.hash_done:
 mov [r8+NEBOC_CONSOLE_ROUTE_HASH_OFFSET],rax
 xor eax,eax
 add rsp,8
 ret
.hash_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 add rsp,8
 ret
.hash_qword:
 push rcx
 mov ecx,8
.hash_byte:
 movzx r9d,dl
 xor eax,r9d
 imul eax,eax,NEBOC_CONSOLE_ROUTE_HASH_FNV1A32_PRIME
 shr rdx,8
 dec ecx
 jnz .hash_byte
 pop rcx
 ret

; console_routing_table_freeze(table*)
NEBOC_ABI_FUNCTION neboc_console_routing_table_freeze
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 test r12,r12
 jz .freeze_invalid
 cmp qword [r12+NEBOC_CONSOLE_ROUTING_TABLE_STATE_OFFSET],NEBOC_CONSOLE_ROUTING_TABLE_STATE_MUTABLE
 jne .freeze_invalid
 mov r13,[r12+NEBOC_CONSOLE_ROUTING_TABLE_COUNT_OFFSET]
 test r13,r13
 jz .freeze_invalid
 mov r14,[r12+NEBOC_CONSOLE_ROUTING_TABLE_DATA_OFFSET]
 test r14,r14
 jz .freeze_invalid
 mov ebx,NEBOC_CONSOLE_ROUTE_HASH_FNV1A32_OFFSET_BASIS
 xor r10d,r10d
.freeze_loop:
 cmp r10,r13
 jae .freeze_done
 mov rax,r10
 imul rax,NEBOC_CONSOLE_ROUTE_SIZE
 add rax,r14
 mov r11,rax
 mov rdx,[r11+NEBOC_CONSOLE_ROUTE_ID_OFFSET]
 lea rax,[r10+1]
 cmp rdx,rax
 jne .freeze_incomplete
 mov rdx,[r11+NEBOC_CONSOLE_ROUTE_MODE_OFFSET]
 cmp rdx,NEBOC_CONSOLE_ROUTE_MODE_DEFAULT
 jb .freeze_incomplete
 cmp rdx,NEBOC_CONSOLE_ROUTE_MODE_SCAN_NAMED
 ja .freeze_incomplete
 mov rdx,[r11+NEBOC_CONSOLE_ROUTE_IDENTITY_SOURCE_OFFSET]
 test rdx,rdx
 jz .freeze_incomplete
 mov rdx,[r11+NEBOC_CONSOLE_ROUTE_IDENTITY_ID_OFFSET]
 test rdx,rdx
 jz .freeze_incomplete
 mov rdx,[r11+NEBOC_CONSOLE_ROUTE_OPERATION_MASK_OFFSET]
 test rdx,rdx
 jz .freeze_incomplete
 mov rdx,[r11+NEBOC_CONSOLE_ROUTE_OPERATION_COUNT_OFFSET]
 test rdx,rdx
 jz .freeze_incomplete
 mov rdx,[r11+NEBOC_CONSOLE_ROUTE_FLAGS_OFFSET]
 and rdx,NEBOC_ROUTE_REQUIRED_COMPLETE_FLAGS
 cmp rdx,NEBOC_ROUTE_REQUIRED_COMPLETE_FLAGS
 jne .freeze_incomplete
 mov rdx,[r11+NEBOC_CONSOLE_ROUTE_HASH_OFFSET]
 call .table_hash_qword
 inc r10
 jmp .freeze_loop
.freeze_done:
 mov [r12+NEBOC_CONSOLE_ROUTING_TABLE_HASH_OFFSET],rbx
 mov qword [r12+NEBOC_CONSOLE_ROUTING_TABLE_STATE_OFFSET],NEBOC_CONSOLE_ROUTING_TABLE_STATE_FROZEN
 xor eax,eax
 jmp .freeze_return
.freeze_incomplete:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .freeze_return
.freeze_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.freeze_return:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.table_hash_qword:
 push rcx
 mov ecx,8
.table_hash_byte:
 movzx eax,dl
 xor ebx,eax
 imul ebx,ebx,NEBOC_CONSOLE_ROUTE_HASH_FNV1A32_PRIME
 shr rdx,8
 dec ecx
 jnz .table_hash_byte
 pop rcx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
