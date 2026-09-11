bits 64
default rel
%include "runtime/serialization/csv.inc"
%include "runtime/filesystem/text.inc"
extern nebo_file_capability_init
extern neboc_column_init
extern neboc_schema_init
extern neboc_table_init
extern neboc_dataset_init
extern neboc_dataset_validate

%define SYS_OPENAT 257
%define SYS_CLOSE 3
%define AT_FDCWD -100
%define O_DIRECTORY 0x10000
%define O_CLOEXEC 0x80000

section .rodata
csv db '1,2',13,10,'3,',13,10,'-4,"5"',13,10
csv_len equ $-csv
canonical db '1,2',10,'3,',10,'-4,5',10
canonical_len equ $-canonical
bad_csv db '1,2',10,'3',10
bad_csv_len equ $-bad_csv
csv_path db 'data.csv',0

section .data
schema_names dq 0x1111,0x2222
schema_dtypes dq NEBO_DTYPE_I64,NEBO_DTYPE_I64

section .bss
align 8
values resq NEBO_DATA_MAX_FIELDS*NEBO_DATA_MAX_ROWS
missing resq NEBO_DATA_MAX_FIELDS
output resb 128
readback resb 128
column_one resb NEBO_COLUMN_SIZE
column_two resb NEBO_COLUMN_SIZE
column_ptrs resq 2
schema resb NEBO_SCHEMA_SIZE
table resb NEBO_TABLE_SIZE
table_ptrs resq 1
dataset resb NEBO_DATASET_SIZE
capability resb NEBO_FILE_CAPABILITY_SIZE

section .text
global _start
_start:
 lea rdi,[values]
 mov qword [rdi],0x55
 lea rsi,[missing]
 mov qword [rsi],0xaa
 lea rdi,[bad_csv]
 mov esi,bad_csv_len
 lea rdx,[values]
 lea rcx,[missing]
 mov r8d,8
 mov r9,0x0000000200000004
 call nebo_csv_parse_i64
 cmp eax,NEBO_FILE_ERROR_MALFORMED_FORMAT
 jne .fail1
 cmp qword [values],0x55
 jne .fail2
 cmp qword [missing],0xaa
 jne .fail3
 lea rdi,[csv]
 mov esi,csv_len
 lea rdx,[values]
 lea rcx,[missing]
 mov r8d,8
 mov r9,0x0000000200000004
 call nebo_csv_parse_i64
 test eax,eax
 jnz .fail4
 cmp edx,3
 jne .fail5
 cmp ecx,2
 jne .fail6
 cmp qword [values],1
 jne .fail7
 cmp qword [values+8],3
 jne .fail8
 cmp qword [values+16],-4
 jne .fail9
 cmp qword [values+NEBO_DATA_MAX_ROWS*8],2
 jne .fail10
 cmp qword [values+NEBO_DATA_MAX_ROWS*8+16],5
 jne .fail11
 cmp qword [missing+8],2
 jne .fail12
 lea rdi,[values]
 lea rsi,[missing]
 mov edx,3
 mov ecx,2
 lea r8,[output]
 mov r9d,128
 call nebo_csv_write_i64
 test eax,eax
 jnz .fail13
 cmp edx,canonical_len
 jne .fail14
 xor ecx,ecx
.compare:
 cmp ecx,canonical_len
 jae .compare_done
 mov al,[output+rcx]
 cmp al,[canonical+rcx]
 jne .fail15
 inc ecx
 jmp .compare
.compare_done:
 lea rdi,[column_one]
 lea rsi,[values]
 mov edx,3
 mov ecx,4
 mov r8d,NEBO_DTYPE_I64
 mov r9,[missing]
 call neboc_column_init
 test eax,eax
 jnz .fail16
 lea rdi,[column_two]
 lea rsi,[values+NEBO_DATA_MAX_ROWS*8]
 mov edx,3
 mov ecx,4
 mov r8d,NEBO_DTYPE_I64
 mov r9,[missing+8]
 call neboc_column_init
 test eax,eax
 jnz .fail17
 lea rax,[column_one]
 mov [column_ptrs],rax
 lea rax,[column_two]
 mov [column_ptrs+8],rax
 lea rdi,[schema]
 lea rsi,[schema_names]
 lea rdx,[schema_dtypes]
 mov ecx,2
 xor r8d,r8d
 mov r9d,2
 call neboc_schema_init
 test eax,eax
 jnz .fail18
 lea rdi,[table]
 lea rsi,[schema]
 lea rdx,[column_ptrs]
 mov ecx,2
 mov r8d,4
 call neboc_table_init
 test eax,eax
 jnz .fail19
 lea rax,[table]
 mov [table_ptrs],rax
 lea rdi,[dataset]
 lea rsi,[schema]
 lea rdx,[table_ptrs]
 mov ecx,1
 mov r8d,8
 mov r9d,1024
 call neboc_dataset_init
 test eax,eax
 jnz .fail20
 lea rdi,[dataset]
 call neboc_dataset_validate
 test eax,eax
 jnz .fail21
 cmp qword [dataset+NEBO_DATASET_ROWS],3
 jne .fail22
 cmp qword [rsp],2
 jne .fail23
 mov rsi,[rsp+16]
 mov eax,SYS_OPENAT
 mov rdi,AT_FDCWD
 mov edx,O_DIRECTORY | O_CLOEXEC
 xor r10d,r10d
 syscall
 test rax,rax
 js .fail24
 mov r15,rax
 lea rdi,[capability]
 mov rsi,r15
 mov edx,41
 mov ecx,NEBO_FILE_CAP_ALL
 mov r8d,4
 mov r9d,65536
 call nebo_file_capability_init
 test eax,eax
 jnz .fail25
 lea rdi,[capability]
 lea rsi,[csv_path]
 mov edx,8
 lea rcx,[output]
 mov r8d,canonical_len
 mov r9d,NEBO_TEXT_WRITE_ATOMIC
 call nebo_file_write_bytes
 test eax,eax
 jnz .fail26
 lea rdi,[capability]
 lea rsi,[csv_path]
 mov edx,8
 lea rcx,[readback]
 mov r8d,128
 call nebo_file_read_bytes
 test eax,eax
 jnz .fail27
 cmp edx,canonical_len
 jne .fail28
 mov eax,SYS_CLOSE
 mov rdi,r15
 syscall
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
 jmp .exit
.fail17: mov edi,17
 jmp .exit
.fail18: mov edi,18
 jmp .exit
.fail19: mov edi,19
 jmp .exit
.fail20: mov edi,20
 jmp .exit
.fail21: mov edi,21
 jmp .exit
.fail22: mov edi,22
 jmp .exit
.fail23: mov edi,23
 jmp .exit
.fail24: mov edi,24
 jmp .exit
.fail25: mov edi,25
 jmp .exit
.fail26: mov edi,26
 jmp .exit
.fail27: mov edi,27
 jmp .exit
.fail28: mov edi,28
.exit:
 mov eax,60
 syscall
