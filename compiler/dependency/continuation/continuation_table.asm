; Nebo Assembly — MF030 deterministic continuation descriptors and cancellation plan
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/dependency/graph/dependency_graph.inc"
%include "compiler/dependency/continuation/continuation_table.inc"

extern neboc_dependency_graph_get_edge

section .text

; continuation_table_init(table*, descriptor_data*, descriptor_capacity,
;                         cancellation_data*, cancellation_capacity)
NEBOC_ABI_FUNCTION neboc_continuation_table_init
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,NEBOC_CONTINUATION_TABLE_MAX_ENTRIES
 ja .invalid
 test rcx,rcx
 jz .invalid
 test r8,r8
 jz .invalid
 cmp r8,NEBOC_CONTINUATION_TABLE_MAX_ENTRIES
 ja .invalid
 mov [rdi+NEBOC_CONTINUATION_TABLE_DESCRIPTOR_DATA_OFFSET],rsi
 mov qword [rdi+NEBOC_CONTINUATION_TABLE_DESCRIPTOR_COUNT_OFFSET],0
 mov [rdi+NEBOC_CONTINUATION_TABLE_DESCRIPTOR_CAPACITY_OFFSET],rdx
 mov [rdi+NEBOC_CONTINUATION_TABLE_CANCELLATION_DATA_OFFSET],rcx
 mov qword [rdi+NEBOC_CONTINUATION_TABLE_CANCELLATION_COUNT_OFFSET],0
 mov [rdi+NEBOC_CONTINUATION_TABLE_CANCELLATION_CAPACITY_OFFSET],r8
 mov qword [rdi+NEBOC_CONTINUATION_TABLE_STATE_OFFSET],NEBOC_CONTINUATION_TABLE_STATE_MUTABLE
 mov qword [rdi+NEBOC_CONTINUATION_TABLE_HASH_OFFSET],0
 mov qword [rdi+NEBOC_CONTINUATION_TABLE_LAST_ERROR_OFFSET],NEBOC_CONTINUATION_ERROR_NONE
 mov qword [rdi+NEBOC_CONTINUATION_TABLE_CANCELLED_COUNT_OFFSET],0
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; continuation_table_get(table*, continuation_id, out_descriptor_ptr*)
NEBOC_ABI_FUNCTION neboc_continuation_table_get
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov qword [rdx],0
 test rsi,rsi
 jz .invalid
 cmp rsi,[rdi+NEBOC_CONTINUATION_TABLE_DESCRIPTOR_COUNT_OFFSET]
 ja .invalid
 dec rsi
 imul rsi,NEBOC_CONTINUATION_DESCRIPTOR_SIZE
 add rsi,[rdi+NEBOC_CONTINUATION_TABLE_DESCRIPTOR_DATA_OFFSET]
 mov [rdx],rsi
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; continuation_create_from_edge(table*, frozen_graph*, request*)
NEBOC_ABI_FUNCTION neboc_continuation_create_from_edge
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 test r14,r14
 jz .bad_no_request
 mov qword [r14+NEBOC_CONTINUATION_REQUEST_OUT_CONTINUATION_ID_OFFSET],0
 mov qword [r14+NEBOC_CONTINUATION_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONTINUATION_ERROR_NONE
 test r12,r12
 jz .bad_table
 test r13,r13
 jz .bad_table
 cmp qword [r12+NEBOC_CONTINUATION_TABLE_STATE_OFFSET],NEBOC_CONTINUATION_TABLE_STATE_MUTABLE
 jne .bad_table
 cmp qword [r13+NEBOC_DEPENDENCY_GRAPH_STATE_OFFSET],NEBOC_DEPENDENCY_GRAPH_STATE_FROZEN
 jne .bad_table
 cmp qword [r14+NEBOC_CONTINUATION_REQUEST_EDGE_ID_OFFSET],0
 je .bad_request
 cmp qword [r14+NEBOC_CONTINUATION_REQUEST_FUNCTION_ID_OFFSET],0
 je .bad_request
 cmp qword [r14+NEBOC_CONTINUATION_REQUEST_DOMAIN_ID_OFFSET],0
 je .bad_request
 mov rax,[r12+NEBOC_CONTINUATION_TABLE_DESCRIPTOR_COUNT_OFFSET]
 cmp rax,[r12+NEBOC_CONTINUATION_TABLE_DESCRIPTOR_CAPACITY_OFFSET]
 jae .limit
 mov rbx,[r12+NEBOC_CONTINUATION_TABLE_CANCELLATION_COUNT_OFFSET]
 cmp rbx,[r12+NEBOC_CONTINUATION_TABLE_CANCELLATION_CAPACITY_OFFSET]
 jae .limit
 sub rsp,16
 mov qword [rsp],0
 mov rdi,r13
 mov rsi,[r14+NEBOC_CONTINUATION_REQUEST_EDGE_ID_OFFSET]
 mov rdx,rsp
 call neboc_dependency_graph_get_edge
 test eax,eax
 jnz .unknown_edge_stack
 mov r15,[rsp]
 add rsp,16
 test r15,r15
 jz .unknown_edge
 mov rax,[r15+NEBOC_DEPENDENCY_EDGE_CONTINUATION_SEED_ID_OFFSET]
 test rax,rax
 jz .unknown_edge
 ; IDs are allocated in canonical edge order and must match the MF029 seed.
 mov rbx,[r12+NEBOC_CONTINUATION_TABLE_DESCRIPTOR_COUNT_OFFSET]
 inc rbx
 cmp rax,rbx
 jne .bad_request
 ; Zero and fill descriptor.
 mov rax,rbx
 dec rax
 imul rax,NEBOC_CONTINUATION_DESCRIPTOR_SIZE
 add rax,[r12+NEBOC_CONTINUATION_TABLE_DESCRIPTOR_DATA_OFFSET]
 mov r10,rax
 mov rdi,r10
 xor eax,eax
 mov ecx,NEBOC_CONTINUATION_DESCRIPTOR_QWORDS
.zero_descriptor:
 mov [rdi],rax
 add rdi,8
 dec ecx
 jnz .zero_descriptor
 mov [r10+NEBOC_CONTINUATION_DESCRIPTOR_ID_OFFSET],rbx
 mov rax,[r15+NEBOC_DEPENDENCY_EDGE_CONTINUATION_SEED_ID_OFFSET]
 mov [r10+NEBOC_CONTINUATION_DESCRIPTOR_SEED_ID_OFFSET],rax
 mov rax,[r14+NEBOC_CONTINUATION_REQUEST_FUNCTION_ID_OFFSET]
 mov [r10+NEBOC_CONTINUATION_DESCRIPTOR_FUNCTION_ID_OFFSET],rax
 mov rdx,[r15+NEBOC_DEPENDENCY_EDGE_PRODUCER_PENDING_ID_OFFSET]
 mov [r10+NEBOC_CONTINUATION_DESCRIPTOR_PRODUCER_PENDING_ID_OFFSET],rdx
 mov rdx,[r15+NEBOC_DEPENDENCY_EDGE_CONSUMER_PENDING_ID_OFFSET]
 mov [r10+NEBOC_CONTINUATION_DESCRIPTOR_CONSUMER_PENDING_ID_OFFSET],rdx
 mov rdx,[r14+NEBOC_CONTINUATION_REQUEST_EDGE_ID_OFFSET]
 mov [r10+NEBOC_CONTINUATION_DESCRIPTOR_TRIGGER_EDGE_ID_OFFSET],rdx
 ; Entry symbol identity encodes FunctionId and ContinuationId.
 mov rdx,rax
 shl rdx,32
 or rdx,rbx
 mov [r10+NEBOC_CONTINUATION_DESCRIPTOR_ENTRY_SYMBOL_ID_OFFSET],rdx
 mov rdx,[r15+NEBOC_DEPENDENCY_EDGE_SOURCE_ORDER_OFFSET]
 mov [r10+NEBOC_CONTINUATION_DESCRIPTOR_SOURCE_ORDER_OFFSET],rdx
 mov rdx,[r14+NEBOC_CONTINUATION_REQUEST_DOMAIN_ID_OFFSET]
 mov [r10+NEBOC_CONTINUATION_DESCRIPTOR_DOMAIN_ID_OFFSET],rdx
 mov qword [r10+NEBOC_CONTINUATION_DESCRIPTOR_CANCELLATION_POLICY_OFFSET],NEBOC_CONTINUATION_CANCELLATION_TRANSITIVE
 mov qword [r10+NEBOC_CONTINUATION_DESCRIPTOR_STATE_OFFSET],NEBOC_CONTINUATION_STATE_WAITING
 mov rdx,[r15+NEBOC_DEPENDENCY_EDGE_CAPTURE_COUNT_OFFSET]
 cmp rdx,4
 ja .bad_request_after_write
 mov [r10+NEBOC_CONTINUATION_DESCRIPTOR_CAPTURE_COUNT_OFFSET],rdx
 mov rax,[r15+NEBOC_DEPENDENCY_EDGE_CAPTURE_0_OFFSET]
 mov [r10+NEBOC_CONTINUATION_DESCRIPTOR_CAPTURE_0_OFFSET],rax
 mov rax,[r15+NEBOC_DEPENDENCY_EDGE_CAPTURE_1_OFFSET]
 mov [r10+NEBOC_CONTINUATION_DESCRIPTOR_CAPTURE_1_OFFSET],rax
 mov rax,[r15+NEBOC_DEPENDENCY_EDGE_CAPTURE_2_OFFSET]
 mov [r10+NEBOC_CONTINUATION_DESCRIPTOR_CAPTURE_2_OFFSET],rax
 mov rax,[r15+NEBOC_DEPENDENCY_EDGE_CAPTURE_3_OFFSET]
 mov [r10+NEBOC_CONTINUATION_DESCRIPTOR_CAPTURE_3_OFFSET],rax
 mov qword [r10+NEBOC_CONTINUATION_DESCRIPTOR_FLAGS_OFFSET],NEBOC_CONTINUATION_REQUIRED_FLAGS
 test rdx,rdx
 jz .descriptor_flags_done
 or qword [r10+NEBOC_CONTINUATION_DESCRIPTOR_FLAGS_OFFSET],NEBOC_CONTINUATION_FLAG_HAS_CAPTURES
.descriptor_flags_done:
 mov rdi,r10
 call neboc_continuation_descriptor_compute_hash
 test eax,eax
 jnz .bad_request_after_write
 ; One cancellation edge per descriptor.
 mov rax,rbx
 dec rax
 imul rax,NEBOC_CANCELLATION_EDGE_SIZE
 add rax,[r12+NEBOC_CONTINUATION_TABLE_CANCELLATION_DATA_OFFSET]
 mov r11,rax
 mov rdi,r11
 xor eax,eax
 mov ecx,NEBOC_CANCELLATION_EDGE_QWORDS
.zero_cancel:
 mov [rdi],rax
 add rdi,8
 dec ecx
 jnz .zero_cancel
 mov [r11+NEBOC_CANCELLATION_EDGE_ID_OFFSET],rbx
 mov rax,[r10+NEBOC_CONTINUATION_DESCRIPTOR_PRODUCER_PENDING_ID_OFFSET]
 mov [r11+NEBOC_CANCELLATION_EDGE_SOURCE_PENDING_ID_OFFSET],rax
 mov [r11+NEBOC_CANCELLATION_EDGE_CONTINUATION_ID_OFFSET],rbx
 mov rax,[r10+NEBOC_CONTINUATION_DESCRIPTOR_CONSUMER_PENDING_ID_OFFSET]
 mov [r11+NEBOC_CANCELLATION_EDGE_CONSUMER_PENDING_ID_OFFSET],rax
 mov rax,[r10+NEBOC_CONTINUATION_DESCRIPTOR_SOURCE_ORDER_OFFSET]
 mov [r11+NEBOC_CANCELLATION_EDGE_SOURCE_ORDER_OFFSET],rax
 mov qword [r11+NEBOC_CANCELLATION_EDGE_POLICY_OFFSET],NEBOC_CONTINUATION_CANCELLATION_TRANSITIVE
 mov qword [r11+NEBOC_CANCELLATION_EDGE_FLAGS_OFFSET],NEBOC_CANCELLATION_EDGE_FLAG_TRANSITIVE | NEBOC_CANCELLATION_EDGE_FLAG_SOURCE_ORDERED
 mov rdi,r11
 call neboc_cancellation_edge_compute_hash
 test eax,eax
 jnz .bad_request_after_write
 mov [r12+NEBOC_CONTINUATION_TABLE_DESCRIPTOR_COUNT_OFFSET],rbx
 mov [r12+NEBOC_CONTINUATION_TABLE_CANCELLATION_COUNT_OFFSET],rbx
 mov [r14+NEBOC_CONTINUATION_REQUEST_OUT_CONTINUATION_ID_OFFSET],rbx
 xor eax,eax
 jmp .done
.unknown_edge_stack:
 add rsp,16
.unknown_edge:
 mov qword [r14+NEBOC_CONTINUATION_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONTINUATION_ERROR_UNKNOWN_EDGE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.bad_request_after_write:
 ; Counts are still unchanged, so partially written slots are unreachable.
.bad_request:
 mov qword [r14+NEBOC_CONTINUATION_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONTINUATION_ERROR_BAD_REQUEST
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.bad_table:
 mov qword [r14+NEBOC_CONTINUATION_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONTINUATION_ERROR_BAD_TABLE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.limit:
 mov qword [r14+NEBOC_CONTINUATION_REQUEST_ERROR_CODE_OFFSET],NEBOC_CONTINUATION_ERROR_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad_no_request:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; continuation_mark_ready(table*, continuation_id)
; Models the one-shot resolution transition only; it does not execute a scheduler.
NEBOC_ABI_FUNCTION neboc_continuation_mark_ready
 push rbx
 mov rbx,rdi
 test rbx,rbx
 jz .invalid
 cmp qword [rbx+NEBOC_CONTINUATION_TABLE_STATE_OFFSET],NEBOC_CONTINUATION_TABLE_STATE_MUTABLE
 jne .invalid
 sub rsp,16
 mov qword [rsp],0
 mov rdi,rbx
 mov rdx,rsp
 call neboc_continuation_table_get
 test eax,eax
 jnz .invalid_stack
 mov rax,[rsp]
 add rsp,16
 cmp qword [rax+NEBOC_CONTINUATION_DESCRIPTOR_STATE_OFFSET],NEBOC_CONTINUATION_STATE_WAITING
 jne .duplicate
 mov qword [rax+NEBOC_CONTINUATION_DESCRIPTOR_STATE_OFFSET],NEBOC_CONTINUATION_STATE_READY
 mov rdi,rax
 call neboc_continuation_descriptor_compute_hash
 mov qword [rbx+NEBOC_CONTINUATION_TABLE_LAST_ERROR_OFFSET],NEBOC_CONTINUATION_ERROR_NONE
 xor eax,eax
 jmp .done
.invalid_stack:
 add rsp,16
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.duplicate:
 mov qword [rbx+NEBOC_CONTINUATION_TABLE_LAST_ERROR_OFFSET],NEBOC_CONTINUATION_ERROR_DUPLICATE_RESOLUTION
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 pop rbx
 ret

; continuation_cancel_from_pending(table*, pending_id, out_cancelled_count*)
; Cancels dependent continuations transitively through their consumer Pending IDs.
NEBOC_ABI_FUNCTION neboc_continuation_cancel_from_pending
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 test r12,r12
 jz .cancel_invalid
 test r13,r13
 jz .cancel_invalid
 test r14,r14
 jz .cancel_invalid
 mov qword [r14],0
 cmp qword [r12+NEBOC_CONTINUATION_TABLE_STATE_OFFSET],NEBOC_CONTINUATION_TABLE_STATE_MUTABLE
 jne .cancel_invalid
 sub rsp,NEBOC_CONTINUATION_TABLE_MAX_ENTRIES*8
 mov [rsp],r13
 mov r15d,1
 xor ebx,ebx
 xor r13d,r13d
.queue_loop:
 cmp ebx,r15d
 jae .cancel_done
 mov r9,[rsp+rbx*8]
 inc ebx
 xor ecx,ecx
.edge_loop:
 cmp rcx,[r12+NEBOC_CONTINUATION_TABLE_CANCELLATION_COUNT_OFFSET]
 jae .queue_loop
 mov rax,rcx
 imul rax,NEBOC_CANCELLATION_EDGE_SIZE
 add rax,[r12+NEBOC_CONTINUATION_TABLE_CANCELLATION_DATA_OFFSET]
 mov r10,rax
 cmp [r10+NEBOC_CANCELLATION_EDGE_SOURCE_PENDING_ID_OFFSET],r9
 jne .edge_next
 mov rdx,[r10+NEBOC_CANCELLATION_EDGE_CONTINUATION_ID_OFFSET]
 dec rdx
 imul rdx,NEBOC_CONTINUATION_DESCRIPTOR_SIZE
 add rdx,[r12+NEBOC_CONTINUATION_TABLE_DESCRIPTOR_DATA_OFFSET]
 cmp qword [rdx+NEBOC_CONTINUATION_DESCRIPTOR_STATE_OFFSET],NEBOC_CONTINUATION_STATE_CANCELLED
 je .edge_next
 mov qword [rdx+NEBOC_CONTINUATION_DESCRIPTOR_STATE_OFFSET],NEBOC_CONTINUATION_STATE_CANCELLED
 push rcx
 sub rsp,8
 mov rdi,rdx
 call neboc_continuation_descriptor_compute_hash
 add rsp,8
 pop rcx
 inc r13
 mov r10,[r10+NEBOC_CANCELLATION_EDGE_CONSUMER_PENDING_ID_OFFSET]
 test r10,r10
 jz .edge_next
 ; Enqueue unique consumer Pending IDs.
 xor edx,edx
.unique_loop:
 cmp edx,r15d
 jae .enqueue
 cmp [rsp+rdx*8],r10
 je .edge_next
 inc edx
 jmp .unique_loop
.enqueue:
 cmp r15d,NEBOC_CONTINUATION_TABLE_MAX_ENTRIES
 jae .cancel_limit
 mov [rsp+r15*8],r10
 inc r15d
.edge_next:
 inc rcx
 jmp .edge_loop
.cancel_done:
 add rsp,NEBOC_CONTINUATION_TABLE_MAX_ENTRIES*8
 mov [r14],r13
 mov [r12+NEBOC_CONTINUATION_TABLE_CANCELLED_COUNT_OFFSET],r13
 mov qword [r12+NEBOC_CONTINUATION_TABLE_LAST_ERROR_OFFSET],NEBOC_CONTINUATION_ERROR_NONE
 xor eax,eax
 jmp .cancel_exit
.cancel_limit:
 add rsp,NEBOC_CONTINUATION_TABLE_MAX_ENTRIES*8
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .cancel_exit
.cancel_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.cancel_exit:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; continuation_table_freeze(table*)
NEBOC_ABI_FUNCTION neboc_continuation_table_freeze
 push rbx
 mov rbx,rdi
 test rbx,rbx
 jz .invalid
 cmp qword [rbx+NEBOC_CONTINUATION_TABLE_STATE_OFFSET],NEBOC_CONTINUATION_TABLE_STATE_MUTABLE
 jne .invalid
 cmp qword [rbx+NEBOC_CONTINUATION_TABLE_DESCRIPTOR_COUNT_OFFSET],0
 je .invalid_source
 mov rdi,rbx
 call neboc_continuation_table_compute_hash
 test eax,eax
 jnz .invalid
 mov qword [rbx+NEBOC_CONTINUATION_TABLE_STATE_OFFSET],NEBOC_CONTINUATION_TABLE_STATE_FROZEN
 xor eax,eax
 jmp .done
.invalid_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop rbx
 ret

NEBOC_ABI_FUNCTION neboc_continuation_descriptor_compute_hash
 sub rsp,8
 test rdi,rdi
 jz .invalid
 mov eax,NEBOC_CONTINUATION_HASH_FNV1A32_OFFSET_BASIS
 xor ecx,ecx
.hash_loop:
 cmp ecx,17
 jae .store
 mov rdx,[rdi+rcx*8]
 call .hash_qword
 inc ecx
 jmp .hash_loop
.store:
 mov [rdi+NEBOC_CONTINUATION_DESCRIPTOR_HASH_OFFSET],rax
 add rsp,8
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
 add rsp,8
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.hash_qword:
 mov r8d,8
.hash_byte:
 movzx r9d,dl
 xor eax,r9d
 imul eax,eax,NEBOC_CONTINUATION_HASH_FNV1A32_PRIME
 shr rdx,8
 dec r8d
 jnz .hash_byte
 ret

NEBOC_ABI_FUNCTION neboc_cancellation_edge_compute_hash
 sub rsp,8
 test rdi,rdi
 jz .invalid
 mov eax,NEBOC_CONTINUATION_HASH_FNV1A32_OFFSET_BASIS
 xor ecx,ecx
.hash_loop:
 cmp ecx,7
 jae .store
 mov rdx,[rdi+rcx*8]
 call .hash_qword
 inc ecx
 jmp .hash_loop
.store:
 mov [rdi+NEBOC_CANCELLATION_EDGE_HASH_OFFSET],rax
 add rsp,8
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
 add rsp,8
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.hash_qword:
 mov r8d,8
.hash_byte:
 movzx r9d,dl
 xor eax,r9d
 imul eax,eax,NEBOC_CONTINUATION_HASH_FNV1A32_PRIME
 shr rdx,8
 dec r8d
 jnz .hash_byte
 ret

NEBOC_ABI_FUNCTION neboc_continuation_table_compute_hash
 push rbx
 push r12
 push r13
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov eax,NEBOC_CONTINUATION_HASH_FNV1A32_OFFSET_BASIS
 mov r13,[r12+NEBOC_CONTINUATION_TABLE_DESCRIPTOR_COUNT_OFFSET]
 mov rdx,r13
 call .hash_qword
 xor ebx,ebx
.desc_loop:
 cmp rbx,r13
 jae .cancel_start
 mov rdx,rbx
 imul rdx,NEBOC_CONTINUATION_DESCRIPTOR_SIZE
 add rdx,[r12+NEBOC_CONTINUATION_TABLE_DESCRIPTOR_DATA_OFFSET]
 mov rdx,[rdx+NEBOC_CONTINUATION_DESCRIPTOR_HASH_OFFSET]
 call .hash_qword
 inc rbx
 jmp .desc_loop
.cancel_start:
 mov r13,[r12+NEBOC_CONTINUATION_TABLE_CANCELLATION_COUNT_OFFSET]
 mov rdx,r13
 call .hash_qword
 xor ebx,ebx
.cancel_loop:
 cmp rbx,r13
 jae .store
 mov rdx,rbx
 imul rdx,NEBOC_CANCELLATION_EDGE_SIZE
 add rdx,[r12+NEBOC_CONTINUATION_TABLE_CANCELLATION_DATA_OFFSET]
 mov rdx,[rdx+NEBOC_CANCELLATION_EDGE_HASH_OFFSET]
 call .hash_qword
 inc rbx
 jmp .cancel_loop
.store:
 mov [r12+NEBOC_CONTINUATION_TABLE_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r13
 pop r12
 pop rbx
 ret
.hash_qword:
 mov r8d,8
.hash_byte:
 movzx r9d,dl
 xor eax,r9d
 imul eax,eax,NEBOC_CONTINUATION_HASH_FNV1A32_PRIME
 shr rdx,8
 dec r8d
 jnz .hash_byte
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
