; Nebo Assembly — MF029 Pending<Text> records
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/intrinsic/intrinsic_table.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/dependency/pending/pending_table.inc"

section .text

; pending_table_init(table*, entries*, capacity)
NEBOC_ABI_FUNCTION neboc_pending_table_init
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov [rdi+NEBOC_PENDING_TABLE_DATA_OFFSET],rsi
 mov qword [rdi+NEBOC_PENDING_TABLE_COUNT_OFFSET],0
 mov [rdi+NEBOC_PENDING_TABLE_CAPACITY_OFFSET],rdx
 mov qword [rdi+NEBOC_PENDING_TABLE_STATE_OFFSET],NEBOC_PENDING_TABLE_STATE_MUTABLE
 mov qword [rdi+NEBOC_PENDING_TABLE_HASH_OFFSET],0
 mov qword [rdi+NEBOC_PENDING_TABLE_ORPHAN_COUNT_OFFSET],0
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; pending_table_get(table*, pending_id, out_record_ptr*)
NEBOC_ABI_FUNCTION neboc_pending_table_get
 test rdi,rdi
 jz .get_invalid
 test rdx,rdx
 jz .get_invalid
 mov qword [rdx],0
 test rsi,rsi
 jz .get_invalid
 cmp rsi,[rdi+NEBOC_PENDING_TABLE_COUNT_OFFSET]
 ja .get_invalid
 mov rax,rsi
 dec rax
 imul rax,NEBOC_PENDING_RECORD_SIZE
 add rax,[rdi+NEBOC_PENDING_TABLE_DATA_OFFSET]
 mov [rdx],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.get_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; pending_record_create(table*, request*)
; Every accepted scan creates one immutable-identity Pending<Text> record.
NEBOC_ABI_FUNCTION neboc_pending_record_create
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 test r13,r13
 jz .bad_request_no_output
 mov qword [r13+NEBOC_PENDING_REQUEST_OUT_PENDING_ID_OFFSET],0
 mov qword [r13+NEBOC_PENDING_REQUEST_ERROR_CODE_OFFSET],NEBOC_PENDING_ERROR_NONE
 test r12,r12
 jz .bad_table
 cmp qword [r12+NEBOC_PENDING_TABLE_STATE_OFFSET],NEBOC_PENDING_TABLE_STATE_MUTABLE
 jne .bad_table
 mov r15,[r12+NEBOC_PENDING_TABLE_DATA_OFFSET]
 test r15,r15
 jz .bad_table
 mov r14,[r13+NEBOC_PENDING_REQUEST_SCAN_NODE_OFFSET]
 test r14,r14
 jz .invalid_producer
 cmp qword [r13+NEBOC_PENDING_REQUEST_ROUTE_ID_OFFSET],0
 je .invalid_route
 mov rax,[r13+NEBOC_PENDING_REQUEST_INTRINSIC_ID_OFFSET]
 cmp rax,NEBOC_INTRINSIC_ID_TEXT_SCAN
 je .intrinsic_ok
 cmp rax,NEBOC_INTRINSIC_ID_CONSOLE_SCAN
 jne .invalid_intrinsic
.intrinsic_ok:
 cmp qword [r13+NEBOC_PENDING_REQUEST_TERMINAL_TYPE_OFFSET],NEBOC_TYPE_ID_PENDING_TEXT
 jne .invalid_type
 cmp qword [r13+NEBOC_PENDING_REQUEST_SOURCE_ORDER_OFFSET],0
 je .invalid_producer

 xor ebx,ebx
 mov rcx,[r12+NEBOC_PENDING_TABLE_COUNT_OFFSET]
.duplicate_loop:
 cmp rbx,rcx
 jae .capacity
 mov rax,rbx
 imul rax,NEBOC_PENDING_RECORD_SIZE
 lea rdx,[r15+rax]
 cmp [rdx+NEBOC_PENDING_RECORD_PRODUCER_SCAN_NODE_OFFSET],r14
 je .duplicate
 inc rbx
 jmp .duplicate_loop

