; Nebo Assembly — MF030 target-independent Function Lowering Plan
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/dependency/pending/pending_table.inc"
%include "compiler/dependency/continuation/continuation_table.inc"
%include "compiler/lowering/function_lowering_plan.inc"

section .text

; function_lowering_table_init(table*, plans*, plan_capacity, operations*, operation_capacity)
NEBOC_ABI_FUNCTION neboc_function_lowering_table_init
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 test r8,r8
 jz .invalid
 mov [rdi+NEBOC_LOWERING_TABLE_PLAN_DATA_OFFSET],rsi
 mov qword [rdi+NEBOC_LOWERING_TABLE_PLAN_COUNT_OFFSET],0
 mov [rdi+NEBOC_LOWERING_TABLE_PLAN_CAPACITY_OFFSET],rdx
 mov [rdi+NEBOC_LOWERING_TABLE_OPERATION_DATA_OFFSET],rcx
 mov qword [rdi+NEBOC_LOWERING_TABLE_OPERATION_COUNT_OFFSET],0
 mov [rdi+NEBOC_LOWERING_TABLE_OPERATION_CAPACITY_OFFSET],r8
 mov qword [rdi+NEBOC_LOWERING_TABLE_STATE_OFFSET],NEBOC_LOWERING_TABLE_STATE_MUTABLE
 mov qword [rdi+NEBOC_LOWERING_TABLE_HASH_OFFSET],0
 mov qword [rdi+NEBOC_LOWERING_TABLE_LAST_ERROR_OFFSET],NEBOC_LOWERING_ERROR_NONE
 mov qword [rdi+NEBOC_LOWERING_TABLE_FLAGS_OFFSET],0
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION neboc_function_lowering_table_get_plan
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov qword [rdx],0
 test rsi,rsi
 jz .invalid
 cmp rsi,[rdi+NEBOC_LOWERING_TABLE_PLAN_COUNT_OFFSET]
 ja .invalid
 dec rsi
 imul rsi,NEBOC_FUNCTION_PLAN_SIZE
 add rsi,[rdi+NEBOC_LOWERING_TABLE_PLAN_DATA_OFFSET]
 mov [rdx],rsi
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION neboc_function_lowering_table_get_operation
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov qword [rdx],0
 test rsi,rsi
 jz .invalid
 cmp rsi,[rdi+NEBOC_LOWERING_TABLE_OPERATION_COUNT_OFFSET]
 ja .invalid
 dec rsi
 imul rsi,NEBOC_LOWERING_OPERATION_SIZE
 add rsi,[rdi+NEBOC_LOWERING_TABLE_OPERATION_DATA_OFFSET]
 mov [rdx],rsi
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; function_lowering_plan_create_scan(table*, continuation_table*, request*)
NEBOC_ABI_FUNCTION neboc_function_lowering_plan_create_scan
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
 mov qword [r14+NEBOC_FUNCTION_PLAN_REQUEST_OUT_PLAN_ID_OFFSET],0
 mov qword [r14+NEBOC_FUNCTION_PLAN_REQUEST_ERROR_CODE_OFFSET],NEBOC_LOWERING_ERROR_NONE
 test r12,r12
 jz .bad_table
 test r13,r13
 jz .bad_table
 cmp qword [r12+NEBOC_LOWERING_TABLE_STATE_OFFSET],NEBOC_LOWERING_TABLE_STATE_MUTABLE
 jne .bad_table
 cmp qword [r13+NEBOC_CONTINUATION_TABLE_STATE_OFFSET],NEBOC_CONTINUATION_TABLE_STATE_FROZEN
 jne .bad_table
 cmp qword [r14+NEBOC_FUNCTION_PLAN_REQUEST_FUNCTION_ID_OFFSET],0
 je .bad_request
 cmp qword [r14+NEBOC_FUNCTION_PLAN_REQUEST_SOURCE_ORDER_OFFSET],0
 je .bad_request
 cmp qword [r14+NEBOC_FUNCTION_PLAN_REQUEST_SOURCE_NODE_ID_OFFSET],0
 je .bad_request
 cmp qword [r14+NEBOC_FUNCTION_PLAN_REQUEST_ROUTE_ID_OFFSET],0
 je .bad_request
 cmp qword [r14+NEBOC_FUNCTION_PLAN_REQUEST_PENDING_ID_OFFSET],0
 je .bad_request
 cmp qword [r14+NEBOC_FUNCTION_PLAN_REQUEST_RUNTIME_CONTRACT_ID_OFFSET],0
 je .bad_request
 mov rax,[r14+NEBOC_FUNCTION_PLAN_REQUEST_CONTINUATION_COUNT_OFFSET]
 test rax,rax
 jz .missing_continuation
 mov rdx,[r14+NEBOC_FUNCTION_PLAN_REQUEST_FIRST_CONTINUATION_ID_OFFSET]
 test rdx,rdx
 jz .missing_continuation
 add rax,rdx
 dec rax
 cmp rax,[r13+NEBOC_CONTINUATION_TABLE_DESCRIPTOR_COUNT_OFFSET]
 ja .missing_continuation
 mov rbx,[r12+NEBOC_LOWERING_TABLE_PLAN_COUNT_OFFSET]
 cmp rbx,[r12+NEBOC_LOWERING_TABLE_PLAN_CAPACITY_OFFSET]
 jae .limit
 mov r15,[r12+NEBOC_LOWERING_TABLE_OPERATION_COUNT_OFFSET]
 lea rax,[r15+NEBOC_LOWERING_OPERATION_COUNT]
 cmp rax,[r12+NEBOC_LOWERING_TABLE_OPERATION_CAPACITY_OFFSET]
 ja .limit
 ; Plan record.
 mov rax,rbx
 imul rax,NEBOC_FUNCTION_PLAN_SIZE
 add rax,[r12+NEBOC_LOWERING_TABLE_PLAN_DATA_OFFSET]
 mov r10,rax
 mov rdi,r10
 xor eax,eax
 mov ecx,NEBOC_FUNCTION_PLAN_QWORDS
