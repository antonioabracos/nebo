bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/data/data_contract.inc"
extern neboc_column_init
extern neboc_schema_init
extern neboc_table_init
extern neboc_schema_validate_missing_rules
extern neboc_row_apply_defaults
extern neboc_table_invalid_rows
extern neboc_column_fill_missing
extern neboc_column_coalesce
global _start
section .text
_start:
 mov qword [rel names],1
 mov qword [rel names+8],2
 mov qword [rel names+16],3
 mov qword [rel dtypes],NEBO_DTYPE_I64
 mov qword [rel dtypes+8],NEBO_DTYPE_I64
 mov qword [rel dtypes+16],NEBO_DTYPE_I64
 mov qword [rel defaults],0
 mov qword [rel defaults+8],22
 mov qword [rel defaults+16],0
 lea rdi,[rel schema]
 lea rsi,[rel names]
 lea rdx,[rel dtypes]
 mov ecx,4                 ; field 2 nullable
 lea r8,[rel defaults]
 mov r9d,3
 call neboc_schema_init
 test eax,eax
 jnz fail1
 mov qword [rel schema+NEBO_SCHEMA_DEFAULT_BITMAP],2
 lea rdi,[rel schema]
 call neboc_schema_validate_missing_rules
 test eax,eax
 jnz fail1

 mov qword [rel row_values],10
 mov qword [rel row_values+8],99
 mov qword [rel row_values+16],77
 lea rdi,[rel schema]
 lea rsi,[rel row_values]
 mov edx,6                 ; default field 1, nullable field 2
 lea rcx,[rel row_out]
 lea r8,[rel missing]
 call neboc_row_apply_defaults
 test eax,eax
 jnz fail2
 cmp qword [rel row_out],10
 jne fail2
 cmp qword [rel row_out+8],22
 jne fail2
 cmp qword [rel missing],4
 jne fail2

 mov qword [rel row_out],0x55
 lea rdi,[rel schema]
 lea rsi,[rel row_values]
 mov edx,1                 ; required field 0 missing
 lea rcx,[rel row_out]
 lea r8,[rel missing]
 call neboc_row_apply_defaults
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail3
 cmp qword [rel row_out],0x55
 jne fail3

 mov qword [rel values0],1
 mov qword [rel values0+8],2
 mov qword [rel values0+16],3
 mov qword [rel values1],10
 mov qword [rel values1+8],20
 mov qword [rel values1+16],30
 mov qword [rel values2],100
 mov qword [rel values2+8],200
 mov qword [rel values2+16],300
 lea rdi,[rel col0]
 lea rsi,[rel values0]
 mov edx,3
 mov ecx,3
 mov r8d,NEBO_DTYPE_I64
 mov r9d,2                 ; required missing row 1
 call neboc_column_init
 test eax,eax
 jnz fail4
 lea rdi,[rel col1]
 lea rsi,[rel values1]
 mov edx,3
 mov ecx,3
 mov r8d,NEBO_DTYPE_I64
 mov r9d,1                 ; defaultable missing row 0
 call neboc_column_init
 test eax,eax
 jnz fail4
 lea rdi,[rel col2]
 lea rsi,[rel values2]
 mov edx,3
 mov ecx,3
 mov r8d,NEBO_DTYPE_I64
 mov r9d,4                 ; nullable missing row 2
 call neboc_column_init
 test eax,eax
 jnz fail4
 lea rax,[rel col0]
 mov [rel columns],rax
 lea rax,[rel col1]
 mov [rel columns+8],rax
 lea rax,[rel col2]
 mov [rel columns+16],rax
 lea rdi,[rel table]
 lea rsi,[rel schema]
 lea rdx,[rel columns]
 mov ecx,3
 mov r8d,3
 call neboc_table_init
 test eax,eax
 jnz fail4
 lea rdi,[rel table]
 lea rsi,[rel invalid]
 call neboc_table_invalid_rows
 test eax,eax
 jnz fail4
 cmp qword [rel invalid],2
 jne fail4

 lea rdi,[rel col1]
 mov esi,22
 lea rdx,[rel filled]
 call neboc_column_fill_missing
 test eax,eax
 jnz fail5
 cmp qword [rel filled],1
 jne fail5
 cmp qword [rel values1],22
 jne fail5
 cmp qword [rel col1+NEBO_COLUMN_MISSING_BITMAP],0
 jne fail5

 ; coalesce takes left first, then right, then retains missing.
 lea rdi,[rel col0]
 lea rsi,[rel col2]
 lea rdx,[rel coalesced]
 lea rcx,[rel missing]
 call neboc_column_coalesce
 test eax,eax
 jnz fail6
 cmp qword [rel coalesced],1
 jne fail6
 cmp qword [rel coalesced+8],200
 jne fail6
 cmp qword [rel coalesced+16],3
 jne fail6
 cmp qword [rel missing],0
 jne fail6

 ; invalid default metadata and dtype mismatch remain typed errors.
 mov qword [rel schema+NEBO_SCHEMA_DEFAULTS],0
 lea rdi,[rel schema]
 call neboc_schema_validate_missing_rules
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail7
 lea rax,[rel defaults]
 mov [rel schema+NEBO_SCHEMA_DEFAULTS],rax
 inc qword [rel col2+NEBO_COLUMN_DTYPE]
 mov qword [rel coalesced],0x66
 lea rdi,[rel col0]
 lea rsi,[rel col2]
 lea rdx,[rel coalesced]
 lea rcx,[rel missing]
 call neboc_column_coalesce
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail7
 cmp qword [rel coalesced],0x66
 jne fail7

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
 jmp exit
fail7: mov edi,7
exit:
 mov eax,60
 syscall
section .bss
align 8
schema: resb NEBO_SCHEMA_SIZE
table: resb NEBO_TABLE_SIZE
col0: resb NEBO_COLUMN_SIZE
col1: resb NEBO_COLUMN_SIZE
col2: resb NEBO_COLUMN_SIZE
names: resq 3
dtypes: resq 3
defaults: resq 3
row_values: resq 3
row_out: resq 3
values0: resq 3
values1: resq 3
values2: resq 3
columns: resq 3
coalesced: resq 3
missing: resq 1
invalid: resq 1
filled: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