.capacity:
 cmp rcx,[r12+NEBOC_PENDING_TABLE_CAPACITY_OFFSET]
 jae .limit
 mov rax,rcx
 imul rax,NEBOC_PENDING_RECORD_SIZE
 lea rbx,[r15+rax]
 mov rdi,rbx
 xor eax,eax
 mov ecx,NEBOC_PENDING_RECORD_QWORDS
.zero_loop:
 mov [rdi],rax
 add rdi,8
 dec ecx
 jnz .zero_loop
 mov rax,[r12+NEBOC_PENDING_TABLE_COUNT_OFFSET]
 inc rax
 mov [rbx+NEBOC_PENDING_RECORD_ID_OFFSET],rax
 mov rdx,[r13+NEBOC_PENDING_REQUEST_SCAN_NODE_OFFSET]
 mov [rbx+NEBOC_PENDING_RECORD_PRODUCER_SCAN_NODE_OFFSET],rdx
 mov rdx,[r13+NEBOC_PENDING_REQUEST_ROUTE_ID_OFFSET]
 mov [rbx+NEBOC_PENDING_RECORD_ROUTE_ID_OFFSET],rdx
 mov rdx,[r13+NEBOC_PENDING_REQUEST_INTRINSIC_ID_OFFSET]
 mov [rbx+NEBOC_PENDING_RECORD_INTRINSIC_ID_OFFSET],rdx
 mov qword [rbx+NEBOC_PENDING_RECORD_PENDING_TYPE_ID_OFFSET],NEBOC_TYPE_ID_PENDING_TEXT
 mov qword [rbx+NEBOC_PENDING_RECORD_RESULT_TYPE_ID_OFFSET],NEBOC_TYPE_ID_TEXT
 mov rdx,[r13+NEBOC_PENDING_REQUEST_SOURCE_ORDER_OFFSET]
 mov [rbx+NEBOC_PENDING_RECORD_SOURCE_ORDER_OFFSET],rdx
 mov qword [rbx+NEBOC_PENDING_RECORD_STATE_OFFSET],NEBOC_PENDING_STATE_PRODUCED
 mov qword [rbx+NEBOC_PENDING_RECORD_FLAGS_OFFSET],NEBOC_PENDING_REQUIRED_FLAGS
 mov rdi,rbx
 call neboc_pending_record_compute_hash
 test eax,eax
 jz .internal
 mov [rbx+NEBOC_PENDING_RECORD_HASH_OFFSET],rax
 mov rax,[rbx+NEBOC_PENDING_RECORD_ID_OFFSET]
 mov [r12+NEBOC_PENDING_TABLE_COUNT_OFFSET],rax
 mov [r13+NEBOC_PENDING_REQUEST_OUT_PENDING_ID_OFFSET],rax
 xor eax,eax
 jmp .done

.duplicate:
 mov qword [r13+NEBOC_PENDING_REQUEST_ERROR_CODE_OFFSET],NEBOC_PENDING_ERROR_DUPLICATE_PRODUCER
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid_producer:
 mov qword [r13+NEBOC_PENDING_REQUEST_ERROR_CODE_OFFSET],NEBOC_PENDING_ERROR_INVALID_PRODUCER
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid_route:
 mov qword [r13+NEBOC_PENDING_REQUEST_ERROR_CODE_OFFSET],NEBOC_PENDING_ERROR_INVALID_ROUTE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid_intrinsic:
 mov qword [r13+NEBOC_PENDING_REQUEST_ERROR_CODE_OFFSET],NEBOC_PENDING_ERROR_INVALID_INTRINSIC
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid_type:
 mov qword [r13+NEBOC_PENDING_REQUEST_ERROR_CODE_OFFSET],NEBOC_PENDING_ERROR_INVALID_TYPE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit:
 mov qword [r13+NEBOC_PENDING_REQUEST_ERROR_CODE_OFFSET],NEBOC_PENDING_ERROR_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad_table:
 mov qword [r13+NEBOC_PENDING_REQUEST_ERROR_CODE_OFFSET],NEBOC_PENDING_ERROR_BAD_TABLE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.internal:
 mov qword [r13+NEBOC_PENDING_REQUEST_ERROR_CODE_OFFSET],NEBOC_PENDING_ERROR_BAD_TABLE
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
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

