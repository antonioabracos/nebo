bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/data/data_contract.inc"
extern neboc_column_init
extern neboc_schema_init
extern neboc_table_init
extern neboc_table_validate
extern neboc_table_get
extern neboc_table_select
extern neboc_table_filter_eq_i64
extern neboc_table_group_by_i64
extern neboc_table_inner_join_i64
global _start
section .text
_start:
 ; left columns: key=[1,2,1,3(missing)], value=[10,20,30,40]
 mov qword [rel key_values],1
 mov qword [rel key_values+8],2
 mov qword [rel key_values+16],1
 mov qword [rel key_values+24],3
 mov qword [rel value_values],10
 mov qword [rel value_values+8],20
 mov qword [rel value_values+16],30
 mov qword [rel value_values+24],40
 lea rdi,[rel key_column]
 lea rsi,[rel key_values]
 mov edx,4
 mov ecx,4
 mov r8d,NEBO_DTYPE_I64
 mov r9d,8
 call neboc_column_init
 test eax,eax
 jnz fail1
 lea rdi,[rel value_column]
 lea rsi,[rel value_values]
 mov edx,4
 mov ecx,4
 mov r8d,NEBO_DTYPE_I64
 xor r9d,r9d
 call neboc_column_init
 test eax,eax
 jnz fail1
 lea rax,[rel key_column]
 mov [rel left_columns],rax
 lea rax,[rel value_column]
 mov [rel left_columns+8],rax

 mov qword [rel left_names],0x6b6579
 mov rax,0x76616c7565
 mov [rel left_names+8],rax
 mov qword [rel left_dtypes],NEBO_DTYPE_I64
 mov qword [rel left_dtypes+8],NEBO_DTYPE_I64
 lea rdi,[rel left_schema]
 lea rsi,[rel left_names]
 lea rdx,[rel left_dtypes]
 mov ecx,1
 xor r8d,r8d
 mov r9d,2
 call neboc_schema_init
 test eax,eax
 jnz fail1
 lea rdi,[rel left_table]
 lea rsi,[rel left_schema]
 lea rdx,[rel left_columns]
 mov ecx,2
 mov r8d,4
 call neboc_table_init
 test eax,eax
 jnz fail1
 cmp qword [rel left_table+NEBO_TABLE_ROW_COUNT],4
 jne fail1

 lea rdi,[rel left_table]
 mov esi,2
 mov edx,1
 lea rcx,[rel out]
 lea r8,[rel present]
 call neboc_table_get
 test eax,eax
 jnz fail2
 cmp qword [rel out],30
 jne fail2
 cmp qword [rel present],1
 jne fail2
 lea rdi,[rel left_table]
 mov esi,3
 xor edx,edx
 lea rcx,[rel out]
 lea r8,[rel present]
 call neboc_table_get
 test eax,eax
 jnz fail2
 cmp qword [rel present],0
 jne fail2

 ; stable projection reverses the two columns and derives a matching schema.
 mov qword [rel select_indices],1
 mov qword [rel select_indices+8],0
 lea rax,[rel selected_names]
 mov [rel select_work+NEBO_TABLE_SELECT_NAMES],rax
 lea rax,[rel selected_dtypes]
 mov [rel select_work+NEBO_TABLE_SELECT_DTYPES],rax
 lea rax,[rel selected_defaults]
 mov [rel select_work+NEBO_TABLE_SELECT_DEFAULTS],rax
 lea rax,[rel selected_columns]
 mov [rel select_work+NEBO_TABLE_SELECT_COLUMNS],rax
 lea rax,[rel selected_schema]
 mov [rel select_work+NEBO_TABLE_SELECT_SCHEMA],rax
 lea rax,[rel selected_table]
 mov [rel select_work+NEBO_TABLE_SELECT_TABLE],rax
 lea rdi,[rel left_table]
 lea rsi,[rel select_indices]
 mov edx,2
 lea rcx,[rel select_work]
 call neboc_table_select
 test eax,eax
 jnz fail3
 mov rax,0x76616c7565
 cmp [rel selected_names],rax
 jne fail3
 lea rdi,[rel selected_table]
 call neboc_table_validate
 test eax,eax
 jnz fail3
 lea rdi,[rel selected_table]
 xor esi,esi
 xor edx,edx
 lea rcx,[rel out]
 lea r8,[rel present]
 call neboc_table_get
 test eax,eax
 jnz fail3
 cmp qword [rel out],10
 jne fail3

 ; filter is stable, skips missing and refuses capacity before writes.
 mov rax,0x1122334455667788
 mov [rel rows],rax
 lea rdi,[rel left_table]
 xor esi,esi
 mov edx,1
 lea rcx,[rel rows]
 mov r8d,1
 lea r9,[rel length]
 call neboc_table_filter_eq_i64
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail4
 mov rax,0x1122334455667788
 cmp [rel rows],rax
 jne fail4
 lea rdi,[rel left_table]
 xor esi,esi
 mov edx,1
 lea rcx,[rel rows]
 mov r8d,4
 lea r9,[rel length]
 call neboc_table_filter_eq_i64
 test eax,eax
 jnz fail4
 cmp qword [rel length],2
 jne fail4
 cmp qword [rel rows],0
 jne fail4
 cmp qword [rel rows+8],2
 jne fail4

 ; groupBy has deterministic first-seen order and excludes missing keys.
 mov qword [rel group_keys],0x55
 lea rdi,[rel left_table]
 xor esi,esi
 lea rdx,[rel group_keys]
 lea rcx,[rel group_counts]
 mov r8d,1
 lea r9,[rel length]
 call neboc_table_group_by_i64
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail5
 cmp qword [rel group_keys],0x55
 jne fail5
 lea rdi,[rel left_table]
 xor esi,esi
 lea rdx,[rel group_keys]
 lea rcx,[rel group_counts]
 mov r8d,4
 lea r9,[rel length]
 call neboc_table_group_by_i64
 test eax,eax
 jnz fail5
 cmp qword [rel length],2
 jne fail5
 cmp qword [rel group_keys],1
 jne fail5
 cmp qword [rel group_counts],2
 jne fail5
 cmp qword [rel group_keys+8],2
 jne fail5
 cmp qword [rel group_counts+8],1
 jne fail5

 ; right table key=[1,3(missing),1], yielding four left-major matches.
 mov qword [rel right_values],1
 mov qword [rel right_values+8],3
 mov qword [rel right_values+16],1
 lea rdi,[rel right_column]
 lea rsi,[rel right_values]
 mov edx,3
 mov ecx,3
 mov r8d,NEBO_DTYPE_I64
 mov r9d,2
 call neboc_column_init
 test eax,eax
 jnz fail6
 lea rax,[rel right_column]
 mov [rel right_columns],rax
 mov qword [rel right_names],0x726b6579
 mov qword [rel right_dtypes],NEBO_DTYPE_I64
 lea rdi,[rel right_schema]
 lea rsi,[rel right_names]
 lea rdx,[rel right_dtypes]
 mov ecx,1
 xor r8d,r8d
 mov r9d,1
 call neboc_schema_init
 test eax,eax
 jnz fail6
 lea rdi,[rel right_table]
 lea rsi,[rel right_schema]
 lea rdx,[rel right_columns]
 mov ecx,1
 mov r8d,3
 call neboc_table_init
 test eax,eax
 jnz fail6
 lea rax,[rel join_left]
 mov [rel join_work+NEBO_TABLE_JOIN_LEFT_ROWS],rax
 lea rax,[rel join_right]
 mov [rel join_work+NEBO_TABLE_JOIN_RIGHT_ROWS],rax
 mov qword [rel join_work+NEBO_TABLE_JOIN_CAPACITY],3
 lea rax,[rel length]
 mov [rel join_work+NEBO_TABLE_JOIN_LENGTH],rax
 mov qword [rel join_left],0x77
 lea rdi,[rel left_table]
 lea rsi,[rel right_table]
 xor edx,edx
 xor ecx,ecx
 lea r8,[rel join_work]
 call neboc_table_inner_join_i64
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail7
 cmp qword [rel join_left],0x77
 jne fail7
 mov qword [rel join_work+NEBO_TABLE_JOIN_CAPACITY],8
 lea rdi,[rel left_table]
 lea rsi,[rel right_table]
 xor edx,edx
 xor ecx,ecx
 lea r8,[rel join_work]
 call neboc_table_inner_join_i64
 test eax,eax
 jnz fail7
 cmp qword [rel length],4
 jne fail7
 cmp qword [rel join_left],0
 jne fail7
 cmp qword [rel join_right],0
 jne fail7
 cmp qword [rel join_left+8],0
 jne fail7
 cmp qword [rel join_right+8],2
 jne fail7
 cmp qword [rel join_left+16],2
 jne fail7

 ; duplicate fields and mismatched lengths are rejected without output mutation.
 mov qword [rel duplicate_names],9
 mov qword [rel duplicate_names+8],9
 mov qword [rel bad_schema],0x12345678
 lea rdi,[rel bad_schema]
 lea rsi,[rel duplicate_names]
 lea rdx,[rel left_dtypes]
 xor ecx,ecx
 xor r8d,r8d
 mov r9d,2
 call neboc_schema_init
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail8
 cmp qword [rel bad_schema],0x12345678
 jne fail8
 dec qword [rel value_column+NEBO_COLUMN_LENGTH]
 mov eax,0x88776655
 mov [rel bad_table],rax
 lea rdi,[rel bad_table]
 lea rsi,[rel left_schema]
 lea rdx,[rel left_columns]
 mov ecx,2
 mov r8d,4
 call neboc_table_init
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail8
 mov eax,0x88776655
 cmp [rel bad_table],rax
 jne fail8

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
 jmp exit
