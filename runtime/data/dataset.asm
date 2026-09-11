; COLECOES-PRIMITIVAS-F05 finite in-memory bounded Dataset.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/data/data_contract.inc"
extern neboc_schema_validate
extern neboc_table_validate
section .text

; dataset_init(ds*, schema*, table_ptrs*, partitions, row_budget, byte_budget)
NEBOC_ABI_FUNCTION neboc_dataset_init
 test rdi,rdi
 jz .di_bad
 test rdi,7
 jnz .di_bad
 test rsi,rsi
 jz .di_bad
 test rdx,rdx
 jz .di_bad
 test rcx,rcx
 jz .di_limit
 cmp rcx,NEBO_DATA_MAX_PARTITIONS
 ja .di_limit
 test r8,r8
 jz .di_limit
 cmp r8,NEBO_DATA_MAX_DATASET_ROWS
 ja .di_limit
 test r9,r9
 jz .di_limit
 cmp r9,NEBO_DATA_MAX_DATASET_BYTES
 ja .di_limit
 push r12
 push r13
 push r14
 push r15
 push rbp
 push rbx
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r8
 mov rbx,r9
 mov rdi,r13
 call neboc_schema_validate
 test eax,eax
 jnz .di_done
 xor r10d,r10d
 xor r11d,r11d
 xor r8d,r8d
.di_loop:
 cmp r10,r15
 jae .di_budget
 mov rdi,[r14+r10*8]
 test rdi,rdi
 jz .di_source
 push r8
 push r10
 push r11
 sub rsp,8
 call neboc_table_validate
 add rsp,8
 pop r11
 pop r10
 pop r8
 test eax,eax
 jnz .di_source
 mov rax,[r14+r10*8]
 cmp [rax+NEBO_TABLE_SCHEMA],r13
 jne .di_source
 mov rcx,[rax+NEBO_TABLE_ROW_COUNT]
 add r11,rcx
 jc .di_limit_saved
 imul rcx,[rax+NEBO_TABLE_COLUMN_COUNT]
 jo .di_limit_saved
 shl rcx,3
 jc .di_limit_saved
 add r8,rcx
 jc .di_limit_saved
 inc r10
 jmp .di_loop
.di_budget:
 cmp r11,rbp
 ja .di_limit_saved
 cmp r8,rbx
 ja .di_limit_saved
 mov rdi,r12
 mov ecx,NEBO_DATASET_SIZE/8
 xor eax,eax
 rep stosq
 mov [r12+NEBO_DATASET_SCHEMA],r13
 mov [r12+NEBO_DATASET_TABLES],r14
 mov [r12+NEBO_DATASET_PARTITIONS],r15
 mov [r12+NEBO_DATASET_ROWS],r11
 mov [r12+NEBO_DATASET_ROW_BUDGET],rbp
 mov [r12+NEBO_DATASET_BYTE_BUDGET],rbx
 mov qword [r12+NEBO_DATASET_GENERATION],1
 xor eax,eax
 jmp .di_done
.di_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .di_done
.di_limit_saved: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.di_done:
 add rsp,8
 pop rbx
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.di_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.di_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_dataset_validate
 test rdi,rdi
 jz .dv_bad
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov r12,rdi
 mov r13,[r12+NEBO_DATASET_SCHEMA]
 mov r14,[r12+NEBO_DATASET_TABLES]
 mov r15,[r12+NEBO_DATASET_PARTITIONS]
 test r13,r13
 jz .dv_source
 test r14,r14
 jz .dv_source
 test r15,r15
 jz .dv_source
 cmp r15,NEBO_DATA_MAX_PARTITIONS
 ja .dv_source
 cmp qword [r12+NEBO_DATASET_ROWS],NEBO_DATA_MAX_DATASET_ROWS
 ja .dv_source
 cmp qword [r12+NEBO_DATASET_ROW_BUDGET],NEBO_DATA_MAX_DATASET_ROWS
 ja .dv_source
 cmp qword [r12+NEBO_DATASET_BYTE_BUDGET],NEBO_DATA_MAX_DATASET_BYTES
 ja .dv_source
 xor r10d,r10d
 xor r11d,r11d
.dv_loop:
 cmp r10,r15
 jae .dv_rows
 mov rdi,[r14+r10*8]
 push r10
 push r11
 call neboc_table_validate
 pop r11
 pop r10
 test eax,eax
 jnz .dv_source
 mov rax,[r14+r10*8]
 cmp [rax+NEBO_TABLE_SCHEMA],r13
 jne .dv_source
 add r11,[rax+NEBO_TABLE_ROW_COUNT]
 inc r10
 jmp .dv_loop
.dv_rows:
 cmp r11,[r12+NEBO_DATASET_ROWS]
 jne .dv_source
 cmp r11,[r12+NEBO_DATASET_ROW_BUDGET]
 ja .dv_source
 xor eax,eax
 jmp .dv_done
.dv_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
.dv_done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.dv_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; partition_at(dataset*, index, out_table_ptr*)
NEBOC_ABI_FUNCTION neboc_dataset_partition_at
 test rdx,rdx
 jz .dpa_bad
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r14],0
 call neboc_dataset_validate
 test eax,eax
 jnz .dpa_done
 cmp r13,[r12+NEBO_DATASET_PARTITIONS]
 jae .dpa_limit
 mov rax,[r12+NEBO_DATASET_TABLES]
 mov rax,[rax+r13*8]
 mov [r14],rax
 xor eax,eax
 jmp .dpa_done
.dpa_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.dpa_done:
 pop r14
 pop r13
 pop r12
 ret
.dpa_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; collect_refs(dataset*, out_partitions*, out_rows*, capacity, out_length*)
NEBOC_ABI_FUNCTION neboc_dataset_collect_refs
 test rsi,rsi
 jz .dcr_bad
 test rdx,rdx
 jz .dcr_bad
 test r8,r8
 jz .dcr_bad
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
 mov qword [rbp],0
 call neboc_dataset_validate
 test eax,eax
 jnz .dcr_done
 mov rax,[r12+NEBO_DATASET_ROWS]
 cmp rax,r15
 ja .dcr_limit
 xor r10d,r10d
 xor r11d,r11d
.dcr_part:
 cmp r10,[r12+NEBO_DATASET_PARTITIONS]
 jae .dcr_ok
 mov rax,[r12+NEBO_DATASET_TABLES]
 mov rax,[rax+r10*8]
 xor ecx,ecx
.dcr_row:
 cmp rcx,[rax+NEBO_TABLE_ROW_COUNT]
 jae .dcr_next
 mov [r13+r11*8],r10
 mov [r14+r11*8],rcx
 inc r11
 inc rcx
 jmp .dcr_row
.dcr_next: inc r10
 jmp .dcr_part
.dcr_ok: mov [rbp],r11
 xor eax,eax
 jmp .dcr_done
.dcr_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.dcr_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.dcr_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