; pending_record_compute_hash(record*) -> eax FNV-1a32, zero on invalid input
NEBOC_ABI_FUNCTION neboc_pending_record_compute_hash
 sub rsp,8
 test rdi,rdi
 jz .hash_invalid
 mov r8,rdi
 mov eax,NEBOC_PENDING_HASH_FNV1A32_OFFSET_BASIS
 xor ecx,ecx
.hash_fields:
 cmp ecx,11
 jae .hash_done
 mov rdx,[r8+rcx*8]
 call .hash_qword
 inc ecx
 jmp .hash_fields
.hash_done:
 add rsp,8
 ret
.hash_invalid:
 xor eax,eax
 add rsp,8
 ret
.hash_qword:
 push rcx
 mov ecx,8
.hash_byte:
 movzx esi,dl
 xor eax,esi
 imul eax,eax,NEBOC_PENDING_HASH_FNV1A32_PRIME
 shr rdx,8
 dec ecx
 jnz .hash_byte
 pop rcx
 ret

; pending_table_freeze(table*)
NEBOC_ABI_FUNCTION neboc_pending_table_freeze
 push rbx
 push r12
 push r13
 mov r12,rdi
 test r12,r12
 jz .freeze_invalid
 cmp qword [r12+NEBOC_PENDING_TABLE_STATE_OFFSET],NEBOC_PENDING_TABLE_STATE_MUTABLE
 jne .freeze_invalid
 mov r13,[r12+NEBOC_PENDING_TABLE_DATA_OFFSET]
 test r13,r13
 jz .freeze_invalid
 mov eax,NEBOC_PENDING_HASH_FNV1A32_OFFSET_BASIS
 mov rdx,[r12+NEBOC_PENDING_TABLE_COUNT_OFFSET]
 call .table_hash_qword
 mov rdx,[r12+NEBOC_PENDING_TABLE_ORPHAN_COUNT_OFFSET]
 call .table_hash_qword
 xor ebx,ebx
.freeze_loop:
 cmp rbx,[r12+NEBOC_PENDING_TABLE_COUNT_OFFSET]
 jae .freeze_done
 mov rcx,rbx
 imul rcx,NEBOC_PENDING_RECORD_SIZE
 lea rdi,[r13+rcx]
 sub rsp,16
 mov [rsp],rax
 call neboc_pending_record_compute_hash
 mov rdx,rax
 mov [rdi+NEBOC_PENDING_RECORD_HASH_OFFSET],rax
 mov rax,[rsp]
 add rsp,16
 call .table_hash_qword
 inc rbx
 jmp .freeze_loop
.freeze_done:
 mov [r12+NEBOC_PENDING_TABLE_HASH_OFFSET],rax
 mov qword [r12+NEBOC_PENDING_TABLE_STATE_OFFSET],NEBOC_PENDING_TABLE_STATE_FROZEN
 xor eax,eax
 jmp .freeze_return
.freeze_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.freeze_return:
 pop r13
 pop r12
 pop rbx
 ret
.table_hash_qword:
 push rcx
 mov ecx,8
.table_hash_byte:
 movzx esi,dl
 xor eax,esi
 imul eax,eax,NEBOC_PENDING_HASH_FNV1A32_PRIME
 shr rdx,8
 dec ecx
 jnz .table_hash_byte
 pop rcx
 ret

; pending_table_count_orphans(table*, out_count*)
NEBOC_ABI_FUNCTION neboc_pending_table_count_orphans
 test rdi,rdi
 jz .count_invalid
 test rsi,rsi
 jz .count_invalid
 mov rax,[rdi+NEBOC_PENDING_TABLE_ORPHAN_COUNT_OFFSET]
 mov [rsi],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.count_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
