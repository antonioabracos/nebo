bits 64
default rel
%include "runtime/data/file_dataset_bridge.inc"
extern neboc_column_init
extern neboc_schema_init
extern neboc_table_init
extern neboc_dataset_init

global _start
section .text
_start:
 mov qword [rel names],0x1111
 mov qword [rel dtypes],NEBO_DTYPE_I64
 lea rdi,[rel schema]
 lea rsi,[rel names]
 lea rdx,[rel dtypes]
 xor ecx,ecx
 xor r8d,r8d
 mov r9d,1
 call neboc_schema_init
 test eax,eax
 jnz .fail1
 mov qword [rel values],17
 mov qword [rel values+8],23
 lea rdi,[rel column]
 lea rsi,[rel values]
 mov edx,2
 mov ecx,2
 mov r8d,NEBO_DTYPE_I64
 xor r9d,r9d
 call neboc_column_init
 test eax,eax
 jnz .fail2
 lea rax,[rel column]
 mov [rel columns],rax
 lea rdi,[rel table]
 lea rsi,[rel schema]
 lea rdx,[rel columns]
 mov ecx,1
 mov r8d,2
 call neboc_table_init
 test eax,eax
 jnz .fail3
 lea rax,[rel table]
 mov [rel tables],rax
 lea rdi,[rel dataset]
 lea rsi,[rel schema]
 lea rdx,[rel tables]
 mov ecx,1
 mov r8d,8
 mov r9d,256
 call neboc_dataset_init
 test eax,eax
 jnz .fail4
 mov rax,NEBO_FILE_CAPABILITY_MAGIC_VALUE
 mov [rel capability+NEBO_FILE_CAPABILITY_MAGIC],rax
 mov qword [rel capability+NEBO_FILE_CAPABILITY_PERMISSIONS],NEBO_FILE_CAP_READ
 mov qword [rel capability+NEBO_FILE_CAPABILITY_MAX_IO_BYTES],4096
 mov dword [rel capability+NEBO_FILE_CAPABILITY_GENERATION],7
 lea rdi,[rel bridge]
 lea rsi,[rel capability]
 lea rdx,[rel dataset]
 mov ecx,8
 mov r8d,256
 call nebo_file_dataset_bridge_init
 test eax,eax
 jnz .fail5
 lea rdi,[rel bridge]
 call nebo_file_dataset_bridge_validate
 test eax,eax
 jnz .fail6
 lea rdi,[rel bridge]
 lea rsi,[rel out_table]
 lea rdx,[rel out_rows]
 call nebo_file_dataset_bridge_scan_next
 test eax,eax
 jnz .fail7
 lea rax,[rel table]
 cmp [rel out_table],rax
 jne .fail8
 cmp qword [rel out_rows],2
 jne .fail9
 mov qword [rel out_table],0x55
 mov qword [rel out_rows],0x66
 lea rdi,[rel bridge]
 lea rsi,[rel out_table]
 lea rdx,[rel out_rows]
 call nebo_file_dataset_bridge_scan_next
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail10
 cmp qword [rel out_table],0x55
 jne .fail11
 cmp qword [rel out_rows],0x66
 jne .fail12
 inc dword [rel capability+NEBO_FILE_CAPABILITY_GENERATION]
 lea rdi,[rel bridge]
 call nebo_file_dataset_bridge_validate
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail13
 dec dword [rel capability+NEBO_FILE_CAPABILITY_GENERATION]
 mov qword [rel denied_bridge],0x77
 mov qword [rel capability+NEBO_FILE_CAPABILITY_PERMISSIONS],NEBO_FILE_CAP_WRITE
 lea rdi,[rel denied_bridge]
 lea rsi,[rel capability]
 lea rdx,[rel dataset]
 mov ecx,8
 mov r8d,256
 call nebo_file_dataset_bridge_init
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail14
 cmp qword [rel denied_bridge],0x77
 jne .fail15
 mov qword [rel capability+NEBO_FILE_CAPABILITY_PERMISSIONS],NEBO_FILE_CAP_READ
 lea rdi,[rel denied_bridge]
 lea rsi,[rel capability]
 lea rdx,[rel dataset]
 mov ecx,1
 mov r8d,256
 call nebo_file_dataset_bridge_init
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail16
 xor edi,edi
 jmp .exit
.fail1: mov edi,1
 jmp .exit
.fail2: mov edi,2
 jmp .exit
.fail3: mov edi,3
 jmp .exit
.fail4: mov edi,4
 jmp .exit
.fail5: mov edi,5
 jmp .exit
.fail6: mov edi,6
 jmp .exit
.fail7: mov edi,7
 jmp .exit
.fail8: mov edi,8
 jmp .exit
.fail9: mov edi,9
 jmp .exit
.fail10: mov edi,10
 jmp .exit
.fail11: mov edi,11
 jmp .exit
.fail12: mov edi,12
 jmp .exit
.fail13: mov edi,13
 jmp .exit
.fail14: mov edi,14
 jmp .exit
.fail15: mov edi,15
 jmp .exit
.fail16: mov edi,16
.exit:
 mov eax,60
 syscall

section .bss
align 8
schema resb NEBO_SCHEMA_SIZE
column resb NEBO_COLUMN_SIZE
table resb NEBO_TABLE_SIZE
dataset resb NEBO_DATASET_SIZE
capability resb NEBO_FILE_CAPABILITY_SIZE
bridge resb NEBO_FILE_DATASET_BRIDGE_SIZE
denied_bridge resb NEBO_FILE_DATASET_BRIDGE_SIZE
names resq 1
dtypes resq 1
values resq 2
columns resq 1
tables resq 1
out_table resq 1
out_rows resq 1

section .note.GNU-stack noalloc noexec nowrite progbits
