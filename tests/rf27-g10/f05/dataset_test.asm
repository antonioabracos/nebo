bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/data/data_contract.inc"
extern neboc_column_init
extern neboc_schema_init
extern neboc_table_init
extern neboc_dataset_init
extern neboc_dataset_validate
extern neboc_dataset_partition_at
extern neboc_dataset_collect_refs
global _start
section .text
_start:
 mov qword [rel names],1
 mov qword [rel dtypes],NEBO_DTYPE_I64
 lea rdi,[rel schema]
 lea rsi,[rel names]
 lea rdx,[rel dtypes]
 xor ecx,ecx
 xor r8d,r8d
 mov r9d,1
 call neboc_schema_init
 test eax,eax
 jnz fail1
 mov qword [rel vals0],10
 mov qword [rel vals0+8],20
 mov qword [rel vals1],30
 lea rdi,[rel col0]
 lea rsi,[rel vals0]
 mov edx,2
 mov ecx,2
 mov r8d,NEBO_DTYPE_I64
 xor r9d,r9d
 call neboc_column_init
 test eax,eax
 jnz fail1
 lea rdi,[rel col1]
 lea rsi,[rel vals1]
 mov edx,1
 mov ecx,1
 mov r8d,NEBO_DTYPE_I64
 xor r9d,r9d
 call neboc_column_init
 test eax,eax
 jnz fail1
 lea rax,[rel col0]
 mov [rel cols0],rax
 lea rax,[rel col1]
 mov [rel cols1],rax
 lea rdi,[rel table0]
 lea rsi,[rel schema]
 lea rdx,[rel cols0]
 mov ecx,1
 mov r8d,2
 call neboc_table_init
 test eax,eax
 jnz fail1
 lea rdi,[rel table1]
 lea rsi,[rel schema]
 lea rdx,[rel cols1]
 mov ecx,1
 mov r8d,1
 call neboc_table_init
 test eax,eax
 jnz fail1
 lea rax,[rel table0]
 mov [rel tables],rax
 lea rax,[rel table1]
 mov [rel tables+8],rax
 lea rdi,[rel dataset]
 lea rsi,[rel schema]
 lea rdx,[rel tables]
 mov ecx,2
 mov r8d,3
 mov r9d,24
 call neboc_dataset_init
 test eax,eax
 jnz fail2
 cmp qword [rel dataset+NEBO_DATASET_ROWS],3
 jne fail2
 lea rdi,[rel dataset]
 call neboc_dataset_validate
 test eax,eax
 jnz fail2

 lea rdi,[rel dataset]
 mov esi,1
 lea rdx,[rel out]
 call neboc_dataset_partition_at
 test eax,eax
 jnz fail3
 lea rax,[rel table1]
 cmp [rel out],rax
 jne fail3

 mov qword [rel out_parts],0x55
 lea rdi,[rel dataset]
 lea rsi,[rel out_parts]
 lea rdx,[rel out_rows]
 mov ecx,2
 lea r8,[rel length]
 call neboc_dataset_collect_refs
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail4
 cmp qword [rel out_parts],0x55
 jne fail4
 lea rdi,[rel dataset]
 lea rsi,[rel out_parts]
 lea rdx,[rel out_rows]
 mov ecx,3
 lea r8,[rel length]
 call neboc_dataset_collect_refs
 test eax,eax
 jnz fail4
 cmp qword [rel length],3
 jne fail4
 cmp qword [rel out_parts],0
 jne fail4
 cmp qword [rel out_rows+8],1
 jne fail4
 cmp qword [rel out_parts+16],1
 jne fail4
 cmp qword [rel out_rows+16],0
 jne fail4

 ; budget refusal is failure atomic.
 mov qword [rel bad_dataset],0x66
 lea rdi,[rel bad_dataset]
 lea rsi,[rel schema]
 lea rdx,[rel tables]
 mov ecx,2
 mov r8d,2
 mov r9d,24
 call neboc_dataset_init
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail5
 cmp qword [rel bad_dataset],0x66
 jne fail5

 ; partition schema identity mismatch is rejected.
 mov qword [rel names2],2
 lea rdi,[rel schema2]
 lea rsi,[rel names2]
 lea rdx,[rel dtypes]
 xor ecx,ecx
 xor r8d,r8d
 mov r9d,1
 call neboc_schema_init
 test eax,eax
 jnz fail6
 mov qword [rel table1+NEBO_TABLE_SCHEMA],schema2
 lea rdi,[rel bad_dataset]
 lea rsi,[rel schema]
 lea rdx,[rel tables]
 mov ecx,2
 mov r8d,3
 mov r9d,24
 call neboc_dataset_init
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail6

 xor edi,edi
 jmp exit
fail1: mov edi,1
 jmp exit
fail2: mov edi,2
 jmp exit
fail3: mov edi,3
 jmp exit
fail4: mov edi,4
 jmp exit
fail5: mov edi,5
 jmp exit
fail6: mov edi,6
exit:
 mov eax,60
 syscall
section .bss
align 8
schema: resb NEBO_SCHEMA_SIZE
schema2: resb NEBO_SCHEMA_SIZE
col0: resb NEBO_COLUMN_SIZE
col1: resb NEBO_COLUMN_SIZE
table0: resb NEBO_TABLE_SIZE
table1: resb NEBO_TABLE_SIZE
dataset: resb NEBO_DATASET_SIZE
bad_dataset: resb NEBO_DATASET_SIZE
names: resq 1
names2: resq 1
dtypes: resq 1
vals0: resq 2
vals1: resq 1
cols0: resq 1
cols1: resq 1
tables: resq 2
out_parts: resq 3
out_rows: resq 3
out: resq 1
length: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