.zero_plan:
 mov [rdi],rax
 add rdi,8
 dec ecx
 jnz .zero_plan
 lea rax,[rbx+1]
 mov [r10+NEBOC_FUNCTION_PLAN_ID_OFFSET],rax
 mov rdx,[r14+NEBOC_FUNCTION_PLAN_REQUEST_FUNCTION_ID_OFFSET]
 mov [r10+NEBOC_FUNCTION_PLAN_FUNCTION_ID_OFFSET],rdx
 mov rdx,[r14+NEBOC_FUNCTION_PLAN_REQUEST_SOURCE_ORDER_OFFSET]
 mov [r10+NEBOC_FUNCTION_PLAN_SOURCE_ORDER_OFFSET],rdx
 lea rdx,[r15+1]
 mov [r10+NEBOC_FUNCTION_PLAN_FIRST_OPERATION_ID_OFFSET],rdx
 mov qword [r10+NEBOC_FUNCTION_PLAN_OPERATION_COUNT_OFFSET],NEBOC_LOWERING_OPERATION_COUNT
 mov rdx,[r14+NEBOC_FUNCTION_PLAN_REQUEST_FIRST_CONTINUATION_ID_OFFSET]
 mov [r10+NEBOC_FUNCTION_PLAN_FIRST_CONTINUATION_ID_OFFSET],rdx
 mov rdx,[r14+NEBOC_FUNCTION_PLAN_REQUEST_CONTINUATION_COUNT_OFFSET]
 mov [r10+NEBOC_FUNCTION_PLAN_CONTINUATION_COUNT_OFFSET],rdx
 mov qword [r10+NEBOC_FUNCTION_PLAN_EXIT_PATH_COUNT_OFFSET],1
 mov qword [r10+NEBOC_FUNCTION_PLAN_FLAGS_OFFSET],NEBOC_LOWERING_PLAN_REQUIRED_FLAGS
 mov qword [r10+NEBOC_FUNCTION_PLAN_CANCELLATION_POLICY_OFFSET],NEBOC_CONTINUATION_CANCELLATION_TRANSITIVE
 mov qword [r10+NEBOC_FUNCTION_PLAN_STATE_OFFSET],NEBOC_FUNCTION_PLAN_STATE_MUTABLE
 ; v0.1 logical plan deliberately has no physical stack layout yet.
 mov qword [r10+NEBOC_FUNCTION_PLAN_PARAMETER_COUNT_OFFSET],0
 mov qword [r10+NEBOC_FUNCTION_PLAN_LOCAL_BINDING_COUNT_OFFSET],1
 ; Emit six canonical logical operations.
 xor ecx,ecx
.operation_loop:
 cmp ecx,NEBOC_LOWERING_OPERATION_COUNT
 jae .operations_done
 mov rax,r15
 add rax,rcx
 imul rax,NEBOC_LOWERING_OPERATION_SIZE
 add rax,[r12+NEBOC_LOWERING_TABLE_OPERATION_DATA_OFFSET]
 mov r11,rax
 mov rdi,r11
 xor eax,eax
 mov edx,NEBOC_LOWERING_OPERATION_QWORDS