fail8: mov edi,8
exit:
 mov eax,60
 syscall
section .bss
align 8
key_column: resb NEBO_COLUMN_SIZE
value_column: resb NEBO_COLUMN_SIZE
right_column: resb NEBO_COLUMN_SIZE
left_schema: resb NEBO_SCHEMA_SIZE
right_schema: resb NEBO_SCHEMA_SIZE
selected_schema: resb NEBO_SCHEMA_SIZE
bad_schema: resb NEBO_SCHEMA_SIZE
left_table: resb NEBO_TABLE_SIZE
right_table: resb NEBO_TABLE_SIZE
selected_table: resb NEBO_TABLE_SIZE
bad_table: resb NEBO_TABLE_SIZE
key_values: resq 4
value_values: resq 4
right_values: resq 3
left_names: resq 2
left_dtypes: resq 2
left_columns: resq 2
right_names: resq 1
right_dtypes: resq 1
right_columns: resq 1
duplicate_names: resq 2
select_indices: resq 2
selected_names: resq 2
selected_dtypes: resq 2
selected_defaults: resq 2
selected_columns: resq 2
select_work: resb NEBO_TABLE_SELECT_WORK_SIZE
rows: resq 4
group_keys: resq 4
group_counts: resq 4
join_left: resq 8
join_right: resq 8
join_work: resb NEBO_TABLE_JOIN_WORK_SIZE
out: resq 1
present: resq 1
length: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
