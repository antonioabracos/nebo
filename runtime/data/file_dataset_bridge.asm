; COLECOES-PRIMITIVAS-F08 finite capability-bound Dataset scan bridge.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%define NEBO_FILE_DATASET_BRIDGE_IMPLEMENTATION 1
%include "runtime/data/file_dataset_bridge.inc"
extern neboc_dataset_validate
extern neboc_dataset_partition_at

section .text

; init(bridge*, FileCapability*, Dataset*, row_limit, byte_limit)
NEBOC_ABI_FUNCTION nebo_file_dataset_bridge_init
 test rdi,rdi
 jz .init_bad
 test rdi,7
 jnz .init_bad
 test rsi,rsi
 jz .init_bad
 test rdx,rdx
 jz .init_bad
 test rcx,rcx
 jz .init_limit
 cmp rcx,NEBO_DATA_MAX_DATASET_ROWS
 ja .init_limit
 test r8,r8
 jz .init_limit
 cmp r8,NEBO_DATA_MAX_DATASET_BYTES
 ja .init_limit
 mov rax,NEBO_FILE_CAPABILITY_MAGIC_VALUE
 cmp [rsi+NEBO_FILE_CAPABILITY_MAGIC],rax
 jne .init_source
 test qword [rsi+NEBO_FILE_CAPABILITY_PERMISSIONS],NEBO_FILE_CAP_READ
 jz .init_source
 cmp dword [rsi+NEBO_FILE_CAPABILITY_GENERATION],0
 je .init_source
 cmp r8,[rsi+NEBO_FILE_CAPABILITY_MAX_IO_BYTES]
 ja .init_limit
 cmp rcx,[rdx+NEBO_DATASET_ROW_BUDGET]
 ja .init_limit
 cmp r8,[rdx+NEBO_DATASET_BYTE_BUDGET]
 ja .init_limit
 cmp qword [rdx+NEBO_DATASET_GENERATION],0
 je .init_source
 cmp [rdx+NEBO_DATASET_ROWS],rcx
 ja .init_limit
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r8
 mov rdi,r14
 call neboc_dataset_validate
 test eax,eax
 jnz .init_done
 mov rdi,r12
 mov ecx,NEBO_FILE_DATASET_BRIDGE_SIZE/8
 xor eax,eax
 rep stosq
 mov [r12+NEBO_FILE_DATASET_BRIDGE_CAPABILITY],r13
 mov [r12+NEBO_FILE_DATASET_BRIDGE_DATASET],r14
 mov eax,[r13+NEBO_FILE_CAPABILITY_GENERATION]
 mov [r12+NEBO_FILE_DATASET_BRIDGE_CAP_GENERATION],rax
 mov rax,[r14+NEBO_DATASET_GENERATION]
 mov [r12+NEBO_FILE_DATASET_BRIDGE_DATA_GENERATION],rax
 mov [r12+NEBO_FILE_DATASET_BRIDGE_ROW_LIMIT],r15
 mov [r12+NEBO_FILE_DATASET_BRIDGE_BYTE_LIMIT],rbp
 mov qword [r12+NEBO_FILE_DATASET_BRIDGE_STATE],NEBO_FILE_DATASET_BRIDGE_READY
 xor eax,eax
.init_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.init_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
.init_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.init_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

NEBOC_ABI_FUNCTION nebo_file_dataset_bridge_validate
 test rdi,rdi
 jz .validate_bad
 cmp qword [rdi+NEBO_FILE_DATASET_BRIDGE_STATE],NEBO_FILE_DATASET_BRIDGE_READY
 jne .validate_source
 mov rsi,[rdi+NEBO_FILE_DATASET_BRIDGE_CAPABILITY]
 mov rdx,[rdi+NEBO_FILE_DATASET_BRIDGE_DATASET]
 test rsi,rsi
 jz .validate_source
 test rdx,rdx
 jz .validate_source
 mov rax,NEBO_FILE_CAPABILITY_MAGIC_VALUE
 cmp [rsi+NEBO_FILE_CAPABILITY_MAGIC],rax
 jne .validate_source
 test qword [rsi+NEBO_FILE_CAPABILITY_PERMISSIONS],NEBO_FILE_CAP_READ
 jz .validate_source
 mov eax,[rsi+NEBO_FILE_CAPABILITY_GENERATION]
 cmp rax,[rdi+NEBO_FILE_DATASET_BRIDGE_CAP_GENERATION]
 jne .validate_source
 mov rax,[rdx+NEBO_DATASET_GENERATION]
 cmp rax,[rdi+NEBO_FILE_DATASET_BRIDGE_DATA_GENERATION]
 jne .validate_source
 mov rax,[rdi+NEBO_FILE_DATASET_BRIDGE_ROW_LIMIT]
 cmp [rdx+NEBO_DATASET_ROWS],rax
 ja .validate_source
 mov rax,[rdi+NEBO_FILE_DATASET_BRIDGE_BYTE_LIMIT]
 cmp rax,[rsi+NEBO_FILE_CAPABILITY_MAX_IO_BYTES]
 ja .validate_source
 cmp rax,[rdx+NEBO_DATASET_BYTE_BUDGET]
 ja .validate_source
 mov rdi,rdx
 jmp neboc_dataset_validate
.validate_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
.validate_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

; scan_next(bridge*, out_table**, out_rows*) is failure atomic.
NEBOC_ABI_FUNCTION nebo_file_dataset_bridge_scan_next
 test rsi,rsi
 jz .scan_bad
 test rdx,rdx
 jz .scan_bad
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call nebo_file_dataset_bridge_validate
 test eax,eax
 jnz .scan_done
 mov r15,[r12+NEBO_FILE_DATASET_BRIDGE_PARTITION_INDEX]
 mov rdi,[r12+NEBO_FILE_DATASET_BRIDGE_DATASET]
 cmp r15,[rdi+NEBO_DATASET_PARTITIONS]
 jae .scan_limit
 mov rsi,r15
 lea rdx,[rsp]
 call neboc_dataset_partition_at
 test eax,eax
 jnz .scan_done
 mov rax,[rsp]
 mov rcx,[rax+NEBO_TABLE_ROW_COUNT]
 cmp rcx,[r12+NEBO_FILE_DATASET_BRIDGE_ROW_LIMIT]
 ja .scan_limit
 mov [r13],rax
 mov [r14],rcx
 inc qword [r12+NEBO_FILE_DATASET_BRIDGE_PARTITION_INDEX]
 xor eax,eax
 jmp .scan_done
.scan_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.scan_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.scan_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