.zero_operation:
 mov [rdi],rax
 add rdi,8
 dec edx
 jnz .zero_operation
 mov rax,r15
 add rax,rcx
 inc rax
 mov [r11+NEBOC_LOWERING_OPERATION_ID_OFFSET],rax
 lea rax,[rbx+1]
 mov [r11+NEBOC_LOWERING_OPERATION_PLAN_ID_OFFSET],rax
 lea eax,[rcx+1]
 mov [r11+NEBOC_LOWERING_OPERATION_KIND_OFFSET],rax
 mov rax,[r14+NEBOC_FUNCTION_PLAN_REQUEST_SOURCE_NODE_ID_OFFSET]
 mov [r11+NEBOC_LOWERING_OPERATION_SOURCE_NODE_ID_OFFSET],rax
 mov rax,[r14+NEBOC_FUNCTION_PLAN_REQUEST_ROUTE_ID_OFFSET]
 mov [r11+NEBOC_LOWERING_OPERATION_ROUTE_ID_OFFSET],rax
 mov rax,[r14+NEBOC_FUNCTION_PLAN_REQUEST_PENDING_ID_OFFSET]
 mov [r11+NEBOC_LOWERING_OPERATION_PENDING_ID_OFFSET],rax
 mov rax,[r14+NEBOC_FUNCTION_PLAN_REQUEST_FIRST_CONTINUATION_ID_OFFSET]
 mov [r11+NEBOC_LOWERING_OPERATION_CONTINUATION_ID_OFFSET],rax
 mov rax,[r14+NEBOC_FUNCTION_PLAN_REQUEST_RUNTIME_CONTRACT_ID_OFFSET]
 mov [r11+NEBOC_LOWERING_OPERATION_RUNTIME_CONTRACT_ID_OFFSET],rax
 mov rax,[r14+NEBOC_FUNCTION_PLAN_REQUEST_SOURCE_ORDER_OFFSET]
 add rax,rcx
 mov [r11+NEBOC_LOWERING_OPERATION_SOURCE_ORDER_OFFSET],rax
 push rcx
 sub rsp,8
 mov rdi,r11
 call neboc_lowering_operation_compute_hash
 add rsp,8
 pop rcx
 test eax,eax
 jnz .bad_request_after_write
 inc ecx
 jmp .operation_loop
.operations_done:
 mov rdi,r10
 call neboc_function_plan_compute_hash
 test eax,eax
 jnz .bad_request_after_write
 inc rbx
 add r15,NEBOC_LOWERING_OPERATION_COUNT
 mov [r12+NEBOC_LOWERING_TABLE_PLAN_COUNT_OFFSET],rbx
 mov [r12+NEBOC_LOWERING_TABLE_OPERATION_COUNT_OFFSET],r15
 mov [r14+NEBOC_FUNCTION_PLAN_REQUEST_OUT_PLAN_ID_OFFSET],rbx
 xor eax,eax
 jmp .done
.missing_continuation:
 mov qword [r14+NEBOC_FUNCTION_PLAN_REQUEST_ERROR_CODE_OFFSET],NEBOC_LOWERING_ERROR_MISSING_CONTINUATION
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.bad_request_after_write:
.bad_request:
 mov qword [r14+NEBOC_FUNCTION_PLAN_REQUEST_ERROR_CODE_OFFSET],NEBOC_LOWERING_ERROR_BAD_REQUEST
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.bad_table:
 mov qword [r14+NEBOC_FUNCTION_PLAN_REQUEST_ERROR_CODE_OFFSET],NEBOC_LOWERING_ERROR_BAD_TABLE
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.limit:
 mov qword [r14+NEBOC_FUNCTION_PLAN_REQUEST_ERROR_CODE_OFFSET],NEBOC_LOWERING_ERROR_LIMIT
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

; function_lowering_table_freeze(table*, pending_table*, continuation_table*)
; Orphan Pending records are a security error at function/program exit.
NEBOC_ABI_FUNCTION neboc_function_lowering_table_freeze
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 test rbx,rbx
 jz .invalid
 test r12,r12
 jz .invalid
 test r13,r13
 jz .invalid
 cmp qword [rbx+NEBOC_LOWERING_TABLE_STATE_OFFSET],NEBOC_LOWERING_TABLE_STATE_MUTABLE
 jne .invalid
 cmp qword [r12+NEBOC_PENDING_TABLE_STATE_OFFSET],NEBOC_PENDING_TABLE_STATE_FROZEN
 jne .invalid
 cmp qword [r13+NEBOC_CONTINUATION_TABLE_STATE_OFFSET],NEBOC_CONTINUATION_TABLE_STATE_FROZEN
 jne .invalid
 cmp qword [r12+NEBOC_PENDING_TABLE_ORPHAN_COUNT_OFFSET],0
 jne .orphan
 cmp qword [rbx+NEBOC_LOWERING_TABLE_PLAN_COUNT_OFFSET],0
 je .incomplete
 cmp qword [rbx+NEBOC_LOWERING_TABLE_OPERATION_COUNT_OFFSET],0
 je .incomplete
 mov rdi,rbx
 call neboc_function_lowering_table_compute_hash
 test eax,eax
 jnz .invalid
 mov qword [rbx+NEBOC_LOWERING_TABLE_STATE_OFFSET],NEBOC_LOWERING_TABLE_STATE_FROZEN
 mov qword [rbx+NEBOC_LOWERING_TABLE_FLAGS_OFFSET],NEBOC_LOWERING_PLAN_REQUIRED_FLAGS
 mov qword [rbx+NEBOC_LOWERING_TABLE_LAST_ERROR_OFFSET],NEBOC_LOWERING_ERROR_NONE
 xor eax,eax
 jmp .done
.orphan:
 mov qword [rbx+NEBOC_LOWERING_TABLE_LAST_ERROR_OFFSET],NEBOC_LOWERING_ERROR_ORPHAN_PENDING_AT_EXIT
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.incomplete:
 mov qword [rbx+NEBOC_LOWERING_TABLE_LAST_ERROR_OFFSET],NEBOC_LOWERING_ERROR_INCOMPLETE_PLAN
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r13
 pop r12
 pop rbx
 ret

NEBOC_ABI_FUNCTION neboc_function_plan_compute_hash
 sub rsp,8
 test rdi,rdi
 jz .invalid
 mov eax,NEBOC_LOWERING_HASH_FNV1A32_OFFSET_BASIS
 xor ecx,ecx
.hash_loop:
 cmp ecx,11
 jae .store
 mov rdx,[rdi+rcx*8]
 call .hash_qword
 inc ecx
 jmp .hash_loop
.store:
 mov [rdi+NEBOC_FUNCTION_PLAN_HASH_OFFSET],rax
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
 imul eax,eax,NEBOC_LOWERING_HASH_FNV1A32_PRIME
 shr rdx,8
 dec r8d
 jnz .hash_byte
 ret

NEBOC_ABI_FUNCTION neboc_lowering_operation_compute_hash
 sub rsp,8
 test rdi,rdi
 jz .invalid
 mov eax,NEBOC_LOWERING_HASH_FNV1A32_OFFSET_BASIS
 xor ecx,ecx
.hash_loop:
 cmp ecx,9
 jae .store
 mov rdx,[rdi+rcx*8]
 call .hash_qword
 inc ecx
 jmp .hash_loop
.store:
 mov [rdi+NEBOC_LOWERING_OPERATION_HASH_OFFSET],rax
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
 imul eax,eax,NEBOC_LOWERING_HASH_FNV1A32_PRIME
 shr rdx,8
 dec r8d
 jnz .hash_byte
 ret

NEBOC_ABI_FUNCTION neboc_function_lowering_table_compute_hash
 push rbx
 push r12
 push r13
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov eax,NEBOC_LOWERING_HASH_FNV1A32_OFFSET_BASIS
 mov r13,[r12+NEBOC_LOWERING_TABLE_PLAN_COUNT_OFFSET]
 mov rdx,r13
 call .hash_qword
 xor ebx,ebx
.plan_loop:
 cmp rbx,r13
 jae .operation_start
 mov rdx,rbx
 imul rdx,NEBOC_FUNCTION_PLAN_SIZE
 add rdx,[r12+NEBOC_LOWERING_TABLE_PLAN_DATA_OFFSET]
 mov rdx,[rdx+NEBOC_FUNCTION_PLAN_HASH_OFFSET]
 call .hash_qword
 inc rbx
 jmp .plan_loop
.operation_start:
 mov r13,[r12+NEBOC_LOWERING_TABLE_OPERATION_COUNT_OFFSET]
 mov rdx,r13
 call .hash_qword
 xor ebx,ebx
.operation_loop:
 cmp rbx,r13
 jae .store
 mov rdx,rbx
 imul rdx,NEBOC_LOWERING_OPERATION_SIZE
 add rdx,[r12+NEBOC_LOWERING_TABLE_OPERATION_DATA_OFFSET]
 mov rdx,[rdx+NEBOC_LOWERING_OPERATION_HASH_OFFSET]
 call .hash_qword
 inc rbx
 jmp .operation_loop
.store:
 mov [r12+NEBOC_LOWERING_TABLE_HASH_OFFSET],rax
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
 imul eax,eax,NEBOC_LOWERING_HASH_FNV1A32_PRIME
 shr rdx,8
 dec r8d
 jnz .hash_byte
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
